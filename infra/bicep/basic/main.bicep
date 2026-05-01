// main.bicep — Microsoft Foundry Workshop: Basic Deployment
//
// API versions used in this deployment (update the declarations in each module when upgrading):
//   Microsoft.Authorization/roleAssignments                        @2022-04-01  → foundry.bicep, rbac.*.bicep
//   Microsoft.CognitiveServices/accounts                           @2025-09-01  → foundry.bicep
//   Microsoft.CognitiveServices/accounts/projects                  @2025-09-01  → foundry.bicep
//   Microsoft.CognitiveServices/accounts/deployments               @2025-09-01  → foundry.deployments.bicep
//   Microsoft.CognitiveServices/accounts/connections               @2025-09-01  → foundry.connections.bicep
//   Microsoft.CognitiveServices/accounts/capabilityHosts           @2025-10-01-preview → foundry.capabilityhost.bicep
//   Microsoft.CognitiveServices/accounts/projects/connections      @2025-09-01         → foundry.project.connections.bicep
//   Microsoft.CognitiveServices/accounts/projects/capabilityHosts  @2025-10-01-preview → foundry.project.capabilityhost.bicep
//
//   Microsoft.Storage/storageAccounts                              @2025-01-01  → storage.bicep, rbac.services.bicep, rbac.users.bicep
//   Microsoft.ContainerRegistry/registries                         @2025-11-01  → acr.bicep
//   Microsoft.OperationalInsights/workspaces                       @2025-07-01  → observability.bicep
//   Microsoft.Insights/components                                  @2020-02-02  → observability.bicep
//   Microsoft.Search/searchServices                                @2025-05-01  → search.bicep
//   Microsoft.KeyVault/vaults                                      @2025-05-01  → keyvault.bicep, keyvault.key.bicep, rbac.cmk.bicep, rbac.users.bicep
//   Microsoft.KeyVault/vaults/keys                                 @2025-05-01  → keyvault.key.bicep
//   Microsoft.ManagedIdentity/userAssignedIdentities               @2024-11-30  → identity.cmk.bicep, azuread-mip-mrms.bicep
//
//   Microsoft.Storage/storageAccounts                              @2025-01-01  → storage.bicep, rbac.services.bicep, rbac.users.bicep
//   Microsoft.Search/searchServices                                @2025-05-01  → search.bicep
//   Microsoft.DocumentDB/databaseAccounts                          @2024-11-15  → cosmos.bicep, rbac.services.bicep
//   Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments       @2024-11-15  → rbac.services.bicep, rbac.cosmos.project.bicep
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

// --- Foundry Models ---

@description('List of models to deploy to Foundry (provisioned sequentially in array order)')
param modelDeployments ModelDeploymentConfig[] = []

// --- BYO Key Vault ---

@description('''
Whether to create a BYO Key Vault connection on the Foundry Account:
  true  → Creates a Key Vault (shared with CMK if both are enabled) and an AzureKeyVault
          connection on the Foundry Account (authType: AccountManagedIdentity).
          Use this when Foundry should store connection secrets in a customer-managed Key Vault.
  false (default) → No Key Vault connection is created.
''')
param enableByoKeyVault bool = false

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

// --- Standard Setup (Hosted Agent BYO Resources) ---

@description('''
Whether to enable Standard Setup for Foundry Hosted Agents (enable_standard_setup):
  true  → Creates BYO resources dedicated to agent hosting (separate from RAG resources):
            - BYO Storage Account      (agent file storage)
            - BYO AI Search service    (agent vector store)
            - Azure Cosmos DB account  (agent session/thread storage)
          Also provisions:
            - Account-level Capability Host
            - Project-level connections (Storage, AI Search, Cosmos DB)
            - Project-level Capability Host
            - Service-to-service RBAC for the above BYO resources
  false (default) → No Standard Setup resources are provisioned.
''')
param enableStandardSetup bool = false

// --- Observability ---

@description('''
Master switch for Application Insights observability:
  true  → Creates (or references when createObservability=false) an Application Insights component
          and adds an account-level AppInsights connection to the Foundry Account.
          The connection string is also forwarded to the Foundry project for agent trace/telemetry.
  false (default) → No Application Insights resource is provisioned. Only Log Analytics is created.
          The Foundry project has no tracing connection.
''')
param enableObservability bool = false

