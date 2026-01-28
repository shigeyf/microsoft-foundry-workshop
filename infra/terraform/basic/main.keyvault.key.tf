// main.keyvault.key.tf

resource "azurerm_key_vault_key" "this" {
  count        = var.enable_cmk ? 1 : 0
  name         = "cmk-${local.cognitive_account_name}"
  key_vault_id = azurerm_key_vault.this[0].id

  key_type        = var.customer_managed_key_policy.key_type
  key_size        = var.customer_managed_key_policy.key_size
  curve           = var.customer_managed_key_policy.curve_type
  expiration_date = var.customer_managed_key_policy.expiration_date

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  dynamic "rotation_policy" {
    for_each = var.customer_managed_key_policy.rotation_policy != null ? [1] : []
    content {
      dynamic "automatic" {
        for_each = var.customer_managed_key_policy.rotation_policy.automatic != null ? [1] : []
        content {
          time_after_creation = var.customer_managed_key_policy.rotation_policy.automatic.time_after_creation
          time_before_expiry  = var.customer_managed_key_policy.rotation_policy.automatic.time_before_expiry
        }
      }
      expire_after         = var.customer_managed_key_policy.rotation_policy.expire_after
      notify_before_expiry = var.customer_managed_key_policy.rotation_policy.notify_before_expiry
    }
  }

  depends_on = [
    time_sleep.wait_for_keyvault_rbac,
  ]
}
