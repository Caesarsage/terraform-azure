output "vm_ids" {
  description = "IDs of the virtual machines"
  value       = module.vm.vm_ids
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

