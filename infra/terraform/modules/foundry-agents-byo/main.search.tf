# main.search.tf

resource "azurerm_search_service" "this" {
  name                = var.vector_store_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku             = var.vector_store_sku
  replica_count   = var.vector_store_replica_count
  partition_count = var.vector_store_partition_count
  hosting_mode    = "Default"
  semantic_search_sku = (
    var.vector_store_sku != "free" && var.vector_store_semantic_search_sku != ""
    ? var.vector_store_semantic_search_sku
    : null
  )

  local_authentication_enabled  = false
  network_rule_bypass_option    = "AzureServices"
  public_network_access_enabled = var.public_network_access_enabled

  # authentication_failure_mode   = "http403"
  # customer_managed_key_enforcement_enabled = false

  identity {
    type = "SystemAssigned"
  }
}
