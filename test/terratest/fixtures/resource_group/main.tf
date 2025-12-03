module "resource_group" {
  source = "../../../../../azure-resource-group"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

output "name" {
  value = module.resource_group.name
}

output "id" {
  value = module.resource_group.id
}

output "location" {
  value = module.resource_group.location
}
