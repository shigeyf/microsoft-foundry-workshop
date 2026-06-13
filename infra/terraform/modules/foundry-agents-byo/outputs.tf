# outputs.tf — foundry-agents-byo module outputs

# Storage Account
output "storage_account_id" {
  description = "Resource ID of the Storage Account (file storage)"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.this.name
}

# Cosmos DB
output "cosmosdb_account_id" {
  description = "Resource ID of the Cosmos DB Account (thread storage)"
  value       = azurerm_cosmosdb_account.this.id
}

output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB Account"
  value       = azurerm_cosmosdb_account.this.name
}

# AI Search
output "search_service_id" {
  description = "Resource ID of the AI Search Service (vector store)"
  value       = azurerm_search_service.this.id
}

output "search_service_name" {
  description = "Name of the AI Search Service"
  value       = azurerm_search_service.this.name
}

# Connections
output "file_storage_connection_name" {
  description = "Name of the file storage connection"
  value       = local.storage_connection_name
}

output "vector_store_connection_name" {
  description = "Name of the vector store connection"
  value       = local.vector_store_connection_name
}

output "thread_storage_connection_name" {
  description = "Name of the thread storage connection"
  value       = local.thread_storage_connection_name
}
