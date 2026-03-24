// main.bicep — Microsoft Foundry Workshop: Basic Deployment
//
// API versions used in this deployment (update the declarations in each module when upgrading):
//   Microsoft.Search/searchServices                    @2025-05-01  → search.bicep
//   Microsoft.Authorization/roleAssignments            @2022-04-01  → foundry.bicep, rbac.*.bicep
//   Microsoft.CognitiveServices/accounts               @2025-09-01  → foundry.bicep
//   Microsoft.CognitiveServices/accounts/projects      @2025-09-01  → foundry.bicep
//   Microsoft.CognitiveServices/accounts/deployments   @2025-09-01  → foundry.deployments.bicep
//   Microsoft.CognitiveServices/accounts/connections   @2025-09-01  → foundry.bicep
//   Microsoft.OperationalInsights/workspaces           @2025-07-01  → observability.bicep
//   Microsoft.Insights/components                      @2020-02-02  → observability.bicep
//   Microsoft.ContainerRegistry/registries             @2025-11-01  → acr.bicep
//   Microsoft.Storage/storageAccounts                  @2025-01-01  → storage.bicep, rbac.services.bicep, rbac.users.bicep
//   Microsoft.KeyVault/vaults                          @2025-05-01  → keyvault.bicep, keyvault.key.bicep, rbac.cmk.bicep, rbac.users.bicep
//   Microsoft.KeyVault/vaults/keys                     @2025-05-01  → keyvault.key.bicep
//   Microsoft.ManagedIdentity/userAssignedIdentities   @2024-11-30  → identity.cmk.bicep, azuread-mip-mrms.bicep
//
// Note: Bicep does not allow variables in resource type declarations ('Type@version' must be a literal).
// API versions are therefore documented here and kept as literals inside each module file.

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------

import { longName, shortName, alphanumName, simpleName } from './modules/naming.bicep'
import { ModelDeploymentConfig } from './modules/types.bicep'
import { regionAbbreviations } from './modules/regions.bicep'

targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

// --- Deployment ---

@description('Deployment environment')
@allowed(['dev', 'stg', 'poc', 'prd'])
param env string = 'poc'

@description('Project abbreviation (lowercase alphanumeric, 8 characters or less recommended)')
param project string

@description('Display name shown in the Foundry portal')
param foundryProjectDisplayName string

@description('Description of the Foundry project')
param foundryProjectDescription string

@description('Azure region for deployment')
param location string

// Optional tag parameters — omit in bicepparam to leave them unset
@description('Responsible team or owner (e.g., platform-team)')
param owner string?

@description('Cost center or chargeback code (e.g., CC-1234)')
param costCenter string?

@description('Business unit or department (e.g., engineering)')
param businessUnit string?

@description('Business criticality: low | medium | high | critical')
param criticality ('low' | 'medium' | 'high' | 'critical')?

@description('Data classification: public | internal | confidential | restricted')
param dataClassification ('public' | 'internal' | 'confidential' | 'restricted')?

@description('Scheduled decommission date for temporary resources (ISO 8601, e.g., 2026-12-31)')
param expiryDate string?

@description('Entra ID object ID of the deployer user (for Azure AI Owner role on Foundry Account)')
param deployerObjectId string = ''

@description('Entra ID object ID of the AI Developer group (pass empty string to skip)')
param aiDeveloperGroupId string = ''

@description('Entra ID object ID of the AI User group for read-only access (pass empty string to skip)')
param aiUserGroupId string = ''

// --- Observability ---

@description('''
How to provision observability resources:
  true  (default) → Creates new Log Analytics and Application Insights.
                     Suitable for self-contained environments such as PoC, dev, and stg.
  false           → References existing shared monitoring resources.
                     Use this for production when connecting to a central Log Analytics
                     managed by the platform team, and provide the two IDs below.
''')
param createObservability bool = true

@description('Resource ID of existing Log Analytics workspace (required when createObservability=false)')
param existingLogWorkspaceId string = ''

