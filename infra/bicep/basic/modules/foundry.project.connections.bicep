// foundry.project.connections.bicep
// Azure AI Foundry project-level connections for Standard Setup (Hosted Agent BYO resources).
//
// Description:
//   Creates project-scoped connections to the three BYO resources required for
//   Foundry Hosted Agents (Standard Setup):
//     - BYO Azure Blob Storage Account  (category: AzureStorageAccount, authType: AAD)
//     - BYO Azure AI Search service     (category: CognitiveSearch,     authType: AAD)
//     - BYO Azure Cosmos DB account     (category: CosmosDb,            authType: AAD)
//
//   These connections are referenced by the project-level CapabilityHost to link
//   BYO resources to the Hosted Agents runtime.
//   This module must be deployed AFTER service-to-service RBAC assignments so that the
//   Foundry Project managed identity already has the required permissions on each resource.
//
// Resources:
//   Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01
//
// Usage:
//   module foundryProjectConnections 'modules/foundry.project.connections.bicep' = if (enableStandardSetup) {
//     params: {
//       location:               location
//       accountName:            foundry.outputs.accountName
//       projectName:            foundry.outputs.projectName
//       agentStorageAccountName: agentStorage.outputs.storageAccountName
//       agentStorageAccountId:   agentStorage.outputs.storageAccountId
//       agentSearchServiceName:  agentSearch.outputs.serviceName
//       agentSearchServiceId:    agentSearch.outputs.serviceId
//       cosmosDbAccountName:     cosmos.outputs.accountName
//       cosmosDbAccountId:       cosmos.outputs.accountId
//       cosmosDbAccountEndpoint: cosmos.outputs.accountEndpoint
//     }
//     dependsOn: [rbacServices]
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string

@description('Name of the parent Foundry Account (AIServices account).')
param accountName string

@description('Name of the Foundry Project to attach connections to.')
param projectName string

// --- BYO Storage Connection Parameters ---
@description('Name of the BYO Storage Account for Hosted Agents.')
param agentStorageAccountName string

@description('Resource ID of the BYO Storage Account for Hosted Agents.')
param agentStorageAccountId string

// --- BYO AI Search Connection Parameters ---
@description('Name of the BYO AI Search service for Hosted Agents.')
param agentSearchServiceName string

@description('Resource ID of the BYO AI Search service for Hosted Agents.')
param agentSearchServiceId string

// --- BYO Cosmos DB Connection Parameters ---
@description('Name of the BYO Cosmos DB account for Hosted Agent thread storage.')
param agentCosmosDbAccountName string

@description('Resource ID of the BYO Cosmos DB account for Hosted Agent thread storage.')
param agentCosmosDbAccountId string

@description('Document endpoint of the BYO Cosmos DB account for Hosted Agent thread storage (e.g., https://<name>.documents.azure.com:443/).')
param agentCosmosDbAccountEndpoint string

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var searchApiVersion  = '2023-11-01'
var cosmosApiVersion  = '2024-11-15'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Parent Foundry Account reference (needed for the nested project reference below)
resource existingFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: accountName
}

// Foundry Project reference for parenting connections
resource existingFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-09-01' existing = {
  parent: existingFoundryAccount
  name: projectName
}

// Connection: BYO Storage Account (agent)
// category: AzureStorageAccount — used by Hosted Agents as the default blob storage backend.
// authType: AAD — the Foundry Project MI authenticates via Entra ID (Storage Blob Data Contributor).
resource agentStorageConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01' = {
  parent: existingFoundryProject
  name: 'conn-${agentStorageAccountName}'
  properties: {
    category: 'AzureStorageAccount'
    // Use environment().suffixes.storage to avoid hardcoded cloud-specific hostname.
    target: 'https://${agentStorageAccountName}.blob.${environment().suffixes.storage}'
    authType: 'AAD'
    // isSharedToAll: false — this connection is scoped to this project only.
    isSharedToAll: false
    metadata: {
      ApiType: 'Azure'
      ResourceId: agentStorageAccountId
      location: location
    }
  }
}

// Connection: BYO AI Search (agent)
// category: CognitiveSearch — used by Hosted Agents as the vector store backend.
// authType: AAD — the Foundry Project MI authenticates via Entra ID
//                 (Search Index Data Reader + Search Service Contributor).
resource agentSearchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01' = {
  parent: existingFoundryProject
  name: 'conn-${agentSearchServiceName}'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${agentSearchServiceName}.search.windows.net'
    authType: 'AAD'
    isSharedToAll: false
    metadata: {
      ApiType: 'Azure'
      ResourceId: agentSearchServiceId
      location: location
      ApiVersion: searchApiVersion
    }
  }
  dependsOn: [agentStorageConnection]
}

// Connection: BYO Cosmos DB (agent)
// category: CosmosDb — used by Hosted Agents as the thread (session) storage backend.
// authType: AAD — the Foundry Project MI authenticates via Entra ID
//                 (Cosmos DB Operator + SQL Built-in Data Contributor on enterprise_memory DB).
resource agentCosmosDbConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-09-01' = {
  parent: existingFoundryProject
  name: 'conn-${agentCosmosDbAccountName}'
  properties: {
    category: 'CosmosDb'
    target: agentCosmosDbAccountEndpoint
    authType: 'AAD'
    isSharedToAll: false
    metadata: {
      ApiType: 'Azure'
      ResourceId: agentCosmosDbAccountId
      location: location
      ApiVersion: cosmosApiVersion
    }
  }
  dependsOn: [agentStorageConnection]
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

// Connection names are used by the project-level CapabilityHost to reference BYO resources.
output agentStorageConnectionName string = agentStorageConnection.name
output agentSearchConnectionName  string = agentSearchConnection.name
output agentCosmosDbConnectionName string = agentCosmosDbConnection.name
