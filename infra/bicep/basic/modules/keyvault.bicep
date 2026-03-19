// keyvault.bicep
// Azure Key Vault for secure secret storage with RBAC authorization mode.
//
// Description:
//   Creates a Key Vault in RBAC authorization mode.
//   This module creates the Key Vault resource only. RBAC assignments are managed externally:
//     - User access: rbac.users.bicep
//     - CMK access: rbac.cmk.bicep
//
// Resources:
//   Microsoft.KeyVault/vaults@2025-05-01
//
// Usage:
//   module keyVault 'modules/keyvault.bicep' = {
//     params: {
//       location:  location
//       vaultName: naming.outputs.vaultName
//       tags:      tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param vaultName string

@description('Key Vault SKU: standard | premium (premium adds HSM-backed keys)')
@allowed(['standard', 'premium'])
param kvSkuName string = 'standard'

@description('Soft-delete retention in days (7-90). Use the minimum for non-production environments.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 7

@description('Enable purge protection to prevent permanent deletion. Required for production and CMK scenarios.')
param enablePurgeProtection bool = false

@description('Allow VM deployments to retrieve secrets from the vault.')
param enabledForDeployment bool = false

@description('Allow Azure Disk Encryption to retrieve secrets from the vault.')
param enabledForDiskEncryption bool = false

@description('Allow Bicep/ARM template deployments to read secrets directly during deployment.')
param enabledForTemplateDeployment bool = false

@description('Public network access: Enabled | Disabled. Set to Disabled and configure private endpoint for production.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

@description('Whether to restore a soft-deleted Key Vault with the same name. false = create new, true = recover soft-deleted. Specifying true for a purged or non-existent resource will result in an error.')
param restore bool = false

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: vaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: kvSkuName
    }
    tenantId: subscription().tenantId
    createMode: restore ? 'recover' : 'default'

    // RBAC mode; role assignments are managed in keyvault-access.bicep
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays

    // Enable purge protection for production and CMK scenarios to prevent permanent deletion
    enablePurgeProtection: enablePurgeProtection ? true : null
    // Allow VM deployments to retrieve secrets from the vault
    enabledForDeployment: enabledForDeployment
    // Allow Azure Disk Encryption to retrieve secrets from the vault
    enabledForDiskEncryption: enabledForDiskEncryption
    // Allow Bicep/ARM template deployments to read secrets directly during deployment.
    // PRODUCTION: set to false if deployments no longer need direct secret retrieval from this vault.
    enabledForTemplateDeployment: enabledForTemplateDeployment

    // PoC: public access enabled.
    // PRODUCTION: set to 'Disabled' and add a private endpoint to prevent internet-facing exposure.
    publicNetworkAccess: publicNetworkAccess
  }
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output vaultName string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
output vaultId string = keyVault.id
