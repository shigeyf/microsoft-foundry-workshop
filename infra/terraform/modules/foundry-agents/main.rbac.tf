# main.rbac.tf — Service-to-service RBAC role assignments within foundry-agents

# Foundry Project MI → ACR (AcrPull)
# Required for Hosted Agent containers to pull images from the registry
resource "azurerm_role_assignment" "foundry_project_to_acr" {
  principal_id         = var.foundry_project_principal_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.this.id
}

# Wait for ACR RBAC propagation (Azure RBAC is eventually consistent)
resource "time_sleep" "wait_for_acr_rbac_propagation" {
  create_duration = var.rbac_propagation_wait_duration

  depends_on = [azurerm_role_assignment.foundry_project_to_acr]
}
