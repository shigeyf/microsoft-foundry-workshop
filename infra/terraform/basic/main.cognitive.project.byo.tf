# main.cognitive.project.byo.tf

resource "azurerm_storage_account" "agent_byo" {
  count               = var.enable_standard_setup ? 1 : 0
  name                = local.byo_storage_account_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.byo_blob_replication_type

  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  https_traffic_only_enabled      = true
  public_network_access_enabled   = local.public_network_access_enabled
  min_tls_version                 = "TLS1_2"

  infrastructure_encryption_enabled = true

  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [network_rules]
  }
}

resource "azurerm_search_service" "agent_byo" {
  count               = var.enable_standard_setup ? 1 : 0
  name                = local.byo_search_service_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags

  sku             = var.byo_ai_search_sku
  replica_count   = var.byo_ai_search_replica_count
  partition_count = var.byo_ai_search_partition_count
  hosting_mode    = "Default"
  semantic_search_sku = (
    var.byo_ai_search_sku != "free" && var.byo_ai_semantic_search_sku != ""
    ? var.byo_ai_semantic_search_sku
    : null
  )

  local_authentication_enabled  = false
  network_rule_bypass_option    = "AzureServices"
  public_network_access_enabled = local.public_network_access_enabled

  # authentication_failure_mode   = "http403"
  # customer_managed_key_enforcement_enabled = false

  identity {
    type = "SystemAssigned"
  }
}
