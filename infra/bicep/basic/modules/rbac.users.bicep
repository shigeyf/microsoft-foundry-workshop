// rbac.users.bicep
// User and group RBAC role assignments for Azure AI Foundry resources.
//
// Description:
//   Centralizes all human user and security group RBAC assignments.
//   Separating user access from service-to-service access enables:
//     - Easier security auditing of human access
//     - Clear separation of concerns
//     - Simplified onboarding/offboarding workflows
//
//   This module is part of the 3-file RBAC structure:
//     - rbac.services.bicep: Service-to-service RBAC
//     - rbac.cmk.bicep: CMK encryption RBAC
//     - rbac.users.bicep: User/group RBAC (this file)
//
// Resources:
//   Microsoft.Authorization/roleAssignments@2022-04-01
//
// Usage:
//   module rbacUsers 'modules/rbac.users.bicep' = {
//     params: {
//       foundryAccountName:     foundry.outputs.accountName
//       keyVaultName:           keyVault.outputs.vaultName
//       deployerObjectId:       deployerObjectId
//       keyVaultAdminObjectId:  keyVaultAdminObjectId
//       // Optional: additional users/groups
//       aiDeveloperGroupId:     aiDeveloperGroupId
//     }
//   }

import { roleIds } from './roleDefinitions.bicep'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Entra ID Object ID of the deployment user. Pass empty string to skip.')
param deployerObjectId string = ''

@description('Entra ID Object ID of a group for AI Developers. Pass empty string to skip.')
param aiDeveloperGroupId string = ''

@description('Entra ID Object ID of a group for AI Users (read-only access). Pass empty string to skip.')
param aiUserGroupId string = ''

// --- Foundry Access ---
@description('Name of the Foundry Account (AIServices account)')
param foundryAccountName string

// --- Foundry Project Access ---
@description('Name of the Foundry Project')
param foundryProjectName string

// --- AI Search Access ---
@description('Name of the AI Search service. Pass empty string to skip AI Search RBAC assignments.')
param searchServiceName string = ''

// --- Blob Storage Access ---
@description('Name of Blob Storage account used for AI Search index storage. Pass empty string to skip Blob Storage RBAC assignments.')
param blobStorageAccountName string = ''

// --- Key Vault Access ---
@description('Name of the Key Vault. Pass empty string to skip Key Vault RBAC assignments.')
param keyVaultName string = ''

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// --- Existing Resource References ---

resource existingFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: foundryAccountName
}

resource existingFoundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-09-01' existing = {
  parent: existingFoundryAccount
  name: foundryProjectName
}

resource existingAISearch 'Microsoft.Search/searchServices@2025-05-01' existing = if (searchServiceName != '') {
  name: searchServiceName
}

resource existingBlobStorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = if (blobStorageAccountName != '') {
  name: blobStorageAccountName
}

resource existingKeyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = if (keyVaultName != '') {
  name: keyVaultName
}

// --- Deployer → Key Vault ---

// RBAC: Deployer → Key Vault (Key Vault Administrator)
// Grants full administrative access to the Key Vault, including the ability
// to manage keys, secrets, and certificates.
resource keyVaultAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (keyVaultName != '' && deployerObjectId != '') {
  name: guid(existingKeyVault.id, deployerObjectId, roleIds.kvAdministrator)
  scope: existingKeyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.kvAdministrator)
    principalId: deployerObjectId
    principalType: 'User'
  }
}

// --- Deployer → Foundry Account ---

// RBAC: Deployer (User) → Foundry Account (Azure AI Owner)
// Grants the deployment user full ownership of the Foundry Account scope,
// enabling Foundry portal access and agent management without needing
// direct subscription-level access.
resource deployerToFoundryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployerObjectId != '') {
  name: guid(existingFoundryAccount.id, deployerObjectId, roleIds.azureAIOwner)
  scope: existingFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.azureAIOwner)
    principalId: deployerObjectId
    principalType: 'User'
  }
}

// --- Deployer → Foundry Project ---

// RBAC: Deployer (User) → Foundry Project (Azure AI Owner)
// Grants the deployment user full ownership of the Foundry Project scope,
// enabling Foundry portal access and agent management without needing
// direct subscription-level access.
resource deployerToFoundryProjectRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployerObjectId != '') {
  name: guid(existingFoundryProject.id, deployerObjectId, roleIds.azureAIOwner)
  scope: existingFoundryProject
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.azureAIOwner)
    principalId: deployerObjectId
    principalType: 'User'
  }
}

// --- Deployer → AI Search ---

// RBAC: Deployer (User) → AI Search (Search Service Contributor)
// Grants the deployment user full ownership of the AI Search scope,
// enabling Foundry portal access and agent management without needing
// direct subscription-level access.
resource deployerToAISearchRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployerObjectId != '' && searchServiceName != '') {
  name: guid(existingAISearch.id, deployerObjectId, roleIds.searchServiceContributor)
  scope: existingAISearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchServiceContributor)
    principalId: deployerObjectId
    principalType: 'User'
  }
}

// RBAC: Deployer (User) → AI Search (Search Index Data Contributor)
// Grants the deployment user full ownership of the AI Search scope,
// enabling Foundry portal access and agent management without needing
// direct subscription-level access.
resource deployerToAISearchIndexDataRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployerObjectId != '' && searchServiceName != '') {
  name: guid(existingAISearch.id, deployerObjectId, roleIds.searchIndexDataContributor)
  scope: existingAISearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchIndexDataContributor)
    principalId: deployerObjectId
    principalType: 'User'
  }
}

