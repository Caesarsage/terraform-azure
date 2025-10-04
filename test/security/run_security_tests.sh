#!/usr/bin/env bash
# Usage: ./run_security_tests.sh [command] [optional_folder]

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() {
  local level=$1; shift
  local color=$NC
  case "$level" in
    INFO) color=$BLUE ;;
    SUCCESS) color=$GREEN ;;
    WARN) color=$YELLOW ;;
    ERROR) color=$RED ;;
  esac
  printf "%b[%s] %s%b\n" "$color" "$level" "$*" "$NC" >&2
}

# Paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly RESULTS_DIR="${RESULTS_DIR:-$PROJECT_ROOT/test-results/security}"

mkdir -p "$RESULTS_DIR"

# Get scan target
get_scan_target() {
  local folder="${1:-}"
  if [[ -z "$folder" ]]; then
    echo "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT/$folder" ]]; then
    echo "$PROJECT_ROOT/$folder"
  elif [[ -d "$folder" ]]; then
    echo "$folder"
  else
    log ERROR "Folder not found: $folder"
    exit 1
  fi
}

# Install Trivy
install_trivy() {
  command -v trivy >/dev/null 2>&1 && return 0
  log INFO "Installing Trivy..."
  case "$(uname -s)" in
    Linux*) curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin ;;
    Darwin*) brew install trivy 2>/dev/null || { log ERROR "Install Trivy manually"; return 1; } ;;
    *) log ERROR "Unsupported OS"; return 1 ;;
  esac
}

# Install Checkov
install_checkov() {
  command -v checkov >/dev/null 2>&1 && return 0
  log INFO "Installing Checkov..."
  pip3 install --user checkov >/dev/null 2>&1 || pip install --user checkov >/dev/null 2>&1 || {
    log ERROR "Failed to install Checkov"
    return 1
  }
  # Add to PATH
  local pybin
  pybin=$(python3 -c "import site; print(site.USER_BASE + '/bin')" 2>/dev/null || echo "")
  [[ -n "$pybin" ]] && export PATH="$pybin:$PATH"
}

# Run Trivy
run_trivy() {
  local target
  target=$(get_scan_target "${1:-}")
  local name
  name=$(basename "$target")

  install_trivy || exit 1

  log INFO "Running Trivy on: $target"
  local out="$RESULTS_DIR/trivy-${name}.json"

  trivy config "$target" \
    --severity CRITICAL,HIGH,MEDIUM \
    --format json \
    --exit-code 0 \
    --output "$out"

  if command -v jq >/dev/null 2>&1 && [[ -f "$out" ]]; then
    local crit high med
    crit=$(jq '[.Results[]?.Misconfigurations[]? | select(.Severity=="CRITICAL")] | length' "$out")
    high=$(jq '[.Results[]?.Misconfigurations[]? | select(.Severity=="HIGH")] | length' "$out")
    med=$(jq '[.Results[]?.Misconfigurations[]? | select(.Severity=="MEDIUM")] | length' "$out")

    log INFO "Results: Critical=$crit, High=$high, Medium=$med"

    if (( crit > 0 || high > 0 )); then
      log WARN "Found critical/high issues. Review: $out"
      return 1
    fi
  fi

  log SUCCESS "Trivy scan passed"
}

