// roleDefinitions.bicep
// Azure built-in role definition GUIDs used across all RBAC assignments.
//
// Description:
//   Single source of truth for all role definition GUIDs used within this deployment.
//   Centralising GUIDs here prevents copy-paste errors and makes it straightforward
//   to add new roles as the solution grows.
//
// Usage:
//   import { roleIds } from './roleDefinitions.bicep'
//
// Notes:
//   Reference: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles

@export()
var roleIds = {
  // Key Vault roles
  kvAdministrator:             '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator
  kvSecretsUser:               '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
  kvCryptoUser:                '12338af0-0e69-4776-bea7-57ae8d297424' // Key Vault Crypto User
  kvCryptoServiceEncryption:   'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User
  // Container Registry roles
  acrPull:                     '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
  // AI Search roles
  searchServiceContributor:    '7ca78c08-252a-4471-8644-bb5ff32d4ba0' // Search Service Contributor
  searchIndexDataReader:       '1407120a-92aa-4202-b7e9-c0e197c71c8f' // Search Index Data Reader
  searchIndexDataContributor:  '8ebe5a00-799e-43f5-93ac-243d3dce84a7' // Search Index Data Contributor
  // Cognitive Services roles
  cognitiveServicesUser:       'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User
  cognitiveServicesOpenAIUser: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
  // Storage roles
  storageBlobDataReader:       '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader
  storageBlobDataContributor:  'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  // Cosmos DB roles
  cosmosDbAccountReader:       'fbdf93bf-df7d-467e-a4d2-9458aa1360c8' // Cosmos DB Account Reader Role
  // Azure AI Foundry roles
  azureAIAccountOwner:         'e47c6f54-e4a2-4754-9501-8e0985b135e1' // Azure AI Account Owner
  azureAIAdministrator:        'b78c5d69-af96-48a3-bf8d-a8b4d589de94' // Azure AI Administrator
  azureAIDeveloper:            '64702f94-c441-49e6-a78b-ef80e0188fee' // Azure AI Developer
  azureAIOwner:                'c883944f-8b7b-4483-af10-35834be79c4a' // Azure AI Owner
  azureAIProjectManager:       'eadc314b-1a2d-4efa-be10-5d325db5065e' // Azure AI Project Manager
  azureAIUser:                 '53ca6127-db72-4b80-b1b0-d745d6d5456d' // Azure AI User
}
