// observability.bicep
// Log Analytics Workspace and Application Insights with create-or-reference modes.
//
// Description:
//   Supports two operating modes controlled by the 'createNew' parameter:
//
//   createNew = true  (default)
//     Creates a new Log Analytics workspace and Application Insights component.
//     Use this for self-contained environments such as PoC, dev, and staging.
//
//   createNew = false
//     References existing Log Analytics / Application Insights resources by ID.
//     Use this in production to connect to a shared monitoring platform managed
//     by the platform team. Both existingLogWorkspaceId and existingAppInsightsId
//     must be provided.
//
// Resources:
//   Microsoft.OperationalInsights/workspaces@2025-07-01
//   Microsoft.Insights/components@2020-02-02
//
// Usage:
//   module observability 'modules/observability.bicep' = {
//     params: {
//       location:         location
//       logWorkspaceName: naming.outputs.logWorkspaceName
//       appInsightsName:  naming.outputs.appInsightsName
//       tags: tags
//       // createNew: true  (default — omit for new environments)
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param logWorkspaceName string
param appInsightsName string

@description('true = create new resources; false = reference existing resources')
param createNew bool = true

@description('Existing Log Analytics workspace resource ID (required when createNew = false)')
param existingLogWorkspaceId string = ''

@description('Existing Application Insights resource ID (required when createNew = false)')
param existingAppInsightsId string = ''

@description('Log Analytics data retention in days (only applies when createNew = true)')
@minValue(30)
@maxValue(730)
param logRetentionInDays int = 30

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// --- Create path ---
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-07-01' = if (createNew) {
  name: logWorkspaceName
  location: location
  properties: {
    sku: {
      // PerGB2018 is the current recommended SKU; the legacy 'Free' and 'Standard' tiers are retired.
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionInDays
    // PoC: public network access enabled for ingestion and query.
    // PRODUCTION: set both to 'Disabled' and route through a private link scope (AMPLS).
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: tags
}

resource appInsights 'microsoft.insights/components@2020-02-02' = if (createNew) {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id // Workspace-based mode (classic Application Insights was retired in 2025)
    // PoC: public network access enabled.
    // PRODUCTION: set to 'Disabled' and configure a private link scope.
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: tags
}

// --- Reference path ---
// Existing resources are referenced using the Bicep 'existing' keyword.
// Using native Bicep references instead of ARM resourceId() provides
// type safety without additional API calls.

resource existingLogAnalytics 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = if (!createNew) {
  // Extract the resource name from the resource ID (last path segment).
  name: last(split(existingLogWorkspaceId, '/'))
}

resource existingAppInsightsResource 'microsoft.insights/components@2020-02-02' existing = if (!createNew) {
  name: last(split(existingAppInsightsId, '/'))
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
// Returns properties from either the new or existing resource depending on createNew.
// Callers are unaware of the branching thanks to Bicep's conditional expressions.
// BCP318: conditional resources are always evaluated at compile time; ! assertions suppress the warnings.

output logAnalyticsId string = createNew ? logAnalytics!.id : existingLogAnalytics!.id
output logAnalyticsWorkspaceId string = createNew
  ? logAnalytics!.properties.customerId
  : existingLogAnalytics!.properties.customerId
output logAnalyticsName string = createNew ? logAnalytics!.name : existingLogAnalytics!.name

output appInsightsId string = createNew ? appInsights!.id : existingAppInsightsResource!.id
output appInsightsName string = createNew ? appInsights!.name : existingAppInsightsResource!.name
output appInsightsConnectionString string = createNew
  ? appInsights!.properties.ConnectionString
  : existingAppInsightsResource!.properties.ConnectionString
output instrumentationKey string = createNew
  ? appInsights!.properties.InstrumentationKey
  : existingAppInsightsResource!.properties.InstrumentationKey
