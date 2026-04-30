# main.rbac.cmk.tf
# CMK encryption RBAC role assignments.
#
# Description:
#   Grants the CMK user-assigned managed identity permission to use
#   the Key Vault encryption key. Includes a time_sleep to wait for
#   RBAC propagation before dependent resources (e.g., Cognitive Account)
#   are created.
#
#   This file is part of the 3-file RBAC structure:
#     - main.rbac.services.tf: Service-to-service RBAC
#     - main.rbac.cmk.tf: CMK encryption RBAC (this file)
#     - main.rbac.users.tf: User/group RBAC

# CMK UAMI -> Key Vault
#   Role Definitions: local.roles_cmk_uami_to_keyvault @main.rbac.definitions.tf
resource "azurerm_role_assignment" "keyvault_for_cognitive_account" {
  for_each             = var.enable_cmk ? local.roles_cmk_uami_to_keyvault : toset([])
  principal_id         = azurerm_user_assigned_identity.cmk[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_key_vault.this[0].id
}

resource "time_sleep" "wait_for_rbac" {
  count           = var.enable_cmk ? 1 : 0
  create_duration = var.cognitive_rbac_propagation_wait_duration

  depends_on = [
    azurerm_role_assignment.keyvault_for_cognitive_account,
  ]
}
