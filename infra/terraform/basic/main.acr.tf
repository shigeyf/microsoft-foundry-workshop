// main.acr.tf

resource "azurerm_container_registry" "this" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags

  // CMK requires Premium SKU — automatically upgrade if CMK is enabled
  sku                           = var.enable_cmk ? "Premium" : var.acr_sku
  public_network_access_enabled = local.public_network_access_enabled
  admin_enabled                 = false

  identity {
    type         = var.enable_cmk ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.enable_cmk ? [azurerm_user_assigned_identity.cmk[0].id] : null
  }

  // Customer Managed Key (CMK) encryption configuration.
  // By default, ACR encrypts data at rest using Microsoft-managed keys.
  // Auto-rotation: Use versionless key_vault_key_id to enable automatic key rotation.
  dynamic "encryption" {
    for_each = var.enable_cmk ? [1] : []
    content {
      key_vault_key_id   = azurerm_key_vault_key.this[0].versionless_id
      identity_client_id = azurerm_user_assigned_identity.cmk[0].client_id
    }
  }

  depends_on = [
    time_sleep.wait_for_rbac,
  ]
}
