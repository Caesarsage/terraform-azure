# Azure Resource Group Module

This module creates an Azure Resource Group with configurable tags and location.

## Resources Created

- `azurerm_resource_group` - Azure Resource Group

## Usage

### Basic Usage

```hcl
module "resource_group" {
  source = "./azure-resource-group"
  
  resource_group_name = "my-resource-group"
  location           = "East US"
  
  tags = {
    Environment = "Production"
    Project     = "MyProject"
    Owner       = "DevOps Team"
  }
}
```

### Advanced Usage

```hcl
module "resource_group" {
  source = "./azure-resource-group"
  
  resource_group_name = "rg-${var.environment}-${var.project}-${var.region}"
  location           = var.location
  
  tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Region      = var.region
      CostCenter  = "IT-1234"
    },
    var.additional_tags
  )
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for resources | `string` | n/a | yes |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | Name of the created resource group |
| id | ID of the resource group |
| location | Location of the resource group |

## Examples

### Production Environment

```hcl
module "prod_resource_group" {
  source = "./azure-resource-group"
  
  resource_group_name = "rg-prod-webapp-eastus"
  location           = "East US"
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Owner       = "DevOps Team"
    CostCenter  = "IT-1234"
    Backup      = "Required"
  }
}
```

### Development Environment

```hcl
module "dev_resource_group" {
  source = "./azure-resource-group"
  
  resource_group_name = "rg-dev-testing-westus2"
  location           = "West US 2"
  
  tags = {
    Environment = "Development"
    Project     = "Testing"
    Owner       = "Dev Team"
    AutoShutdown = "Enabled"
  }
}
```

## Notes

- Resource group names must be unique within your subscription
- Use meaningful names that follow your organization's naming conventions
- Tags are highly recommended for cost management and resource organization
- The location parameter determines the Azure region where the resource group metadata is stored

## Related Modules

- [azure-networking](./azure-networking/) - For creating networking resources within this resource group
- [azure-vm](./azure-vm/) - For creating virtual machines in this resource group
- [azure-storage](./azure-storage/) - For creating storage accounts in this resource group
