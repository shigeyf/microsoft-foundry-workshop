// foundry.bicep
// Azure AI Foundry account and project.
//
// Description:
//   Creates an AIServices account (kind: AIServices) as the Foundry hub and a Foundry project
//   nested under the account.
//
//   Account-level connections (BYO Key Vault, AI Search, Application Insights) are managed
//   separately in foundry.connections.bicep, which is deployed AFTER RBAC assignments.
//
//   RBAC Management:
//     - Parent-child RBAC (Foundry Project → Foundry Account) is managed in this module
//     - Service-to-service RBAC is managed in rbac.services.bicep
//     - User access RBAC is managed in rbac.users.bicep
//
//   Model deployments are managed separately in foundry.deployments.bicep.
//
// Resources:
//   Microsoft.CognitiveServices/accounts@2025-09-01
//   Microsoft.CognitiveServices/accounts/projects@2025-09-01
//   Microsoft.Authorization/roleAssignments@2022-04-01
//
// Usage:
//   module foundry 'modules/foundry.bicep' = {
//     params: {
//       location:                    location
//       accountName:                 naming.outputs.foundryAccountName
//       projectName:                 naming.outputs.foundryProjectName
//       appInsightsConnectionString: observability.outputs.appInsightsConnectionString
//       tags:                        tags
//     }
//   }

import { roleIds } from './roleDefinitions.bicep'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param accountName string
param projectName string

@description('Display name shown in the Foundry portal')
param projectDisplayName string

@description('Human-readable description of the Foundry project')
param projectDescription string

@description('Disable local authentication (API keys). Set to true to enforce Entra ID authentication only.')
param disableLocalAuth bool = true

@description('''
When restoring a soft-deleted Foundry account with the same name, set to true.
Setting this to true for a non-soft-deleted or already purged account will result
in a CanNotRestoreANonExistingResource error.
''')
param restore bool = false

@description('Public network access: Enabled | Disabled. Set to Disabled and configure private endpoint for production.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

// --- Application Insights (for Foundry Project telemetry) ---
@secure()
@description('Application Insights connection string for Foundry Agent tracing and telemetry. Forwarded to the Foundry project for agent trace/telemetry.')
param appInsightsConnectionString string = ''

// --- CMK (Customer Managed Key) Parameters ---
@description('Enable Customer Managed Key (CMK) encryption. When true, CMK-related parameters are required.')
param enableCmk bool = false

@description('Resource ID of the User Assigned Managed Identity for CMK encryption. Required when enableCmk is true.')
param userAssignedIdentityId string = ''

@description('Client ID of the User Assigned Managed Identity for CMK encryption. Required when enableCmk is true.')
param userAssignedIdentityClientId string = ''

@description('Key Vault base URI (e.g., https://vault.vault.azure.net/). Required when enableCmk is true.')
param keyVaultBaseUri string = ''

@description('CMK key name in Key Vault. Required when enableCmk is true.')
param cmkKeyName string = ''

@description('CMK key version. Empty string enables auto-rotation; specific version pins to that version.')
param cmkKeyVersion string = ''

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// --- Foundry Resources (AIServices Account) ---
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' = {
  name: accountName
  location: location
  kind: 'AIServices'
  sku: {
    // S0 is the only supported SKU for AIServices/Foundry accounts; this value is not configurable.
    name: 'S0'
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
    customSubDomainName: accountName

    // PoC: public access enabled for ease of development.
    // PRODUCTION: set to 'Disabled' and configure a private endpoint.
    publicNetworkAccess: publicNetworkAccess

    // Enables Foundry project management
    allowProjectManagement: true

    // Managed Identity-first: local auth disabled to enforce Entra ID authentication only.
    // Developers authenticate via 'az login'; the Container App uses its system-assigned managed identity.
    disableLocalAuth: disableLocalAuth

    // Network ACL configuration
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
      bypass: 'AzureServices'
    }

    // Restore from soft-deleted account if specified.
    // The account must be in a soft-deleted state and have the same name.
    restore: restore

    // Customer Managed Key (CMK) encryption configuration
    // Note: Updating encryption mode from CMK to Microsoft-managed keys is not supported
    // when allowProjectManagement is true. Use CMK with user assigned identity only.
    //
    // Auto-rotation: Set cmkKeyVersion to empty string ('') to enable automatic key rotation.
    // When keyVersion is empty, Cognitive Services automatically uses the latest key version.
    encryption: enableCmk ? {
      keySource: 'Microsoft.KeyVault'
      keyVaultProperties: {
        keyVaultUri: keyVaultBaseUri
        keyName: cmkKeyName
        keyVersion: cmkKeyVersion  // Empty string = auto-rotation enabled
        identityClientId: userAssignedIdentityClientId
      }
    } : null
  }
  tags: tags
}

// --- Foundry project ---
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-09-01' = {
  parent: foundryAccount
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectDisplayName
    description: projectDescription
    // Connecting Application Insights enables Foundry Agent trace and metric data
    // to be forwarded to Azure Monitor and Application Insights.
    // PRODUCTION: pass the connection string of the shared monitoring platform.
    // BCP037: property not yet reflected in the ARM type definition but is supported at runtime.
    #disable-next-line BCP037
    applicationInsightsConnectionString: appInsightsConnectionString
  }
  tags: tags
}

// --- Parent-Child RBAC (kept in this module due to tight coupling) ---
// External RBAC assignments are managed in rbac.service.bicep

// RBAC: Foundry Project MI → Foundry Account (Cognitive Services User)
// The Hosted Agent container runs as the Foundry Project MI. This grants it permission
// to call GPT-4.1 and text-embedding-3-small via DefaultAzureCredential inside @ai_function tools.
resource foundryProjectToFoundryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryAccount.id, foundryProject.id, roleIds.cognitiveServicesUser)
  scope: foundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.cognitiveServicesUser)
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output accountId string = foundryAccount.id
output accountName string = foundryAccount.name
output projectName string = foundryProject.name
output foundryProjectPrincipalId string = foundryProject.identity.principalId
output endpoint string = foundryAccount.properties.endpoint
output principalId string = foundryAccount.identity.principalId
