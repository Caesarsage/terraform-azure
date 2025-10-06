output "route_table_id" {
  description = "ID of the route table"
  value       = azurerm_route_table.main.id
}

output "route_table_name" {
  description = "Name of the route table"
  value       = azurerm_route_table.main.name
}

output "route_table_subnets" {
  description = "Subnets associated with the route table"
  value       = azurerm_route_table.main.subnets
}

output "association_ids" {
  description = "IDs of subnet route table associations"
  value       = azurerm_subnet_route_table_association.main[*].id
}
