// private-dns-zone.bicep
// Private DNS Zone with Virtual Network Link for Private Endpoint DNS resolution.
//
// Description:
//   Creates a Private DNS Zone and links it to a Virtual Network for automatic DNS
//   resolution of Private Endpoint addresses. Supports both creating new zones and
//   referencing existing zones in a hub/connectivity subscription.
//
// Resources:
//   Microsoft.Network/privateDnsZones@2024-06-01
//   Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01
//
// Usage:
//   module dnsZoneCognitive 'modules/private-dns-zone.bicep' = {
//     params: {
//       zoneName:    'privatelink.cognitiveservices.azure.com'
//       vnetId:      vnet.outputs.vnetId
//       linkName:    'vnet-link-cognitive-${uniqueString(resourceGroup().id)}'
//       tags:        tags
//     }
//   }

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

param tags object

@description('The name of the Private DNS Zone (e.g., privatelink.cognitiveservices.azure.com)')
param zoneName string

@description('Resource ID of the Virtual Network to link to the DNS Zone')
param vnetId string

@description('Name of the VNet link (must be unique within the DNS Zone)')
param linkName string

@description('Enable auto-registration of VM DNS records. Set to false for Private Endpoint zones.')
param registrationEnabled bool = false

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: zoneName
  location: 'global' // Private DNS Zones are always global
  properties: {}
  tags: tags
}

// VNet Link to enable DNS resolution from the linked VNet
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: linkName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: registrationEnabled
  }
  tags: tags
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output zoneId string = privateDnsZone.id
output zoneName string = privateDnsZone.name
output linkId string = vnetLink.id
