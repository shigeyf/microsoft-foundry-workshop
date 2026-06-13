# main.foundry.connections.tf — Foundry Account-level Connections
# Using azapi (not yet supported by azurerm provider)

# Connection: BYO Key Vault (AccountManagedIdentity auth)
# The Foundry Account's system-assigned MI accesses this Key Vault
# to store and retrieve connection secrets.
# Constraint: Only one Key Vault connection per Foundry Account is allowed.
# Note: Other connections should depend on this resource and its RBAC assignment.
resource "azapi_resource" "keyvault_connection" {
  count     = var.enable_keyvault ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/connections@${local.cognitiveservices_api_version}"
  name      = "conn-${var.key_vault_name}"
  parent_id = azurerm_cognitive_account.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      category      = "AzureKeyVault"
      authType      = "AccountManagedIdentity"
      isSharedToAll = true
      target        = azurerm_key_vault.this[0].id

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_key_vault.this[0].id
        location   = var.location
      }
    }
  }

  # RBAC must propagate before the connection can access the Key Vault
  depends_on = [time_sleep.wait_for_keyvault_rbac_propagation]
}

# Connection: Application Insights (account-level)
# Must be created after Key Vault connection and its RBAC assignment.
resource "azapi_resource" "app_insights_connection" {
  count     = var.enable_app_insights_connection ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/connections@${local.cognitiveservices_api_version}"
  name      = "conn-${var.app_insights_name}"
  parent_id = azurerm_cognitive_account.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      category      = "AppInsights"
      authType      = "ApiKey"
      isSharedToAll = true
      target        = var.app_insights_id

      credentials = {
        key = var.app_insights_connection_string
      }

      metadata = {
        ApiType    = "Azure"
        ResourceId = var.app_insights_id
      }
    }
  }

  depends_on = [azapi_resource.keyvault_connection]
}
