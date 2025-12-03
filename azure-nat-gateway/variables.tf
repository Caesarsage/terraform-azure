variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the Public IP for NAT Gateway"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku_name" {
  description = "SKU name for NAT Gateway"
  type        = string
  default     = "Standard"
}

variable "idle_timeout_in_minutes" {
  description = "Idle timeout in minutes"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

