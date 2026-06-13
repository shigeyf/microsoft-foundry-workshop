# main.cosmosdb.tf

resource "azurerm_cosmosdb_account" "this" {
  name                = var.thread_storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  minimal_tls_version = "Tls12"

  # Set security-related settings
  local_authentication_disabled         = true
  public_network_access_enabled         = var.public_network_access_enabled
  network_acl_bypass_for_azure_services = true

  # Set high availability and failover settings
  automatic_failover_enabled       = false
  multiple_write_locations_enabled = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  lifecycle {
    prevent_destroy = false
  }
}
