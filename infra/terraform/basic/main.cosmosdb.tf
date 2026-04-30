# main.cosmosdb.tf

resource "azurerm_cosmosdb_account" "agent_byo" {
  count               = var.enable_standard_setup ? 1 : 0
  name                = local.byo_cosmosdb_account_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags


  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  minimal_tls_version = "Tls12"

  # Set security-related settings
  local_authentication_disabled         = true
  public_network_access_enabled         = local.public_network_access_enabled
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
