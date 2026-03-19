// search.bicep
// Azure AI Search service with configurable SKU, replicas, partitions, and semantic search.
//
// Description:
//   Provisions an Azure AI Search service with a system-assigned managed identity.
//   SKU, replica count, partition count, and semantic search tier are all parameterised
//   to support both minimal PoC deployments (free/basic, single replica) and
//   production-grade setups (Standard+, multiple replicas and partitions).
//
// Resources:
//   Microsoft.Search/searchServices@2025-05-01
//
// Usage:
//   module search 'modules/search.bicep' = {
//     params: {
//       location:    location
//       serviceName: naming.outputs.searchServiceName
//       tags: tags
//       // skuName: 'basic'  (default)
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param serviceName string

@description('Pricing tier: free | basic | standard | standard2 | standard3')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param skuName string = 'basic'

@description('Number of replicas (1 for Free, 1-3 for Basic, 1-12 for Standard+)')
@minValue(1)
param replicaCount int = 1

@description('Number of partitions (1, 2, 3, 4, 6, or 12)')
@allowed([1, 2, 3, 4, 6, 12])
param partitionCount int = 1

@description('Semantic search tier: disabled | free | standard')
@allowed(['disabled', 'free', 'standard'])
param semanticSearch string = 'standard'

@description('Disable local authentication (API keys). Set to true to enforce Entra ID (AAD) authentication only.')
param disableLocalAuth bool = true

@description('Public network access: enabled | disabled')
@allowed(['enabled', 'disabled'])
param publicNetworkAccess string = 'enabled'

@description('Hosting mode: Default | HighDensity (HighDensity is for Standard3 only)')
@allowed(['Default', 'HighDensity'])
param hostingMode string = 'Default'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource searchService 'Microsoft.Search/searchServices@2025-05-01' = {
  name: serviceName
  location: location
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: hostingMode
    // PoC: public access enabled.
    // PRODUCTION: set to 'disabled' and configure a private endpoint.
    publicNetworkAccess: publicNetworkAccess
    semanticSearch: semanticSearch
    // Enforce Entra ID authentication (disable API keys)
    disableLocalAuth: disableLocalAuth
    // Allow access from Azure services
    networkRuleSet: {
      bypass: 'AzureServices'
    }
  }
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output serviceId string = searchService.id
output serviceName string = searchService.name
output endpoint string = 'https://${searchService.name}.search.windows.net'
output principalId string = searchService.identity.principalId