@description('Resource ID of existing Application Insights (required when createObservability=false)')
param existingAppInsightsId string = ''

// --- Foundry Models ---

@description('List of models to deploy to Foundry (provisioned sequentially in array order)')
param modelDeployments ModelDeploymentConfig[] = []

// --- AI Search ---

@description('''
Whether to deploy Azure AI Search:
  true  → Creates an AI Search service and configures connections and RBAC.
  false (default) → Skips AI Search creation and all dependent resources (connections, RBAC).
''')
param enableAiSearch bool = false

// --- Soft-deleted resource restore ---

@description('''
Whether to restore a soft-deleted Key Vault with the same name:
  false (default) → Create a new Key Vault.
  true            → Recover the soft-deleted Key Vault with the same name.
                    Specifying true for a purged or non-existent resource will result in an error.
''')
param keyvaultRestore bool = false

@description('''
Whether to restore a soft-deleted Cognitive Services (Foundry Account) with the same name:
  false (default) → Create a new account.
  true            → Recover the soft-deleted account with the same name.
                    Specifying true for a purged or non-existent resource will result in an error.
''')
param foundryRestore bool = false

// --- CMK ---

@description('''
Whether to enable Customer Managed Key (CMK) encryption:
  true  → Creates Key Vault, encryption key, and user-assigned managed identity,
          then encrypts target resources (Foundry Account, ACR) with CMK.
  false (default) → Uses default encryption with Microsoft-managed keys.
''')
param enableCmk bool = false

@description('''
Whether to enable automatic key rotation for CMK (only effective when enableCmk=true):
  true  (default) → Enables Key Vault automatic key rotation, and each service
                    automatically uses the latest key version.
  false           → Pins to a specific key version.
                    Use this when manually rotating keys.
''')
param enableCmkAutoRotation bool = true

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// Region abbreviation — safe-dereference + coalesce for any region not in the map
var regionAbbr = regionAbbreviations[?location] ?? take(location, 4)

// Multi-seed hash: encodes project/env/region → deterministic and collision-resistant across environments
var nameHash = uniqueString(resourceGroup().id, project, env, regionAbbr)

// All resource names in one place — update here only when naming rules change
//
// Naming function selection:
//   longName      → DNS-globally unique required  (hash suffix appended)
//   alphanumName  → DNS-globally unique, no hyphens allowed
//   simpleName    → Scope-unique only (resource group or parent resource); no hash needed
var names = {
  search:            longName('srch', project, env, regionAbbr, nameHash)     // globally unique DNS; max 60 chars, hyphens OK
  foundryAccount:    longName('cogacct', project, env, regionAbbr, nameHash)  // globally unique DNS (customSubDomainName); max 64 chars
  foundryProject:    simpleName('proj', project, env, regionAbbr)             // scoped within Foundry account; max 32 chars — 'proj-<project>-<env>-<regionAbbr>' (19 chars or less recommended for project)
  containerRegistry: alphanumName('cr', project, env, nameHash)               // globally unique DNS; max 50 chars, alphanumeric only (no hyphens)
  logAnalytics:      longName('log', project, env, regionAbbr, nameHash)      // scoped within resource group; max 63 chars — longName used for consistency
  appInsights:       longName('appi', project, env, regionAbbr, nameHash)     // Application Insights component; max 260 chars — longName used for consistency
  vault:             shortName('kv', project, env, nameHash)                  // globally unique DNS; max 24 chars (KV limit) — shortName omits region to stay within limit
  storage:           alphanumName('st', project, env, nameHash)               // globally unique DNS; max 24 chars, alphanumeric only (no hyphens)
  cmkIdentity:       longName('uami-cmk', project, env, regionAbbr, nameHash) // User-assigned managed identity for CMK encryption
  cmkKey:            simpleName('cmk', project, env, regionAbbr)              // CMK key name in Key Vault (unique within Key Vault scope)
}

