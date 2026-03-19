// keyvault-key.bicep
// Customer Managed Key (CMK) for encryption of Azure resources.
//
// Description:
//   Creates an RSA or EC key in Azure Key Vault for use as a Customer Managed Key (CMK).
//   The key is configured with encryption-related operations and optional rotation policy.
//   Used by Cognitive Services accounts, ACR, and other resources requiring CMK encryption.
//
// Best Practices:
//   - Shared CMK Key: The current implementation shares a single CMK key across multiple
//     services (Foundry Account, ACR). This approach is appropriate for PoC and development
//     environments. For production environments, consider separating keys based on data
//     classification or compliance requirements to reduce blast radius in case of key compromise.
//
//   - Auto-Rotation: When enableRotation=true (default), Azure automatically rotates the key
//     based on the configured rotation policy. Services must be configured to follow the
//     latest key version:
//       * Cognitive Services: Set keyVersion='' (empty string)
//       * ACR: Use versionless keyUri (without version suffix)
//     When enableRotation=false, services are pinned to the specific key version deployed.
//
// Outputs:
//   - keyUri: Versionless key URI (for auto-rotation scenarios)
//   - keyUriWithVersion: Versioned key URI (for fixed version scenarios)
//   - keyVaultBaseUri: Key Vault base URI (for Cognitive Services encryption)
//   - keyVersion: Current key version
//
// Resources:
//   Microsoft.KeyVault/vaults/keys@2023-07-01
//
// Usage:
//   module cmk 'modules/keyvault-key.bicep' = if (enableCmk) {
//     params: {
//       keyVaultName: keyVault.outputs.vaultName
//       keyName:      'cmk-${names.foundryAccount}'
//       tags:         tags
//       enableRotation: true  // Enable auto-rotation (default)
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param tags object
param keyVaultName string
param keyName string

@description('Key type: RSA | EC | RSA-HSM | EC-HSM')
@allowed(['RSA', 'EC', 'RSA-HSM', 'EC-HSM'])
param keyType string = 'RSA'

@description('Key size in bits (for RSA keys): 2048 | 3072 | 4096')
@allowed([2048, 3072, 4096])
param keySize int = 4096

@description('Elliptic curve name (for EC keys): P-256 | P-384 | P-521 | P-256K')
@allowed(['P-256', 'P-384', 'P-521', 'P-256K'])
param curveName string = 'P-256'

@description('Key expiration date in ISO 8601 format. Pass empty string for no expiration.')
param expirationDate string = ''

@description('Enable automatic key rotation')
param enableRotation bool = true

@description('Time before expiry to trigger rotation (ISO 8601 duration, e.g., P30D)')
param rotationTimeBeforeExpiry string = 'P30D'

@description('Key expiration period (ISO 8601 duration, e.g., P180D)')
param expirationPeriod string = 'P180D'

@description('Time before expiry to notify (ISO 8601 duration, e.g., P29D)')
param notifyBeforeExpiry string = 'P29D'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

// Create the encryption key
resource key 'Microsoft.KeyVault/vaults/keys@2025-05-01' = {
  parent: keyVault
  name: keyName
  properties: {
    kty: keyType
    keySize: keyType == 'RSA' || keyType == 'RSA-HSM' ? keySize : null
    curveName: keyType == 'EC' || keyType == 'EC-HSM' ? curveName : null
    keyOps: [
      'decrypt'
      'encrypt'
      'sign'
      'unwrapKey'
      'verify'
      'wrapKey'
    ]
    attributes: {
      enabled: true
      exp: expirationDate != '' ? dateTimeToEpoch(expirationDate) : null
    }
    rotationPolicy: enableRotation ? {
      attributes: {
        expiryTime: expirationPeriod
      }
      lifetimeActions: [
        {
          action: {
            type: 'Rotate'
          }
          trigger: {
            timeBeforeExpiry: rotationTimeBeforeExpiry
          }
        }
        {
          action: {
            type: 'Notify'
          }
          trigger: {
            timeBeforeExpiry: notifyBeforeExpiry
          }
        }
      ]
    } : null
  }
  tags: tags
}

// Extract key version from the versioned URI
// Format: https://{vault}.vault.azure.net/keys/{keyName}/{version}
var keyVersionFromUri = last(split(key.properties.keyUriWithVersion, '/'))

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output keyId string = key.id
output keyName string = key.name
output keyUri string = key.properties.keyUri
output keyUriWithVersion string = key.properties.keyUriWithVersion
// Key Vault base URI (without /keys/... path) for Cognitive Services encryption
output keyVaultBaseUri string = keyVault.properties.vaultUri
// Current key version (use empty string for auto-rotation in services that support keyVersion param)
output keyVersion string = keyVersionFromUri
// Whether auto-rotation is enabled for this key
output enableRotation bool = enableRotation