@description('''
How to provision observability resources (only effective when enableObservability=true):
  true  (default) → Creates a new Log Analytics workspace and Application Insights component.
                     Suitable for self-contained environments such as PoC, dev, and stg.
  false           → References existing shared monitoring resources.
                     Use this for production when connecting to a central Log Analytics
                     managed by the platform team, and provide the IDs below.
''')
param createObservability bool = true

@description('Resource ID of existing Log Analytics workspace (required when createObservability=false)')
param existingLogWorkspaceId string = ''

@description('Resource ID of existing Application Insights (required when createObservability=false and enableObservability=true)')
param existingAppInsightsId string = ''

// --- AI Search ---

@description('''
Whether to deploy Azure AI Search:
  true  → Creates an AI Search service and configures connections and RBAC.
  false (default) → Skips AI Search creation and all dependent resources (connections, RBAC).
''')
param enableAiSearch bool = false

@description('Azure region for the AI Search service. Defaults to the main deployment location when empty. Used in connection metadata to reflect the actual Search service region when AI Search is deployed in a different region.')
param aiSearchLocation string = location

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// Region abbreviation — safe-dereference + coalesce for any region not in the map
var regionAbbr = regionAbbreviations[?location] ?? take(location, 4)

// Multi-seed hash: encodes project/env/region → deterministic and collision-resistant across environments
var nameHash = uniqueString(resourceGroup().id, project, env, regionAbbr)

// Separate hash seed for Standard Setup (agent) resources to avoid name collision with RAG resources
// that share the same prefix (e.g., 'st' for storage, 'srch' for AI Search).
var agentNameHash = uniqueString(resourceGroup().id, 'agent', project, env, regionAbbr)

