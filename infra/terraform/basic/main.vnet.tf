// main.vnet.tf

resource "azurerm_virtual_network" "this" {
  count               = local.enable_private_networking ? 1 : 0
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "private_endpoint" {
  count                = local.enable_private_networking ? 1 : 0
  name                 = "snet-private-endpoint"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [var.private_endpoint_subnet_address_prefix]
}
