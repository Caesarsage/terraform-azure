# Azure Route Table Module

This module creates an Azure Route Table with custom routes for directing network traffic according to specific routing requirements.

## Resources Created

- `azurerm_route_table` - Route table with custom routes
- `azurerm_subnet_route_table_association` - Association between subnet and route table

## Usage

### Basic Usage

```hcl
module "route_table" {
  source = "./azure-route-table"
  
  name                = "rt-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_ids         = [module.networking.subnet_ids["web"]]
  
  routes = [
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    }
  ]
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
  }
}
```

### Advanced Usage with Multiple Routes

```hcl
module "route_table" {
  source = "./azure-route-table"
  
  name                = "rt-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-networking"
  
  # Multiple subnets
  subnet_ids = [
    module.networking.subnet_ids["web"],
    module.networking.subnet_ids["app"]
  ]
  
  # Custom routes
  routes = [
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    },
    {
      name                   = "InternalRoute"
      address_prefix         = "10.0.0.0/8"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.1.4"
    },
    {
      name                   = "DatabaseRoute"
      address_prefix         = "10.0.3.0/24"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.1.4"
    }
  ]
  
  # Disable BGP route propagation
  disable_bgp_route_propagation = true
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Purpose     = "CustomRouting"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the route table | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| subnet_ids | List of subnet IDs to associate | `list(string)` | n/a | yes |
| routes | List of routes | `list(object)` | `[]` | no |
| disable_bgp_route_propagation | Disable BGP route propagation | `bool` | `false` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

### Route Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| name | Name of the route | `string` | yes |
| address_prefix | Address prefix for the route | `string` | yes |
| next_hop_type | Next hop type | `string` | yes |
| next_hop_in_ip_address | Next hop IP address (if applicable) | `string` | no |

## Outputs

| Name | Description |
|------|-------------|
| route_table_id | ID of the route table |
| route_table_name | Name of the route table |
| subnet_association_ids | List of subnet association IDs |

## Examples

### Hub and Spoke Routing

```hcl
# Hub route table
module "hub_route_table" {
  source = "./azure-route-table"
  
  name                = "rt-hub"
  location           = "East US"
  resource_group_name = "rg-hub-networking"
  subnet_ids         = [module.networking.subnet_ids["hub"]]
  
  routes = [
    {
      name                   = "Spoke1Route"
      address_prefix         = "10.1.0.0/16"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.1.4"  # Firewall IP
    },
    {
      name                   = "Spoke2Route"
      address_prefix         = "10.2.0.0/16"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.1.4"  # Firewall IP
    }
  ]
  
  tags = {
    Environment = "Production"
    Architecture = "HubSpoke"
    Purpose     = "HubRouting"
  }
}

# Spoke route table
module "spoke_route_table" {
  source = "./azure-route-table"
  
  name                = "rt-spoke"
  location           = "East US"
  resource_group_name = "rg-spoke-networking"
  subnet_ids         = [module.networking.subnet_ids["spoke"]]
  
  routes = [
    {
      name                   = "HubRoute"
      address_prefix         = "10.0.0.0/16"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.1.1.4"  # Hub firewall IP
    },
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.1.1.4"  # Hub firewall IP
    }
  ]
  
  tags = {
    Environment = "Production"
    Architecture = "HubSpoke"
    Purpose     = "SpokeRouting"
  }
}
```

### Firewall Integration

```hcl
# Route table for firewall integration
module "firewall_route_table" {
  source = "./azure-route-table"
  
  name                = "rt-firewall"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_ids         = [module.networking.subnet_ids["web"]]
  
  routes = [
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.firewall_private_ip
    },
    {
      name                   = "InternalRoute"
      address_prefix         = "10.0.0.0/8"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.firewall_private_ip
    }
  ]
  
  disable_bgp_route_propagation = true
  
  tags = {
    Environment = "Production"
    Purpose     = "FirewallRouting"
    Security    = "High"
  }
}
```

### Development Environment

```hcl
module "dev_route_table" {
  source = "./azure-route-table"
  
  name                = "rt-dev-testing"
  location           = "East US"
  resource_group_name = "rg-dev-networking"
  subnet_ids         = [module.dev_networking.subnet_ids["web"]]
  
  # Simple routing for development
  routes = [
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    }
  ]
  
  tags = {
    Environment = "Development"
    Project     = "Testing"
    AutoShutdown = "Enabled"
  }
}
```

## Best Practices

### Routing Design
1. **Route Priority**: Routes are processed in order of specificity
2. **Default Routes**: Use default routes (0.0.0.0/0) carefully
3. **BGP Propagation**: Consider disabling BGP route propagation for custom routes
4. **Route Testing**: Test routes thoroughly before production deployment

### Security
1. **Firewall Integration**: Use route tables to direct traffic through firewalls
2. **Network Segmentation**: Implement proper network segmentation
3. **Monitoring**: Monitor route table changes and traffic flow
4. **Documentation**: Document routing decisions and requirements

### Common Next Hop Types

| Next Hop Type | Description | Use Case |
|---------------|-------------|----------|
| **Internet** | Direct internet access | Public subnets |
| **VirtualAppliance** | Route through network appliance | Firewall, NVA |
| **VirtualNetworkGateway** | Route through VPN/ExpressRoute | Hybrid connectivity |
| **VnetLocal** | Route within VNet | Internal routing |
| **None** | Drop traffic | Security, blackhole |

## Integration Examples

### With Azure Firewall

```hcl
# Azure Firewall
resource "azurerm_firewall" "main" {
  name                = "firewall-webapp"
  location           = "East US"
  resource_group_name = "rg-networking"
  sku_name           = "AZFW_VNet"
  sku_tier           = "Standard"
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.networking.subnet_ids["firewall"]
    public_ip_address_id = azurerm_public_ip.firewall_ip.id
  }
}

# Route table directing traffic through firewall
module "firewall_route_table" {
  source = "./azure-route-table"
  
  name                = "rt-firewall"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_ids         = [module.networking.subnet_ids["web"]]
  
  routes = [
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
    }
  ]
  
  disable_bgp_route_propagation = true
  
  tags = {
    Environment = "Production"
    Purpose     = "FirewallRouting"
  }
}
```

### With Network Virtual Appliance

```hcl
# NVA (Network Virtual Appliance)
resource "azurerm_virtual_machine" "nva" {
  name                = "nva-firewall"
  location           = "East US"
  resource_group_name = "rg-networking"
  vm_size            = "Standard_D2s_v3"
  
  # NVA configuration...
}

# Route table for NVA
module "nva_route_table" {
  source = "./azure-route-table"
  
  name                = "rt-nva"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_ids         = [module.networking.subnet_ids["web"]]
  
  routes = [
    {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_virtual_machine.nva.private_ip_address
    },
    {
      name                   = "InternalRoute"
      address_prefix         = "10.0.0.0/8"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_virtual_machine.nva.private_ip_address
    }
  ]
  
  tags = {
    Environment = "Production"
    Purpose     = "NVARouting"
  }
}
```

## Notes

- Route tables are associated with subnets, not individual VMs
- Routes are processed in order of specificity (longest prefix match)
- BGP route propagation can be disabled for custom routing
- Route tables are free but have limits on number of routes

## Related Modules

- [azure-networking](./azure-networking/) - For VNet and subnet configuration
- [azure-monitoring](./azure-monitoring/) - For route table monitoring
- [azure-nat-gateway](./azure-nat-gateway/) - For outbound connectivity routing
