# main.rbac.users.tf
# User and group RBAC role assignments for Azure AI Foundry resources.
#
# Description:
#   Centralizes all human user and security group RBAC assignments.
#   Separating user access from service-to-service access enables:
#     - Easier security auditing of human access
#     - Clear separation of concerns
#     - Simplified onboarding/offboarding workflows
#
#   This file is part of the 3-file RBAC structure:
#     - main.rbac.services.tf: Service-to-service RBAC
#     - main.rbac.cmk.tf: CMK encryption RBAC
#     - main.rbac.users.tf: User/group RBAC (this file)

# ---------------------------------------------------------------------------
# Deployer (current user) RBAC
# ---------------------------------------------------------------------------

# Deployer -> Foundry Account
#   Role Definitions: local.roles_deployer_to_foundry_account @main.rbac.definitions.tf
resource "azurerm_role_assignment" "foundry_for_deployer" {
  for_each             = local.roles_deployer_to_foundry_account
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account.this.id
}

# Deployer -> Foundry Project
#   Role Definitions: local.roles_deployer_to_foundry_project @main.rbac.definitions.tf
resource "azurerm_role_assignment" "foundry_project_for_deployer" {
  for_each             = local.roles_deployer_to_foundry_project
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account_project.this.id
}

# Deployer -> AI Search
#   Role Definitions: local.roles_deployer_to_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "search_for_deployer" {
  for_each             = var.enable_ai_search ? local.roles_deployer_to_search : toset([])
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

# Deployer -> Blob Storage
#   Role Definitions: local.roles_deployer_to_blob @main.rbac.definitions.tf
resource "azurerm_role_assignment" "blob_for_deployer" {
  for_each             = local.roles_deployer_to_blob
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.this.id
}

# ---------------------------------------------------------------------------
# AI Developer Group RBAC
# ---------------------------------------------------------------------------

# Developer Group -> Foundry Account
#   Role Definitions: local.roles_developer_group_to_foundry_account @main.rbac.definitions.tf
resource "azurerm_role_assignment" "foundry_for_developer_group" {
  for_each             = var.ai_project_developers_group_name != "" ? local.roles_developer_group_to_foundry_account : toset([])
  principal_id         = data.azuread_group.ai_developer_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account.this.id
}

# Developer Group -> Foundry Project
#   Role Definitions: local.roles_developer_group_to_foundry_project @main.rbac.definitions.tf
resource "azurerm_role_assignment" "foundry_project_for_developer_group" {
  for_each             = var.ai_project_developers_group_name != "" ? local.roles_developer_group_to_foundry_project : toset([])
  principal_id         = data.azuread_group.ai_developer_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account_project.this.id
}

# Developer Group -> AI Search
#   Role Definitions: local.roles_developer_group_to_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "search_for_developer_group" {
  for_each             = var.ai_project_developers_group_name != "" && var.enable_ai_search ? local.roles_developer_group_to_search : toset([])
  principal_id         = data.azuread_group.ai_developer_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

# Developer Group -> Blob Storage
#   Role Definitions: local.roles_developer_group_to_blob @main.rbac.definitions.tf
resource "azurerm_role_assignment" "blob_for_developer_group" {
  for_each             = var.ai_project_developers_group_name != "" ? local.roles_developer_group_to_blob : toset([])
  principal_id         = data.azuread_group.ai_developer_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.this.id
}

# ---------------------------------------------------------------------------
# AI User Group RBAC (read-only access)
# ---------------------------------------------------------------------------

# User Group -> Foundry Account
#   Role Definitions: local.roles_user_group_to_foundry_account @main.rbac.definitions.tf
resource "azurerm_role_assignment" "foundry_for_user_group" {
  for_each             = var.ai_project_users_group_name != "" ? local.roles_user_group_to_foundry_account : toset([])
  principal_id         = data.azuread_group.ai_user_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account.this.id
}

# User Group -> Foundry Project
#   Role Definitions: local.roles_user_group_to_foundry_project @main.rbac.definitions.tf
resource "azurerm_role_assignment" "foundry_project_for_user_group" {
  for_each             = var.ai_project_users_group_name != "" ? local.roles_user_group_to_foundry_project : toset([])
  principal_id         = data.azuread_group.ai_user_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_cognitive_account_project.this.id
}

# User Group -> AI Search
#   Role Definitions: local.roles_user_group_to_search @main.rbac.definitions.tf
resource "azurerm_role_assignment" "search_for_user_group" {
  for_each             = var.ai_project_users_group_name != "" && var.enable_ai_search ? local.roles_user_group_to_search : toset([])
  principal_id         = data.azuread_group.ai_user_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_search_service.this[0].id
}

# User Group -> Blob Storage
#   Role Definitions: local.roles_user_group_to_blob @main.rbac.definitions.tf
resource "azurerm_role_assignment" "blob_for_user_group" {
  for_each             = var.ai_project_users_group_name != "" ? local.roles_user_group_to_blob : toset([])
  principal_id         = data.azuread_group.ai_user_group[0].object_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.this.id
}
