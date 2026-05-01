// rbac.services.bicep
// Service-to-service RBAC role assignments for Azure AI Foundry ecosystem.
//
// Description:
//   Centralizes all cross-service RBAC assignments to enable security review
//   and auditing from a single location. This module handles permissions between:
//     - Foundry Account ↔ AI Search
//     - Foundry Project ↔ ACR
//     - AI Search ↔ Foundry Account (Integrated Vectorization)
//
//   This module is part of the 3-file RBAC structure:
//     - rbac.services.bicep: Service-to-service RBAC (this file)
//     - rbac.cmk.bicep: CMK encryption RBAC
//     - rbac.users.bicep: User/group RBAC
//
//   Parent-child relationships (e.g., Foundry Project → Foundry Account) remain
//   in the resource module (foundry.bicep) as they are tightly coupled.
//
// Resources:
//   Microsoft.Authorization/roleAssignments@2022-04-01
//
// Usage:
//   module rbacServices 'modules/rbac.services.bicep' = {
//     params: {
//       foundryAccountName:        foundry.outputs.accountName
//       foundryAccountPrincipalId: foundry.outputs.principalId
//       foundryProjectPrincipalId: foundry.outputs.foundryProjectPrincipalId
//       searchServiceName:         search.outputs.serviceName
//       searchPrincipalId:         search.outputs.principalId
//       containerRegistryName:     acr.outputs.registryName
//       blobStorageAccountName:    storage.outputs.storageAccountName
//     }
//   }

import { roleIds } from './roleDefinitions.bicep'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

// --- Foundry ---
@description('Name of the Foundry Account (AIServices account)')
param foundryAccountName string

@description('Principal ID of the Foundry Account system-assigned managed identity')
param foundryAccountPrincipalId string

@description('Principal ID of the Foundry Project system-assigned managed identity')
param foundryProjectPrincipalId string

// --- Blob Storage ---
@description('Name of the Azure Blob Storage account used for AI Search index storage')
param blobStorageAccountName string

// --- Container Registry ---
@description('Name of the Azure Container Registry')
param containerRegistryName string

// --- AI Search ---
@description('Whether AI Search is enabled. When false, all AI Search RBAC assignments are skipped.')
param enableAiSearch bool

@description('Name of the AI Search service. Required when enableAiSearch is true.')
param searchServiceName string = ''

@description('Principal ID of the AI Search system-assigned managed identity. Required when enableAiSearch is true.')
param searchPrincipalId string = ''

// --- Standard Setup (Hosted Agent BYO Resources) ---
@description('Whether Standard Setup is enabled. When false, all BYO resource RBAC assignments are skipped.')
param enableStandardSetup bool = false

@description('Name of the BYO Storage Account for Hosted Agents. Required when enableStandardSetup is true.')
param agentStorageAccountName string = ''

@description('Name of the BYO AI Search service for Hosted Agents. Required when enableStandardSetup is true.')
param agentSearchServiceName string = ''

@description('Name of the BYO Cosmos DB account for Hosted Agents. Required when enableStandardSetup is true.')
param agentCosmosDbAccountName string = ''

// --- BYO Key Vault ---
@description('Whether BYO Key Vault is enabled. When false, all Key Vault RBAC assignments are skipped.')
param enableByoKeyVault bool = false

@description('Name of the Key Vault. Required when enableByoKeyVault or enableCmk is true.')
param keyVaultName string = ''

// --- CMK ---
@description('Whether CMK is enabled. When true, the CMK UAMI is granted Key Vault Secrets Officer on the Key Vault.')
param enableCmk bool = false

@description('Principal ID of the CMK User Assigned Managed Identity. Required when enableCmk is true.')
param cmkIdentityPrincipalId string = ''

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// --- Existing Resource References ---

// Foundry Account reference for scoping
resource existingFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: foundryAccountName
}

// AI Search reference for scoping
resource existingSearch 'Microsoft.Search/searchServices@2025-05-01' existing = if (enableAiSearch) {
  name: searchServiceName
}

// Container Registry reference for scoping
resource existingRegistry 'Microsoft.ContainerRegistry/registries@2025-11-01' existing = {
  name: containerRegistryName
}

