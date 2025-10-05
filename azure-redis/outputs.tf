output "redis_id" {
  description = "ID of the Redis Cache"
  value       = azurerm_redis_cache.main.id
}

output "redis_name" {
  description = "Name of the Redis Cache"
  value       = azurerm_redis_cache.main.name
}

output "redis_hostname" {
  description = "Hostname of the Redis Cache"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_ssl_port" {
  description = "SSL port of the Redis Cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "redis_port" {
  description = "Port of the Redis Cache"
  value       = azurerm_redis_cache.main.port
}

output "redis_primary_access_key" {
  description = "Primary access key for the Redis Cache"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.redis[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address : null
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = var.enable_private_endpoint ? azurerm_private_dns_zone.redis[0].name : null
}

output "redis_secondary_access_key" {
  description = "Secondary access key for the Redis Cache"
  value       = azurerm_redis_cache.main.secondary_access_key
  sensitive   = true
}

output "firewall_rule_ids" {
  description = "IDs of the firewall rules"
  value       = azurerm_redis_firewall_rule.main[*].id
}

output "primary_connection_string" {
  description = "Primary connection string for the Redis Cache"
  value       = azurerm_redis_cache.main.primary_connection_string
}

output "secondary_connection_string" {
  description = "Secondary connection string for the Redis Cache"
  value       = azurerm_redis_cache.main.secondary_connection_string
}

