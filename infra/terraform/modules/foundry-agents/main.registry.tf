# main.registry.tf — foundry-agents module
# Azure Container Registry for Hosted Agent container images

locals {
  # CMK is enabled when key ID is provided
  enable_acr_cmk = var.acr_cmk_key_vault_key_id != ""
  # CMK requires Premium SKU — auto-upgrade when enabled
  effective_sku = local.enable_acr_cmk ? "Premium" : var.sku
}

resource "azurerm_container_registry" "this" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku                           = local.effective_sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  identity {
    type         = local.enable_acr_cmk ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = local.enable_acr_cmk ? [var.acr_cmk_user_assigned_identity_id] : null
  }

  # CMK encryption settings
  # Versionless keyIdentifier = auto-rotation enabled
  dynamic "encryption" {
    for_each = local.enable_acr_cmk ? [1] : []
    content {
      key_vault_key_id   = var.acr_cmk_key_vault_key_id
      identity_client_id = var.acr_cmk_user_assigned_identity_client_id
    }
  }
}
