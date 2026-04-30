# main.cognitive.project.capabilityhost.tf

resource "azapi_resource" "project_capability_host" {
  count     = var.enable_standard_setup ? 1 : 0
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-10-01-preview"
  name      = "projectcaphost"
  parent_id = azurerm_cognitive_account_project.this.id

  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind       = "Agents"
      storageConnections       = [azurerm_storage_account.agent_byo[0].name]
      vectorStoreConnections   = [replace(azurerm_search_service.agent_byo[0].name, "-", "")]
      threadStorageConnections = [azurerm_cosmosdb_account.agent_byo[0].name]
    }
  }

  depends_on = [
    azapi_resource.capability_host,
    azapi_resource.foundry_project_storage_connection,
    azapi_resource.foundry_project_ai_search_connection,
    azapi_resource.foundry_project_cosmos_connection,
    time_sleep.wait_for_rbac_foundry_project,
  ]

  timeouts {
    create = "60m"
  }
}
