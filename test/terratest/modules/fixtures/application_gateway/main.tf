module "networking" {
  source = "../../../../../azure-networking"

  vnet_name           = var.vnet_name
  vnet_address_space  = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  subnets = {
    vm-subnet = {
      address_prefixes = ["10.0.1.0/24"]
      delegation       = null
    }
  }

  tags = var.tags
}

module "application_gateway" {
  source = "../../../../../azure-application-gateway"

  application_gateway_name = var.application_gateway_name
  public_ip_name           = var.public_ip_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  subnet_id                = module.networking.subnet_ids["vm-subnet"]

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  health_probe = {
    name                                      = "health-probe"
    protocol                                  = "Https"
    path                                      = "/health"
    pick_host_name_from_backend_http_settings = true
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    minimum_servers                           = 0
    status_codes                              = ["200"]
    host_name                                 = "api.example.com"
  }

  backend_pools = [
    { name = "vmss-pool" }
  ]

  ssl_certificate_path = ""

  tags = var.tags
}

variable "application_gateway_name" {
  type    = string
  default = "test-agw"
}

variable "public_ip_name" {
  type    = string
  default = "test-agw-pip"
}

variable "vnet_name" {
  type    = string
  default = "test-vnet"
}

variable "resource_group_name" {
  type    = string
  default = "rg-tests"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "test"
    project     = "terratest"
  }
}
