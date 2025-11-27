# Azure PostgreSQL Flexible Server Module

This module creates an Azure PostgreSQL Flexible Server with private networking, high availability, and comprehensive configuration options.

## Resources Created

- `azurerm_private_dns_zone` - Private DNS zone for PostgreSQL
- `azurerm_private_dns_zone_virtual_network_link` - DNS zone to VNet link
- `azurerm_postgresql_flexible_server` - PostgreSQL Flexible Server
- `azurerm_postgresql_flexible_server_configuration` - Server configuration parameters
- `azurerm_postgresql_flexible_server_database` - Databases

## Usage

### Basic Usage

```hcl
module "postgresql" {
  source = "./azure-postgresql-flexible"
  
  server_name         = "postgres-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-database"
  virtual_network_id  = module.networking.vnet_id
  delegated_subnet_id = module.networking.subnet_ids["database"]
  
  administrator_login    = "postgresadmin"
  administrator_password = var.postgresql_admin_password
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
  }
}
```

### Advanced Usage with High Availability and Custom Configuration

```hcl
module "postgresql" {
  source = "./azure-postgresql-flexible"
  
  server_name         = "postgres-webapp-prod"
  location           = "East US"
  resource_group_name = "rg-database"
  virtual_network_id  = module.networking.vnet_id
  delegated_subnet_id = module.networking.subnet_ids["database"]
  
  administrator_login    = "postgresadmin"
  administrator_password = var.postgresql_admin_password
  
  # High availability configuration
  postgresql_version                = "14"
  sku_name                         = "GP_Standard_D4s_v3"
  storage_mb                       = 131072  # 128 GB
  zone                             = "1"
  high_availability_mode           = "ZoneRedundant"
  standby_availability_zone       = "2"
  
  # Backup configuration
  backup_retention_days        = 30
  geo_redundant_backup_enabled = true
  
  # Maintenance window
  maintenance_window = {
    day_of_week  = 0  # Sunday
    start_hour   = 2
    start_minute = 0
  }

  # Server configurations
  server_configurations = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "checkpoint_completion_target"
      value = "0.9"
    }
  ]
  
  # Databases
  databases = [
    {
      name     = "webapp_db"
      collation = "en_US.utf8"
      charset   = "utf8"
    },
    {
      name     = "analytics_db"
      collation = "en_US.utf8"
      charset   = "utf8"
    },
    {
      name     = "audit_db"
      collation = "en_US.utf8"
      charset   = "utf8"
    }
  ]

  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Database    = "PostgreSQL"
    Tier        = "Primary"
  }
}
```

### Development Environment

```hcl
module "dev_postgresql" {
  source = "./azure-postgresql-flexible"
  
  server_name         = "postgres-dev-testing"
  location           = "East US"
  resource_group_name = "rg-dev-database"
  virtual_network_id  = module.dev_networking.vnet_id
  delegated_subnet_id = module.dev_networking.subnet_ids["database"]
  
  administrator_login    = "devadmin"
  administrator_password = var.dev_postgresql_password
  
  # Development configuration
  postgresql_version = "14"
  sku_name          = "Burstable_B1ms"  # Cheaper for dev
  storage_mb        = 32768             # 32 GB
  
  # Basic backup
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  
  databases = [
    {
      name     = "dev_webapp"
      collation = "en_US.utf8"
      charset   = "utf8"
    }
  ]
  
  tags = {
    Environment = "Development"
    Project     = "Testing"
    AutoShutdown = "Enabled"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| server_name | Name of the PostgreSQL server | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| virtual_network_id | ID of the virtual network | `string` | n/a | yes |
| delegated_subnet_id | ID of the delegated subnet | `string` | n/a | yes |
| administrator_login | Administrator username | `string` | n/a | yes |
| administrator_password | Administrator password | `string` | n/a | yes |
| postgresql_version | PostgreSQL version | `string` | `"14"` | no |
| sku_name | SKU name for the server | `string` | `"GP_Standard_D2s_v3"` | no |
| storage_mb | Storage size in MB | `number` | `32768` | no |
| zone | Availability zone | `string` | `null` | no |
| high_availability_mode | High availability mode | `string` | `"Disabled"` | no |
| standby_availability_zone | Standby availability zone | `string` | `null` | no |
| backup_retention_days | Backup retention days | `number` | `7` | no |
| geo_redundant_backup_enabled | Enable geo-redundant backup | `bool` | `false` | no |
| maintenance_window | Maintenance window configuration | `object` | `null` | no |
| server_configurations | List of server configuration parameters | `list(object)` | `[]` | no |
| databases | List of databases to create | `list(object)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

