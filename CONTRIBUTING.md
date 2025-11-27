# Contributing Guide

Thanks for your interest in contributing.

## Quick Start
1. Fork the repo; create a feature branch.
2. Make changes; keep modules self-contained and documented.
3. Format and validate:
```bash
   terraform fmt -recursive
   terraform --init
   terraform validate
```
4. Run tests:
```bash
   cd test/terratest
   go test ./test/terratest/... -v
```
5. Update module README and examples.
6. Open a PR.

## Requirements
- Terraform ≥ 1.6; AzureRM provider per repo baseline in `provider.hcl`.
- Go ≥ 1.22 for Terratest.
- Azure subscription with rights to create and destroy resources.

## Azure Auth for Tests
Choose one path.

**Service principal:**
```bash
export ARM_CLIENT_ID=...
export ARM_CLIENT_SECRET=...
export ARM_TENANT_ID=...
export ARM_SUBSCRIPTION_ID=...
```

Optional test knobs:
```bash
export TEST_LOCATION="West Europe"
export TEST_RESOURCE_GROUP_NAME="test-rg"
export TEST_TIMEOUT="30m"
export TEST_PARALLELISM="1"
```

## Repository Standards
- **Provider policy:** pin AzureRM in `provider.hcl`; do not duplicate provider blocks inside modules. Modules may declare `required_providers` for docs tooling; tests or root stacks supply the concrete `provider "azurerm" { features {} }`.
- **Idempotence:** `terraform plan` after `apply` is empty for all examples.
- **Naming:** predictable, lowercase, hyphenated; expose `name` or `{resource}_name` where applicable.
- **Tags:** every resource supports `tags` where Azure allows it.

## Module Layout
```
module-name/
├── main.tf
├── variables.tf   # types, defaults, validation, descriptions
├── outputs.tf     # descriptions for every output
├── README.md      # usage, inputs, outputs, examples
└── examples/      # minimal runnable examples
```

## Documentation
- Use Markdown; keep examples copy-pastable.
- List inputs and outputs; include defaults and constraints.
- Link to upstream docs with full URLs:
  - Terraform: https://developer.hashicorp.com/terraform
  - AzureRM provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
  - Azure Architecture Center: https://learn.microsoft.com/azure/architecture/

## Testing (Terratest)
- Tests live under `test/terratest/`.
- Use fixtures that wrap the module and supply the provider.

**Example fixture** `test/terratest/fixtures/rg_basic/main.tf`:
```hcl
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
  }
}
provider "azurerm" { features {} }

variable "resource_group_name" { type = string }
variable "location"           { type = string }
variable "tags"               { type = map(string) }

module "rg" {
  source              = "../../../../azure-resource-group"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

output "name"     { value = module.rg.name }
output "id"       { value = module.rg.id }
output "location" { value = module.rg.location }
```

**Test rules:**
- Use `t.Parallel()` where safe; gate fan-out with `TEST_PARALLELISM`.
- Keep retries narrow; match only transient errors like timeouts or throttling.
- Always `defer terraform.Destroy`.
- Support `go test -short` to skip live Azure runs.

**Run:**
```bash
go test ./test/terratest/... -v
go test -short ./... -v
```

## Coding Standards
- Variables: typed; validated; descriptive `description`.
- Outputs: minimal surface; never expose secrets.
- Sensitive data: `sensitive = true`; do not log.
- Examples: one minimal; add advanced only if useful.
- No hard-coded regions or subscription IDs.

## Security
- Do not commit credentials or state files.
- Provide `terraform.tfvars.example`; never real secrets.
- Sanitize logs in tests; avoid printing env values.

## Commit and PR Guidelines
- Conventional Commits; examples:
  - `feat(networking): add NAT gateway support`
  - `fix(vm): correct data disk caching`
  - `docs(resource-group): clarify tag expectations`

**PR checklist:**
- [ ] Formatted; validated; linted.
- [ ] Tests pass; fixtures included.
- [ ] README updated; examples runnable.
- [ ] No secrets; no drift in examples.
- [ ] Breaking changes labeled with `!` and migration notes included.

## Versioning and Breaking Changes
- Follow SemVer at the module level.
- Mark breaking changes in commits and PR titles; provide upgrade steps in the module README.

## Local Dev Tips
```bash
# format all
terraform fmt -recursive

# validate each module (no backend init)
find . -maxdepth 2 -type f -name "main.tf" -execdir terraform init -backend=false \; -execdir terraform validate \;

# run a single test
go test ./test/terratest/modules -run TestResourceGroup -v
```

## Code of Conduct
Be respectful; keep reviews technical; assume good faith.
