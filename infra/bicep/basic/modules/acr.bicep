// acr.bicep
// Azure Container Registry with system-assigned managed identity and optional CMK encryption.
//
// Description:
//   Provisions an Azure Container Registry (ACR) for storing container images.
//   Used by both the Hosted Agent (Foundry Project MI pulls images) and the
//   Container App gateway (Container App MI pulls images via containerapps.bicep RBAC).
//   This module is always deployed, independently of deployContainerAppGateway,
//   because ACR is a prerequisite for Hosted Agent image management.
//
//   CMK (Customer Managed Key) encryption is supported with Premium SKU only.
//   When enableCmk is true, SKU is automatically upgraded to Premium.
//
// Resources:
//   Microsoft.ContainerRegistry/registries@2025-11-01
//
// Usage:
//   module acr 'modules/acr.bicep' = {
//     params: {
//       location:     location
//       registryName: names.containerRegistry
//       tags:         tags
//     }
//   }
//
//   // Example with CMK enabled:
//   module acr 'modules/acr.bicep' = {
//     params: {
//       location:                    location
//       registryName:                names.containerRegistry
//       tags:                        tags
//       enableCmk:                   true
//       userAssignedIdentityId:      identity.outputs.identityId
//       userAssignedIdentityClientId: identity.outputs.clientId
//       keyVaultKeyUri:              keyVaultKey.outputs.keyUri
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param registryName string

@description('The SKU of the Azure Container Registry: Basic | Standard | Premium. Automatically upgraded to Premium when enableCmk is true.')
@allowed(['Basic', 'Standard', 'Premium'])
param skuName string = 'Basic'

@description('Enable admin user for legacy authentication. Set to false and use managed identity for production.')
param adminUserEnabled bool = false

@description('Public network access: Enabled | Disabled. Set to Disabled and configure private endpoint for production.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

// --- CMK (Customer Managed Key) Parameters ---
@description('Enable Customer Managed Key (CMK) encryption. When true, userAssignedIdentityId and keyVaultKeyUri are required. Premium SKU is enforced.')
param enableCmk bool = false

@description('Resource ID of the User Assigned Managed Identity for CMK encryption. Required when enableCmk is true.')
param userAssignedIdentityId string = ''

@description('Client ID of the User Assigned Managed Identity for CMK encryption. Required when enableCmk is true.')
param userAssignedIdentityClientId string = ''

@description('''
Key Vault Key URI for CMK encryption. Required when enableCmk is true.
- For auto-rotation: Use versionless URI (e.g., https://vault.vault.azure.net/keys/keyName)
- For fixed version: Use versioned URI (e.g., https://vault.vault.azure.net/keys/keyName/version)
''')
param keyVaultKeyUri string = ''

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// CMK requires Premium SKU — automatically upgrade if CMK is enabled
var effectiveSkuName = enableCmk ? 'Premium' : skuName

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: registryName
  location: location
  sku: {
    // Basic SKU is sufficient for PoC (single region, no geo-replication, no content trust).
    // PRODUCTION: upgrade to Standard (geo-replication) or Premium (private link, content trust, retention policies).
    // CMK encryption requires Premium SKU.
    name: effectiveSkuName
  }
  identity: enableCmk ? {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  } : {
    type: 'SystemAssigned'
  }
  properties: {
    // Admin disabled; authentication via system-assigned managed identity.
    // PoC may set to true (same as Terraform).
    adminUserEnabled: adminUserEnabled
    // PoC: public access enabled.
    // PRODUCTION: set to 'Disabled' and configure a private endpoint for registry pull traffic.
    publicNetworkAccess: publicNetworkAccess

    // Customer Managed Key (CMK) encryption configuration.
    // By default, ACR encrypts data at rest using Microsoft-managed keys.
    // Set the encryption property only when using CMK.
    //
    // Auto-rotation: Use versionless keyIdentifier (keyUri) to enable automatic key rotation.
    // Fixed version: Use versioned keyIdentifier (keyUriWithVersion) to pin to a specific key version.
    encryption: enableCmk ? {
      status: 'enabled'
      keyVaultProperties: {
        keyIdentifier: keyVaultKeyUri
        identity: userAssignedIdentityClientId
      }
    } : null
  }
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output registryLoginServer string = registry.properties.loginServer
output registryName string = registry.name
output registryId string = registry.id
output registryPrincipalId string = registry.identity.principalId
