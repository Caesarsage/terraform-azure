# Azure Networking Module

This module creates a comprehensive Azure networking infrastructure including Virtual Networks, Subnets, Network Security Groups, Route Tables, NAT Gateways, and Private Endpoints.

## Resources Created

- `azurerm_virtual_network` - Virtual Network
- `azurerm_subnet` - Subnets with service endpoints
- `azurerm_network_security_group` - Network Security Groups with rules
- `azurerm_subnet_network_security_group_association` - NSG associations
- `azurerm_private_endpoint` - Private endpoints for Azure services
- `azurerm_route_table` - Route tables with custom routes
- `azurerm_subnet_route_table_association` - Route table associations
- `azurerm_public_ip` - Public IPs for NAT Gateways
- `azurerm_nat_gateway` - NAT Gateways for outbound connectivity
- `azurerm_nat_gateway_public_ip_association` - NAT Gateway IP associations
- `azurerm_subnet_nat_gateway_association` - NAT Gateway subnet associations

## Usage

### Basic Usage

```hcl
module "networking" {
  source = "./azure-networking"
  
  vnet_name           = "my-vnet"
  vnet_address_space  = ["10.0.0.0/16"]
  location           = "East US"
  resource_group_name = "my-rg"
  
  subnets = {
    "web" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "app" = {
      address_prefixes = ["10.0.2.0/24"]
    }
    "data" = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
  }
}
```

### Advanced Usage with Security

```hcl
module "networking" {
  source = "./azure-networking"
  
  vnet_name           = "vnet-prod-webapp"
  vnet_address_space  = ["10.0.0.0/16", "10.1.0.0/16"]
  location           = "East US"
  resource_group_name = "rg-prod-webapp"
  
  # Subnets with service endpoints
  subnets = {
    "web" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "app" = {
      address_prefixes = ["10.0.2.0/24"]
    }
    "data" = {
      address_prefixes = ["10.0.3.0/24"]
    }
    "private-endpoints" = {
      address_prefixes = ["10.0.4.0/24"]
      delegation = {
        name = "Microsoft.Network.managedResoures"
        service_delegation = {
          name    = "Microsoft.ContainerInstance/containerGroups"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
  }
  
  # Network Security Groups
  network_security_groups = {
    "web-nsg" = {
      security_rules = [
        {
          name                       = "AllowHTTP"
          priority                   = 1000
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowHTTPS"
          priority                   = 1010
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
    "app-nsg" = {
      security_rules = [
        {
          name                       = "AllowAppPort"
          priority                   = 1000
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "10.0.1.0/24"
          destination_address_prefix = "*"
        }
      ]
    }
  }
  
  # Associate NSGs with subnets
  subnet_nsg_associations = {
    "web-nsg-association" = {
      subnet_name = "web"
      nsg_name    = "web-nsg"
    }
    "app-nsg-association" = {
      subnet_name = "app"
      nsg_name    = "app-nsg"
    }
  }
  
  # NAT Gateways for outbound connectivity
  nat_gateways = {
    "web-nat-gateway" = {
      sku_name                = "Standard"
      idle_timeout_in_minutes = 4
    }
  }
  
  subnet_nat_gateway_associations = {
    "web-nat-association" = {
      subnet_name      = "web"
      nat_gateway_name = "web-nat-gateway"
    }
  }
  
  # Private Endpoints
  private_endpoints = {
    "storage-private-endpoint" = {
      subnet_name        = "private-endpoints"
      resource_id        = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Storage/storageAccounts/mystorage"
      subresource_names  = ["blob"]
    }
  }
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Owner       = "DevOps Team"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vnet_name | Name of the virtual network | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| vnet_address_space | Address space for the virtual network | `list(string)` | `["10.0.0.0/16"]` | no |
| subnets | Map of subnet configurations | `map(object)` | `{}` | no |
| network_security_groups | Map of network security group configurations | `map(object)` | `{}` | no |
| subnet_nsg_associations | Map of subnet to NSG associations | `map(object)` | `{}` | no |
| private_endpoints | Map of private endpoint configurations | `map(object)` | `{}` | no |
| route_tables | Map of route table configurations | `map(object)` | `{}` | no |
| subnet_route_table_associations | Map of subnet to route table associations | `map(object)` | `{}` | no |
| nat_gateways | Map of NAT Gateway configurations | `map(object)` | `{}` | no |
| subnet_nat_gateway_associations | Map of subnet to NAT Gateway associations | `map(object)` | `{}` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | ID of the virtual network |
| vnet_name | Name of the virtual network |
| subnet_ids | Map of subnet names to their IDs |
| subnet_names | Map of subnet names to their names |
| nsg_ids | Map of NSG names to their IDs |
| private_endpoint_ids | Map of private endpoint names to their IDs |
| route_table_ids | Map of route table names to their IDs |
| nat_gateway_ids | Map of NAT gateway names to their IDs |

## Examples

### Hub and Spoke Architecture

```hcl
module "hub_networking" {
  source = "./azure-networking"
  
