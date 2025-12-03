output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.nat_gateway.nat_gateway_id
}

output "public_ip_id" {
  description = "ID of the public IP address"
  value       = module.nat_gateway.public_ip_id
}
