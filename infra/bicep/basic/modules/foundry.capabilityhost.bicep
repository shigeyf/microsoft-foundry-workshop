// foundry.capabilityhost.bicep
// Account-level Capability Host for Azure AI Foundry Agent Service (Hosted Agents).
//
// Description:
//   Creates an account-level capability host that enables Hosted Agents
//   (public hosting environment). This resource must exist before project-level
//   capability hosts and agent deployments can be provisioned.
//
//   Hosted Agents require an account-level capability host with the public hosting
//   environment enabled. Without this resource, agent deployments will fail with
//   a timeout error because the managed environment is not ready.
//
// IMPORTANT — DELETE NOT SUPPORTED:
//   The capabilityHosts API does not support DELETE operations.
//   Once created, this resource cannot be removed via a standard Bicep/ARM delete.
//   When decommissioning, the parent Foundry Account must be deleted instead,
//   or the resource must be manually removed from the deployment state.
//
// API version notes:
//   2025-10-01-preview — Required to avoid "The request is not valid" error
//   2025-12-01         — GA version (available but may require validation)
//   This module uses 2025-10-01-preview for compatibility until 2025-12-01 is confirmed stable.
//
// Reference:
//   https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/hosted-agents#create-an-account-level-capability-host
//   https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts/capabilityhosts
//
// Resources:
//   Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview
//
// Usage:
//   module accountCapabilityHost 'modules/foundry.capabilityhost.bicep' = {
//     params: {
//       accountName: foundry.outputs.accountName
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name of the parent Foundry Account (AIServices account)')
param accountName string

@description('Name of the capability host resource. Must be unique within the account.')
param capabilityHostName string = 'accountcaphost'

@description('''
Enable the public hosting environment for Hosted Agents.
  true  (default) → Agents are hosted in a Microsoft-managed public environment.
  false           → Reserved for future private hosting scenarios.
''')
param enablePublicHostingEnvironment bool = true

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Parent Foundry Account reference
resource existingFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: accountName
}

// Account-level Capability Host
// Enables the Hosted Agents managed environment within the Foundry Account.
// capabilityHostKind: 'Agents' activates the Foundry Agent Service runtime.
#disable-next-line use-recent-api-versions
resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview' = {
  parent: existingFoundryAccount
  name: capabilityHostName
  properties: {
    capabilityHostKind: 'Agents'
    enablePublicHostingEnvironment: enablePublicHostingEnvironment
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output capabilityHostName string = accountCapabilityHost.name
