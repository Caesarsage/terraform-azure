# ========= Output file ========
# It defines the output.
# This file is part of the Azure resource group module.

output "name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}