// Build a clean string-only tags object — union() merges non-null optional tags,
// omitting keys whose values are null so ARM never receives a null tag value.
var tags = union(
  {
    project: project
    env: env
    managedBy: 'bicep'
  },
  owner != null ? { owner: owner! } : {},
  costCenter != null ? { costCenter: costCenter! } : {},
  businessUnit != null ? { businessUnit: businessUnit! } : {},
  criticality != null ? { criticality: criticality! } : {},
  dataClassification != null ? { dataClassification: dataClassification! } : {},
  expiryDate != null ? { expiryDate: expiryDate! } : {}
)

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// --- Observability ---

module observability 'modules/observability.bicep' = {
  params: {
    location: location
    tags: tags
    logWorkspaceName: names.logAnalytics
    appInsightsName: names.appInsights
    createNew: createObservability
    existingLogWorkspaceId: existingLogWorkspaceId
    existingAppInsightsId: existingAppInsightsId
  }
}

// --- AI Search ---

module search 'modules/search.bicep' = if (enableAiSearch) {
  params: {
    location: location
    tags: tags
    serviceName: names.search
  }
}

// --- Key Vault & CMK ---

// Key Vault is created only when CMK is enabled.
// CMK requires Key Vault for encryption key storage and crypto operations.
// When CMK is disabled, no customer-managed Key Vault is needed — Connection secrets
// are stored in Microsoft-managed internal storage, not in customer Key Vault.
module keyVault 'modules/keyvault.bicep' = if (enableCmk) {
  params: {
    location: location
    tags: tags
    vaultName: names.vault
    // CMK requires purge protection to prevent permanent loss of encryption keys
    enablePurgeProtection: true
    restore: keyvaultRestore
  }
}

// User Assigned Managed Identity — Shared identity used for CMK encryption
module cmkIdentity 'modules/identity.cmk.bicep' = if (enableCmk) {
  params: {
    location: location
    tags: tags
    identityName: names.cmkIdentity
  }
}

// Key Vault Key — CMK encryption key
module cmkKey 'modules/keyvault.key.bicep' = if (enableCmk) {
  params: {
    tags: tags
    keyVaultName: keyVault!.outputs.vaultName
    keyName: names.cmkKey
    enableRotation: enableCmkAutoRotation
  }
}

// RBAC: CMK Identity → Key Vault (Key Vault Crypto User)
module rbacCmk 'modules/rbac.cmk.bicep' = if (enableCmk) {
  params: {
    keyVaultName: keyVault!.outputs.vaultName
    identityPrincipalId: cmkIdentity!.outputs.principalId
  }
}

// --- Foundry ---

module foundry 'modules/foundry.bicep' = {
  params: {
    location: location
    tags: tags
    accountName: names.foundryAccount
    projectName: names.foundryProject
    projectDisplayName: foundryProjectDisplayName
    projectDescription: foundryProjectDescription
    enableAiSearch: enableAiSearch
    searchServiceName: enableAiSearch ? search!.outputs.serviceName : ''
    searchServiceId: enableAiSearch ? search!.outputs.serviceId : ''
    appInsightsConnectionString: observability.outputs.appInsightsConnectionString
    restore: foundryRestore
    // CMK parameters (only set when CMK is enabled)
    enableCmk: enableCmk
    userAssignedIdentityId: enableCmk ? cmkIdentity!.outputs.identityId : ''
    userAssignedIdentityClientId: enableCmk ? cmkIdentity!.outputs.clientId : ''
    keyVaultBaseUri: enableCmk ? cmkKey!.outputs.keyVaultBaseUri : ''
    cmkKeyName: enableCmk ? cmkKey!.outputs.keyName : ''
    // The AIServices 2025-09-01 API does not accept an empty string for keyVersion.
    // Always pass the concrete key version resolved at deploy time.
    // The Key Vault rotation policy continues to function, but adopting a new version
    // requires a redeployment.
    cmkKeyVersion: enableCmk ? cmkKey!.outputs.keyVersion : ''
  }
  dependsOn: enableCmk ? [rbacCmk] : []
}

