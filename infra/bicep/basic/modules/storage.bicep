// storage.bicep
// Azure Storage Account for Foundry workspace storage.
//
// Description:
//   Provisions an Azure Storage Account for storing data used by Foundry resources.
//   Configured with security best practices: shared access key disabled,
//   nested public access disabled.
//
// Resources:
//   Microsoft.Storage/storageAccounts@2023-05-01
//
// Usage:
//   module storage 'modules/storage.bicep' = {
//     params: {
//       location:           location
//       storageAccountName: names.storage
//       tags:               tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param storageAccountName string

@description('Storage account kind: StorageV2 | BlobStorage | BlockBlobStorage | FileStorage')
@allowed(['StorageV2', 'BlobStorage', 'BlockBlobStorage', 'FileStorage'])
param accountKind string = 'StorageV2'

@description('Storage account tier: Standard | Premium')
@allowed(['Standard', 'Premium'])
param accountTier string = 'Standard'

@description('Replication type: LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS')
@allowed(['LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', 'RAGZRS'])
param replicationType string = 'LRS'

@description('Enable shared key access. Set to false for Entra ID authentication only.')
param allowSharedKeyAccess bool = false

@description('Allow nested public access to blobs. Set to false for production.')
param allowBlobPublicAccess bool = false

@description('Public network access: Enabled | Disabled. Set to Disabled and configure private endpoint for production.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

@description('Minimum TLS version')
@allowed(['TLS1_0', 'TLS1_1', 'TLS1_2'])
param minimumTlsVersion string = 'TLS1_2'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  kind: accountKind
  sku: {
    name: '${accountTier}_${replicationType}'
  }
  properties: {
    // Disable shared key access to enforce Entra ID authentication
    allowSharedKeyAccess: allowSharedKeyAccess
    // Disable public access to nested items (blobs)
    allowBlobPublicAccess: allowBlobPublicAccess
    // PoC: public access enabled.
    // PRODUCTION: set to 'Disabled' and configure a private endpoint.
    publicNetworkAccess: publicNetworkAccess
    // Enforce TLS 1.2 minimum
    minimumTlsVersion: minimumTlsVersion
    // Enable secure transfer (HTTPS only)
    supportsHttpsTrafficOnly: true
    // Enable infrastructure encryption for double encryption at rest
    // requireInfrastructureEncryption: Microsoft-managed key double encryption (AES-256 at rest)
    encryption: {
      requireInfrastructureEncryption: true
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
