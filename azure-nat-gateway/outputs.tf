output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = azurerm_nat_gateway.main.id
}

output "public_ip_address" {
  description = "Public IP address of the NAT Gateway"
  value       = azurerm_public_ip.nat_gateway.ip_address
}

output "public_ip_id" {
  description = "ID of the Public IP"
  value       = azurerm_public_ip.nat_gateway.id
}
