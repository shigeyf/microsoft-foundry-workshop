# outputs.tf — foundry-agents module outputs

output "registry_id" {
  description = "Resource ID of the ACR"
  value       = azurerm_container_registry.this.id
}

output "registry_name" {
  description = "Name of the ACR"
  value       = azurerm_container_registry.this.name
}

output "registry_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.this.login_server
}

output "registry_principal_id" {
  description = "System-assigned managed identity principal ID of the ACR"
  value       = azurerm_container_registry.this.identity[0].principal_id
}
