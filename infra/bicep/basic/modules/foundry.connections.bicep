// foundry.connections.bicep
// Azure AI Foundry account-level connections.
//
// Description:
//   Creates optional account-level connections shared across all projects:
//     - BYO Key Vault connection (when enableBYOKeyVault = true)
//     - Azure AI Search connection (when enableAiSearch = true)
//     - Application Insights connection (when enableAppInsights = true)
//
//   This module is deployed AFTER RBAC assignments are complete so that
//   the Foundry Account's managed identity already has the required
//   permissions when the connections are established.
//   In main.bicep, set dependsOn: [rbacServices, rbacUsers].
//
// Resources:
//   Microsoft.CognitiveServices/accounts/connections@2025-09-01
//
// Usage:
//   module foundryConnections 'modules/foundry.connections.bicep' = {
//     params: {
//       location:                    location
//       accountName:                 foundry.outputs.accountName
//       enableByoKeyVault:           enableByoKeyVault
//       keyVaultName:                keyVault.outputs.vaultName
//       keyVaultId:                  keyVault.outputs.vaultId
//       enableAiSearch:              enableAiSearch
//       searchServiceName:           search.outputs.serviceName
//       searchServiceId:             search.outputs.serviceId
//       enableAppInsights:           enableObservability
//       appInsightsName:             observability.outputs.appInsightsName
//       appInsightsId:               observability.outputs.appInsightsId
//       appInsightsConnectionString: observability.outputs.appInsightsConnectionString
//     }
//     dependsOn: [rbacServices, rbacUsers]
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string

@description('Name of the Foundry Account (AIServices account) to attach connections to.')
param accountName string

// --- BYO Key Vault Connection Parameters ---
@description('''
Whether to create a BYO Key Vault connection on the Foundry Account.
  true  → Creates an AzureKeyVault connection (authType: AccountManagedIdentity),
          exposing the Key Vault to all projects within the Foundry account.
  false (default) → No Key Vault connection is created.
''')
param enableByoKeyVault bool = false

@description('Name of the Key Vault to connect. Required when enableByoKeyVault is true.')
param keyVaultName string = ''

@description('Resource ID of the Key Vault to connect. Required when enableByoKeyVault is true.')
param keyVaultId string = ''

// --- AI Search Connection Parameters ---
@description('Whether AI Search is enabled. When false, the search connection is not created.')
param enableAiSearch bool = false

@description('AI Search service name. Required when enableAiSearch is true.')
param searchServiceName string = ''

@description('AI Search service resource ID. Required when enableAiSearch is true.')
param searchServiceId string = ''

@description('Azure region of the AI Search service. Used in connection metadata to reflect the actual Search service region when AI Search is deployed in a different region.')
param searchServiceLocation string = location

// --- Application Insights Connection Parameters ---
@description('''
Whether to create an Application Insights connection at account level on the Foundry Account.
  true  → Creates an AppInsights connection (authType: ApiKey) shared across all projects.
  false (default) → No account-level connection is created.
''')
param enableAppInsights bool = false

@description('Name of the Application Insights instance. Used to derive the connection resource name. Required when enableAppInsights is true.')
param appInsightsName string = ''

@description('Resource ID of the Application Insights instance. Required when enableAppInsights is true.')
param appInsightsId string = ''

@secure()
@description('Application Insights connection string. Required when enableAppInsights is true.')
param appInsightsConnectionString string = ''

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// Used in connection metadata (Bicep does not allow variables in resource type declarations)
var searchApiVersion = '2023-11-01'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Existing Foundry Account reference for parenting connections
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: accountName
}

// Connection: BYO Key Vault (only when enableByoKeyVault is true)
// Uses AccountManagedIdentity auth: the Foundry Account's system-assigned managed identity
// is used to access the Key Vault. This allows all projects within the account to
// store and retrieve connection secrets in the customer-managed Key Vault.
// The connection name is derived from the Key Vault name with hyphens removed,
// matching the Terraform convention: replace(key_vault_name, "-", "").
resource keyVaultConnection 'Microsoft.CognitiveServices/accounts/connections@2025-09-01' = if (enableByoKeyVault) {
  parent: foundryAccount
  name: 'conn-${keyVaultName}'
  properties: {
    category: 'AzureKeyVault'
    target: keyVaultId
    // BCP036: AccountManagedIdentity is not yet reflected in the ARM type definition but is supported at runtime.
    #disable-next-line BCP036
    authType: 'AccountManagedIdentity'
    useWorkspaceManagedIdentity: false
    // isSharedToAll exposes this connection to all projects within the Foundry account.
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: keyVaultId
      location: location
    }
  }
}

// Connection: Azure AI Search (only when AI Search is enabled)
resource searchConnection 'Microsoft.CognitiveServices/accounts/connections@2025-09-01' = if (enableAiSearch) {
  parent: foundryAccount
  name: 'conn-${searchServiceName}'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${searchServiceName}.search.windows.net'
    authType: 'AAD'
    // isSharedToAll exposes this connection to all projects within the Foundry account.
    // PRODUCTION: set to false and grant per-project access if multi-project isolation is required.
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: searchServiceId
      location: searchServiceLocation
      ApiVersion: searchApiVersion
    }
  }
  // Deploy AI Search connection after the BYO Key Vault connection when both are enabled.
  // This mirrors the Terraform depends_on pattern:
  //   foundry_appInsights_connection depends_on foundry_kv_connection
  dependsOn: enableByoKeyVault ? [keyVaultConnection] : []
}

// Connection: Application Insights (only when enableAppInsights is true)
// Uses ApiKey auth: the Application Insights connection string is stored as a credential,
// matching the Terraform authType: "ApiKey" with credentials.key = connection_string.
// This account-level connection exposes Application Insights in the Foundry portal
// and enables telemetry from all projects within the account.
// The connection name is derived from the App Insights name with hyphens removed,
// matching the Terraform convention: replace(local.app_insights_name, "-", "").
resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/connections@2025-09-01' = if (enableAppInsights) {
  parent: foundryAccount
  name: 'conn-${appInsightsName}'
  properties: {
    category: 'AppInsights'
    target: appInsightsId
    authType: 'ApiKey'
    // isSharedToAll exposes this connection to all projects within the Foundry account.
    isSharedToAll: true
    credentials: {
      key: appInsightsConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsightsId
      location: location
    }
  }
  // Deploy App Insights connection after the BYO Key Vault connection when both are enabled.
  // This mirrors the Terraform depends_on pattern:
  //   foundry_appInsights_connection depends_on foundry_kv_connection
  dependsOn: enableByoKeyVault ? [keyVaultConnection] : []
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

// Connection names
output keyVaultConnectionName string = keyVaultConnection.name
output searchConnectionName  string = searchConnection.name
output appInsightsConnectionName string = appInsightsConnection.name
