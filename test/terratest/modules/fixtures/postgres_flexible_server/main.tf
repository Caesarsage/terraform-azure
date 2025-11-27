module "postgresql_flexible" {
  source = "../../../../../azure-postgresql-flexible"

  server_name         = var.postgresql_flexible_name
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  zone                   = 2

  tags = var.tags
}

variable "postgresql_flexible_name" {
  type    = string
  default = "test-postgresql-flexible"
}

variable "resource_group_name" {
  type    = string
  default = "rg-tests"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "administrator_login" {
  type    = string
  default = "psqladminun"
}

variable "administrator_password" {
  type    = string
  default = "H@Sh1CoR3!"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "test"
    project     = "terratest"
  }
}