// All resource names in one place — update here only when naming rules change
//
// Naming function selection:
//   longName      → DNS-globally unique required  (hash suffix appended)
//   alphanumName  → DNS-globally unique, no hyphens allowed
//   simpleName    → Scope-unique only (resource group or parent resource); no hash needed
var names = {
  search:            longName('srch', project, env, regionAbbr, nameHash)         // globally unique DNS; max 60 chars, hyphens OK
  foundryAccount:    longName('cogacct', project, env, regionAbbr, nameHash)      // globally unique DNS (customSubDomainName); max 64 chars
  foundryProject:    simpleName('proj', project, env, regionAbbr)                 // scoped within Foundry account; max 32 chars — 'proj-<project>-<env>-<regionAbbr>' (19 chars or less recommended for project)
  containerRegistry: alphanumName('cr', project, env, nameHash)                   // globally unique DNS; max 50 chars, alphanumeric only (no hyphens)
  logAnalytics:      longName('log', project, env, regionAbbr, nameHash)          // scoped within resource group; max 63 chars — longName used for consistency
  appInsights:       longName('appi', project, env, regionAbbr, nameHash)         // Application Insights component; max 260 chars — longName used for consistency
  vault:             shortName('kv', project, env, nameHash)                      // globally unique DNS; max 24 chars (KV limit) — shortName omits region to stay within limit
  storage:           alphanumName('st', project, env, nameHash)                   // globally unique DNS; max 24 chars, alphanumeric only (no hyphens)
  cmkIdentity:       longName('uami-cmk', project, env, regionAbbr, nameHash)     // User-assigned managed identity for CMK encryption
  cmkKey:            simpleName('cmk', project, env, regionAbbr)                  // CMK key name in Key Vault (unique within Key Vault scope)
  // Standard Setup (agent BYO resources) — uses agentNameHash to avoid name collision with RAG resources
  agentStorage:      alphanumName('st', 'agent', env, agentNameHash)              // BYO agent storage; separate from RAG storage
  agentSearch:       longName('srch', 'agent', env, regionAbbr, agentNameHash)    // BYO agent AI Search; separate from RAG AI Search
  agentCosmosDb:     longName('cosmos', 'agent', env, regionAbbr, agentNameHash)  // Cosmos DB for agent thread/session storage
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

// --- Storage ---

module storage 'modules/storage.bicep' = {
  params: {
    location: location
    tags: tags
    storageAccountName: names.storage
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

// --- Observability ---

// Observability (Log Analytics + Application Insights) is provisioned only when enableObservability=true.
// When disabled, the Foundry project has no tracing connection and appInsights* outputs are empty.
module observability 'modules/observability.bicep' = if (enableObservability) {
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
    location: aiSearchLocation
    tags: tags
    serviceName: names.search
  }
}

// --- Standard Setup: BYO Resources for Hosted Agents ---
// These resources are dedicated to agent hosting and are separate from the RAG resources above.
// All three modules are deployed in parallel when enableStandardSetup is true.

// BYO Storage Account — agent file storage (separate from RAG blob storage)
module agentStorage 'modules/storage.bicep' = if (enableStandardSetup) {
  params: {
    location: location
    tags: tags
    storageAccountName: names.agentStorage
  }
}

// BYO AI Search — agent vector store (separate from RAG AI Search)
module agentSearch 'modules/search.bicep' = if (enableStandardSetup) {
  params: {
    location: location
    tags: tags
    serviceName: names.agentSearch
  }
}

// BYO Cosmos DB — agent session / thread storage
module agentCosmos 'modules/cosmos.bicep' = if (enableStandardSetup) {
  params: {
    location: location
    tags: tags
    cosmosAccountName: names.agentCosmosDb
  }
}

// --- Key Vault & CMK ---

// Key Vault is created when CMK is enabled or when BYO Key Vault connection is requested.
// CMK requires Key Vault for encryption key storage and crypto operations.
// BYO Key Vault stores Foundry connection secrets in a customer-managed vault.
module keyVault 'modules/keyvault.bicep' = if (enableCmk || enableByoKeyVault) {
  params: {
    location: location
    tags: tags
    vaultName: names.vault
    // Enable purge protection to prevent permanent loss of encryption keys (CMK)
    // and accidental deletion of the vault when in use by Foundry (BYO KV).
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
    restore: foundryRestore

    // App Insights connection string forwarded to the Foundry project for agent trace/telemetry
    appInsightsConnectionString: enableObservability ? observability!.outputs.appInsightsConnectionString : ''

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

// --- RBAC ---

// Service-to-service RBAC (Foundry ↔ AI Search, ACR, Storage)
module rbacServices 'modules/rbac.services.bicep' = {
  params: {
    foundryAccountName:        foundry.outputs.accountName
    foundryAccountPrincipalId: foundry.outputs.principalId
    foundryProjectPrincipalId: foundry.outputs.foundryProjectPrincipalId
    enableByoKeyVault:         enableByoKeyVault
    keyVaultName:              enableByoKeyVault ? keyVault!.outputs.vaultName : ''
    enableCmk:                 enableCmk
    cmkIdentityPrincipalId:    enableCmk ? cmkIdentity!.outputs.principalId : ''
    enableAiSearch:            enableAiSearch
    searchServiceName:         enableAiSearch ? search!.outputs.serviceName : ''
    searchPrincipalId:         enableAiSearch ? search!.outputs.principalId : ''
    containerRegistryName:     acr.outputs.registryName
    blobStorageAccountName:    storage.outputs.storageAccountName
    // Standard Setup BYO resource RBAC
    enableStandardSetup:       enableStandardSetup
    agentStorageAccountName:   enableStandardSetup ? agentStorage!.outputs.storageAccountName : ''
    agentSearchServiceName:    enableStandardSetup ? agentSearch!.outputs.serviceName : ''
    agentCosmosDbAccountName:  enableStandardSetup ? agentCosmos!.outputs.accountName : ''
  }
}

// User/group RBAC (Deployer, Developer Group, User Group)
module rbacUsers 'modules/rbac.users.bicep' = {
  params: {
    foundryAccountName:        foundry.outputs.accountName
    foundryProjectName:        foundry.outputs.projectName
    searchServiceName:         enableAiSearch ? search!.outputs.serviceName : ''
    blobStorageAccountName:    storage.outputs.storageAccountName
    keyVaultName:              (enableCmk || enableByoKeyVault) ? keyVault!.outputs.vaultName : ''
    deployerObjectId:          deployerObjectId
    aiDeveloperGroupId:        aiDeveloperGroupId
    aiUserGroupId:             aiUserGroupId
    // Standard Setup BYO resource RBAC
    enableStandardSetup:       enableStandardSetup
    agentStorageAccountName:   enableStandardSetup ? agentStorage!.outputs.storageAccountName : ''
    agentCosmosDbAccountName:  enableStandardSetup ? agentCosmos!.outputs.accountName : ''
  }
}

// Foundry Account-level connections — deployed AFTER RBAC assignments are complete
// so the Foundry Account's managed identity has the required permissions.
module foundryConnections 'modules/foundry.connections.bicep' = {
  params: {
    location:    location
    accountName: foundry.outputs.accountName

    // BYO Key Vault connection parameters (only set when enableByoKeyVault is true)
    enableByoKeyVault: enableByoKeyVault
    keyVaultName:      enableByoKeyVault ? keyVault!.outputs.vaultName : ''
    keyVaultId:        enableByoKeyVault ? keyVault!.outputs.vaultId : ''

    // AI Search connection parameters (only set when enableAiSearch is true)
    enableAiSearch:        enableAiSearch
    searchServiceName:     enableAiSearch ? search!.outputs.serviceName : ''
    searchServiceId:       enableAiSearch ? search!.outputs.serviceId : ''
    searchServiceLocation: enableAiSearch ? search!.outputs.serviceLocation : location

    // App Insights account-level connection parameters (only set when enableObservability is true)
    enableAppInsights:           enableObservability
    appInsightsName:             enableObservability ? observability!.outputs.appInsightsName : ''
    appInsightsId:               enableObservability ? observability!.outputs.appInsightsId : ''
    appInsightsConnectionString: enableObservability ? observability!.outputs.appInsightsConnectionString : ''
  }
  dependsOn: [rbacServices]
}

// Foundry Account-level Capability Host — required for Hosted Agents (Standard Setup)
// Must exist before the project-level Capability Host is provisioned.
module accountCapabilityHost 'modules/foundry.capabilityhost.bicep' = {
  params: {
    accountName: foundry.outputs.accountName
  }
}

// Foundry Project-level connections — BYO resources for Hosted Agents (Standard Setup)
// Deployed AFTER service-to-service RBAC so the Foundry Project MI has the required permissions.
module foundryProjectConnections 'modules/foundry.project.connections.bicep' = if (enableStandardSetup) {
  params: {
    location:                     location
    accountName:                  foundry.outputs.accountName
    projectName:                  foundry.outputs.projectName
    agentStorageAccountName:      agentStorage!.outputs.storageAccountName
    agentStorageAccountId:        agentStorage!.outputs.storageAccountId
    agentSearchServiceName:       agentSearch!.outputs.serviceName
    agentSearchServiceId:         agentSearch!.outputs.serviceId
    agentCosmosDbAccountName:     agentCosmos!.outputs.accountName
    agentCosmosDbAccountId:       agentCosmos!.outputs.accountId
    agentCosmosDbAccountEndpoint: agentCosmos!.outputs.accountEndpoint
  }
  dependsOn: [rbacServices, accountCapabilityHost]
}

// Foundry Project-level Capability Host — links BYO connections to the Hosted Agents runtime
// Deployed AFTER project connections are created (references connection names).
module projectCapabilityHost 'modules/foundry.project.capabilityhost.bicep' = if (enableStandardSetup) {
  params: {
    accountName:                 foundry.outputs.accountName
    projectName:                 foundry.outputs.projectName
    vectorStoreConnectionName:   foundryProjectConnections!.outputs.agentSearchConnectionName
    storageConnectionName:       foundryProjectConnections!.outputs.agentStorageConnectionName
    threadStorageConnectionName: foundryProjectConnections!.outputs.agentCosmosDbConnectionName
  }
  dependsOn: [accountCapabilityHost]
}

// Cosmos DB SQL role assignment — scoped to /dbs/enterprise_memory
// MUST run AFTER projectCapabilityHost because the Foundry Agent Service automatically
// creates the 'enterprise_memory' database when the Project CapabilityHost is provisioned.
// (Mirrors the Terraform pattern: depends_on = [azapi_resource.project_capability_host])
module rbacCosmosProject 'modules/rbac.agentCosmos.sqlRole.bicep' = if (enableStandardSetup) {
  params: {
    agentCosmosDbAccountName:  agentCosmos!.outputs.accountName
    foundryProjectPrincipalId: foundry.outputs.foundryProjectPrincipalId
  }
  dependsOn: [projectCapabilityHost]
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
output appInsightsConnectionString string = enableObservability ? observability!.outputs.appInsightsConnectionString : ''
output logAnalyticsId string = enableObservability ? observability!.outputs.logAnalyticsId : ''
output keyVaultName string = (enableCmk || enableByoKeyVault) ? keyVault!.outputs.vaultName : ''
output keyVaultUri string = (enableCmk || enableByoKeyVault) ? keyVault!.outputs.vaultUri : ''
// Standard Setup outputs
output agentStorageAccountName string = enableStandardSetup ? agentStorage!.outputs.storageAccountName : ''
output agentSearchEndpoint string = enableStandardSetup ? agentSearch!.outputs.endpoint : ''
output agentCosmosDbAccountName string = enableStandardSetup ? agentCosmos!.outputs.accountName : ''
output agentCosmosDbAccountEndpoint string = enableStandardSetup ? agentCosmos!.outputs.accountEndpoint : ''
