// main.role_assignments.tf

resource "azurerm_role_assignment" "keyvault_for_cognitive_account" {
  count                = var.enable_cmk ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.cognitive_account[0].principal_id
  role_definition_name = "Key Vault Crypto User"
  scope                = azurerm_key_vault.this[0].id
}

resource "time_sleep" "wait_for_rbac" {
  count           = var.enable_cmk ? 1 : 0
  create_duration = var.cognitive_rbac_propagation_wait_duration

  depends_on = [
    azurerm_role_assignment.keyvault_for_cognitive_account,
  ]
}

// For Azure AI Search integration
//
// https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=foundry-perms#configure-access
// On your Foundry resource:
//   - Assign Cognitive Services User to your search service identity.
resource "azurerm_role_assignment" "cognitive_for_search_service" {
  count                = var.enable_ai_search ? 1 : 0
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = "Cognitive Services User"
  scope                = azurerm_cognitive_account.this.id
}
// https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=storage-perms#configure-access
// On your Azure Blob Storage account:
//   - Assign Storage Blob Data Reader to your search service identity.
resource "azurerm_role_assignment" "blob_for_search_service" {
  count                = var.enable_ai_search ? 1 : 0
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = azurerm_storage_account.this.id
}

// For Foundry resource with Azure AI Search
//   - Assign Search Index Data Contributor to your Foundry resource managed identity.
//   - Assign Search Index Data Reader to your Foundry resource managed identity.
//   - Assign Search Index Data Reader to your Foundry resource managed identity.
locals {
  cognitive_account_roles_for_ai_search = toset([
    "Search Service Contributor",
    "Search Index Data Contributor",
    "Search Index Data Reader",
  ])
}

resource "azurerm_role_assignment" "search_service_for_cognitive_account" {
  for_each             = var.enable_ai_search ? local.cognitive_account_roles_for_ai_search : toset([])
  principal_id         = azurerm_cognitive_account.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

// For Foundry Project with Azure AI Search
//   - Assign Search Index Data Contributor to your Foundry Project managed identity.
//   - Assign Search Index Data Reader to your Foundry Project managed identity.
//   - Assign Search Index Data Reader to your Foundry Project managed identity.
locals {
  cognitive_project_roles_for_ai_search = toset([
    "Search Service Contributor",
    "Search Index Data Contributor",
    "Search Index Data Reader",
  ])
}

resource "azurerm_role_assignment" "search_service_for_cognitive_account_project" {
  for_each             = var.enable_ai_search ? local.cognitive_project_roles_for_ai_search : toset([])
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

// For Foundry users
// https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=search-perms#configure-access
// Assign the following roles to yourself.
//  - Search Service Contributor
//  - Search Index Data Contributor
//  - Search Index Data Reader
locals {
  users_roles_for_ai_search = toset([
    "Search Service Contributor",
    "Search Index Data Contributor",
    "Search Index Data Reader",
  ])
  users_roles_for_blob = toset([
    "Storage Blob Data Owner",
  ])
}

resource "azurerm_role_assignment" "search_service_for_developer_group" {
  for_each             = var.enable_ai_search ? local.users_roles_for_ai_search : toset([])
  principal_id         = data.azuread_group.ai_developer_group.object_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

resource "azurerm_role_assignment" "blob_for_developer_group" {
  for_each             = var.enable_ai_search ? local.users_roles_for_blob : toset([])
  principal_id         = data.azuread_group.ai_developer_group.object_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.this.id
}
