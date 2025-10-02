output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.networking.subnet_ids
}

output "nsg_ids" {
  description = "Map of NSG names to IDs"
  value       = module.networking.nsg_ids
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway names to IDs"
  value       = module.networking.nat_gateway_ids
}

output "nat_gateway_public_ip_ids" {
  description = "Map of NAT Gateway public IP names to IDs"
  value       = module.networking.nat_gateway_public_ip_ids
}