// --- Deployer → Blob Storage Account ---

// RBAC: Deployer (User) → Blob Storage Account (Storage Blob Data Contributor)
// Grants the deployment user permission to create and manage AI resources within
// the Blob Storage Account, including creating models, deployments, and agents.
resource deployerToBlobStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployerObjectId != '' && blobStorageAccountName != '') {
  name: guid(existingBlobStorageAccount.id, deployerObjectId, roleIds.storageBlobDataContributor)
  scope: existingBlobStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.storageBlobDataContributor)
    principalId: deployerObjectId
    principalType: 'User'
  }
}


// --- AI Developer Group → Foundry Account ---

// RBAC: AI Developer Group → Foundry Account (Azure AI Developer)
// Grants developers permission to create and manage AI resources within
// the Foundry Account, including creating models, deployments, and agents.
resource aiDeveloperGroupToFoundryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiDeveloperGroupId != '') {
  name: guid(existingFoundryAccount.id, aiDeveloperGroupId, roleIds.azureAIDeveloper)
  scope: existingFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.azureAIDeveloper)
    principalId: aiDeveloperGroupId
    principalType: 'Group'
  }
}

// --- AI Developer Group → Foundry Project ---

// RBAC: AI Developer Group → Foundry Project (Azure AI Developer)
// Grants developers permission to create and manage AI resources within
// the Foundry Project, including creating models, deployments, and agents.
resource aiDeveloperGroupToFoundryProjectRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiDeveloperGroupId != '') {
  name: guid(existingFoundryProject.id, aiDeveloperGroupId, roleIds.azureAIDeveloper)
  scope: existingFoundryProject
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.azureAIDeveloper)
    principalId: aiDeveloperGroupId
    principalType: 'Group'
  }
}

// --- AI Developer Group → AI Search ---

// RBAC: AI Developer Group → AI Search (Search Service Contributor)
// Grants developers permission to create and manage AI resources within
// the AI Search, including creating models, deployments, and agents.
resource aiDeveloperGroupToAISearchRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiDeveloperGroupId != '' && searchServiceName != '') {
  name: guid(existingAISearch.id, aiDeveloperGroupId, roleIds.searchServiceContributor)
  scope: existingAISearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchServiceContributor)
    principalId: aiDeveloperGroupId
    principalType: 'Group'
  }
}

// RBAC: AI Developer Group → AI Search (Search Index Data Contributor)
// Grants developers permission to create and manage AI resources within
// the AI Search, including creating models, deployments, and agents.
resource aiDeveloperGroupToAISearchIndexDataRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiDeveloperGroupId != '' && searchServiceName != '') {
  name: guid(existingAISearch.id, aiDeveloperGroupId, roleIds.searchIndexDataContributor)
  scope: existingAISearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchIndexDataContributor)
    principalId: aiDeveloperGroupId
    principalType: 'Group'
  }
}


// --- AI Developer Group → Blob Storage Account ---

// RBAC: AI Developer Group → Blob Storage Account (Storage Blob Data Contributor)
// Grants developers permission to create and manage AI resources within
// the Blob Storage Account, including creating models, deployments, and agents.
resource aiDeveloperGroupToBlobStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiDeveloperGroupId != '' && blobStorageAccountName != '') {
  name: guid(existingBlobStorageAccount.id, aiDeveloperGroupId, roleIds.storageBlobDataContributor)
  scope: existingBlobStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.storageBlobDataContributor)
    principalId: aiDeveloperGroupId
    principalType: 'Group'
  }
}

// --- AI User Group → Foundry Account ---

// RBAC: AI User Group → Foundry Account (Azure AI User)
// Grants users read-only access to AI resources and the ability to use
// deployed models and agents without modification privileges.
resource aiUserGroupRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiUserGroupId != '') {
  name: guid(existingFoundryAccount.id, aiUserGroupId, roleIds.azureAIUser)
  scope: existingFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.azureAIUser)
    principalId: aiUserGroupId
    principalType: 'Group'
  }
}

// --- AI User Group → AI Search ---

// RBAC: AI User Group → AI Search (Search Index Data Reader)
// Grants users permission to read and interact with AI resources within
// the AI Search, including accessing models, deployments, and agents.
resource aiUserGroupToAISearchIndexDataRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiUserGroupId != '' && searchServiceName != '') {
  name: guid(existingAISearch.id, aiUserGroupId, roleIds.searchIndexDataReader)
  scope: existingAISearch
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.searchIndexDataReader)
    principalId: aiUserGroupId
    principalType: 'Group'
  }
}

// --- AI User Group → Blob Storage Account ---

// RBAC: AI User Group → Blob Storage Account (Storage Blob Data Reader)
// Grants users permission to read and interact with AI resources within
// the Blob Storage Account, including accessing models, deployments, and agents.
resource aiUserGroupToBlobStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aiUserGroupId != '' && blobStorageAccountName != '') {
  name: guid(existingBlobStorageAccount.id, aiUserGroupId, roleIds.storageBlobDataReader)
  scope: existingBlobStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.storageBlobDataReader)
    principalId: aiUserGroupId
    principalType: 'Group'
  }
}
