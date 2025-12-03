# Azure NAT Gateway Module

This module creates an Azure NAT Gateway for secure outbound internet connectivity from virtual networks without exposing inbound connections.

## Resources Created

- `azurerm_nat_gateway` - NAT Gateway
- `azurerm_public_ip` - Public IP for NAT Gateway
- `azurerm_nat_gateway_public_ip_association` - Association between NAT Gateway and Public IP
- `azurerm_subnet_nat_gateway_association` - Association between subnet and NAT Gateway

## Usage

### Basic Usage

```hcl
module "nat_gateway" {
  source = "./azure-nat-gateway"

  name                = "nat-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-networking"
 
  tags = {
    Environment = "Production"
    Project     = "WebApp"
  }
}
```

### Advanced Usage with Multiple Subnets

```hcl
module "nat_gateway" {
  source = "./azure-nat-gateway"

  name                = "nat-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-networking"

  # Multiple subnets for outbound connectivity
  subnet_ids = [
    module.networking.subnet_ids["web"],
    module.networking.subnet_ids["app"],
    module.networking.subnet_ids["data"]
  ]

  # NAT Gateway configuration
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4

  # Public IP configuration
  public_ip_allocation = "Static"
  public_ip_sku        = "Standard"

  # Custom public IP name
  public_ip_name = "pip-nat-webapp-prod"

  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Purpose     = "OutboundConnectivity"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the NAT Gateway | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| subnet_ids | List of subnet IDs to associate | `list(string)` | n/a | yes |
| sku_name | SKU name for NAT Gateway | `string` | `"Standard"` | no |
| idle_timeout_in_minutes | Idle timeout in minutes | `number` | `4` | no |
| public_ip_allocation | Public IP allocation method | `string` | `"Static"` | no |
| public_ip_sku | Public IP SKU | `string` | `"Standard"` | no |
| public_ip_name | Name of the public IP | `string` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| nat_gateway_id | ID of the NAT Gateway |
| nat_gateway_name | Name of the NAT Gateway |
| public_ip_id | ID of the public IP |
| public_ip_address | Public IP address |
| subnet_association_ids | List of subnet association IDs |

## Examples

### Development Environment

```hcl
module "dev_nat_gateway" {
  source = "./azure-nat-gateway"

  name                = "nat-dev-testing"
  location           = "East US"
  resource_group_name = "rg-dev-networking"
  subnet_ids         = [module.dev_networking.subnet_ids["web"]]

  sku_name                = "Standard"
  idle_timeout_in_minutes = 4

  tags = {
    Environment = "Development"
    Project     = "Testing"
    AutoShutdown = "Enabled"
  }
}
```

### High-Performance Production Setup

```hcl
module "prod_nat_gateway" {
  source = "./azure-nat-gateway"

  name                = "nat-prod-high-perf"
  location           = "East US"
  resource_group_name = "rg-prod-networking"

  # Multiple subnets for comprehensive outbound connectivity
  subnet_ids = [
    module.networking.subnet_ids["web"],
    module.networking.subnet_ids["app"],
    module.networking.subnet_ids["data"],
    module.networking.subnet_ids["cache"]
  ]

  # High-performance configuration
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4

  # Standard public IP for reliability
  public_ip_allocation = "Static"
  public_ip_sku        = "Standard"
  public_ip_name       = "pip-nat-prod-high-perf"

  tags = {
    Environment = "Production"
    Project     = "HighPerformance"
    Purpose     = "OutboundConnectivity"
    Tier        = "Critical"
  }
}
```

### Multi-Region Setup

```hcl
# Primary region NAT Gateway
module "nat_gateway_primary" {
  source = "./azure-nat-gateway"

  name                = "nat-primary-eastus"
  location           = "East US"
  resource_group_name = "rg-networking-primary"
  subnet_ids         = [module.networking_primary.subnet_ids["web"]]

  sku_name                = "Standard"
  idle_timeout_in_minutes = 4

  public_ip_name = "pip-nat-primary-eastus"

