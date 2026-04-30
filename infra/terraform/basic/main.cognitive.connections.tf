# main.cognitive.connections.tf

# TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_kv_connection" {
  count     = var.enable_byo_keyvault ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/connections@2025-09-01"
  name      = replace(azurerm_key_vault.this[0].name, "-", "")
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
        location   = azurerm_key_vault.this[0].location
      }
    }
  }

  depends_on = [
    azurerm_cognitive_account.this,
    azurerm_key_vault.this,
    time_sleep.wait_for_rbac_foundry_account,
  ]
}

# TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_ai_search_connection" {
  count     = var.enable_ai_search ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/connections@2025-09-01"
  name      = replace(azurerm_search_service.this[0].name, "-", "")
  parent_id = azurerm_cognitive_account.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      category      = "CognitiveSearch"
      authType      = "AAD"
      isSharedToAll = true
      target        = "https://${azurerm_search_service.this[0].name}.search.windows.net/"

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.this[0].id
        location   = azurerm_search_service.this[0].location
        type       = "azure_ai_search"
      }
    }
  }
}

# TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_appInsights_connection" {
  count     = var.enable_app_insights ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/connections@2025-09-01"
  name      = replace(local.app_insights_name, "-", "")
  parent_id = azurerm_cognitive_account.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      category      = "AppInsights"
      authType      = "ApiKey"
      isSharedToAll = true
      target        = local.app_insights_id

      credentials = {
        key = local.app_insights_connection_string
      }

      metadata = {
        ApiType    = "Azure"
        ResourceId = local.app_insights_id
      }
    }
  }

  depends_on = [
    azurerm_application_insights.this,
    azapi_resource.foundry_kv_connection,
  ]
}
