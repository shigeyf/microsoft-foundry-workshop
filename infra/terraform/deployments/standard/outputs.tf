# outputs.tf — Basic Deployment Outputs

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "Resource ID of the resource group"
  value       = azurerm_resource_group.this.id
}

# ---------------------------------------------------------------------------
# Foundry
# ---------------------------------------------------------------------------

output "foundry_account_name" {
  description = "Name of the Foundry Account"
  value       = module.foundry_core.foundry_account_name
}

output "foundry_account_endpoint" {
  description = "Foundry Account endpoint URL"
  value       = module.foundry_core.foundry_account_endpoint
}

output "foundry_project_name" {
  description = "Name of the Foundry Project"
  value       = module.foundry_core.foundry_project_name
}

output "foundry_deployment_names" {
  description = "List of deployed model names"
  value       = module.foundry_core.foundry_deployment_names
}

# ---------------------------------------------------------------------------
# Container Registry
# ---------------------------------------------------------------------------

output "container_registry_name" {
  description = "Name of the ACR"
  value       = module.foundry_agents.registry_name
}

output "container_registry_login_server" {
  description = "ACR login server URL"
  value       = module.foundry_agents.registry_login_server
}

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = var.enable_observability ? module.observability[0].log_analytics_workspace_id : ""
}

output "app_insights_name" {
  description = "Name of the Application Insights resource"
  value       = var.enable_observability ? module.observability[0].app_insights_name : ""
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = var.enable_observability ? module.observability[0].app_insights_connection_string : ""
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Key Vault (BYO)
# ---------------------------------------------------------------------------

output "key_vault_name" {
  description = "Name of the BYO Key Vault (empty when disabled)"
  value       = module.foundry_core.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the BYO Key Vault (empty when disabled)"
  value       = module.foundry_core.key_vault_uri
}