### Maintenance Window Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| day_of_week | Day of week (0-6, Sunday=0) | `number` | yes |
| start_hour | Start hour (0-23) | `number` | yes |
| start_minute | Start minute (0-59) | `number` | yes |

### Server Configuration Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| name | Configuration parameter name | `string` | yes |
| value | Configuration parameter value | `string` | yes |

### Database Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| name | Database name | `string` | yes |
| collation | Database collation | `string` | yes |
| charset | Database charset | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| server_id | ID of the PostgreSQL server |
| server_name | Name of the PostgreSQL server |
| fqdn | Fully qualified domain name of the server |
| private_dns_zone_id | ID of the private DNS zone |
| database_names | List of created database names |

## Examples

### Production Database with Read Replica

```hcl
# Primary server
module "postgresql_primary" {
  source = "./azure-postgresql-flexible"
  
  server_name         = "postgres-primary-prod"
  location           = "East US"
  resource_group_name = "rg-database-prod"
  virtual_network_id  = module.networking.vnet_id
  delegated_subnet_id = module.networking.subnet_ids["database"]
  
  administrator_login    = "postgresadmin"
  administrator_password = var.postgresql_admin_password
  
  postgresql_version                = "14"
  sku_name                         = "GP_Standard_D8s_v3"
  storage_mb                       = 262144  # 256 GB
  zone                             = "1"
  high_availability_mode           = "ZoneRedundant"
  standby_availability_zone       = "2"
  
  backup_retention_days        = 30
  geo_redundant_backup_enabled = true
  
  maintenance_window = {
    day_of_week  = 0  # Sunday
    start_hour   = 2
    start_minute = 0
  }
  
  server_configurations = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements,pg_audit"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_connections"
      value = "on"
    },
    {
      name  = "log_disconnections"
      value = "on"
    },
    {
      name  = "log_checkpoints"
      value = "on"
    }
  ]
  
  databases = [
    {
      name     = "production_db"
      collation = "en_US.utf8"
      charset   = "utf8"
    }
  ]
  
  tags = {
    Environment = "Production"
    Role        = "Primary"
    Database    = "PostgreSQL"
  }
}

# Read replica (if needed, create separately)
resource "azurerm_postgresql_flexible_server" "read_replica" {
  name                = "postgres-replica-prod"
  location           = "West US 2"  # Different region for DR
  resource_group_name = "rg-database-prod"
  
  administrator_login    = "postgresadmin"
  administrator_password = var.postgresql_admin_password
  
  sku_name = "GP_Standard_D4s_v3"
  storage_mb = 131072
  
  create_mode = "Replica"
  source_server_id = module.postgresql_primary.server_id
  
  tags = {
    Environment = "Production"
    Role        = "ReadReplica"
    Database    = "PostgreSQL"
  }
}
```

### Multi-Database Setup

```hcl
module "multi_db_postgresql" {
  source = "./azure-postgresql-flexible"
  
  server_name         = "postgres-multi-db"
  location           = "East US"
  resource_group_name = "rg-multi-db"
  virtual_network_id  = module.networking.vnet_id
  delegated_subnet_id = module.networking.subnet_ids["database"]
  
  administrator_login    = "dbadmin"
  administrator_password = var.db_admin_password
  
  postgresql_version = "14"
  sku_name          = "GP_Standard_D4s_v3"
  storage_mb        = 131072
  
  # Multiple databases for different applications
  databases = [
    {
      name     = "user_management"
      collation = "en_US.utf8"
      charset   = "utf8"
    },
    {
      name     = "content_management"
      collation = "en_US.utf8"
      charset   = "utf8"
    },
    {
      name     = "analytics"
      collation = "en_US.utf8"
      charset   = "utf8"
    },
    {
      name     = "audit_logs"
      collation = "en_US.utf8"
      charset   = "utf8"
    },
    {
      name     = "session_store"
      collation = "en_US.utf8"
      charset   = "utf8"
    }
  ]
  
  server_configurations = [
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "shared_buffers"
      value = "256MB"
    },
    {
      name  = "effective_cache_size"
      value = "1GB"
    },
    {
      name  = "work_mem"
      value = "4MB"
    }
  ]
  
  tags = {
    Environment = "Production"
    Purpose     = "MultiApplication"
    Database    = "PostgreSQL"
  }
}
```

