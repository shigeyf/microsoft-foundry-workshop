# main.cognitive.project.connections.tf

# TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_project_storage_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01"
  name      = azurerm_storage_account.this.name
  parent_id = azurerm_cognitive_account_project.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      category = "AzureStorageAccount"
      authType = "AAD"
      target   = azurerm_storage_account.this.primary_blob_endpoint

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_storage_account.this.id
        location   = var.location
      }
    }
  }
}

# TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_project_ai_search_connection" {
  count     = var.enable_ai_search ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01"
  name      = replace(azurerm_search_service.this[0].name, "-", "")
  parent_id = azurerm_cognitive_account_project.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      category = "CognitiveSearch"
      authType = "AAD"
      target   = "https://${azurerm_search_service.this[0].name}.search.windows.net/"

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.this[0].id
        type       = "azure_ai_search"
        location   = var.location
      }
    }
  }
}

# TODO: replace with AzureRM provider resource when supported
resource "azapi_resource" "foundry_project_cosmos_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01"
  name      = azurerm_cosmosdb_account.this.name
  parent_id = azurerm_cognitive_account_project.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      category = "CosmosDb"
      authType = "AAD"
      target   = azurerm_cosmosdb_account.this.endpoint

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_cosmosdb_account.this.id
        location   = var.location
      }
    }
  }
}
