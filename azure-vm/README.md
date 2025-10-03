# Azure Virtual Machine Module

This module creates Linux Virtual Machines with configurable networking, storage, and security options. It supports multiple VMs, data disks, and network interface configurations.

## Resources Created

- `azurerm_public_ip` - Public IP addresses (optional)
- `azurerm_network_interface` - Network interfaces for VMs
- `azurerm_network_interface_security_group_association` - NSG associations (optional)
- `azurerm_linux_virtual_machine` - Linux Virtual Machines
- `azurerm_managed_disk` - Data disks for VMs
- `azurerm_virtual_machine_data_disk_attachment` - Data disk attachments

## Usage

### Basic Usage

```hcl
module "vm" {
  source = "./azure-vm"
  
  location           = "East US"
  resource_group_name = "my-rg"
  subnet_id          = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx/subnets/web"
  
  vm_configs = [
    {
      name = "web-vm-01"
      size = "Standard_B2s"
      source_image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 128
      }
    }
  ]
  
  admin_username = "azureuser"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
  }
}
```

### Advanced Usage with Multiple VMs and Data Disks

```hcl
module "vm" {
  source = "./azure-vm"
  
  location           = "East US"
  resource_group_name = "rg-webapp"
  subnet_id          = module.networking.subnet_ids["web"]
  
  vm_configs = [
    {
      name = "web-vm-01"
      size = "Standard_D2s_v3"
      source_image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 256
      }
      data_disks = [
        {
          name                 = "app-data"
          disk_size_gb         = 512
          storage_account_type = "Premium_LRS"
          lun                  = 0
          caching              = "ReadWrite"
        },
        {
          name                 = "logs"
          disk_size_gb         = 256
          storage_account_type = "Standard_LRS"
          lun                  = 1
          caching              = "ReadOnly"
        }
      ]
      custom_data = base64encode(file("${path.module}/scripts/init.sh"))
      tags = {
        Role = "WebServer"
        Tier = "Frontend"
      }
    },
    {
      name = "app-vm-01"
      size = "Standard_D4s_v3"
      source_image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 512
      }
      data_disks = [
        {
          name                 = "database"
          disk_size_gb         = 1024
          storage_account_type = "Premium_LRS"
          lun                  = 0
          caching              = "ReadWrite"
        }
      ]
      tags = {
        Role = "Application"
        Tier = "Backend"
      }
    }
  ]
  
  admin_username    = "azureuser"
  ssh_public_key    = file("~/.ssh/id_rsa.pub")
  create_public_ip  = true
  public_ip_sku     = "Standard"
  
  attach_network_security_group = true
  network_security_group_id     = module.networking.nsg_ids["web-nsg"]
  
  enable_system_assigned_identity = true
  
  tags = {
    Environment = "Production"
    Project     = "WebApp"
    Owner       = "DevOps Team"
  }
}
```

### Private VMs with NAT Gateway

```hcl
module "private_vm" {
  source = "./azure-vm"
  
  location           = "East US"
  resource_group_name = "rg-private"
  subnet_id          = module.networking.subnet_ids["app"]
  
  vm_configs = [
    {
      name = "app-vm-private"
      size = "Standard_B2s"
      source_image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 128
      }
    }
  ]
  
  admin_username              = "azureuser"
  ssh_public_key             = file("~/.ssh/id_rsa.pub")
  create_public_ip           = false  # Private VM
  attach_network_security_group = true
  network_security_group_id     = module.networking.nsg_ids["app-nsg"]
  
  tags = {
    Environment = "Production"
    NetworkType = "Private"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| subnet_id | ID of the subnet | `string` | n/a | yes |
| vm_configs | List of VM configurations | `list(object)` | n/a | yes |
| admin_username | Admin username for VMs | `string` | `"azureuser"` | no |
| ssh_public_key | SSH public key for VMs | `string` | n/a | yes |
| create_public_ip | Create public IP for VMs | `bool` | `true` | no |
| public_ip_allocation | Allocation method for public IP | `string` | `"Static"` | no |
| public_ip_sku | SKU for public IP | `string` | `"Standard"` | no |
| attach_network_security_group | Whether to attach a network security group | `bool` | `false` | no |
| network_security_group_id | ID of the network security group | `string` | `null` | no |
| enable_system_assigned_identity | Enable system assigned identity | `bool` | `true` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

### VM Configuration Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| name | Name of the VM | `string` | yes |
| size | VM size | `string` | yes |
| source_image | Source image configuration | `object` | yes |
| os_disk | OS disk configuration | `object` | yes |
| data_disks | List of data disk configurations | `list(object)` | no |
| custom_data | Custom data script | `string` | no |
| tags | Tags specific to this VM | `map(string)` | no |

### Source Image Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| publisher | Image publisher | `string` | yes |
| offer | Image offer | `string` | yes |
| sku | Image SKU | `string` | yes |
| version | Image version | `string` | yes |

### OS Disk Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| caching | Caching type | `string` | yes |
| storage_account_type | Storage account type | `string` | yes |
| disk_size_gb | Disk size in GB | `number` | yes |

### Data Disk Object

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| name | Name of the data disk | `string` | yes |
| disk_size_gb | Disk size in GB | `number` | yes |
| storage_account_type | Storage account type | `string` | yes |
| lun | Logical Unit Number | `number` | yes |
| caching | Caching type | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| vm_ids | List of VM IDs |
| vm_names | List of VM names |
| vm_public_ips | List of public IP addresses |
| vm_private_ips | List of private IP addresses |
| network_interface_ids | List of network interface IDs |
| data_disk_ids | List of data disk IDs |

## Examples

### Web Server with Custom Script

```hcl
module "web_server" {
  source = "./azure-vm"
  
