// rbac.cmk.bicep
// Key Vault RBAC assignments for CMK (Customer Managed Key) encryption.
//
// Description:
//   Grants the CMK User Assigned Managed Identity the required Key Vault role
//   to use the encryption key. This role assignment is required before
//   Cognitive Services or other Azure resources can use the CMK for encryption.
//
//   Reference:
//     https://learn.microsoft.com/en-us/azure/ai-services/encryption/cognitive-services-encryption-keys-portal
//     > If you're using Azure RBAC, assign Key Vault Crypto Service Encryption User role
//     > to the managed identity.
//
//   This module is part of the 3-file RBAC structure:
//     - rbac.services.bicep: Service-to-service RBAC
//     - rbac.cmk.bicep: CMK encryption RBAC (this file)
//     - rbac.users.bicep: User/group RBAC
//
// Resources:
//   Microsoft.Authorization/roleAssignments@2022-04-01
//
// Usage:
//   module rbacCmk 'modules/rbac.cmk.bicep' = if (enableCmk) {
//     params: {
//       keyVaultName:        keyVault.outputs.vaultName
//       identityPrincipalId: identity.outputs.principalId
//     }
//   }

import { roleIds } from './roleDefinitions.bicep'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param keyVaultName string

@description('Principal ID of the User Assigned Managed Identity that will use the CMK')
param identityPrincipalId string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

// RBAC: UAMI → Key Vault (Key Vault Crypto Service Encryption User)
// Required for service-side encryption scenarios where the identity needs to perform
// wrap/unwrap operations on behalf of Azure services (e.g., Cognitive Services CMK).
// This is the only role required per official documentation.
resource cryptoServiceEncryptionRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, identityPrincipalId, roleIds.kvCryptoServiceEncryption)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.kvCryptoServiceEncryption)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
