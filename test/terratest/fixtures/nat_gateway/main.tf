module "nat_gateway" {
  source = "../../../../../azure-nat-gateway"

  nat_gateway_name = var.nat_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  public_ip_name = var.public_ip_name

  tags = var.tags
}

variable "nat_gateway_name" {
  type    = string
  default = "test-nat-gateway"
}

variable "public_ip_name" {
  type    = string
  default = "test-nat-gateway-pip"
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
  type = map(string)
  default = {
    environment = "test"
    project     = "terratest"
  }
}
