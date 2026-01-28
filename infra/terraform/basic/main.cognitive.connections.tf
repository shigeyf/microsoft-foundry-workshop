// main.cognitive.connections.tf

// TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_ai_search_connection" {
  count                     = var.enable_ai_search ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-09-01"
  name                      = replace(azurerm_search_service.this[0].name, "-", "")
  parent_id                 = azurerm_cognitive_account.this.id
  schema_validation_enabled = false

  body = {
    properties = {
      isSharedToAll = true
      category      = "CognitiveSearch"
      target        = "https://${azurerm_search_service.this[0].name}.search.windows.net/"

      authType = "AAD"

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.this[0].id
        type       = "azure_ai_search"
      }
    }
  }
}

// TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_appInsights_connection" {
  count                     = var.enable_app_insights ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-09-01"
  name                      = replace(azurerm_application_insights.this[0].name, "-", "")
  parent_id                 = azurerm_cognitive_account.this.id
  schema_validation_enabled = false

  body = {
    properties = {
      isSharedToAll = true
      category      = "AppInsights"
      target        = azurerm_application_insights.this[0].id

      authType = "ApiKey"
      credentials = {
        key = azurerm_application_insights.this[0].connection_string
      }

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_application_insights.this[0].id
      }
    }
  }
}
