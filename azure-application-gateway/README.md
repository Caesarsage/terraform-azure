# Azure Application Gateway Module

This module creates an Azure Application Gateway with SSL termination, load balancing, and advanced routing capabilities.

## Resources Created

- `azurerm_application_gateway` - Application Gateway with listeners, backend pools, and routing rules

## Usage

### Basic Usage

```hcl
module "app_gateway" {
  source = "./azure-application-gateway"
  
  name                = "appgw-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_id          = module.networking.subnet_ids["gateway"]
  
  sku_name     = "Standard_v2"
  sku_tier     = "Standard_v2"
  capacity     = 2
  
  frontend_ip_configuration = {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = module.public_ip.public_ip_id
  }
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
  }
}
```

### Advanced Usage with SSL and Multiple Backends

```hcl
module "app_gateway" {
  source = "./azure-application-gateway"
  
  name                = "appgw-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-networking"
  subnet_id          = module.networking.subnet_ids["gateway"]
  
  sku_name     = "WAF_v2"
  sku_tier     = "WAF_v2"
  capacity     = 2
  
  # SSL Certificate
  ssl_certificate = {
    name     = "webapp-ssl-cert"
    data     = filebase64("path/to/certificate.pfx")
    password = var.ssl_certificate_password
  }
  
  # Frontend IP Configuration
  frontend_ip_configuration = {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = module.public_ip.public_ip_id
  }
  
  # Frontend Ports
  frontend_ports = [
    {
      name = "port_80"
      port = 80
    },
    {
      name = "port_443"
      port = 443
    }
  ]
  
  # Backend Address Pools
  backend_address_pools = [
    {
      name  = "web-backend"
      fqdns = ["webapp1.example.com", "webapp2.example.com"]
    },
    {
      name         = "api-backend"
      ip_addresses = ["10.0.2.4", "10.0.2.5"]
    }
  ]
  
  # Backend HTTP Settings
  backend_http_settings = [
    {
      name                  = "web-http-settings"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 60
      probe_name            = "web-probe"
    },
    {
      name                  = "api-http-settings"
      cookie_based_affinity = "Disabled"
      path                  = "/api"
      port                  = 8080
      protocol              = "Http"
      request_timeout       = 30
      probe_name            = "api-probe"
    }
  ]
  
  # Health Probes
  probes = [
    {
      name                                      = "web-probe"
      protocol                                  = "Http"
      path                                      = "/health"
      host                                      = "webapp.example.com"
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = true
      minimum_servers                           = 0
      match = {
        status_codes = ["200-399"]
        body         = ""
      }
    },
    {
      name                                      = "api-probe"
      protocol                                  = "Http"
      path                                      = "/api/health"
      host                                      = "api.example.com"
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = true
      minimum_servers                           = 0
      match = {
        status_codes = ["200-399"]
        body         = ""
      }
    }
  ]
  
  # HTTP Listeners
  http_listeners = [
    {
      name                           = "web-listener"
      frontend_ip_configuration_name = "appGwPublicFrontendIp"
      frontend_port_name             = "port_80"
      protocol                       = "Http"
    },
    {
      name                           = "web-ssl-listener"
      frontend_ip_configuration_name = "appGwPublicFrontendIp"
      frontend_port_name             = "port_443"
      protocol                       = "Https"
      ssl_certificate_name           = "webapp-ssl-cert"
    }
  ]
  
  # Request Routing Rules
  request_routing_rules = [
    {
      name                       = "web-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "web-listener"
      backend_address_pool_name  = "web-backend"
      backend_http_settings_name = "web-http-settings"
      priority                   = 100
    },
    {
      name                       = "web-ssl-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "web-ssl-listener"
      backend_address_pool_name  = "web-backend"
      backend_http_settings_name = "web-http-settings"
      priority                   = 110
    },
    {
      name                       = "api-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "web-ssl-listener"
      backend_address_pool_name  = "api-backend"
      backend_http_settings_name = "api-http-settings"
      url_path_map_name          = "api-path-map"
      priority                   = 120
    }
  ]
  
  # URL Path Maps
  url_path_maps = [
    {
      name                               = "api-path-map"
      default_backend_address_pool_name  = "web-backend"
      default_backend_http_settings_name = "web-http-settings"
      path_rules = [
        {
          name                       = "api-paths"
          paths                      = ["/api/*"]
          backend_address_pool_name  = "api-backend"
          backend_http_settings_name = "api-http-settings"
        }
      ]
    }
  ]
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Component   = "LoadBalancer"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the Application Gateway | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| subnet_id | ID of the subnet | `string` | n/a | yes |
| sku_name | SKU name | `string` | `"Standard_v2"` | no |
| sku_tier | SKU tier | `string` | `"Standard_v2"` | no |
| capacity | Capacity (instances) | `number` | `2` | no |
| ssl_certificate | SSL certificate configuration | `object` | `null` | no |
| frontend_ip_configuration | Frontend IP configuration | `object` | n/a | yes |
| frontend_ports | List of frontend ports | `list(object)` | n/a | yes |
| backend_address_pools | List of backend address pools | `list(object)` | `[]` | no |
| backend_http_settings | List of backend HTTP settings | `list(object)` | `[]` | no |
| probes | List of health probes | `list(object)` | `[]` | no |
| http_listeners | List of HTTP listeners | `list(object)` | n/a | yes |
| request_routing_rules | List of request routing rules | `list(object)` | n/a | yes |
| url_path_maps | List of URL path maps | `list(object)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| application_gateway_id | ID of the Application Gateway |
| application_gateway_name | Name of the Application Gateway |
| frontend_ip_configuration | Frontend IP configuration |
| backend_address_pools | Backend address pools |

