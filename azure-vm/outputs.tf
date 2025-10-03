output "vm_ids" {
  description = "IDs of the virtual machines"
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "vm_names" {
  description = "Names of the virtual machines"
  value       = azurerm_linux_virtual_machine.main[*].name
}

output "public_ip_addresses" {
  description = "Public IP addresses of the VMs"
  value       = var.create_public_ip ? azurerm_public_ip.main[*].ip_address : []
}

output "private_ip_addresses" {
  description = "Private IP addresses of the VMs"
  value       = azurerm_network_interface.main[*].private_ip_address
}

output "vm_identities" {
  description = "System assigned identities of the VMs"
  value = {
    for i, vm in azurerm_linux_virtual_machine.main : vm.name => {
      principal_id = var.enable_system_assigned_identity ? vm.identity[0].principal_id : null
      tenant_id    = var.enable_system_assigned_identity ? vm.identity[0].tenant_id : null
    }
  }
}
