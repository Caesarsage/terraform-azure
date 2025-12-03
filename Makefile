# Azure Terraform Modules - Makefile
# This Makefile provides common tasks for testing, validation, and development

.PHONY: help test test-unit test-integration test-security test-performance lint format validate clean install-tools

# Default target
help: ## Show this help message
	@echo "Azure Terraform Modules - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Tool installation
install-tools: ## Install required tools for testing
	@echo "Installing required tools..."
	@if ! command -v terraform >/dev/null 2>&1; then \
		echo "Please install Terraform: https://terraform.io/downloads.html"; \
		exit 1; \
	fi
	@if ! command -v go >/dev/null 2>&1; then \
		echo "Please install Go: https://golang.org/dl/"; \
		exit 1; \
	fi
	@if ! command -v checkov >/dev/null 2>&1; then \
		echo "Installing Checkov..."; \
		pip install checkov; \
	fi
	@if ! command -v tfsec >/dev/null 2>&1; then \
		echo "Installing TFSec..."; \
		go install github.com/aquasecurity/tfsec/cmd/tfsec@latest; \
	fi
	@echo "Installing Terratest dependencies..."
	@cd test/terratest && go mod tidy

# Code quality and formatting
format: ## Format all Terraform files
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive .

lint: ## Lint all Terraform files
	@echo "Linting Terraform files..."
	@terraform fmt -check -recursive .

validate: ## Validate all Terraform configurations
	@echo "Validating Terraform configurations..."
	@find . -name "*.tf" -not -path "./test/*" -exec dirname {} \; | sort -u | while read dir; do \
		echo "Validating $$dir..."; \
		cd "$$dir" && terraform init -backend=false && terraform validate && cd -; \
	done

# Security scanning
security-scan: ## Run security scans on all modules
	@echo "Running security scans..."
	@echo "Running Checkov..."
	@checkov -d . --framework terraform --skip-check CKV_AZURE_1 --output cli
	@echo "Running TFSec..."
	@tfsec . --format json --out tfsec-results.json || true
	@echo "Security scan complete. Results saved to tfsec-results.json"

# Testing
test: test-unit test-integration test-security ## Run all tests

test-unit: lint validate ## Run unit tests (linting and validation)
	@echo "Running unit tests..."

test-integration: ## Run integration tests with Terratest
	@echo "Running integration tests..."
	@cd test/terratest && go test -v -timeout 30m

test-security: security-scan ## Run security tests
	@echo "Running security tests..."

#TODO: test-performance: ## Run performance tests
# 	@echo "Running performance tests..."
# 	@cd test/performance && ./run_performance_tests.sh

# Module-specific testing
test-module: ## Test specific module (usage: make test-module MODULE=azure-vm)
	@if [ -z "$(MODULE)" ]; then \
		echo "Usage: make test-module MODULE=module-name"; \
		echo "Available modules:"; \
		ls -d azure-*/ | sed 's|/||g'; \
		exit 1; \
	fi
	@echo "Testing module: $(MODULE)"
	@cd $(MODULE) && terraform init -backend=false && terraform validate
	@echo "Running Terratest for $(MODULE)..."
	@cd test/terratest && go test -v -run Test$(shell echo $(MODULE) | tr '[:lower:]-' '[:upper:]_') -timeout 30m

# TODO: Documentation
# docs: ## Generate documentation
# 	@echo "Generating documentation..."
# 	@terraform-docs markdown table --output-file README.md --output-mode inject .

# Cleanup
clean: ## Clean up temporary files and test resources
	@echo "Cleaning up..."
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
	@find . -name "terraform.tfstate*" -type f -delete 2>/dev/null || true
	@find . -name "*.tfplan" -type f -delete 2>/dev/null || true
	@find . -name "tfsec-results.json" -type f -delete 2>/dev/null || true
	@echo "Cleanup complete"

# Pre-commit setup
setup-pre-commit: ## Set up pre-commit hooks
	@echo "Setting up pre-commit hooks..."
	@pip install pre-commit
	@pre-commit install
	@echo "Pre-commit hooks installed"

# CI/CD helpers
ci-test: ## Run tests suitable for CI/CD
	@echo "Running CI tests..."
	@make lint
	@make validate
	@make security-scan
	@echo "CI tests complete"

ci-integration: ## Run integration tests for CI/CD
	@echo "Running CI integration tests..."
	@cd test/terratest && go test -v -short -timeout 15m ./...

# Development helpers
dev-setup: install-tools setup-pre-commit ## Set up development environment
	@echo "Development environment setup complete"

# Module validation
validate-modules: ## Validate all modules
	@echo "Validating all modules..."
	@for module in azure-*/; do \
		echo "Validating $$module..."; \
		cd "$$module" && terraform init -backend=false && terraform validate && cd ..; \
	done
	@echo "All modules validated successfully"

# Example generation
generate-examples: ## Generate example configurations
	@echo "Generating example configurations..."
	@mkdir -p examples
	@for module in azure-*/; do \
		module_name=$$(basename "$$module"); \
		echo "Generating example for $$module_name..."; \
		cp -r "$$module" "examples/$$module_name-example"; \
	done
	@echo "Examples generated in examples/ directory"

# Release helpers
release-check: ## Check if ready for release
	@echo "Checking release readiness..."
	@make lint
	@make validate-modules
	@make security-scan
	@echo "Release check complete"

# Help for contributors
contributor-help: ## Show help for contributors
	@echo "Contributor Guidelines:"
	@echo ""
	@echo "1. Before submitting a PR:"
	@echo "   make dev-setup    # Set up development environment"
	@echo "   make test         # Run all tests"
	@echo "   make docs         # Update documentation"
	@echo ""
	@echo "2. For specific module testing:"
	@echo "   make test-module MODULE=azure-vm"
	@echo ""
	@echo "3. For security validation:"
	@echo "   make security-scan"
	@echo ""
	@echo "4. For code quality:"
	@echo "   make lint validate"
	@echo ""
	@echo "See CONTRIBUTING.md for detailed guidelines."

# Default target
.DEFAULT_GOAL := help
