// rbac.cosmos.project.bicep
// Cosmos DB SQL data-plane role assignment for Foundry Project (Standard Setup).
//
// Description:
//   Assigns the Cosmos DB Built-in Data Contributor SQL role to the Foundry Project
//   managed identity, scoped to the 'enterprise_memory' database.
//
//   This module is intentionally SEPARATE from rbac.services.bicep because the
//   'enterprise_memory' database does NOT exist at the start of deployment.
//   It is automatically created by the Foundry Agent Service when the Project-level
//   CapabilityHost is provisioned. The role assignment must therefore run AFTER
//   projectCapabilityHost has completed.
//
//   Deployment order in main.bicep:
//     1. agentCosmos          → Cosmos DB account is created
//     2. rbacServices         → Cosmos DB Operator (ARM-level) is assigned
//     3. projectCapabilityHost → Foundry creates 'enterprise_memory' DB automatically
//     4. THIS MODULE          → SQL role scoped to /dbs/enterprise_memory is assigned
//
//   This mirrors the Terraform pattern where azurerm_cosmosdb_sql_role_assignment
//   uses depends_on = [azapi_resource.project_capability_host].
//
// Resources:
//   Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-11-15
//
// Usage:
//   module rbacCosmosProject 'modules/rbac.cosmos.project.bicep' = if (enableStandardSetup) {
//     params: {
//       agentCosmosDbAccountName:  agentCosmos.outputs.accountName
//       foundryProjectPrincipalId: foundry.outputs.foundryProjectPrincipalId
//     }
//     dependsOn: [projectCapabilityHost]
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name of the BYO Cosmos DB account for Hosted Agents.')
param agentCosmosDbAccountName string

@description('Principal ID of the Foundry Project system-assigned managed identity.')
param foundryProjectPrincipalId string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Existing Cosmos DB account reference for parenting the SQL role assignment
resource existingAgentCosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
  name: agentCosmosDbAccountName
}

// Cosmos DB SQL Role Assignment: Foundry Project MI → enterprise_memory DB (Built-in Data Contributor)
// Grants data-plane read/write access to the 'enterprise_memory' database used by
// Foundry Hosted Agents for thread and session storage.
//
// Built-in Data Contributor (00000000-0000-0000-0000-000000000002):
//   Allows full CRUD on items within the scoped database.
//
// Scope: /dbs/enterprise_memory (database-level, least-privilege)
//   The enterprise_memory database is created by the Foundry Agent Service when the
//   Project CapabilityHost is provisioned. This module must be deployed after that event.
resource foundryProjectToCosmosDbSqlRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-11-15' = {
  parent: existingAgentCosmosDb
  name: guid(existingAgentCosmosDb.id, foundryProjectPrincipalId, '00000000-0000-0000-0000-000000000002')
  properties: {
    roleDefinitionId: '${existingAgentCosmosDb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: foundryProjectPrincipalId
    scope: '${existingAgentCosmosDb.id}/dbs/enterprise_memory'
  }
}
