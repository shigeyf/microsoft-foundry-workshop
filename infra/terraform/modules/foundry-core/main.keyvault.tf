# main.keyvault.tf — BYO Key Vault for Foundry connection secrets
# This Key Vault is dedicated to the Foundry Account (1 KV per Foundry Account constraint).
# CMK Key Vault is managed separately in the 'security' module.

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  count               = var.enable_keyvault ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = var.key_vault_sku_name

  rbac_authorization_enabled = true

  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_enable_purge_protection

  public_network_access_enabled = var.key_vault_public_network_access_enabled

  # Destroy ordering: The Foundry Account holds an internal reference to this
  # Key Vault even after the keyvault_connection is deleted via API. The KV
  # soft-delete is blocked until the Account is fully removed (~10 min wait).
  # This dependency ensures Account is destroyed first, eliminating the wait.
  depends_on = [azurerm_cognitive_account.this]
}
