# Azure Redis Cache Module

This module creates an Azure Redis Cache instance with configurable clustering, persistence, and security options.

## Resources Created

- `azurerm_redis_cache` - Azure Redis Cache instance

## Usage

### Basic Usage

```hcl
module "redis" {
  source = "./azure-redis"
  
  name                = "redis-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-cache"
  
  capacity = 1
  family   = "C"
  sku_name = "Standard"
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
  }
}
```

### Advanced Usage with Clustering and Persistence

```hcl
module "redis" {
  source = "./azure-redis"
  
  name                = "redis-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-cache"
  
  capacity = 2
  family   = "C"
  sku_name = "Premium"
  
  # Clustering for high availability
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  
  # Persistence for data durability
  redis_configuration = {
    maxmemory_policy = "allkeys-lru"
    maxmemory_reserved = 2
    maxmemory_delta = 2
    maxfragmentationmemory_reserved = 12
    maxmemory_samples = 5
    notify_keyspace_events = ""
    rdb_backup_enabled = true
    rdb_backup_frequency = 60
    rdb_backup_max_snapshot_count = 1
    rdb_storage_connection_string = module.storage.storage_account_primary_connection_string
  }
  
  # Patch schedule for maintenance
  patch_schedule = {
    day_of_week        = "Saturday"
    start_hour_utc     = 2
    maintenance_window = "PT5H"
  }
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Cache       = "Redis"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the Redis cache | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| capacity | Redis cache size | `number` | `1` | no |
| family | Redis cache family | `string` | `"C"` | no |
| sku_name | Redis cache SKU | `string` | `"Basic"` | no |
| enable_non_ssl_port | Enable non-SSL port | `bool` | `false` | no |
| minimum_tls_version | Minimum TLS version | `string` | `"1.0"` | no |
| redis_configuration | Redis configuration | `map(string)` | `{}` | no |
| patch_schedule | Patch schedule configuration | `object` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| redis_cache_id | ID of the Redis cache |
| redis_cache_name | Name of the Redis cache |
| hostname | Hostname of the Redis cache |
| port | Port of the Redis cache |
| ssl_port | SSL port of the Redis cache |
| primary_access_key | Primary access key (sensitive) |
| secondary_access_key | Secondary access key (sensitive) |
| primary_connection_string | Primary connection string (sensitive) |
| secondary_connection_string | Secondary connection string (sensitive) |

## Examples

### Development Environment

```hcl
module "dev_redis" {
  source = "./azure-redis"
  
  name                = "redis-dev-testing"
  location           = "East US"
  resource_group_name = "rg-dev-cache"
  
  capacity = 0  # Basic tier
  family   = "C"
  sku_name = "Basic"
  
  enable_non_ssl_port = true  # For development convenience
  
  tags = {
    Environment = "Development"
    Project     = "Testing"
    AutoShutdown = "Enabled"
  }
}
```

### High-Performance Production Cache

```hcl
module "prod_redis" {
  source = "./azure-redis"
  
  name                = "redis-prod-high-perf"
  location           = "East US"
  resource_group_name = "rg-cache-prod"
  
  capacity = 4  # Large cache
  family   = "P"  # Premium family
  sku_name = "Premium"
  
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  
  redis_configuration = {
    maxmemory_policy = "allkeys-lru"
    maxmemory_reserved = 50
    maxmemory_delta = 20
    maxfragmentationmemory_reserved = 50
    maxmemory_samples = 10
    notify_keyspace_events = "Ex"
    rdb_backup_enabled = true
    rdb_backup_frequency = 60
    rdb_backup_max_snapshot_count = 3
    rdb_storage_connection_string = module.backup_storage.storage_account_primary_connection_string
  }
  
  patch_schedule = {
    day_of_week        = "Sunday"
    start_hour_utc     = 3
    maintenance_window = "PT4H"
  }
  
  tags = {
    Environment = "Production"
    Project     = "HighPerformance"
    Cache       = "Redis"
    Tier        = "Premium"
  }
}
```

## Best Practices

### Performance
1. **SKU Selection**: Choose appropriate SKU based on memory and performance needs
2. **Memory Management**: Configure appropriate memory policies
3. **Clustering**: Use clustering for high availability and performance
4. **Persistence**: Enable persistence for data durability
5. **Monitoring**: Monitor cache hit rates and performance metrics

### Security
1. **SSL/TLS**: Always use SSL/TLS in production
2. **Access Keys**: Rotate access keys regularly
3. **Network Security**: Use VNet integration for private access
4. **Firewall**: Configure firewall rules appropriately

### Common SKU Types

| SKU | Memory | Performance | Features |
|-----|--------|-------------|----------|
| **Basic** | 250MB - 53GB | Standard | Single node |
| **Standard** | 250MB - 53GB | Standard | Clustering, persistence |
| **Premium** | 6GB - 1.2TB | High | All features |

## Related Modules

- [azure-storage](./azure-storage/) - For Redis persistence backup
- [azure-networking](./azure-networking/) - For VNet integration
- [azure-monitoring](./azure-monitoring/) - For Redis monitoring