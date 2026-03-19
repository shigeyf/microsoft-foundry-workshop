// identity.cmk.bicep
// User Assigned Managed Identity for CMK (Customer Managed Key) encryption.
//
// Description:
//   Creates a shared User Assigned Managed Identity (UAMI) for CMK encryption.
//   This identity is granted Key Vault Crypto roles via rbac.cmk.bicep and is
//   then assigned to Azure resources (Cognitive Services, ACR, Storage, etc.) that
//   require CMK encryption.
//
// Best Practices:
//   - Shared UAMI: Using a single shared UAMI for all CMK-encrypted resources is
//     recommended by Microsoft, as they require identical Key Vault permissions
//     (Key Vault Crypto Service Encryption User). This simplifies RBAC management
//     and reduces operational overhead.
//
// Resources:
//   Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31
//
// Usage:
//   module identity 'modules/identity.cmk.bicep' = if (enableCmk) {
//     params: {
//       location:     location
//       identityName: names.cmkIdentity
//       tags:         tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param identityName string

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: identityName
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output identityId string = userAssignedIdentity.id
output identityName string = userAssignedIdentity.name
output principalId string = userAssignedIdentity.properties.principalId
output clientId string = userAssignedIdentity.properties.clientId
output tenantId string = userAssignedIdentity.properties.tenantId
