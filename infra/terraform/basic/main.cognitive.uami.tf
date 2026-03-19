// main.cognitive.uami.tf
//
// DEPRECATED: Renamed to main.uami.cmk.tf to clarify this UAMI is for CMK
// encryption, not specific to the Cognitive Account.
// Delete this file once confirmed.

/*
resource "azurerm_user_assigned_identity" "cognitive_account" {
  count               = var.enable_cmk ? 1 : 0
  name                = local.cognitive_uami_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags
}
*/
