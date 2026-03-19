// main.loganalytics.tf

// --- Create path ---
resource "azurerm_log_analytics_workspace" "this" {
  count               = var.create_observability ? 1 : 0
  name                = local.loganalytics_workspace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags

  sku               = "PerGB2018"
  retention_in_days = 30
}

// --- Reference path ---
data "azurerm_log_analytics_workspace" "existing" {
  count               = var.create_observability ? 0 : 1
  name                = element(split("/", var.existing_log_workspace_id), length(split("/", var.existing_log_workspace_id)) - 1)
  resource_group_name = element(split("/", var.existing_log_workspace_id), 4)
}

locals {
  log_analytics_workspace_id = var.create_observability ? azurerm_log_analytics_workspace.this[0].id : data.azurerm_log_analytics_workspace.existing[0].id
}
