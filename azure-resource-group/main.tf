# ========= Main file ========
# This file is part of the Azure resource group module.
# It defines the resources required to create a Resource Group in Azure.

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

