// main.rbac.definitions.tf
// Centralized RBAC role definitions for Azure AI Foundry ecosystem.
//
// Description:
//   Centralizes all role names used in RBAC assignments.
//   Each Identity × Scope pair has its own locals entry for easy
//   change management, auditing, and review.
//
//   Terraform can reference Azure built-in roles by name,
//   so GUID management (as in Bicep's roleDefinitions.bicep) is unnecessary.
//
//   Referenced by the following RBAC files:
//     - main.rbac.services.tf: Service-to-service RBAC
//     - main.rbac.cmk.tf:      CMK encryption RBAC
//     - main.rbac.users.tf:    User/group RBAC

locals {
  // ---------------------------------------------------------------------------
  // Service-to-service RBAC role definitions (main.rbac.services.tf)
  // ---------------------------------------------------------------------------

  // Foundry Account → AI Search
  // Used for Foundry portal AI Search connection validation and indexer management
  roles_foundry_account_to_search = toset([
    "Search Index Data Reader",
  ])

  // Foundry Project → Foundry Account (Parent-child RBAC)
  // The Hosted Agent container runs as the Foundry Project MI. This grants it permission
  // to call GPT-4.1 and text-embedding-3-small via DefaultAzureCredential inside @ai_function tools.
  roles_foundry_project_to_foundry_account = toset([
    "Cognitive Services User",
  ])

  // Foundry Project → AI Search
  // Used by the Hosted Agent container to query AI Search indexes directly
  roles_foundry_project_to_search = toset([
    "Search Index Data Reader",
  ])

  // Foundry Project → ACR
  // Used to pull Hosted Agent container images from ACR
  roles_foundry_project_to_acr = toset([
    "AcrPull",
  ])

  // AI Search → Foundry Account (Integrated Vectorization)
  // https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=foundry-perms#configure-access
  // On your Foundry resource:
  //   - Assign Cognitive Services OpenAI User to your search service identity.
  //
  // NOTE: Using 'Cognitive Services OpenAI User' instead of 'Cognitive Services User'
  // for least-privilege: AI Search only calls OpenAI embeddings, not other Cognitive Services.
  roles_search_to_foundry = toset([
    "Cognitive Services OpenAI User",
  ])

  // AI Search → Blob Storage
  // https://learn.microsoft.com/en-us/azure/search/get-started-portal-agentic-retrieval?tabs=storage-perms#configure-access
  // On your Azure Blob Storage account:
  //   - Assign Storage Blob Data Reader to your search service identity.
  roles_search_to_blob = toset([
    "Storage Blob Data Reader",
  ])
}

locals {
  // ---------------------------------------------------------------------------
  // CMK RBAC role definitions (main.rbac.cmk.tf)
  // ---------------------------------------------------------------------------

  // CMK UAMI → Key Vault
  // Used to access the encryption key for Cognitive Account and ACR
  roles_cmk_uami_to_keyvault = toset([
    "Key Vault Crypto User",
  ])
}

locals {
  // ---------------------------------------------------------------------------
  // Deployer RBAC role definitions (main.rbac.users.tf)
  // ---------------------------------------------------------------------------
  // Grants the deployment user (identified by az login / service principal)
  // the same set of roles as the Bicep deployer, enabling Foundry portal
  // access and resource management without subscription-level access.

  // Deployer → Foundry Account
  roles_deployer_to_foundry_account = toset([
    "Azure AI Owner",
  ])

  // Deployer → Foundry Project
  roles_deployer_to_foundry_project = toset([
    "Azure AI Owner",
  ])

  // Deployer → AI Search
  roles_deployer_to_search = toset([
    "Search Service Contributor",
    "Search Index Data Contributor",
  ])

  // Deployer → Blob Storage
  roles_deployer_to_blob = toset([
    "Storage Blob Data Contributor",
  ])

  // Deployer → Key Vault
  roles_deployer_to_keyvault = toset([
    "Key Vault Administrator",
  ])

  // ---------------------------------------------------------------------------
  // AI Developer Group RBAC role definitions (main.rbac.users.tf)
  // ---------------------------------------------------------------------------

  // Developer Group → Foundry Account
  // Azure AI Developer: permissions to create and manage models, deployments, and agents
  roles_developer_group_to_foundry_account = toset([
    "Azure AI Developer",
  ])

  // Developer Group → Foundry Project
  roles_developer_group_to_foundry_project = toset([
    "Azure AI Developer",
  ])

  // Developer Group → AI Search
  roles_developer_group_to_search = toset([
    "Search Service Contributor",
    "Search Index Data Contributor",
  ])

  // Developer Group → Blob Storage
  roles_developer_group_to_blob = toset([
    "Storage Blob Data Contributor",
  ])

  // ---------------------------------------------------------------------------
  // AI User Group RBAC role definitions (main.rbac.users.tf)
  // ---------------------------------------------------------------------------
  // Grants users read-only access to AI resources and the ability to use
  // deployed models and agents without modification privileges.
  // Pass empty string for ai_project_users_group_name to skip.

  // User Group → Foundry Account (read-only)
  roles_user_group_to_foundry_account = toset([
    "Azure AI User",
  ])

  // User Group → Foundry Project (read-only)
  roles_user_group_to_foundry_project = toset([
    "Azure AI User",
  ])

  // User Group → AI Search (read-only)
  roles_user_group_to_search = toset([
    "Search Index Data Reader",
  ])

  // User Group → Blob Storage (read-only)
  roles_user_group_to_blob = toset([
    "Storage Blob Data Reader",
  ])
}
