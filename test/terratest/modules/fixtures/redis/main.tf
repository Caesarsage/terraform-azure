module "redis" {
  source = "../../../../../azure-redis"

  redis_name          = var.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "Standard"
  family   = "C"
  capacity = 1

  tags = var.tags
}

variable "redis_name" {
  type    = string
  default = "test-redis"
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

