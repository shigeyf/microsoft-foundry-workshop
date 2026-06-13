# main.rbac.tf — Service-to-service RBAC role assignments within foundry-core
#
# These assignments must complete and propagate before connections are created.

locals {
  role_assignments = {
    "file_storage" = {
      role_definition_name = "Storage Blob Data Contributor"
      scope                = azurerm_storage_account.this.id
    },
    "vector_store" = {
      role_definition_name = "Search Service Contributor"
      scope                = azurerm_search_service.this.id
    },
    "vector_store_index" = {
      role_definition_name = "Search Index Data Contributor"
      scope                = azurerm_search_service.this.id
    },
    "thread_store" = {
      role_definition_name = "Cosmos DB Operator"
      scope                = azurerm_cosmosdb_account.this.id
    }
  }
}

# Foundry Project MI → BYO resources (storage, search, cosmos)
resource "azurerm_role_assignment" "foundry_project_to_byo_resources" {
  for_each             = local.role_assignments
  principal_id         = var.foundry_project_principal_id
  principal_type       = "ServicePrincipal"
  role_definition_name = each.value.role_definition_name
  scope                = each.value.scope
}
