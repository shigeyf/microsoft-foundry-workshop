# main.foundry.project.tf — Foundry Project

resource "azurerm_cognitive_account_project" "this" {
  name                 = var.project_name
  cognitive_account_id = azurerm_cognitive_account.this.id
  location             = var.location
  tags                 = var.tags

  description  = var.project_description
  display_name = var.project_display_name

  identity {
    type = "SystemAssigned"
  }

  # Destroy ordering: All account-level connections must be deleted before the
  # project, so that the BYO Key Vault connection (deleted last) sees no remaining
  # workspace connections. Azure API returns 400 otherwise.
  depends_on = [
    azapi_resource.keyvault_connection,
    azapi_resource.app_insights_connection,
  ]
}
