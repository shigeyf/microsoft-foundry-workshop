// private-endpoint.bicep
// Generic Private Endpoint module for Azure resources.
//
// Description:
//   Creates a Private Endpoint for an Azure resource with optional Private DNS Zone integration.
//   This module is designed to be reusable across different resource types (Cognitive Services,
//   Key Vault, AI Search, Storage, etc.).
//
// Resources:
//   Microsoft.Network/privateEndpoints@2024-05-01
//
// Usage:
//   module peCognitive 'modules/private-endpoint.bicep' = {
//     params: {
//       location:          location
//       privateEndpointName: 'pe-${names.foundryAccount}'
//       subnetId:          vnet.outputs.peSubnetId
//       privateLinkServiceId: foundry.outputs.accountId
//       groupIds:          ['account']
//       privateDnsZoneIds: [dnsZoneCognitive.outputs.zoneId, dnsZoneOpenAI.outputs.zoneId]
//       tags:              tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param privateEndpointName string

@description('Resource ID of the subnet where the Private Endpoint will be deployed')
param subnetId string

@description('Resource ID of the target Azure resource to connect via Private Endpoint')
param privateLinkServiceId string

@description('Target sub-resource (group ID) for the Private Endpoint (e.g., account, vault, searchService, blob)')
param groupIds array

@description('Array of Private DNS Zone resource IDs to associate with this Private Endpoint. Pass empty array to skip DNS integration.')
param privateDnsZoneIds array = []

@description('Name of the Private DNS Zone Group (used when privateDnsZoneIds is provided)')
param dnsZoneGroupName string = 'default'

@description('Whether the connection requires manual approval')
param isManualConnection bool = false

@description('Request message for manual approval (only used if isManualConnection is true)')
param requestMessage string = ''

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: isManualConnection ? [] : [
      {
        name: 'psc-${privateEndpointName}'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
    manualPrivateLinkServiceConnections: isManualConnection ? [
      {
        name: 'psc-${privateEndpointName}'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
          requestMessage: requestMessage
        }
      }
    ] : []
  }
  tags: tags
}

// Private DNS Zone Group for automatic DNS registration
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (length(privateDnsZoneIds) > 0) {
  parent: privateEndpoint
  name: dnsZoneGroupName
  properties: {
    privateDnsZoneConfigs: [for (zoneId, i) in privateDnsZoneIds: {
      name: 'config-${i}'
      properties: {
        privateDnsZoneId: zoneId
      }
    }]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output networkInterfaceIds array = privateEndpoint.properties.networkInterfaces
