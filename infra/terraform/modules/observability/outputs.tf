# outputs.tf — observability module outputs

# ---------------------------------------------------------------------------
# Log Analytics Workspace
# ---------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = var.use_existing ? data.azurerm_log_analytics_workspace.existing[0].id : azurerm_log_analytics_workspace.this[0].id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = var.use_existing ? data.azurerm_log_analytics_workspace.existing[0].name : azurerm_log_analytics_workspace.this[0].name
}

# ---------------------------------------------------------------------------
# Application Insights
# ---------------------------------------------------------------------------

output "app_insights_id" {
  description = "Resource ID of the Application Insights"
  value       = var.use_existing ? data.azurerm_application_insights.existing[0].id : azurerm_application_insights.this[0].id
}

output "app_insights_name" {
  description = "Name of the Application Insights"
  value       = var.use_existing ? data.azurerm_application_insights.existing[0].name : azurerm_application_insights.this[0].name
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = var.use_existing ? data.azurerm_application_insights.existing[0].connection_string : azurerm_application_insights.this[0].connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = var.use_existing ? data.azurerm_application_insights.existing[0].instrumentation_key : azurerm_application_insights.this[0].instrumentation_key
  sensitive   = true
}
