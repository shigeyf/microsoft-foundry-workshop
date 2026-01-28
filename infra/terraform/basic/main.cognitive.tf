// main.cognitive.tf

resource "azurerm_cognitive_account" "this" {
  name                = local.cognitive_account_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags

  custom_subdomain_name         = local.cognitive_account_name
  kind                          = "AIServices"
  local_auth_enabled            = false
  project_management_enabled    = true
  public_network_access_enabled = local.public_network_access_enabled
  sku_name                      = var.cognitive_account_sku

  identity {
    type         = var.enable_cmk ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.enable_cmk ? [azurerm_user_assigned_identity.cognitive_account[0].id] : null
  }

  network_acls {
    default_action = local.public_network_access_enabled ? "Allow" : "Deny"
    bypass         = "AzureServices"
  }

  // Updating encryption mode from customer-managed keys to microsoft-managed keys is
  // not supported when allowProjectManagement flag is set.
  // Thus, `azurerm_cognitive_account_customer_managed_key` resource is not allowed.
  // Use customer managed key with user assigned identity only.
  dynamic "customer_managed_key" {
    for_each = var.enable_cmk ? [1] : []
    content {
      key_vault_key_id   = azurerm_key_vault_key.this[0].id
      identity_client_id = azurerm_user_assigned_identity.cognitive_account[0].client_id
    }
  }

  depends_on = [
    time_sleep.wait_for_rbac
  ]
}
