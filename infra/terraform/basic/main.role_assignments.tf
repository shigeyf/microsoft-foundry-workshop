// main.role_assignments.tf
//
// DEPRECATED: This file has been split into the 3-file RBAC structure:
//   - main.rbac.cmk.tf:      CMK encryption RBAC
//   - main.rbac.services.tf:  Service-to-service RBAC
//   - main.rbac.users.tf:     User/group RBAC
//
// All resources below are commented out. Delete this file once confirmed.

/*

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
//   - Assign Cognitive Services OpenAI User to your search service identity.
//
// NOTE: Using 'Cognitive Services OpenAI User' instead of 'Cognitive Services User'
// for least-privilege: AI Search only calls OpenAI embeddings, not other Cognitive Services.
resource "azurerm_role_assignment" "cognitive_for_search_service" {
  count                = var.enable_ai_search ? 1 : 0
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = "Cognitive Services OpenAI User"
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

resource "azurerm_role_assignment" "self_search_service" {
  count                = var.enable_ai_search ? 1 : 0
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = "Search Index Data Contributor"
  scope                = azurerm_search_service.this[0].id
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

// Foundry Project → ACR (AcrPull)
// Foundry pulls the Hosted Agent container image from ACR using the Foundry Project MI.
resource "azurerm_role_assignment" "acr_for_cognitive_account_project" {
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.this.id
}

// ---------------------------------------------------------------------------
// Deployer (current user) RBAC
// ---------------------------------------------------------------------------
// Grants the deployment user (identified by az login / service principal)
// the same set of roles as the Bicep deployer, enabling Foundry portal
// access and resource management without subscription-level access.

// Deployer → Foundry Account (Azure AI Owner)
resource "azurerm_role_assignment" "foundry_for_deployer" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure AI Owner"
  scope                = azurerm_cognitive_account.this.id
  principal_type       = "User"
}

// Deployer → Foundry Project (Azure AI Owner)
resource "azurerm_role_assignment" "foundry_project_for_deployer" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure AI Owner"
  scope                = azurerm_cognitive_account_project.this.id
  principal_type       = "User"
}

// Deployer → AI Search (Search Service Contributor)
resource "azurerm_role_assignment" "search_service_contributor_for_deployer" {
  count                = var.enable_ai_search ? 1 : 0
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Search Service Contributor"
  scope                = azurerm_search_service.this[0].id
  principal_type       = "User"
}

// Deployer → AI Search (Search Index Data Contributor)
resource "azurerm_role_assignment" "search_index_data_contributor_for_deployer" {
  count                = var.enable_ai_search ? 1 : 0
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Search Index Data Contributor"
  scope                = azurerm_search_service.this[0].id
  principal_type       = "User"
}

// Deployer → Blob Storage (Storage Blob Data Contributor)
resource "azurerm_role_assignment" "blob_contributor_for_deployer" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.this.id
  principal_type       = "User"
}

// For Foundry users
// https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=search-perms#configure-access
// Assign the following roles to yourself.
//  - Search Service Contributor
//  - Search Index Data Contributor
//  - Search Index Data Reader
locals {
  users_roles_for_foundry = toset([
    "Azure AI Administrator",
    "Azure AI Account Owner",
    "Azure AI Owner",
  ])
  users_roles_for_ai_search = toset([
    "Search Service Contributor",
    "Search Index Data Contributor",
    "Search Index Data Reader",
  ])
  users_roles_for_blob = toset([
    "Storage Blob Data Owner",
  ])
}

resource "azurerm_role_assignment" "foundry_for_developer_group" {
  for_each             = local.users_roles_for_foundry
  principal_id         = data.azuread_group.ai_developer_group.object_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account.this.id
}

resource "azurerm_role_assignment" "search_service_for_developer_group" {
  for_each             = var.enable_ai_search ? local.users_roles_for_ai_search : toset([])
  principal_id         = data.azuread_group.ai_developer_group.object_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

resource "azurerm_role_assignment" "blob_for_developer_group" {
  for_each             = local.users_roles_for_blob
  principal_id         = data.azuread_group.ai_developer_group.object_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.this.id
}

*/
