# This file is part of the Azure Redis Cache module.
# It defines the resources required to create a Redis Cache in Azure.

resource "azurerm_redis_cache" "main" {
  name                = var.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku_name
  minimum_tls_version = "1.2"

  non_ssl_port_enabled          = var.enable_non_ssl_port
  public_network_access_enabled = var.public_network_access_enabled

  redis_configuration {
    maxmemory_reserved     = var.redis_configuration.maxmemory_reserved
    maxmemory_delta        = var.redis_configuration.maxmemory_delta
    maxmemory_policy       = var.redis_configuration.maxmemory_policy
    notify_keyspace_events = var.redis_configuration.notify_keyspace_events
  }

  dynamic "patch_schedule" {
    for_each = var.patch_schedules
    content {
      day_of_week    = patch_schedule.value.day_of_week
      start_hour_utc = patch_schedule.value.start_hour_utc
    }
  }

  tags = var.tags
}

resource "azurerm_redis_firewall_rule" "main" {
  count = length(var.firewall_rules)

  name                = var.firewall_rules[count.index].name
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip            = var.firewall_rules[count.index].start_ip
  end_ip              = var.firewall_rules[count.index].end_ip
}

# Private Endpoint for Redis
resource "azurerm_private_endpoint" "redis" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.redis_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.redis_name}-psc"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for Redis
resource "azurerm_private_dns_zone" "redis" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count                 = var.enable_private_endpoint ? 1 : 0
  name                  = "${var.redis_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}

# Private DNS A Record
resource "azurerm_private_dns_a_record" "redis" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_redis_cache.main.name
  zone_name           = azurerm_private_dns_zone.redis[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address]

  tags = var.tags
}