# Run Checkov
run_checkov() {
  local target
  target=$(get_scan_target "${1:-}")
  local name
  name=$(basename "$target")

  install_checkov || exit 1

  log INFO "Running Checkov on: $target"
  local out="$RESULTS_DIR/checkov-${name}.json"

  local args=(
    --directory "$target"
    --framework terraform
    --quiet
    --output json
  )

  # Use config if exists
  if [[ -f "$PROJECT_ROOT/.checkov.yaml" ]]; then
    args+=(--config-file "$PROJECT_ROOT/.checkov.yaml")
  fi

  set +e
  checkov "${args[@]}" > "$out" 2>/dev/null
  local rc=$?
  set -e

  # Pretty-print failures to GitHub Actions log
  if command -v jq >/dev/null 2>&1 && [[ -s "$out" ]]; then
    echo "::group::Checkov failed checks"
    jq -r '
        .results.failed_checks[]? |
        "\(.severity)\t\(.check_id)\t\(.check_name)\n  file:\(.file_path):\(.file_line_range[0] // 1)  resource:\(.resource)\n  guideline:\(.guideline // "n/a")\n"
    ' "$out"
    echo "::endgroup::"

    # Inline annotations on the PR (non-fatal warnings)
    jq -r '
        .results.failed_checks[]? |
        "::warning file=\(.file_path),line=\(.file_line_range[0] // 1),title=\(.check_id) \(.severity)::\(.check_name)"
    ' "$out"
  else
    # Fallback: dump raw output
    [ -f "$out" ] && cat "$out" || true
  fi

  if command -v jq >/dev/null 2>&1 && [[ -f "$out" ]]; then
    local passed failed
    passed=$(jq -r '.summary.passed // 0' "$out")
    failed=$(jq -r '.summary.failed // 0' "$out")

    log INFO "Results: Passed=$passed, Failed=$failed"

    if (( failed > 0 )); then
      log WARN "Found $failed failures. Review: $out"
      return 1
    fi
  elif (( rc != 0 )); then
    log WARN "Checkov returned non-zero. Review: $out"
    return 1
  fi

  log SUCCESS "Checkov scan passed"
}

# Validate Terraform
validate() {
  local target
  target=$(get_scan_target "${1:-}")

  log INFO "Validating Terraform in: $target"

  local failed=0
  while IFS= read -r -d '' dir; do
    (
      cd "$dir"
      terraform init -backend=false >/dev/null 2>&1 || exit 1
      terraform validate >/dev/null 2>&1 || exit 1
      terraform fmt -check -recursive >/dev/null 2>&1 || exit 1
    ) || {
      log ERROR "Validation failed: $dir"
      ((failed++))
    }
  done < <(find "$target" -type f -name "*.tf" \
    -not -path "*/.terraform/*" \
    -exec dirname {} \; | sort -u | tr '\n' '\0')

  if (( failed > 0 )); then
    log ERROR "Validation failed for $failed module(s)"
    return 1
  fi

  log SUCCESS "Validation passed"
}

# Run all checks
run_all() {
  local target="${1:-}"
  local failed=0

  validate "$target" || ((failed++))
  run_trivy "$target" || ((failed++))
  run_checkov "$target" || ((failed++))

  echo
  if (( failed == 0 )); then
    log SUCCESS "All checks passed"
    exit 0
  else
    log ERROR "$failed check(s) failed"
    exit 1
  fi
}

# Usage
usage() {
  cat <<'EOF'
Usage: ./run_security_tests.sh [command] [folder]

Commands:
  validate [folder]    Validate Terraform
  run_trivy [folder]   Run Trivy scan
  run_checkov [folder] Run Checkov scan
  all [folder]         Run all checks (default)
  help                 Show this help

Examples:
  ./run_security_tests.sh                    # Scan entire project
  ./run_security_tests.sh run_trivy          # Trivy on entire project
  ./run_security_tests.sh run_checkov azure-vm   # Checkov on azure-vm module
  ./run_security_tests.sh all azure-storage  # All checks on azure-storage

Results: $RESULTS_DIR
EOF
}

# Main
main() {
  local cmd="${1:-all}"
  local folder="${2:-}"

  case "$cmd" in
    help|-h|--help) usage; exit 0 ;;
    validate) validate "$folder" ;;
    run_trivy) run_trivy "$folder" ;;
    run_checkov) run_checkov "$folder" ;;
    all) run_all "$folder" ;;
    *)
      if [[ -d "$PROJECT_ROOT/$cmd" ]] || [[ -d "$cmd" ]]; then
        # Treat first arg as folder if it's a directory
        run_all "$cmd"
      else
        log ERROR "Unknown command: $cmd"
        usage
        exit 1
      fi
      ;;
  esac
}

main "$@"
