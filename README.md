# Azure Terraform Modules

A comprehensive collection of reusable Terraform modules for Azure resources, designed to simplify infrastructure provisioning and promote best practices.

## 📋 Table of Contents

- [Overview](#overview)
- [Available Modules](#available-modules)
- [Getting Started](#getting-started)
- [Module Usage](#module-usage)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## 🚀 Overview

This repository contains production-ready Terraform modules for Azure infrastructure components. Each module is designed to be:

- **Reusable**: Can be used across multiple projects and environments
- **Configurable**: Flexible variables to meet different requirements
- **Secure**: Implements Azure security best practices by default
- **Well-documented**: Comprehensive documentation and examples
- **Maintainable**: Clean, readable code following Terraform best practices

## 📦 Available Modules

### Core Infrastructure
- **[azure-resource-group](./azure-resource-group/)** - Azure Resource Groups with tagging support
- **[azure-networking](./azure-networking/)** - Virtual Networks, Subnets, NSGs, Route Tables, NAT Gateways, and Private Endpoints
- **[azure-storage](./azure-storage/)** - Storage Accounts with containers, file shares, queues, and tables
- **[azure-keyvault](./azure-keyvault/)** - Key Vault with secrets management and access policies

### Compute
- **[azure-vm](./azure-vm/)** - Linux Virtual Machines with data disks and network interfaces
- **[azure-vmss](./azure-vmss/)** - Virtual Machine Scale Sets
- **[azure-vmss-flexible](./azure-vmss-flexible/)** - Flexible Virtual Machine Scale Sets
- **[azure-jumpbox-vm](./azure-jumpbox-vm/)** - Jumpbox/bastion VMs for secure access
- **[azure-bastion](./azure-bastion/)** - Azure Bastion Host for secure VM access

### Networking & Security
- **[azure-application-gateway](./azure-application-gateway/)** - Application Gateway with SSL termination
- **[azure-nat-gateway](./azure-nat-gateway/)** - NAT Gateway for outbound connectivity
- **[azure-route-table](./azure-route-table/)** - Route tables for custom routing

### Databases & Data
- **[azure-postgresql-flexible](./azure-postgresql-flexible/)** - PostgreSQL Flexible Server
- **[azure-redis](./azure-redis/)** - Redis Cache instances
- **[azure-container-registry](./azure-container-registry/)** - Container Registry for container images

### Monitoring & DevOps
- **[azure-monitoring](./azure-monitoring/)** - Log Analytics Workspace and Application Insights
- **[azure-metric-alert](./azure-metric-alert/)** - Metric alerts and action groups
- **[azure-action-group](./azure-action-group/)** - Action groups for notifications
- **[azure-github-oidc](./azure-github-oidc/)** - GitHub OIDC for secure CI/CD authentication

## 🚀 Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) or Azure PowerShell
- Azure subscription with appropriate permissions

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Caesarsage/terraform-azure.git
   cd azure-terraform-modules
   ```

2. **Authenticate with Azure**
   ```bash
   az login
   az account set --subscription "Your Subscription ID"
   ```

3. **Use a module in your project**
   ```hcl
   module "resource_group" {
     source = "./azure-resource-group"
     
     resource_group_name = "my-resource-group"
     location           = "East US"
     tags = {
       Environment = "Production"
       Project     = "MyProject"
     }
   }
   ```

## 📖 Module Usage

Each module follows a consistent structure:

```
module-name/
├── main.tf      # Main resource definitions
├── variables.tf # Input variables
├── outputs.tf   # Output values
└── README.md    # Module documentation
```

### Example: Creating a Virtual Machine

```hcl
module "networking" {
  source = "./azure-networking"
  
  vnet_name           = "my-vnet"
  vnet_address_space  = ["10.0.0.0/16"]
  location           = "East US"
  resource_group_name = "my-rg"
  
  subnets = {
    "web" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "app" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
  
  tags = {
    Environment = "Production"
  }
}

module "vm" {
  source = "./azure-vm"
  
  location           = "East US"
  resource_group_name = "my-rg"
  subnet_id          = module.networking.subnet_ids["web"]
  
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
      data_disks = [
        {
          name                 = "data-disk-1"
          disk_size_gb         = 256
          storage_account_type = "Premium_LRS"
          lun                  = 0
          caching              = "ReadWrite"
        }
      ]
    }
  ]
  
  admin_username    = "azureuser"
  ssh_public_key    = file("~/.ssh/id_rsa.pub")
  create_public_ip  = true
  
  tags = {
    Environment = "Production"
  }
}
```

## ⚙️ Requirements

### Terraform Providers

All modules require the following Terraform providers:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### Azure Permissions

Ensure your Azure account has the necessary permissions to create the resources defined in each module. Common required roles include:

- **Contributor** - For most resource creation
- **User Access Administrator** - For RBAC assignments
- **DNS Zone Contributor** - For DNS-related resources

## 🏗️ Architecture Examples

### Basic Web Application
```
Internet → Application Gateway → VM Scale Set → Database
```

### Secure Enterprise Setup
```
VPN/ExpressRoute → Virtual Network → Private Endpoints → Azure Services
```

### Container-based Application
```
Internet → Application Gateway → Container Instances → Container Registry
```

## 🔧 Customization

All modules are designed to be highly configurable. Key customization points include:

- **Tags**: Consistent tagging strategy across all resources
- **Naming**: Configurable naming conventions
- **Security**: Network security groups, private endpoints, encryption
- **Monitoring**: Built-in monitoring and alerting capabilities
- **Backup**: Automated backup configurations where applicable

## 📝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

### Development Setup

1. Install pre-commit hooks
   ```bash
   pre-commit install
   ```

2. Run tests
   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```

3. Follow our coding standards:
   - Use consistent naming conventions
   - Add comprehensive variable descriptions
   - Include examples in module READMEs
   - Follow Terraform best practices


## 🆘 Support

- **Documentation**: Check individual module READMEs for detailed usage examples
- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/Caesarsage/terraform-azure/issues)
- **Discussions**: Join community discussions in [GitHub Discussions](https://github.com/Caesarsage/terraform-azure/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Made with ❤️ for the Azure and Terraform community**
