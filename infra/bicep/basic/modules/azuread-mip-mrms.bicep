// azuread-mip-mrms.bicep
// Azure AD App Role Assignments for Microsoft Information Protection (MIP) and
// Microsoft Rights Management Services (MRMS) integration with AI Search.
//
// Description:
//   AI Search requires specific Azure AD app role assignments to enable indexing
//   of files with sensitivity labels:
//   - MIP (Microsoft Information Protection): UnifiedPolicy.Tenant.Read
//   - MRMS (Microsoft Rights Management Services): Content.SuperUser
//
//   These permissions allow AI Search to read sensitivity labels and decrypt
//   protected content during indexing operations.
//
// IMPORTANT:
//   Bicep does not natively support Microsoft Graph API operations for creating
//   app role assignments. This module uses a deployment script with Azure CLI
//   to create the required assignments.
//
//   Prerequisites:
//   - Azure CLI with Microsoft Graph permissions
//   - Deployment identity with Application.ReadWrite.All or equivalent
//
// Resources:
//   Microsoft.Resources/deploymentScripts@2023-08-01
//
// Usage:
//   module mipMrms 'modules/azuread-mip-mrms.bicep' = if (enableSensitivityLabels) {
//     params: {
//       location:           location
//       searchPrincipalId:  search.outputs.principalId
//       tags:               tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object

@description('Principal ID of the AI Search service managed identity')
param searchPrincipalId string

@description('Name of the deployment script resource')
param deploymentScriptName string = 'ds-mip-mrms-assignment'

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// Well-known client IDs for MIP and MRMS service principals
var mipClientId = '870c4f2e-85b6-4d43-bdda-6ed9a579b725'
var mrmsClientId = '00000012-0000-0000-c000-000000000000'

// Well-known app role IDs
var mipAppRoleId = '8b2071cd-015a-4025-8052-1c0dba2d3f64' // UnifiedPolicy.Tenant.Read
var mrmsAppRoleId = '7347eb49-7a1a-43c5-8eac-a5cd1d1c7cf0' // Content.SuperUser

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// User-assigned managed identity for running the deployment script
// This identity needs Microsoft Graph permissions to create app role assignments
resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: '${deploymentScriptName}-identity'
  location: location
  tags: tags
}

// Deployment script to create app role assignments via Azure CLI
// Note: This script requires the deployment identity to have sufficient Graph API permissions
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: deploymentScriptName
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.50.0'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    scriptContent: '''
      #!/bin/bash
      set -e

      SEARCH_PRINCIPAL_ID="$1"
      MIP_CLIENT_ID="$2"
      MRMS_CLIENT_ID="$3"
      MIP_APP_ROLE_ID="$4"
      MRMS_APP_ROLE_ID="$5"

      echo "Getting MIP service principal object ID..."
      MIP_SP_ID=$(az ad sp show --id "$MIP_CLIENT_ID" --query id -o tsv 2>/dev/null || echo "")

      echo "Getting MRMS service principal object ID..."
      MRMS_SP_ID=$(az ad sp show --id "$MRMS_CLIENT_ID" --query id -o tsv 2>/dev/null || echo "")

      if [ -z "$MIP_SP_ID" ]; then
        echo "WARNING: MIP service principal not found. Skipping MIP role assignment."
      else
        echo "Creating MIP app role assignment..."
        az rest --method POST \
          --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$MIP_SP_ID/appRoleAssignedTo" \
          --headers "Content-Type=application/json" \
          --body "{\"principalId\":\"$SEARCH_PRINCIPAL_ID\",\"resourceId\":\"$MIP_SP_ID\",\"appRoleId\":\"$MIP_APP_ROLE_ID\"}" \
          2>/dev/null || echo "MIP role assignment may already exist or failed."
      fi

      if [ -z "$MRMS_SP_ID" ]; then
        echo "WARNING: MRMS service principal not found. Skipping MRMS role assignment."
      else
        echo "Creating MRMS app role assignment..."
        az rest --method POST \
          --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$MRMS_SP_ID/appRoleAssignedTo" \
          --headers "Content-Type=application/json" \
          --body "{\"principalId\":\"$SEARCH_PRINCIPAL_ID\",\"resourceId\":\"$MRMS_SP_ID\",\"appRoleId\":\"$MRMS_APP_ROLE_ID\"}" \
          2>/dev/null || echo "MRMS role assignment may already exist or failed."
      fi

      echo "App role assignment script completed."
    '''
    arguments: '${searchPrincipalId} ${mipClientId} ${mrmsClientId} ${mipAppRoleId} ${mrmsAppRoleId}'
  }
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output scriptIdentityId string = scriptIdentity.id
output scriptIdentityPrincipalId string = scriptIdentity.properties.principalId
