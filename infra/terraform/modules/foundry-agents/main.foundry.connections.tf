# main.foundry.connections.tf — Foundry Account-level Connections (agent-related)
# Using azapi (not yet supported by azurerm provider)

locals {
  connections_api_version = "2025-09-01"
}

# Connection: Azure Container Registry
# Registers the ACR with the Foundry Account for Hosted Agent image pulls.
resource "azapi_resource" "acr_connection" {
  type      = "Microsoft.CognitiveServices/accounts/connections@${local.connections_api_version}"
  name      = "conn-${var.registry_name}"
  parent_id = var.foundry_account_id

  schema_validation_enabled = false

  body = {
    properties = {
      category      = "ContainerRegistry"
      authType      = "ManagedIdentity"
      isSharedToAll = true
      target        = azurerm_container_registry.this.login_server

      credentials = {
        clientId   = var.foundry_project_principal_id
        resourceId = azurerm_container_registry.this.id
      }

      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_container_registry.this.id
      }
    }
  }

  # RBAC must propagate before the connection can pull from ACR
  depends_on = [time_sleep.wait_for_acr_rbac_propagation]
}
