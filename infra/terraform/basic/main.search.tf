# main.search.tf

locals {
  search_location = var.ai_search_location != "" ? var.ai_search_location : var.location
}

resource "azurerm_search_service" "this" {
  count               = var.enable_ai_search ? 1 : 0
  name                = local.search_service_name
  resource_group_name = azurerm_resource_group.this.name
  location            = local.search_location
  tags                = local.tags

  sku                 = var.ai_search_sku
  replica_count       = var.ai_search_replica_count
  partition_count     = var.ai_search_partition_count
  hosting_mode        = "Default"
  semantic_search_sku = var.ai_search_sku != "free" ? var.ai_semantic_search_sku : null

  local_authentication_enabled  = false
  network_rule_bypass_option    = "AzureServices"
  public_network_access_enabled = local.public_network_access_enabled

  # authentication_failure_mode   = "http403"
  # customer_managed_key_enforcement_enabled = false

  identity {
    type = "SystemAssigned"
  }
}
