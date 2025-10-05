output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.agw.ip_address
}

output "public_ip_id" {
  description = "ID of the public IP address"
  value       = azurerm_public_ip.agw.id
}

output "backend_pool_ids" {
  description = "IDs of backend address pools"
  value       = { for pool in azurerm_application_gateway.main.backend_address_pool : pool.name => pool.id }
}

output "frontend_ip_configuration_id" {
  description = "ID of the frontend IP configuration"
  value       = azurerm_application_gateway.main.frontend_ip_configuration[0].id
}
