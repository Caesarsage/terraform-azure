# This file is part of the Azure Networking module.
# It defines the networking resources required for the Azure environment.

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]


  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "main" {
  for_each = var.network_security_groups

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.subnet_nsg_associations

  subnet_id                 = azurerm_subnet.subnets[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.main[each.value.nsg_name].id
}

resource "azurerm_private_endpoint" "main" {
  for_each = var.private_endpoints

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.subnets[each.value.subnet_name].id

  private_service_connection {
    name                           = "${each.key}-connection"
    private_connection_resource_id = each.value.resource_id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_route_table" "main" {
  for_each = var.route_tables

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = each.value.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "main" {
  for_each = var.subnet_route_table_associations

  subnet_id      = azurerm_subnet.subnets[each.value.subnet_name].id
  route_table_id = azurerm_route_table.main[each.value.route_table_name].id
}

resource "azurerm_public_ip" "nat_gateway" {
  for_each = var.nat_gateways

  name                = "${each.key}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_nat_gateway" "main" {
  for_each = var.nat_gateways

  name                    = each.key
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = each.value.sku_name
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  for_each = var.nat_gateways

  nat_gateway_id       = azurerm_nat_gateway.main[each.key].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = var.subnet_nat_gateway_associations

  subnet_id      = azurerm_subnet.subnets[each.value.subnet_name].id
  nat_gateway_id = azurerm_nat_gateway.main[each.value.nat_gateway_name].id
}
