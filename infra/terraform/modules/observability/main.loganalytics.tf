# main.loganalytics.tf — Log Analytics Workspace (create new or reference existing)

# ---------------------------------------------------------------------------
# Create path
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  count               = var.use_existing ? 0 : 1
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku               = "PerGB2018"
  retention_in_days = var.log_retention_in_days
}

# ---------------------------------------------------------------------------
# Reference path
# ---------------------------------------------------------------------------

data "azurerm_log_analytics_workspace" "existing" {
  count               = var.use_existing ? 1 : 0
  name                = element(split("/", var.existing_log_workspace_id), length(split("/", var.existing_log_workspace_id)) - 1)
  resource_group_name = element(split("/", var.existing_log_workspace_id), 4)
}
