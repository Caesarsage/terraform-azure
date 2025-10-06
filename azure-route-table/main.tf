# Route Table
resource "azurerm_route_table" "main" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = var.tags
}

# Subnet Route Table Associations
resource "azurerm_subnet_route_table_association" "main" {
  count          = length(var.subnet_associations)
  subnet_id      = var.subnet_associations[count.index]
  route_table_id = azurerm_route_table.main.id
}
