// foundry.project.capabilityhost.bicep
// Project-level Capability Host for Azure AI Foundry Hosted Agents (Standard Setup).
//
// Description:
//   Creates a project-scoped capability host that links the three BYO resource connections
//   to the Hosted Agents runtime within the Foundry Project:
//     - vectorStoreConnections  → BYO AI Search connection name
//     - storageConnections      → BYO Blob Storage connection name
//     - threadStorageConnections → BYO Cosmos DB connection name
//
//   This resource must be created AFTER:
//     1. The account-level capability host (foundry.capabilityhost.bicep)
//     2. The project-level BYO connections (foundry.project.connections.bicep)
//
// IMPORTANT — DELETE NOT SUPPORTED:
//   The capabilityHosts API does not support DELETE operations.
//   Once created, this resource cannot be removed via a standard Bicep/ARM delete.
//   When decommissioning, the parent Foundry Project must be deleted instead,
//   or the resource must be manually removed from the deployment state.
//
// API version notes:
//   2025-10-01-preview — Required for project/capabilityHosts support.
//
// Resources:
//   Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-10-01-preview
//
// Usage:
//   module projectCapabilityHost 'modules/foundry.project.capabilityhost.bicep' = if (enableStandardSetup) {
//     params: {
//       accountName:                 foundry.outputs.accountName
//       projectName:                 foundry.outputs.projectName
//       vectorStoreConnectionName:   foundryProjectConnections.outputs.agentSearchConnectionName
//       storageConnectionName:       foundryProjectConnections.outputs.agentStorageConnectionName
//       threadStorageConnectionName: foundryProjectConnections.outputs.cosmosDbConnectionName
//     }
//     dependsOn: [accountCapabilityHost, foundryProjectConnections]
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name of the parent Foundry Account (AIServices account).')
param accountName string

@description('Name of the Foundry Project under which the capability host is created.')
param projectName string

@description('Name of the project capability host resource. Must be unique within the project.')
param capabilityHostName string = 'projectcaphost'

@description('Name of the project-level BYO AI Search connection (used as vector store).')
param vectorStoreConnectionName string

@description('Name of the project-level BYO Blob Storage connection (used as agent file storage).')
param storageConnectionName string

@description('Name of the project-level BYO Cosmos DB connection (used as thread/session storage).')
param threadStorageConnectionName string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Parent Foundry Account reference (needed for the nested project reference below)
resource existingFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: accountName
}

// Foundry Project reference for parenting the capability host
resource existingFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-09-01' existing = {
  parent: existingFoundryAccount
  name: projectName
}

// Project-level Capability Host
// Links BYO connections to the Hosted Agents runtime within this Foundry Project.
#disable-next-line use-recent-api-versions
resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-10-01-preview' = {
  parent: existingFoundryProject
  name: capabilityHostName
  properties: {
    // BCP037: capabilityHostKind is not yet reflected in the ARM type definition for
    // ProjectCapabilityHostProperties but is supported at runtime.
    #disable-next-line BCP037
    capabilityHostKind: 'Agents'
    // BCP037: vectorStoreConnections, storageConnections, threadStorageConnections are not yet
    // reflected in the ARM type definition but are supported at runtime.
    #disable-next-line BCP037
    vectorStoreConnections: [vectorStoreConnectionName]
    #disable-next-line BCP037
    storageConnections: [storageConnectionName]
    #disable-next-line BCP037
    threadStorageConnections: [threadStorageConnectionName]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output capabilityHostName string = projectCapabilityHost.name
