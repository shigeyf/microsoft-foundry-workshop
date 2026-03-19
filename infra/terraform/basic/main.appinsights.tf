// main.appinsights.tf

// --- Create path ---
resource "azurerm_application_insights" "this" {
  count               = var.enable_app_insights && var.create_observability ? 1 : 0
  name                = local.application_insights_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.tags

  application_type = "web"
  workspace_id     = local.log_analytics_workspace_id
}

// --- Reference path ---
data "azurerm_application_insights" "existing" {
  count               = var.enable_app_insights && !var.create_observability ? 1 : 0
  name                = element(split("/", var.existing_app_insights_id), length(split("/", var.existing_app_insights_id)) - 1)
  resource_group_name = element(split("/", var.existing_app_insights_id), 4)
}

locals {
  app_insights_connection_string = var.enable_app_insights ? (
    var.create_observability
    ? azurerm_application_insights.this[0].connection_string
    : data.azurerm_application_insights.existing[0].connection_string
  ) : ""
  app_insights_id = var.enable_app_insights ? (
    var.create_observability
    ? azurerm_application_insights.this[0].id
    : data.azurerm_application_insights.existing[0].id
  ) : ""
  app_insights_name = var.enable_app_insights ? (
    var.create_observability
    ? azurerm_application_insights.this[0].name
    : data.azurerm_application_insights.existing[0].name
  ) : ""
}
