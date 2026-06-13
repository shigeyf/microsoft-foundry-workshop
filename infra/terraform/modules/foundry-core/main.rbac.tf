# main.rbac.tf — Service-to-service RBAC role assignments within foundry-core
#
# These assignments must complete and propagate before connections are created.

# Foundry Account MI → Key Vault (Key Vault Secrets Officer)
# Required for the Foundry Account to store/retrieve connection secrets.
resource "azurerm_role_assignment" "foundry_account_to_keyvault" {
  count                = var.enable_keyvault ? 1 : 0
  principal_id         = azurerm_cognitive_account.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.this[0].id
}

# Foundry Project MI → Foundry Account (Cognitive Services User)
# Required for Hosted Agent containers to invoke models (e.g. GPT-4.1)
resource "azurerm_role_assignment" "foundry_project_to_account" {
  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Cognitive Services User"
  scope                = azurerm_cognitive_account.this.id
}

# Foundry Project MI → Application Insights (Log Analytics Reader)
# Required for evaluations that read traces collected in Application Insights.
resource "azurerm_role_assignment" "project_to_app_insights_log_analytics_reader" {
  count = var.enable_app_insights_connection ? 1 : 0

  principal_id         = azurerm_cognitive_account_project.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Log Analytics Reader"
  scope                = var.app_insights_id

  lifecycle {
    precondition {
      condition     = var.app_insights_id != ""
      error_message = "app_insights_id must be set when enable_app_insights_connection is true."
    }
  }
}

# Wait for Key Vault RBAC propagation (Azure RBAC is eventually consistent)
resource "time_sleep" "wait_for_keyvault_rbac_propagation" {
  count           = var.enable_keyvault ? 1 : 0
  create_duration = var.rbac_propagation_wait_duration

  depends_on = [azurerm_role_assignment.foundry_account_to_keyvault]
}
