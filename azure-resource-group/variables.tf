# ========= Variables file ========
# This file is part of the Azure resource group module.
# It defines the resources required to create a Resource Group in Azure.

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
