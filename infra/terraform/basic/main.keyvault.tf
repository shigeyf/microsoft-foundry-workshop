// main.keyvault.tf

resource "azurerm_key_vault" "this" {
  count               = var.enable_cmk ? 1 : 0
  name                = local.key_vault_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags

  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  public_network_access_enabled   = local.public_network_access_enabled
  rbac_authorization_enabled      = var.keyvault_enable_rbac_authorization
  enabled_for_deployment          = var.keyvault_enabled_for_deployment
  enabled_for_disk_encryption     = var.keyvault_enabled_for_disk_encryption
  enabled_for_template_deployment = var.keyvault_enabled_for_template_deployment
  purge_protection_enabled        = var.keyvault_purge_protection_enabled
  soft_delete_retention_days      = var.keyvault_soft_delete_retention_days
}

resource "azurerm_role_assignment" "keyvault_for_admin" {
  count                = var.enable_cmk ? 1 : 0
  scope                = azurerm_key_vault.this[0].id
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"

  depends_on = [
    azurerm_key_vault.this,
  ]
}

resource "time_sleep" "wait_for_keyvault_rbac" {
  count           = var.enable_cmk ? 1 : 0
  create_duration = var.keyvault_rbac_propagation_wait_duration
  depends_on = [
    azurerm_role_assignment.keyvault_for_admin,
  ]
}
