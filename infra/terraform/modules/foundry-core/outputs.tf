# outputs.tf — foundry-core module outputs

# ---------------------------------------------------------------------------
# Foundry Account
# ---------------------------------------------------------------------------

output "foundry_account_id" {
  description = "Resource ID of the Foundry Account"
  value       = azurerm_cognitive_account.this.id
}

output "foundry_account_name" {
  description = "Name of the Foundry Account"
  value       = azurerm_cognitive_account.this.name
}

output "foundry_account_principal_id" {
  description = "System-assigned managed identity principal ID of the Foundry Account"
  value       = azurerm_cognitive_account.this.identity[0].principal_id
}

output "foundry_account_endpoint" {
  description = "Foundry Account endpoint URL"
  value       = azurerm_cognitive_account.this.endpoint
}

# ---------------------------------------------------------------------------
# Foundry Project
# ---------------------------------------------------------------------------

output "foundry_project_id" {
  description = "Resource ID of the Foundry Project"
  value       = azurerm_cognitive_account_project.this.id
}

output "foundry_project_name" {
  description = "Name of the Foundry Project"
  value       = azurerm_cognitive_account_project.this.name
}

output "foundry_project_principal_id" {
  description = "System-assigned managed identity principal ID of the Foundry Project"
  value       = azurerm_cognitive_account_project.this.identity[0].principal_id
}

# ---------------------------------------------------------------------------
# Model Deployments
# ---------------------------------------------------------------------------

output "foundry_deployment_names" {
  description = "List of deployed model names"
  value       = [for d in azurerm_cognitive_deployment.models : d.name]
}

# ---------------------------------------------------------------------------
# Key Vault (BYO Connection Secrets)
# ---------------------------------------------------------------------------

output "key_vault_id" {
  description = "Resource ID of the BYO Key Vault (empty when enable_keyvault is false)"
  value       = var.enable_keyvault ? azurerm_key_vault.this[0].id : ""
}

output "key_vault_name" {
  description = "Name of the BYO Key Vault (empty when enable_keyvault is false)"
  value       = var.enable_keyvault ? azurerm_key_vault.this[0].name : ""
}

output "key_vault_uri" {
  description = "URI of the BYO Key Vault (empty when enable_keyvault is false)"
  value       = var.enable_keyvault ? azurerm_key_vault.this[0].vault_uri : ""
}
