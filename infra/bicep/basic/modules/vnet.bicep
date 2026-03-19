// vnet.bicep
// Azure Virtual Network with Private Endpoint subnet for network isolation.
//
// Description:
//   Provisions an Azure Virtual Network with a dedicated subnet for Private Endpoints.
//   This module is deployed only when network isolation is required (hybrid or private mode).
//   The subnet is pre-configured for Private Endpoint deployment with appropriate settings.
//
// Resources:
//   Microsoft.Network/virtualNetworks@2024-05-01
//
// Usage:
//   module vnet 'modules/vnet.bicep' = if (enablePrivateNetworking) {
//     params: {
//       location:              location
//       vnetName:              names.vnet
//       addressSpace:          '192.168.0.0/16'
//       peSubnetAddressPrefix: '192.168.1.0/24'
//       tags:                  tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param location string
param tags object
param vnetName string

@description('Address space for the virtual network in CIDR notation')
param addressSpace string = '192.168.0.0/16'

@description('Address prefix for the Private Endpoint subnet in CIDR notation')
param peSubnetAddressPrefix string = '192.168.1.0/24'

@description('Name of the Private Endpoint subnet')
param peSubnetName string = 'snet-private-endpoint'

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [
      {
        name: peSubnetName
        properties: {
          addressPrefix: peSubnetAddressPrefix
          // Private Endpoint subnet does not require service endpoints
          serviceEndpoints: []
          // Private Endpoint subnet should not have a delegated service
          delegations: []
          // Disable default outbound access for security
          defaultOutboundAccess: false
        }
      }
    ]
  }
  tags: tags
}

// Reference to the Private Endpoint subnet
resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: peSubnetName
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output vnetId string = vnet.id
output vnetName string = vnet.name
output peSubnetId string = peSubnet.id
output peSubnetName string = peSubnet.name
