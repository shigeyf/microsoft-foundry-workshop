// foundry.deployments.bicep
// OpenAI model deployments under an existing Azure AI Foundry AIServices account.
//
// Description:
//   Deploys one or more OpenAI models as cognitive services deployments under a
//   pre-existing Foundry account. @batchSize(1) enforces sequential provisioning
//   because the Azure API rejects concurrent deployment requests on the same account.
//   Model definitions are passed as an array of ModelDeploymentConfig objects
//   (defined in types.bicep), making it straightforward to add or remove models
//   without modifying this module.
//
// Resources:
//   Microsoft.CognitiveServices/accounts/deployments@2025-09-01
//
// Usage:
//   module foundryDeployments 'modules/foundry.deployments.bicep' = {
//     params: {
//       accountName: foundry.outputs.accountName
//       modelDeployments: [
//         { name: 'gpt-4.1', modelName: 'gpt-4.1', modelVersion: '2025-04-14', skuName: 'GlobalStandard', capacity: 10 }
//         { name: 'text-embedding-3-small', modelName: 'text-embedding-3-small', modelVersion: '1', skuName: 'Standard', capacity: 10 }
//       ]
//     }
//   }

import { ModelDeploymentConfig } from './types.bicep'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param accountName string

@description('Ordered list of model deployments. Models are provisioned sequentially in array order.')
param modelDeployments ModelDeploymentConfig[]

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: accountName
}

@batchSize(1)
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2025-09-01' = [
  for model in modelDeployments: {
    parent: foundryAccount
    name: model.name
    sku: {
      name: model.skuName
      capacity: model.capacity
    }
    properties: {
      model: {
        format: model.?format ?? 'OpenAI'
        name: model.modelName
        version: model.modelVersion
      }
      // RAI policy name (required for certain models such as GPT-5)
      raiPolicyName: model.?raiPolicyName ?? null
      // OnceCurrentVersionExpired: the deployed version runs until Microsoft retires it, then auto-upgrades.
      // PRODUCTION: consider 'NoAutoUpgrade' to pin the version and prevent unexpected behaviour changes
      // at the cost of manual version management.
      versionUpgradeOption: 'OnceCurrentVersionExpired'
    }
  }
]

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output deploymentNames string[] = [for (model, i) in modelDeployments: deployments[i].name]
