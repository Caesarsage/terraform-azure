# This file is part of the Azure PostgreSQL Flexible Server module.
# It defines the resources required to create a PostgreSQL Flexible Server in Azure.


# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  administrator_login          = var.administrator_login
  administrator_password       = var.administrator_password
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  version                      = var.postgresql_version
  sku_name                     = var.sku_name
  storage_mb                   = var.storage_mb
  zone                         = var.zone

  high_availability {
    mode                      = var.high_availability_mode
    standby_availability_zone = var.standby_availability_zone
  }

  # VNet Integration
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  # Security
  public_network_access_enabled = var.enable_private_endpoint

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_configuration" "main" {
  count = length(var.server_configurations)

  name      = var.server_configurations[count.index].name
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = var.server_configurations[count.index].value
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  count = length(var.databases)

  name      = var.databases[count.index].name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = var.databases[count.index].collation
  charset   = var.databases[count.index].charset
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}
