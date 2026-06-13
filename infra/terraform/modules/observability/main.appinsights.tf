# main.appinsights.tf — Application Insights (create new or reference existing)

# ---------------------------------------------------------------------------
# Create path
# ---------------------------------------------------------------------------

resource "azurerm_application_insights" "this" {
  count               = var.use_existing ? 0 : 1
  name                = var.application_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  application_type = "web"
  workspace_id     = azurerm_log_analytics_workspace.this[0].id
}

# ---------------------------------------------------------------------------
# Reference path
# ---------------------------------------------------------------------------

data "azurerm_application_insights" "existing" {
  count               = var.use_existing ? 1 : 0
  name                = element(split("/", var.existing_app_insights_id), length(split("/", var.existing_app_insights_id)) - 1)
  resource_group_name = element(split("/", var.existing_app_insights_id), 4)
}
