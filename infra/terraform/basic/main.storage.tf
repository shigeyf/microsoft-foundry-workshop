# main.storage.tf

resource "azurerm_storage_account" "this" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags

  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
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
