variable "redis_name" {
  description = "Name of the Redis Cache"
  type        = string
}

variable "minimum_tls_version" {
  description = "TLS version"
  default     = 1.2
}

variable "location" {
  description = "Azure region where the Redis Cache will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "capacity" {
  description = "Size of the Redis cache"
  type        = number
  default     = 1
}

variable "family" {
  description = "Family of the Redis SKU"
  type        = string
  default     = "C"
}

variable "sku_name" {
  description = "SKU name for the Redis Cache"
  type        = string
  default     = "Standard"
}

variable "enable_non_ssl_port" {
  description = "Enable non-SSL port for Redis (use for debugging only)"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for Redis Cache"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "Virtual Network ID for private DNS zone"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled"
  type        = bool
  default     = false
}

variable "redis_configuration" {
  description = "Redis configuration settings"
  type = object({
    maxmemory_reserved     = number
    maxmemory_delta        = number
    maxmemory_policy       = string
    notify_keyspace_events = string
  })
  default = {
    maxmemory_reserved     = 2
    maxmemory_delta        = 2
    maxmemory_policy       = "volatile-lru"
    notify_keyspace_events = ""
  }
}

variable "patch_schedules" {
  description = "List of patch schedules for Redis"
  type = list(object({
    day_of_week    = string
    start_hour_utc = number
  }))
  default = []
}

variable "firewall_rules" {
  description = "List of firewall rules for Redis"
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the Redis Cache"
  type        = map(string)
  default     = {}
}
