# Integration Test: Uses the networking module to create dependencies

# Generate SSH key pair for testing
resource "tls_private_key" "test" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Use the networking module to create VNet, Subnet, and NSG
module "networking" {
  source = "../../../../../azure-networking"

  vnet_name           = var.vnet_name
  vnet_address_space  = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  # Create subnet for VMs
  subnets = {
    vm-subnet = {
      address_prefixes = ["10.0.1.0/24"]
      delegation       = null
    }
  }

  # Create NSG with SSH rule
  network_security_groups = {
    vm-nsg = {
      security_rules = [
        {
          name                       = "AllowSSH"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowHTTP"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  }

  # Associate NSG with subnet
  subnet_nsg_associations = {
    vm-subnet-nsg = {
      subnet_name = "vm-subnet"
      nsg_name    = "vm-nsg"
    }
  }

  # No private endpoints, route tables, or NAT gateways for basic test
  private_endpoints               = {}
  route_tables                    = {}
  subnet_route_table_associations = {}
  nat_gateways                    = {}
  subnet_nat_gateway_associations = {}

  tags = var.tags
}

module "vm" {
  source = "../../../../../azure-vm"

  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = module.networking.subnet_ids["vm-subnet"]
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.test.public_key_openssh

  # VM Configuration
  create_public_ip                = var.create_public_ip
  attach_network_security_group   = var.attach_nsg
  network_security_group_id       = var.attach_nsg ? module.networking.nsg_ids["vm-nsg"] : null

  vm_configs = [
    {
      name = var.vm_name
      size = var.vm_size

      source_image = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }

      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb         = 30
      }

      custom_data = base64encode(<<-EOF
        #!/bin/bash
        echo "Hello from Terratest" > /tmp/hello.txt
        apt-get update
        apt-get install -y nginx
        EOF
      )

      data_disks = var.create_data_disk ? [
        {
          name                 = "data-disk-1"
          disk_size_gb         = 10
          storage_account_type = "Standard_LRS"
          lun                  = 0
          caching              = "ReadWrite"
        }
      ] : []

    }
  ]

  tags = var.tags
}

variable "resource_group_name" {
  type    = string
  default = "rg-tests"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "vm_name" {
  type    = string
  default = "test-vm"
}

variable "vnet_name" {
  type    = string
  default = "test-vnet"
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "create_public_ip" {
  type    = bool
  default = false
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-rsa AAAABBBBAAABAQC7I1V+H3h8t5nRZP..."
}

variable "attach_nsg" {
  type = bool
  default = false
}

variable "create_data_disk" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {
    environment = "test"
    project     = "terratest"
  }
}