  vnet_name           = "vnet-hub"
  vnet_address_space  = ["10.0.0.0/16"]
  location           = "East US"
  resource_group_name = "rg-hub"
  
  subnets = {
    "gateway" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "firewall" = {
      address_prefixes = ["10.0.2.0/24"]
    }
    "shared" = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
  
  tags = {
    Environment = "Production"
    Architecture = "Hub-Spoke"
  }
}
```

### Microservices Architecture

```hcl
module "microservices_networking" {
  source = "./azure-networking"
  
  vnet_name           = "vnet-microservices"
  vnet_address_space  = ["10.1.0.0/16"]
  location           = "East US"
  resource_group_name = "rg-microservices"
  
  subnets = {
    "frontend" = {
      address_prefixes = ["10.1.1.0/24"]
    }
    "backend" = {
      address_prefixes = ["10.1.2.0/24"]
    }
    "database" = {
      address_prefixes = ["10.1.3.0/24"]
    }
    "cache" = {
      address_prefixes = ["10.1.4.0/24"]
    }
  }
  
  # NAT Gateway for outbound connectivity
  nat_gateways = {
    "main-nat-gateway" = {
      sku_name                = "Standard"
      idle_timeout_in_minutes = 4
    }
  }
  
  subnet_nat_gateway_associations = {
    "frontend-nat" = {
      subnet_name      = "frontend"
      nat_gateway_name = "main-nat-gateway"
    }
    "backend-nat" = {
      subnet_name      = "backend"
      nat_gateway_name = "main-nat-gateway"
    }
  }
  
  tags = {
    Environment = "Production"
    Architecture = "Microservices"
  }
}
```

## Best Practices

1. **Subnet Planning**: Plan your subnet sizes carefully to avoid running out of IP addresses
2. **NSG Rules**: Follow the principle of least privilege when creating NSG rules
3. **Service Endpoints**: Enable service endpoints for Azure services you plan to use
4. **Private Endpoints**: Use private endpoints for sensitive data services
5. **NAT Gateways**: Use NAT gateways for secure outbound internet connectivity
6. **Naming Conventions**: Use consistent naming conventions across all resources

## Notes

- All subnets automatically include service endpoints for Storage, Key Vault, and Container Registry
- NAT Gateways provide secure outbound internet connectivity without exposing VMs directly
- Private endpoints enable secure connectivity to Azure services without internet exposure
- Route tables allow custom routing for specific network requirements

## Related Modules

- [azure-vm](./azure-vm/) - For creating VMs in the subnets
- [azure-application-gateway](./azure-application-gateway/) - For load balancing traffic
- [azure-keyvault](./azure-keyvault/) - For secure key and secret management
- [azure-storage](./azure-storage/) - For storage accounts with private endpoints
