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

// --- AI Search ---
@description('Whether AI Search is enabled. When false, all AI Search RBAC assignments are skipped.')
param enableAiSearch bool

@description('Name of the AI Search service. Required when enableAiSearch is true.')
param searchServiceName string = ''

@description('Principal ID of the AI Search system-assigned managed identity. Required when enableAiSearch is true.')
param searchPrincipalId string = ''

// --- Container Registry ---
@description('Name of the Azure Container Registry')
param containerRegistryName string

// --- Blob Storage ---
@description('Name of the Azure Blob Storage account used for AI Search index storage')
param blobStorageAccountName string

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
