// main.appinsights.tf

resource "azurerm_application_insights" "this" {
  count               = var.enable_app_insights ? 1 : 0
  name                = local.application_insights_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags

  application_type = "web"
  workspace_id     = azurerm_log_analytics_workspace.this.id
}