// Foundry model deployments — sequential, driven by modelDeployments param
module foundryDeployments 'modules/foundry.deployments.bicep' = {
  params: {
    accountName: foundry.outputs.accountName
    modelDeployments: modelDeployments
  }
}

// --- Container Registry ---

module acr 'modules/acr.bicep' = {
  params: {
    location: location
    registryName: names.containerRegistry
    tags: tags
    // CMK parameters (only set when CMK is enabled)
    enableCmk: enableCmk
    userAssignedIdentityId: enableCmk ? cmkIdentity!.outputs.identityId : ''
    userAssignedIdentityClientId: enableCmk ? cmkIdentity!.outputs.clientId : ''
    // Auto-rotation: use versionless URI; Fixed: use versioned URI
    keyVaultKeyUri: enableCmk ? (enableCmkAutoRotation ? cmkKey!.outputs.keyUri : cmkKey!.outputs.keyUriWithVersion) : ''
  }
  dependsOn: enableCmk ? [rbacCmk] : []
}

// --- Storage ---

module storage 'modules/storage.bicep' = {
  params: {
    location: location
    tags: tags
    storageAccountName: names.storage
  }
}

// --- RBAC ---

// Service-to-service RBAC (Foundry ↔ AI Search, ACR, Storage)
module rbacServices 'modules/rbac.services.bicep' = {
  params: {
    foundryAccountName:        foundry.outputs.accountName
    foundryAccountPrincipalId: foundry.outputs.principalId
    foundryProjectPrincipalId: foundry.outputs.foundryProjectPrincipalId
    enableAiSearch:            enableAiSearch
    searchServiceName:         enableAiSearch ? search!.outputs.serviceName : ''
    searchPrincipalId:         enableAiSearch ? search!.outputs.principalId : ''
    containerRegistryName:     acr.outputs.registryName
    blobStorageAccountName:    storage.outputs.storageAccountName
  }
}

// User/group RBAC (Deployer, Developer Group, User Group)
module rbacUsers 'modules/rbac.users.bicep' = {
  params: {
    foundryAccountName:     foundry.outputs.accountName
    foundryProjectName:     foundry.outputs.projectName
    searchServiceName:      enableAiSearch ? search!.outputs.serviceName : ''
    blobStorageAccountName: storage.outputs.storageAccountName
    keyVaultName:           enableCmk ? keyVault!.outputs.vaultName : ''
    deployerObjectId:       deployerObjectId
    aiDeveloperGroupId:     aiDeveloperGroupId
    aiUserGroupId:          aiUserGroupId
  }
}

// ---------------------------------------------------------------------------
// Extension Modules (Available for network isolation scenarios)
// ---------------------------------------------------------------------------
// The following modules are not directly included in this template,
// but can be used when extending to a private network configuration.
// Use in combination with the NetworkIsolationMode
// in types.bicep ('public' | 'hybrid' | 'private').
//
//   modules/vnet.bicep              — VNet + Private Endpoint subnet
//   modules/private-endpoint.bicep  — Private Endpoint for each resource
//   modules/private-dns-zone.bicep  — Private DNS Zone + VNet link
//   modules/azuread-mip-mrms.bicep  — MIP / MRMS app role assignments for AI Search

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

// Foundry Endpoint (OpenAI-compatible: {foundryEndpoint}/openai/...)
output foundryEndpoint string = foundry.outputs.endpoint
output searchEndpoint string = enableAiSearch ? search!.outputs.endpoint : ''
output registryLoginServer string = acr.outputs.registryLoginServer
output storageAccountName string = storage.outputs.storageAccountName
output appInsightsConnectionString string = observability.outputs.appInsightsConnectionString
output logAnalyticsId string = observability.outputs.logAnalyticsId
output keyVaultName string = enableCmk ? keyVault!.outputs.vaultName : ''
output keyVaultUri string = enableCmk ? keyVault!.outputs.vaultUri : ''
