# locals.definitions.tf — RBAC role definitions (centralized GUID-based management)
#
# Microsoft recommends using role definition IDs (GUIDs) instead of role names
# during the Foundry RBAC role rename rollout.
#
# References:
#   https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry
#   https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning
#
# Service-to-service RBAC roles are defined in their respective modules:
#   - foundry-core: Cognitive Services User, Key Vault Secrets Officer
#   - foundry-agents: AcrPull

locals {
  # ---------------------------------------------------------------------------
  # Subscription ID (for constructing full role definition paths)
  # ---------------------------------------------------------------------------
  subscription_id = data.azurerm_subscription.current.subscription_id

  # ---------------------------------------------------------------------------
  # Foundry Built-in Role Definitions (GUID-based)
  # ---------------------------------------------------------------------------
  #
  # Important: The Foundry RBAC roles were recently renamed.
  #   Previous Name            → New Name                 (GUID unchanged)
  #   Azure AI User            → Foundry User
  #   Azure AI Owner           → Foundry Owner
  #   Azure AI Account Owner   → Foundry Account Owner
  #   Azure AI Project Manager → Foundry Project Manager
  #   Azure AI Developer       → (Not for Foundry use — scoped to ML workspaces/Hubs)

  role_ids = {
    # Foundry-specific roles
    foundry_user            = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/53ca6127-db72-4b80-b1b0-d745d6d5456d"
    foundry_owner           = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/c883944f-8b7b-4483-af10-35834be79c4a"
    foundry_account_owner   = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/e47c6f54-e4a2-4754-9501-8e0985b135e1"
    foundry_project_manager = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/eadc314b-1a2d-4efa-be10-5d325db5065e"

    # Generic Azure roles
    reader = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"

    # Container Registry roles
    acr_push = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec"

    # Key Vault roles
    key_vault_administrator = "/subscriptions/${local.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483"
  }

  # ---------------------------------------------------------------------------
  # Deployer RBAC
  # ---------------------------------------------------------------------------
  # Default: Foundry Account Owner (control plane only).
  # Optional: switch to Foundry Owner (includes data plane access).

  # Deployer → Foundry Account
  roles_deployer_to_foundry_account = toset([
    (
      var.deployer_use_foundry_owner
      ? local.role_ids.foundry_owner
      : local.role_ids.foundry_account_owner
    )
  ])

  # Deployer → Key Vault (Key Vault Administrator)
  roles_deployer_to_keyvault = toset([
    local.role_ids.key_vault_administrator,
  ])

  # ---------------------------------------------------------------------------
  # Foundry Developer Group RBAC
  # ---------------------------------------------------------------------------

  # Developer Group → Foundry Account (Foundry Project Manager)
  roles_developer_group_to_foundry_account = toset([
    local.role_ids.foundry_project_manager,
  ])

  # Developer Group → Foundry Project (Foundry Project Manager)
  roles_developer_group_to_foundry_project = toset([
    local.role_ids.foundry_project_manager,
  ])

  # ---------------------------------------------------------------------------
  # Foundry User Group RBAC (Full Isolation Pattern)
  # ---------------------------------------------------------------------------
  # Official recommended "full isolation" pattern:
  #   - Account scope: Reader (resource metadata visibility only)
  #   - Project scope: Foundry User (data plane access)

  # User Group → Foundry Account (Reader のみ)
  roles_user_group_to_foundry_account = toset([
    local.role_ids.reader,
  ])

  # User Group → Foundry Project (Foundry User)
  roles_user_group_to_foundry_project = toset([
    local.role_ids.foundry_user,
  ])

  # ---------------------------------------------------------------------------
  # Developer Group → Container Registry (ACR)
  # ---------------------------------------------------------------------------
  # AcrPush: push and pull images (required for `az acr build` / docker push)

  roles_developer_group_to_acr = toset([
    local.role_ids.acr_push,
  ])
}