## Best Practices

### Security
1. **Network Security**: Use private endpoints and VNet integration
2. **Authentication**: Use strong passwords and consider Azure AD authentication
3. **Encryption**: Enable encryption at rest and in transit
4. **Access Control**: Implement proper firewall rules and RBAC
5. **Audit Logging**: Enable comprehensive logging and monitoring

### Performance
1. **SKU Selection**: Choose appropriate SKU based on workload
2. **Storage**: Use Premium SSD for production workloads
3. **Monitoring**: Monitor performance metrics and query performance
4. **Indexing**: Optimize database indexes for your workload
5. **Connection Pooling**: Use connection pooling for applications

### High Availability
1. **Zone Redundancy**: Use zone-redundant HA for critical workloads
2. **Backup Strategy**: Implement appropriate backup and restore procedures
3. **Read Replicas**: Use read replicas for read-heavy workloads
4. **Disaster Recovery**: Plan for cross-region disaster recovery

### Common SKU Types

| SKU Family | Use Case | Performance | Cost |
|------------|----------|-------------|------|
| **Burstable** | Development, testing | Low to moderate | Lowest |
| **General Purpose** | Most production workloads | Balanced | Medium |
| **Memory Optimized** | Memory-intensive workloads | High memory | Higher |
| **Compute Optimized** | CPU-intensive workloads | High CPU | Higher |

### Common Configuration Parameters

| Parameter | Purpose | Typical Values |
|-----------|---------|----------------|
| `shared_preload_libraries` | Load extensions at startup | `pg_stat_statements,pg_audit` |
| `log_statement` | Log SQL statements | `all`, `ddl`, `mod`, `none` |
| `log_connections` | Log connection attempts | `on`, `off` |
| `max_connections` | Maximum connections | 100-500 depending on SKU |
| `shared_buffers` | Shared memory buffers | 25% of RAM |
| `effective_cache_size` | Estimated cache size | 75% of RAM |

## Integration Examples

### With Application Insights

```hcl
# Monitor PostgreSQL with Application Insights
module "postgresql" {
  source = "./azure-postgresql-flexible"
  
  # ... PostgreSQL configuration ...
  
  server_configurations = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "log_statement"
      value = "all"
    }
  ]
}

# Application Insights configuration for PostgreSQL monitoring
resource "azurerm_monitor_diagnostic_setting" "postgresql" {
  name                       = "postgresql-diagnostics"
  target_resource_id         = module.postgresql.server_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  
  enabled_log {
    category = "PostgreSQLLogs"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

### With Key Vault Integration

```hcl
# Store PostgreSQL password in Key Vault
module "keyvault" {
  source = "./azure-keyvault"
  
  name                = "kv-database-secrets"
  location           = "East US"
  resource_group_name = "rg-security"
  
  secrets = {
    "postgresql-admin-password" = {
      value = var.postgresql_admin_password
    }
  }
}

# Use Key Vault secret for PostgreSQL
module "postgresql" {
  source = "./azure-postgresql-flexible"
  
  server_name         = "postgres-secure"
  location           = "East US"
  resource_group_name = "rg-database"
  virtual_network_id  = module.networking.vnet_id
  delegated_subnet_id = module.networking.subnet_ids["database"]
  
  administrator_login    = "postgresadmin"
  administrator_password = module.keyvault.generated_secret_values["postgresql-admin-password"]
  
  # ... other configuration ...
}
```

## Notes

- PostgreSQL Flexible Server requires a delegated subnet
- Private DNS zone is automatically created for private connectivity
- High availability is only available in certain regions
- Read replicas can be created in different regions for disaster recovery
- Server configurations take effect after server restart

## Related Modules

- [azure-networking](./azure-networking/) - For VNet integration and private endpoints
- [azure-monitoring](./azure-monitoring/) - For database monitoring and alerting
- [azure-keyvault](./azure-keyvault/) - For storing database credentials
- [azure-storage](./azure-storage/) - For database backup storage