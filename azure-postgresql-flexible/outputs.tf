output "server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "server_version" {
  description = "Version of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.version
}

output "server_sku_name" {
  description = "SKU name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.sku_name
}

output "server_administrator_login" {
  description = "Administrator login of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "configuration_ids" {
  description = "IDs of the server configurations"
  value       = azurerm_postgresql_flexible_server_configuration.main[*].id
}

# Firewall rules output - only if firewall rules exist
# output "firewall_rule_ids" {
#   description = "IDs of the firewall rules"
#   value       = azurerm_postgresql_flexible_server_firewall_rule.main[*].id
# }

output "database_ids" {
  description = "IDs of the databases"
  value       = azurerm_postgresql_flexible_server_database.main[*].id
}
