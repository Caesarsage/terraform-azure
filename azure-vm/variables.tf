variable "attach_network_security_group" {
  description = "Whether to attach a network security group to the network interfaces"
  type        = bool
  default     = false
}

variable "vm_configs" {
  description = "List of VM configurations"
  type = list(object({
    name = string
    size = string
    os_disk = object({
      caching              = string
      storage_account_type = string
      disk_size_gb         = number
    })
    source_image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    custom_data = optional(string)
    data_disks = optional(list(object({
      name                 = string
      disk_size_gb         = number
      storage_account_type = string
      lun                  = number
      caching              = string
    })))
    tags = optional(map(string), {})
  }))
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VMs"
  type        = string
}

variable "create_public_ip" {
  description = "Create public IP for VMs"
  type        = bool
  default     = true
}

variable "public_ip_allocation" {
  description = "Allocation method for public IP"
  type        = string
  default     = "Static"
}

variable "public_ip_sku" {
  description = "SKU for public IP"
  type        = string
  default     = "Standard"
}

variable "network_security_group_id" {
  description = "ID of the network security group"
  type        = string
  default     = null
}

variable "enable_system_assigned_identity" {
  description = "Enable system assigned identity"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
variable "disk_encryption_set_id" {
  description = "ID of the Disk Encryption Set for customer-managed key encryption. Leave null to use platform-managed keys."
  type        = string
  default     = null
}