## Examples

### Simple Load Balancer

```hcl
module "simple_app_gateway" {
  source = "./azure-application-gateway"
  
  name                = "appgw-simple"
  location           = "East US"
  resource_group_name = "rg-simple"
  subnet_id          = module.networking.subnet_ids["gateway"]
  
  sku_name = "Standard_v2"
  sku_tier = "Standard_v2"
  capacity = 1
  
  frontend_ip_configuration = {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.gateway_ip.id
  }
  
  frontend_ports = [
    {
      name = "port_80"
      port = 80
    }
  ]
  
  backend_address_pools = [
    {
      name         = "default-backend"
      ip_addresses = ["10.0.2.4", "10.0.2.5"]
    }
  ]
  
  backend_http_settings = [
    {
      name                  = "default-http-settings"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 60
    }
  ]
  
  http_listeners = [
    {
      name                           = "default-listener"
      frontend_ip_configuration_name = "appGwPublicFrontendIp"
      frontend_port_name             = "port_80"
      protocol                       = "Http"
    }
  ]
  
  request_routing_rules = [
    {
      name                       = "default-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "default-listener"
      backend_address_pool_name  = "default-backend"
      backend_http_settings_name = "default-http-settings"
      priority                   = 100
    }
  ]
  
  tags = {
    Environment = "Production"
    Project     = "SimpleApp"
  }
}
```

## Best Practices

### Security
1. **WAF**: Use WAF_v2 SKU for web application firewall protection
2. **SSL/TLS**: Always use HTTPS in production
3. **Certificates**: Use managed certificates or Key Vault integration
4. **Network Security**: Use private IP addresses when possible

### Performance
1. **SKU Selection**: Choose appropriate SKU based on traffic requirements
2. **Capacity**: Scale capacity based on traffic patterns
3. **Health Probes**: Configure appropriate health probes
4. **Connection Draining**: Enable connection draining for graceful updates

### Common SKU Types

| SKU | Features | Use Case |
|-----|----------|----------|
| **Standard_v2** | Basic load balancing | Simple applications |
| **WAF_v2** | Web Application Firewall | Security-focused applications |
| **Standard** | Legacy standard tier | Legacy applications |

## Related Modules

- [azure-networking](./azure-networking/) - For VNet and subnet configuration
- [azure-monitoring](./azure-monitoring/) - For Application Gateway monitoring
- [azure-keyvault](./azure-keyvault/) - For SSL certificate management