// Blob Storage Account reference for scoping
resource existingBlobStorage 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: blobStorageAccountName
}

// BYO Agent Storage Account reference for scoping (Standard Setup)
resource existingAgentStorage 'Microsoft.Storage/storageAccounts@2025-01-01' existing = if (enableStandardSetup) {
  name: agentStorageAccountName
}

// BYO Agent AI Search reference for scoping (Standard Setup)
resource existingAgentSearch 'Microsoft.Search/searchServices@2025-05-01' existing = if (enableStandardSetup) {
  name: agentSearchServiceName
}

// BYO Cosmos DB reference for scoping (Standard Setup)
resource existingAgentCosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = if (enableStandardSetup) {
  name: agentCosmosDbAccountName
}

// Key Vault reference for scoping
// Loaded when BYO Key Vault is enabled (kvSecretsOfficer role assignment requires BYO Key Vault).
resource existingKeyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = if (enableByoKeyVault) {
  name: keyVaultName
}

// --- Key Vault Secrets Officer (BYO Key Vault) ---
// kvSecretsOfficer is only relevant when BYO Key Vault is enabled.
// The recipient depends on whether CMK is also enabled:
//   enableByoKeyVault && enableCmk  → assign to CMK UAMI
//   enableByoKeyVault && !enableCmk → assign to Foundry Account MI

// RBAC: CMK UAMI → Key Vault (Key Vault Secrets Officer)
// When both BYO Key Vault and CMK are enabled, Foundry uses the UAMI to store
// and retrieve connection secrets in the customer-managed Key Vault.
// Key Vault Crypto User (encrypt/decrypt) is assigned separately in rbac.cmk.bicep.
resource cmkIdentityToKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableByoKeyVault && enableCmk) {
  name: guid(existingKeyVault.id, cmkIdentityPrincipalId, roleIds.kvSecretsOfficer)
  scope: existingKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.kvSecretsOfficer)
    principalId: cmkIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- Foundry Account → BYO Key Vault ---

// RBAC: Foundry Account MI → Key Vault (Key Vault Secrets Officer)
// When BYO Key Vault is enabled WITHOUT CMK, the Foundry Account's managed identity
// is granted permission to read, write, and delete secrets in the customer-managed Key Vault.
// Required so Foundry can store and retrieve connection secrets (e.g., API keys) on behalf of the account.
// When CMK is also enabled, the CMK UAMI takes this role instead (see cmkIdentityToKeyVaultRole above).
//
// NOTE: Role assignments propagate asynchronously in Azure AD and can take up to a few minutes
// to become effective. Bicep has no built-in mechanism to wait for propagation.
// The recommended pattern is to use a deployment script with a retry loop (deploymentScripts),
// or to accept eventual consistency and let downstream operations retry on 403s.
resource foundryAccountToKeyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableByoKeyVault && !enableCmk) {
  name: guid(existingKeyVault.id, foundryAccountPrincipalId, roleIds.kvSecretsOfficer)
  scope: existingKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.kvSecretsOfficer)
    principalId: foundryAccountPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- Foundry Account → AI Search ---

// RBAC: Foundry Account MI → AI Search (Search Index Data Reader)
// Used by the Foundry portal AI Search connection (authType: AAD) for connection validation
// and indexer management. Scoped to the exact Search service.
resource foundryAccountToSearchRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAiSearch) {
  name: guid(existingSearch.id, foundryAccountPrincipalId, roleIds.searchIndexDataReader)
  scope: existingSearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchIndexDataReader)
    principalId: foundryAccountPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- Foundry Project → AI Search ---

// RBAC: Foundry Project MI → AI Search (Search Index Data Reader)
// Grants the Hosted Agent container permission to query the AI Search index directly
// via azure-search-documents SDK inside @ai_function tool implementations.
resource foundryProjectToSearchRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAiSearch) {
  name: guid(existingSearch.id, foundryProjectPrincipalId, roleIds.searchIndexDataReader)
  scope: existingSearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchIndexDataReader)
    principalId: foundryProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- Foundry Project → Container Registry ---

