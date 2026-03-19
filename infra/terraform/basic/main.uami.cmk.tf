// main.uami.cmk.tf
// User Assigned Managed Identity for CMK (Customer Managed Key) encryption.
//
// Description:
//   Shared UAMI used for CMK encryption across all target resources
//   (Cognitive Services, ACR, etc.). Following Microsoft's recommendation
//   to share a single UAMI for CMK to simplify RBAC management.
//
//   This file is part of the CMK encryption chain:
//     - main.uami.cmk.tf: UAMI creation (this file)
//     - main.keyvault.key.tf: Encryption key creation
//     - main.rbac.cmk.tf: Key Vault RBAC for UAMI

resource "azurerm_user_assigned_identity" "cmk" {
  count               = var.enable_cmk ? 1 : 0
  name                = local.uami_cmk_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags
}
