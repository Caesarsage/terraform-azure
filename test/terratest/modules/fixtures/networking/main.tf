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
  private_endpoints                = {}
  route_tables                     = {}
  subnet_route_table_associations  = {}
  nat_gateways                     = {}
  subnet_nat_gateway_associations  = {}

  tags = var.tags
}

variable "vnet_name" {
  type = string
  default = "test-vnet"
}

variable "resource_group_name" {
  type    = string
  default = "rg-tests"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "tags" {
  type    = map(string)
  default = {
    environment = "test"
    project     = "terratest"
  }
}
