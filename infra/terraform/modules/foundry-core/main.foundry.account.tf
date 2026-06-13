# main.foundry.account.tf — Foundry Account (AIServices)

locals {
  # CMK is enabled when key ID is provided
  enable_foundry_cmk = var.foundry_cmk_key_vault_key_id != ""
}

resource "azurerm_cognitive_account" "this" {
  name                = var.account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  custom_subdomain_name         = var.account_name
  kind                          = "AIServices"
  local_auth_enabled            = var.local_auth_enabled
  project_management_enabled    = true
  public_network_access_enabled = var.public_network_access_enabled
  sku_name                      = var.sku_name

  identity {
    type         = local.enable_foundry_cmk ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = local.enable_foundry_cmk ? [var.foundry_cmk_user_assigned_identity_id] : null
  }

  network_acls {
    default_action = var.public_network_access_enabled ? "Allow" : "Deny"
    bypass         = "AzureServices"
  }

  # CMK encryption settings
  # With allowProjectManagement=true, switching from CMK to Microsoft-managed key is not allowed
  dynamic "customer_managed_key" {
    for_each = local.enable_foundry_cmk ? [1] : []
    content {
      key_vault_key_id   = var.foundry_cmk_key_vault_key_id
      identity_client_id = var.foundry_cmk_user_assigned_identity_client_id
    }
  }
}
