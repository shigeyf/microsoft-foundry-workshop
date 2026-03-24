// types.bicep
// Shared user-defined types for resource tagging and model deployment configuration.
//
// Description:
//   Exports CommonTags (enforces CAF-recommended tagging structure across all resources)
//   and ModelDeploymentConfig (defines the shape of each OpenAI model deployment entry
//   consumed by foundry-models.bicep). Centralising types here prevents structural drift
//   between modules.
//
// Usage:
//   import { CommonTags } from './types.bicep'
//   import { ModelDeploymentConfig } from './types.bicep'
//
// Notes:
//   CAF tagging strategy: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging
//   Required tags: project, env, managedBy
//   Optional tags: owner, costCenter, businessUnit, criticality, dataClassification, expiryDate

// --- Common Tags Types ---

@export()
@description('Common tags to be applied to all resources for consistent metadata and governance')
type CommonTags = {
  // --- Required ---

  @description('Workload / project short name (e.g. disai)')
  project: string

  @description('Deployment environment: dev | stg | poc | prod')
  env: string

  @description('IaC tooling that manages this resource (e.g. bicep)')
  managedBy: string

  // --- Optional ---

  @description('Team or individual responsible for the resource (e.g. platform-team)')
  owner: string?

  @description('Cost centre or charge-back code for billing allocation (e.g. CC-1234)')
  costCenter: string?

  @description('Business unit or department that owns the workload (e.g. engineering)')
  businessUnit: string?

  @description('Business criticality of the resource: low | medium | high | critical')
  criticality: ('low' | 'medium' | 'high' | 'critical')?

  @description('Data sensitivity classification: public | internal | confidential | restricted')
  dataClassification: ('public' | 'internal' | 'confidential' | 'restricted')?

  @description('Scheduled decommission date for temporary resources, ISO 8601 (e.g. 2026-12-31)')
  expiryDate: string?
}

// --- Model Deployment Config Types ---

@export()
@description('Configuration for an OpenAI model deployment')
type ModelDeploymentConfig = {
  @description('Deployment resource name, also used as the inference endpoint path segment (e.g. gpt-4.1)')
  name: string

  @description('OpenAI model name (e.g. gpt-4.1)')
  modelName: string

  @description('Model version string (e.g. 2025-04-14)')
  modelVersion: string

  @description('Model format (e.g. OpenAI)')
  format: string?

  @description('Provisioning SKU: GlobalStandard | Standard | DataZoneStandard')
  skuName: string

  @description('Capacity in thousands of tokens per minute (TPM)')
  capacity: int

  @description('RAI policy name (e.g. Microsoft.DefaultV2). Required for certain models such as GPT-5.')
  raiPolicyName: string?
}

// --- Network Isolation Types ---

@export()
@description('''
Network isolation mode for Azure resources:
  - public: Public access only (no VNet/PE), suitable for development
  - hybrid: VNet/PE created + public access enabled (deployment Phase 1)
  - private: VNet/PE created + public access disabled (production, deployment Phase 2)
''')
type NetworkIsolationMode = 'public' | 'hybrid' | 'private'

@export()
@description('Private DNS Zone configuration for Private Endpoint integration')
type PrivateDnsZoneConfig = {
  @description('Name of the Private DNS Zone (e.g., privatelink.cognitiveservices.azure.com)')
  zoneName: string

  @description('Resource ID of the existing Private DNS Zone, if using existing zones from a connectivity subscription')
  existingZoneId: string?
}

// --- CMK (Customer Managed Key) Types ---

@export()
@description('Customer Managed Key configuration for encryption at rest')
type CmkConfig = {
  @description('Enable Customer Managed Key encryption')
  enabled: bool

  @description('Key type: RSA | EC | RSA-HSM | EC-HSM')
  keyType: 'RSA' | 'EC' | 'RSA-HSM' | 'EC-HSM'

  @description('Key size in bits (for RSA keys)')
  keySize: 2048 | 3072 | 4096

  @description('Enable automatic key rotation')
  enableRotation: bool

  @description('Key expiration period (ISO 8601 duration)')
  expirationPeriod: string?
}
