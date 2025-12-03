output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = module.application_gateway.application_gateway_id
}

output "public_ip_id" {
  description = "ID of the public IP address"
  value       = module.application_gateway.public_ip_id
}