// RBAC: Foundry Project MI → ACR (AcrPull)
// Foundry pulls the Hosted Agent container image from ACR using the Foundry Project MI.
resource foundryProjectToRegistryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(existingRegistry.id, foundryProjectPrincipalId, roleIds.acrPull)
  scope: existingRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.acrPull)
    principalId: foundryProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- AI Search → Foundry Account (Integrated Vectorization) ---

// RBAC: AI Search MI → Foundry Account (Cognitive Services OpenAI User)
// https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=foundry-perms#configure-access
// On your Foundry resource:
//   - Assign Cognitive Services User to your search service identity.
//
// NOTE: Using 'Cognitive Services OpenAI User' instead of 'Cognitive Services User'
// for least-privilege: AI Search only calls OpenAI embeddings, not other Cognitive Services.
//
// Grants the AI Search service permission to call text-embedding-3-small
// via Integrated Vectorization at both index-build time and query time.
resource searchToFoundryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAiSearch) {
  name: guid(existingFoundryAccount.id, searchPrincipalId, roleIds.cognitiveServicesOpenAIUser)
  scope: existingFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.cognitiveServicesOpenAIUser)
    principalId: searchPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- AI Search → Blob Storage Account ---

// RBAC: AI Search MI → Blob Storage Account (Storage Blob Data Reader)
// https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=storage-perms#configure-access
// On your Azure Blob Storage account:
//   - Assign Storage Blob Data Reader to your search service identity.
resource searchToBlobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAiSearch) {
  name: guid(existingBlobStorage.id, searchPrincipalId, roleIds.storageBlobDataReader)
  scope: existingBlobStorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.storageBlobDataReader)
    principalId: searchPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Standard Setup: Foundry Project → BYO Resources (Hosted Agent RBAC)
// ---------------------------------------------------------------------------

// --- Foundry Project → BYO Agent Storage ---

// RBAC: Foundry Project MI → BYO Agent Storage (Storage Blob Data Contributor)
// Grants the Hosted Agent runtime read/write access to the BYO agent blob storage.
// Required for agent file I/O operations (e.g., code interpreter, file search).
resource foundryProjectToAgentStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableStandardSetup) {
  name: guid(existingAgentStorage.id, foundryProjectPrincipalId, roleIds.storageBlobDataContributor)
  scope: existingAgentStorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.storageBlobDataContributor)
    principalId: foundryProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- Foundry Project → BYO Agent AI Search ---

// RBAC: Foundry Project MI → BYO Agent AI Search (Search Index Data Reader)
// Grants the Hosted Agent runtime read access to AI Search indexes for retrieval.
resource foundryProjectToAgentSearchIndexReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableStandardSetup) {
  name: guid(existingAgentSearch.id, foundryProjectPrincipalId, roleIds.searchIndexDataReader)
  scope: existingAgentSearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchIndexDataReader)
    principalId: foundryProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: Foundry Project MI → BYO Agent AI Search (Search Service Contributor)
// Grants the Hosted Agent runtime permission to manage indexes, indexers, and data sources
// required for agent vector-store operations.
resource foundryProjectToAgentSearchContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableStandardSetup) {
  name: guid(existingAgentSearch.id, foundryProjectPrincipalId, roleIds.searchServiceContributor)
  scope: existingAgentSearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchServiceContributor)
    principalId: foundryProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- Foundry Project → BYO Cosmos DB ---

// RBAC: Foundry Project MI → BYO Cosmos DB (Cosmos DB Operator)
// Grants ARM-level management permissions on the Cosmos DB account
// (e.g., creating databases and containers for agent thread storage).
resource foundryProjectToCosmosDbOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableStandardSetup) {
  name: guid(existingAgentCosmosDb.id, foundryProjectPrincipalId, roleIds.cosmosDbOperator)
  scope: existingAgentCosmosDb
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.cosmosDbOperator)
    principalId: foundryProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// NOTE: The Cosmos DB SQL role assignment scoped to /dbs/enterprise_memory is intentionally
// NOT included here. The enterprise_memory database is created automatically by the Foundry
// Agent Service when the Project CapabilityHost is provisioned. The SQL role assignment
// must therefore be deployed AFTER the Project CapabilityHost.
// See: rbac.cosmos.project.bicep (called from main.bicep after projectCapabilityHost)
