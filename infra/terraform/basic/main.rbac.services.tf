// main.rbac.services.tf
// Service-to-service RBAC role assignments for Azure AI Foundry ecosystem.
//
// Description:
//   Centralizes all cross-service RBAC assignments to enable security review
//   and auditing from a single location. This file handles permissions between:
//     - Foundry Account ↔ AI Search
//     - Foundry Project ↔ AI Search
//     - Foundry Project → ACR
//     - AI Search → Foundry Account (Integrated Vectorization)
//     - AI Search → Blob Storage
//
//   This file is part of the 3-file RBAC structure:
//     - main.rbac.services.tf: Service-to-service RBAC (this file)
//     - main.rbac.cmk.tf: CMK encryption RBAC
//     - main.rbac.users.tf: User/group RBAC

// AI Search -> Foundry Account (Integrated Vectorization)
//   Role Definitions: local.roles_search_to_foundry @main.rbac.definitions.tf
resource "azurerm_role_assignment" "cognitive_for_search_service" {
  for_each             = var.enable_ai_search ? local.roles_search_to_foundry : toset([])
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account.this.id
}

// AI Search -> Blob Storage
//   Role Definitions: local.roles_search_to_blob @main.rbac.definitions.tf
resource "azurerm_role_assignment" "blob_for_search_service" {
  for_each             = var.enable_ai_search ? local.roles_search_to_blob : toset([])
  principal_id         = azurerm_search_service.this[0].identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.this.id
}

// Foundry Account -> AI Search
//   Role Definitions: local.roles_foundry_account_to_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "search_service_for_cognitive_account" {
  for_each             = var.enable_ai_search ? local.roles_foundry_account_to_search : toset([])
  principal_id         = azurerm_cognitive_account.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

// Foundry Project -> AI Search
//   Role Definitions: local.roles_foundry_project_to_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "search_service_for_cognitive_account_project" {
  for_each             = var.enable_ai_search ? local.roles_foundry_project_to_search : toset([])
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

// Foundry Project -> ACR
//   Role Definitions: local.roles_foundry_project_to_acr @main.rbac.definitions.tf
resource "azurerm_role_assignment" "acr_for_cognitive_account_project" {
  for_each             = local.roles_foundry_project_to_acr
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_container_registry.this.id
}