  location           = "East US"
  resource_group_name = "rg-web"
  subnet_id          = module.networking.subnet_ids["web"]
  
  vm_configs = [
    {
      name = "web-server-01"
      size = "Standard_B2s"
      source_image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 128
      }
      custom_data = base64encode(templatefile("${path.module}/scripts/nginx.sh", {
        domain_name = "example.com"
      }))
    }
  ]
  
  admin_username = "azureuser"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
  
  tags = {
    Role = "WebServer"
    Environment = "Production"
  }
}
```

### Database Server with Multiple Data Disks

```hcl
module "database_server" {
  source = "./azure-vm"
  
  location           = "East US"
  resource_group_name = "rg-database"
  subnet_id          = module.networking.subnet_ids["data"]
  
  vm_configs = [
    {
      name = "db-server-01"
      size = "Standard_D4s_v3"
      source_image = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 256
      }
      data_disks = [
        {
          name                 = "data"
          disk_size_gb         = 1024
          storage_account_type = "Premium_LRS"
          lun                  = 0
          caching              = "ReadWrite"
        },
        {
          name                 = "logs"
          disk_size_gb         = 512
          storage_account_type = "Premium_LRS"
          lun                  = 1
          caching              = "ReadWrite"
        },
        {
          name                 = "backup"
          disk_size_gb         = 2048
          storage_account_type = "Standard_LRS"
          lun                  = 2
          caching              = "None"
        }
      ]
      tags = {
        Role = "Database"
        Database = "PostgreSQL"
      }
    }
  ]
  
  admin_username = "azureuser"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
  create_public_ip = false  # Private database server
  
  tags = {
    Environment = "Production"
    Tier = "Database"
  }
}
```

## Best Practices

1. **VM Sizing**: Choose appropriate VM sizes based on workload requirements
2. **Storage**: Use Premium SSD for production workloads, Standard SSD for development
3. **Security**: 
   - Disable password authentication (SSH keys only)
   - Use Network Security Groups
   - Enable system-assigned identities
4. **Networking**: Use private VMs when possible, public IPs only when necessary
5. **Data Disks**: Separate OS and data disks for better performance and backup strategies
6. **Tags**: Use consistent tagging for cost management and resource organization

## Common VM Sizes

| Size | vCPUs | RAM | Use Case |
|------|-------|-----|----------|
| Standard_B1s | 1 | 1 GB | Development, testing |
| Standard_B2s | 2 | 4 GB | Small web servers |
| Standard_D2s_v3 | 2 | 8 GB | General purpose |
| Standard_D4s_v3 | 4 | 16 GB | Medium workloads |
| Standard_D8s_v3 | 8 | 32 GB | Large applications |
| Standard_E4s_v3 | 4 | 32 GB | Memory-intensive workloads |

## Notes

- Only Linux VMs are supported in this module
- SSH key authentication is required (password authentication is disabled)
- Data disks are created separately and attached to VMs
- System-assigned managed identity is enabled by default
- Custom data scripts are base64 encoded automatically

## Related Modules

- [azure-networking](./azure-networking/) - For creating the network infrastructure
- [azure-storage](./azure-storage/) - For additional storage requirements
- [azure-monitoring](./azure-monitoring/) - For VM monitoring and logging
- [azure-keyvault](./azure-keyvault/) - For storing VM secrets and certificates
