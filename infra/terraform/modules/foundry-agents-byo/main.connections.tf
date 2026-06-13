# main.connections.tf — Foundry Account-level Connections
# Using azapi (not yet supported by azurerm provider)

locals {
  connections_api_version        = "2025-09-01"
  storage_connection_name        = "conn-filestorage-${var.file_storage_account_name}"
  vector_store_connection_name   = "conn-vectorstore-${var.vector_store_account_name}"
  thread_storage_connection_name = "conn-threadstorage-${var.thread_storage_account_name}"
}

# Connection: File Storage for Agent Service
# The Foundry Account's system-assigned MI
resource "azapi_resource" "file_storage_connection" {
  type      = "Microsoft.CognitiveServices/accounts/connections@${local.connections_api_version}"
  name      = local.storage_connection_name
  parent_id = var.foundry_account_id

  schema_validation_enabled = false

  body = {
    properties = {
      authType      = "AAD"
      category      = "AzureStorageAccount"
      isSharedToAll = true
      target        = azurerm_storage_account.this.primary_blob_endpoint

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_storage_account.this.id
        location   = var.location
      }
    }
  }

  depends_on = [
    azurerm_storage_account.this,
    azurerm_role_assignment.foundry_project_to_byo_resources["file_storage"],
  ]
}

# Connection: Vector Store for Agent Service
# The Foundry Account's system-assigned MI
resource "azapi_resource" "vector_store_connection" {
  type      = "Microsoft.CognitiveServices/accounts/connections@${local.connections_api_version}"
  name      = local.vector_store_connection_name
  parent_id = var.foundry_account_id

  schema_validation_enabled = false

  body = {
    properties = {
      category      = "CognitiveSearch"
      authType      = "AAD"
      isSharedToAll = true
      target        = "https://${azurerm_search_service.this.name}.search.windows.net/"

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.this.id
        type       = "azure_ai_search"
        location   = var.location
      }
    }
  }

  depends_on = [
    azurerm_search_service.this,
    azurerm_role_assignment.foundry_project_to_byo_resources["vector_store"],
    azurerm_role_assignment.foundry_project_to_byo_resources["vector_store_index"],
  ]
}

# Connection: Thread Storage for Agent Service
# The Foundry Account's system-assigned MI
resource "azapi_resource" "thread_storage_connection" {
  type      = "Microsoft.CognitiveServices/accounts/connections@${local.connections_api_version}"
  name      = local.thread_storage_connection_name
  parent_id = var.foundry_account_id

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

  depends_on = [
    azurerm_cosmosdb_account.this,
    azurerm_role_assignment.foundry_project_to_byo_resources["thread_store"],
  ]
}
