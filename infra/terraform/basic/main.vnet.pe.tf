// main.vnet.pe.tf

// Private Endpoint for Cognitive Services (AI Foundry Hub)
resource "azurerm_private_endpoint" "cognitive" {
  count               = local.enable_private_networking ? 1 : 0
  name                = "pe-${local.cognitive_account_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoint[0].id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.cognitive_account_name}"
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "dns-zone-group-cognitive"
    private_dns_zone_ids = [
      local.private_dns_zone_id_cognitive,
      local.private_dns_zone_id_openai,
      local.private_dns_zone_id_ai_services
    ]
  }
}

// Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  count               = local.enable_private_networking && var.enable_cmk ? 1 : 0
  name                = "pe-${local.key_vault_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoint[0].id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.this[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group-keyvault"
    private_dns_zone_ids = [local.private_dns_zone_id_keyvault]
  }
}

// Private Endpoint for AI Search
resource "azurerm_private_endpoint" "search" {
  count               = local.enable_private_networking && var.enable_ai_search ? 1 : 0
  name                = "pe-${local.search_service_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoint[0].id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.search_service_name}"
    private_connection_resource_id = azurerm_search_service.this[0].id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group-search"
    private_dns_zone_ids = [local.private_dns_zone_id_search]
  }
}
