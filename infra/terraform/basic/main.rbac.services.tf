# main.rbac.services.tf
# Service-to-service RBAC role assignments for Azure AI Foundry ecosystem.
#
# Description:
#   Centralizes all cross-service RBAC assignments to enable security review
#   and auditing from a single location. This file handles permissions between:
#     - Foundry Account ↔ AI Search
#     - Foundry Project → Foundry Account (Parent-child RBAC)
#     - Foundry Project → BYO Blob Storage
#     - Foundry Project → BYO AI Search
#     - Foundry Project → BYO Cosmos DB
#     - Foundry Project → AI Search RAG
#     - Foundry Project → ACR
#     - AI Search → Foundry Account (Integrated Vectorization)
#     - AI Search → Blob Storage
#
#   This file is part of the 3-file RBAC structure:
#     - main.rbac.services.tf: Service-to-service RBAC (this file)
#     - main.rbac.cmk.tf: CMK encryption RBAC
#     - main.rbac.users.tf: User/group RBAC

# Foundry Account -> BYO Key Vault
#   Role Definitions: local.roles_foundry_account_to_byo_keyvault @main.rbac.definitions.tf
resource "azurerm_role_assignment" "byo_keyvault_for_foundry_account" {
  for_each = var.enable_byo_keyvault ? local.roles_foundry_account_to_byo_keyvault : toset([])
  # Need to use User Assigned Identity for CMK scenarios,
  # as the Cognitive Account MI is not selected to be used for Key Vault access.
  principal_id = (
    var.enable_cmk
    ? azurerm_user_assigned_identity.cmk[0].principal_id
    : azurerm_cognitive_account.this.identity[0].principal_id
  )
  role_definition_name = each.key
  scope                = azurerm_key_vault.this[0].id
}

# Foundry Account -> AI Search
#   Role Definitions: local.roles_foundry_account_to_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "search_service_for_cognitive_account" {
  for_each             = var.enable_ai_search ? local.roles_foundry_account_to_search : toset([])
  principal_id         = azurerm_cognitive_account.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

# Foundry Project -> Foundry Account (Parent-child RBAC)
#   The Hosted Agent container runs as the Foundry Project MI. This grants it permission
#   to call GPT-4.1 and text-embedding-3-small via DefaultAzureCredential.
#   Role Definitions: local.roles_foundry_project_to_foundry_account @main.rbac.definitions.tf
resource "azurerm_role_assignment" "cognitive_account_for_cognitive_account_project" {
  for_each             = local.roles_foundry_project_to_foundry_account
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account.this.id
}

# Foundry Project -> BYO Blob Storage
#   Role Definitions: local.roles_foundry_project_to_byo_blob @main.rbac.definitions.tf
resource "azurerm_role_assignment" "byo_blob_for_cognitive_account_project" {
  for_each             = var.enable_standard_setup ? local.roles_foundry_project_to_byo_blob : toset([])
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.agent_byo[0].id
}

# Foundry Project -> BYO AI Search
#   Role Definitions: local.roles_foundry_project_to_byo_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "byo_search_service_for_cognitive_account_project" {
  for_each             = var.enable_standard_setup ? local.roles_foundry_project_to_byo_search : toset([])
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_search_service.agent_byo[0].id
}

# Foundry Project -> BYO Cosmos DB
#   Role Definitions: local.roles_foundry_project_to_byo_cosmosdb @main.rbac.definitions.tf
resource "azurerm_role_assignment" "byo_cosmos_service_for_cognitive_account_project" {
  for_each             = var.enable_standard_setup ? local.roles_foundry_project_to_byo_cosmosdb : toset([])
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_cosmosdb_account.agent_byo[0].id
}

# Foundry Project -> AI Search RAG
#   Role Definitions: local.roles_foundry_project_to_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "search_service_for_cognitive_account_project" {
  for_each             = var.enable_ai_search ? local.roles_foundry_project_to_search : toset([])
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

# Foundry Project -> ACR
#   Role Definitions: local.roles_foundry_project_to_acr @main.rbac.definitions.tf
resource "azurerm_role_assignment" "acr_for_cognitive_account_project" {
  for_each             = local.roles_foundry_project_to_acr
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_container_registry.this.id
}

# AI Search -> Foundry Account (Integrated Vectorization)
#   Role Definitions: local.roles_search_to_foundry @main.rbac.definitions.tf
resource "azurerm_role_assignment" "cognitive_for_search_service" {
  for_each             = var.enable_ai_search ? local.roles_search_to_foundry : toset([])
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account.this.id
}

# AI Search -> Blob Storage
#   Role Definitions: local.roles_search_to_blob @main.rbac.definitions.tf
resource "azurerm_role_assignment" "blob_for_search_service" {
  for_each             = var.enable_ai_search ? local.roles_search_to_blob : toset([])
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.this.id
}

# Cosmos DB role assignment for Foundry Project
# Foundry Project -> Cosmos DB data-plane access
# after caphost creates enterprise_memory db
resource "azurerm_cosmosdb_sql_role_assignment" "byo_cosmos_contributor" {
  count               = var.enable_standard_setup ? 1 : 0
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_cosmosdb_account.agent_byo[0].name
  role_definition_id  = "${azurerm_cosmosdb_account.agent_byo[0].id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_cognitive_account_project.this.identity[0].principal_id
  scope               = "${azurerm_cosmosdb_account.agent_byo[0].id}/dbs/enterprise_memory"

  depends_on = [
    azapi_resource.project_capability_host
  ]
}
resource "time_sleep" "wait_for_rbac_foundry_account" {
  create_duration = var.cognitive_rbac_propagation_wait_duration

  depends_on = [
    azurerm_role_assignment.byo_keyvault_for_foundry_account,
  ]
}

resource "time_sleep" "wait_for_rbac_foundry_project" {
  create_duration = var.cognitive_rbac_propagation_wait_duration

  depends_on = [
    azurerm_role_assignment.byo_blob_for_cognitive_account_project,
    azurerm_role_assignment.byo_search_service_for_cognitive_account_project,
    azurerm_role_assignment.byo_cosmos_service_for_cognitive_account_project,
  ]
}