  tags = {
    Environment = "Production"
    Region      = "Primary"
    Purpose     = "OutboundConnectivity"
  }
}

# Secondary region NAT Gateway
module "nat_gateway_secondary" {
  source = "./azure-nat-gateway"

  name                = "nat-secondary-westus2"
  location           = "West US 2"
  resource_group_name = "rg-networking-secondary"
  subnet_ids         = [module.networking_secondary.subnet_ids["web"]]

  sku_name                = "Standard"
  idle_timeout_in_minutes = 4

  public_ip_name = "pip-nat-secondary-westus2"

  tags = {
    Environment = "Production"
    Region      = "Secondary"
    Purpose     = "OutboundConnectivity"
  }
}
```

## Best Practices

### Security
1. **Private Connectivity**: NAT Gateway provides secure outbound connectivity
2. **No Inbound Access**: NAT Gateway doesn't allow inbound connections
3. **Network Security**: Use with Network Security Groups for additional security
4. **Monitoring**: Monitor NAT Gateway usage and performance

### Performance
1. **SKU Selection**: Use Standard SKU for production workloads
2. **Idle Timeout**: Configure appropriate idle timeout
3. **Public IP**: Use Static allocation for consistent outbound IP
4. **Subnet Association**: Associate all subnets that need outbound access

### Cost Optimization
1. **Shared NAT Gateway**: Use single NAT Gateway for multiple subnets
2. **Idle Timeout**: Optimize idle timeout to balance performance and cost
3. **Monitoring**: Monitor usage to optimize costs

### Common Use Cases

| Use Case | Description | Benefits |
|----------|-------------|----------|
| **Web Applications** | Outbound API calls, updates | Secure, predictable IP |
| **Database Access** | Access to external databases | No inbound exposure |
| **Container Workloads** | Container registry access | Secure container deployments |
| **Backup Services** | Backup to external services | Secure data transfer |

## Integration Examples

### With Virtual Machines

```hcl
# NAT Gateway for VM outbound connectivity
module "nat_gateway" {
  source = "./azure-nat-gateway"

  name                = "nat-vm-outbound"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_ids         = [module.networking.subnet_ids["vm"]]

  tags = {
    Purpose = "VMOutbound"
    Environment = "Production"
  }
}

# VMs without public IPs
module "private_vms" {
  source = "./azure-vm"

  location           = "East US"
  resource_group_name = "rg-compute"
  subnet_id          = module.networking.subnet_ids["vm"]

  vm_configs = [
    {
      name = "private-vm-01"
      size = "Standard_D2s_v3"
      source_image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 128
      }
    }
  ]

  admin_username    = "azureuser"
  ssh_public_key    = file("~/.ssh/id_rsa.pub")
  create_public_ip  = false  # No public IP needed

  tags = {
    Environment = "Production"
    Connectivity = "ViaNAT"
  }
}
```

### With Container Instances

```hcl
# NAT Gateway for container outbound connectivity
module "nat_gateway" {
  source = "./azure-nat-gateway"

  name                = "nat-container-outbound"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_ids         = [module.networking.subnet_ids["containers"]]

  tags = {
    Purpose = "ContainerOutbound"
    Environment = "Production"
  }
}

# Container instances with NAT Gateway
resource "azurerm_container_group" "main" {
  name                = "container-group"
  location           = "East US"
  resource_group_name = "rg-containers"
  os_type            = "Linux"

  container {
    name   = "web-container"
    image  = "nginx:latest"
    cpu    = "1"
    memory = "2"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  subnet_ids = [module.networking.subnet_ids["containers"]]

  tags = {
    Environment = "Production"
    Connectivity = "ViaNAT"
  }
}
```

## Notes

- NAT Gateway provides secure outbound internet connectivity
- No inbound connections are allowed through NAT Gateway
- Use Standard SKU for production workloads
- Idle timeout affects connection persistence

## Related Modules

- [azure-networking](./azure-networking/) - For VNet and subnet configuration
- [azure-vm](./azure-vm/) - For VMs using NAT Gateway
- [azure-monitoring](./azure-monitoring/) - For NAT Gateway monitoring
