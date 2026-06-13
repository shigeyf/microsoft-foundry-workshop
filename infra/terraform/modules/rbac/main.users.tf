# main.users.tf — User/group RBAC role assignments
#
# This file manages RBAC for human users and security groups:
#   - Deployer (deployment executor)
#   - Foundry Developer Group
#   - Foundry User Group
#
# All role assignments use role_definition_id (GUID-based) for stability
# during the Foundry RBAC role rename rollout.

# ---------------------------------------------------------------------------
# Deployer → Foundry Account
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "deployer_to_foundry_account" {
  for_each           = var.deployer_principal_id != "" ? local.roles_deployer_to_foundry_account : toset([])
  principal_id       = var.deployer_principal_id
  role_definition_id = each.key
  scope              = var.foundry_account_id
}

# ---------------------------------------------------------------------------
# Deployer → Key Vault (Key Vault Administrator)
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "deployer_to_keyvault" {
  for_each           = var.deployer_principal_id != "" && var.enable_keyvault ? local.roles_deployer_to_keyvault : toset([])
  principal_id       = var.deployer_principal_id
  role_definition_id = each.key
  scope              = var.key_vault_id
}

# ---------------------------------------------------------------------------
# Foundry Developer Group → Foundry Account
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "developer_group_to_foundry_account" {
  for_each           = var.foundry_developer_group_id != "" ? local.roles_developer_group_to_foundry_account : toset([])
  principal_id       = var.foundry_developer_group_id
  role_definition_id = each.key
  scope              = var.foundry_account_id
}

# ---------------------------------------------------------------------------
# Foundry Developer Group → Foundry Project
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "developer_group_to_foundry_project" {
  for_each           = var.foundry_developer_group_id != "" ? local.roles_developer_group_to_foundry_project : toset([])
  principal_id       = var.foundry_developer_group_id
  role_definition_id = each.key
  scope              = var.foundry_project_id
}

# ---------------------------------------------------------------------------
# Foundry User Group → Foundry Account (Reader only — full isolation pattern)
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "user_group_to_foundry_account" {
  for_each           = var.foundry_user_group_id != "" ? local.roles_user_group_to_foundry_account : toset([])
  principal_id       = var.foundry_user_group_id
  role_definition_id = each.key
  scope              = var.foundry_account_id
}

# ---------------------------------------------------------------------------
# Foundry User Group → Foundry Project (Foundry User — data plane access)
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "user_group_to_foundry_project" {
  for_each           = var.foundry_user_group_id != "" ? local.roles_user_group_to_foundry_project : toset([])
  principal_id       = var.foundry_user_group_id
  role_definition_id = each.key
  scope              = var.foundry_project_id
}

# ---------------------------------------------------------------------------
# Foundry Developer Group → Container Registry (AcrPush)
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "developer_group_to_acr" {
  for_each           = var.foundry_developer_group_id != "" ? local.roles_developer_group_to_acr : toset([])
  principal_id       = var.foundry_developer_group_id
  role_definition_id = each.key
  scope              = var.container_registry_id
}
