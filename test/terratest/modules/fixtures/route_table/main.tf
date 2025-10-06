module "route_table" {
  source = "../../../../../azure-route-table"

  route_table_name    = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name

  routes = coalesce(var.routes, [])

  tags = var.tags
}


variable "route_table_name" {
  type    = string
  default = "test-route-table"
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

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = [
    {
      name           = "route-to-internet"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}
