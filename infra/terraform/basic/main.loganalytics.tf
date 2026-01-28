// main.loganalytics.tf

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.loganalytics_workspace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags

  sku               = "PerGB2018"
  retention_in_days = 30
}
