variable "high_availability_mode" {
  description = "High availability mode for PostgreSQL Flexible Server. Possible values: 'ZoneRedundant', 'SameZone', or 'Disabled'"
  type        = string
  default     = "Disabled"
}

variable "standby_availability_zone" {
  description = "The availability zone for the standby server when using high availability. Must be different from the primary zone."
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for PostgreSQL server"
  type        = bool
  default     = false
}

variable "virtual_network_id" {
  description = "Virtual Network ID for private DNS zone link"
  type        = string
  default     = null
}

variable "delegated_subnet_id" {
  description = "Subnet ID for PostgreSQL delegation (must be delegated to Microsoft.DBforPostgreSQL/flexibleServers)"
  type        = string
  default     = null
}

variable "server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  type        = string
}

variable "location" {
  description = "Azure region where the PostgreSQL Flexible Server will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "administrator_login" {
  description = "Administrator login for the PostgreSQL server"
  type        = string
}

variable "administrator_password" {
  description = "Administrator password for the PostgreSQL server"
  type        = string
  sensitive   = true
}

variable "backup_retention_days" {
  description = "Backup retention days for the PostgreSQL server"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = true
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "14"
}

variable "sku_name" {
  description = "SKU name for the PostgreSQL Flexible Server"
  type        = string
  default     = "Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage size in MB for the PostgreSQL server"
  type        = number
  default     = 32768
}

variable "zone" {
  description = "Availability zone for the PostgreSQL server"
  type        = string
  default     = "1"
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
}

variable "server_configurations" {
  description = "List of server configurations"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "firewall_rules" {
  description = "List of firewall rules for the PostgreSQL server"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "databases" {
  description = "List of databases to create"
  type = list(object({
    name      = string
    collation = string
    charset   = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the PostgreSQL Flexible Server"
  type        = map(string)
  default     = {}
}
