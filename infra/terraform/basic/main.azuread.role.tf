// main.azuread.role.tf

// Azure AI Search requires specific permissions to enable indexing capabilities
// against files with sensitivity labels.
//   - Microsoft Information Protection (MIP)
//   - Microsoft Rights Management Services (MRMS)
// The following code defines the necessary Azure AD service principal data sources
// and app role assignments for MIP and MRMS.

data "azuread_service_principal" "mip" {
  client_id = "870c4f2e-85b6-4d43-bdda-6ed9a579b725"
}

data "azuread_service_principal" "mrms" {
  client_id = "00000012-0000-0000-c000-000000000000"
}

resource "azuread_app_role_assignment" "mip_assignment" {
  count               = var.enable_ai_search && var.enable_ai_search_sensitivity_labels ? 1 : 0
  app_role_id         = "8b2071cd-015a-4025-8052-1c0dba2d3f64" // UnifiedPolicy.Tenant.Read
  principal_object_id = azurerm_search_service.this[0].identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.mip.object_id
}

resource "azuread_app_role_assignment" "mrms_assignment" {
  count               = var.enable_ai_search && var.enable_ai_search_sensitivity_labels ? 1 : 0
  app_role_id         = "7347eb49-7a1a-43c5-8eac-a5cd1d1c7cf0" // Content.SuperUser
  principal_object_id = azurerm_search_service.this[0].identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.mrms.object_id
}
