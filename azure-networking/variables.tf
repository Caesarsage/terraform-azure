variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    address_prefixes = list(string)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))
  default = {}
}

variable "network_security_groups" {
  description = "Map of network security group configurations"
  type = map(object({
    security_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  description = "Map of subnet to NSG associations"
  type = map(object({
    subnet_name = string
    nsg_name    = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "subnet_route_table_associations" {
  description = "Map of subnet to route table associations"
  type = map(object({
    subnet_name      = string
    route_table_name = string
  }))
  default = {}
}

variable "route_tables" {
  description = "Map of route table configurations"
  type = map(object({
    routes = list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    }))
  }))
  default = {}
}

variable "private_endpoints" {
  description = "Map of private endpoint configurations"
  type = map(object({
    subnet_name       = string
    resource_id       = string
    subresource_names = list(string)
  }))
  default = {}
}

variable "nat_gateways" {
  description = "Map of NAT Gateway configurations"
  type = map(object({
    sku_name                = optional(string, "Standard")
    idle_timeout_in_minutes = optional(number, 4)
  }))
  default = {}
}

variable "subnet_nat_gateway_associations" {
  description = "Map of subnet to NAT Gateway associations"
  type = map(object({
    subnet_name      = string
    nat_gateway_name = string
  }))
  default = {}
}
