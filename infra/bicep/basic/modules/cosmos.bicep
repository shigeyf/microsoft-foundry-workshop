// cosmos.bicep
// Azure Cosmos DB Account for Foundry Hosted Agent session and memory storage.
//
// Description:
//   Provisions an Azure Cosmos DB account (kind: GlobalDocumentDB / SQL API) with
//   Session consistency. Used as the BYO thread-storage backend for Foundry Hosted Agents
//   (Standard Setup). Key-based authentication is disabled to enforce Entra ID (AAD) access.
//
// Resources:
//   Microsoft.DocumentDB/databaseAccounts@2024-11-15
//
// Usage:
//   module agentCosmos 'modules/cosmos.bicep' = if (enableStandardSetup) {
//     params: {
//       location:          location
//       cosmosAccountName: names.agentCosmosDb
//       tags:              tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param cosmosAccountName string

@description('Default consistency level for the Cosmos DB account.')
@allowed(['BoundedStaleness', 'ConsistentPrefix', 'Eventual', 'Session', 'Strong'])
param defaultConsistencyLevel string = 'Session'

@description('Public network access: Enabled | Disabled. Set to Disabled and configure private endpoint for production.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    // Disable key-based auth to enforce Entra ID (AAD) authentication only.
    disableLocalAuth: true
    // Prevent accidental writes to metadata (databases/containers) via data-plane keys.
    disableKeyBasedMetadataWriteAccess: true
    // PoC: public access enabled.
    // PRODUCTION: set to 'Disabled' and configure a private endpoint.
    publicNetworkAccess: publicNetworkAccess
  }
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output accountId string = cosmosAccount.id
output accountName string = cosmosAccount.name
// documentEndpoint format: https://<accountName>.documents.azure.com:443/
output accountEndpoint string = cosmosAccount.properties.documentEndpoint
output principalId string = cosmosAccount.identity.principalId
