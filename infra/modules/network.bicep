// Declare parameters
param basePrefix string
param location string
param baseTags object
param domains object
param includePublic bool = false

// Declare variables
var vnetName = '${basePrefix}-vnet'
var computeSnetName = '${basePrefix}-compute-snet'
var publicSnetName = '${basePrefix}-public-snet'
var computeNSGName = '${basePrefix}-compute-nsg'
var publicNSGName = '${basePrefix}-public-nsg'
var vnetAddressPrefixes = ['10.0.0.0/16']
var computeSnetAddressPrefix = '10.0.0.0/24'
var publicSnetAddressPrefix = '10.0.1.0/24'

// Define security rules
var computeInboundRules = [
  {
    name: 'AllowInboundFromSelf'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Inbound'
      protocol: '*'
      sourceAddressPrefix: computeSnetAddressPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: computeSnetAddressPrefix
      destinationPortRange: '*'
    }
  }
  {
    name: 'DenyAllInbound'
    properties: {
      priority: 3096
      access: 'Deny'
      direction: 'Inbound'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
]

var computeOutboundRules = [
  {
    name: 'AllowOutboundToSelf'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Outbound'
      protocol: '*'
      sourceAddressPrefix: computeSnetAddressPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: computeSnetAddressPrefix
      destinationPortRange: '*'
    }
  }
  {
    name: 'AllowOutboundToInternet'
    properties: {
      priority: 1100
      access: 'Allow'
      direction: 'Outbound'
      protocol: '*'
      sourceAddressPrefix: computeSnetAddressPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '*'
    }
  }
  {
    name: 'DenyAllOutbound'
    properties: {
      priority: 3096
      access: 'Deny'
      direction: 'Outbound'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
]

var publicInboundRules = [
  {
    name: 'AllowInboundFromSelf'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Inbound'
      protocol: '*'
      sourceAddressPrefix: publicSnetAddressPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: publicSnetAddressPrefix
      destinationPortRange: '*'
    }
  }
  {
    name: 'AllowInboundOnPorts'
    properties: {
      priority: 1100
      access: 'Allow'
      direction: 'Inbound'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: publicSnetAddressPrefix
      destinationPortRange: '19999'
    }
  }
  {
    name: 'DenyAllInbound'
    properties: {
      priority: 3096
      access: 'Deny'
      direction: 'Inbound'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
]

var publicOutboundRules = [
  {
    name: 'AllowOutboundFromSelf'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Outbound'
      protocol: '*'
      sourceAddressPrefix: publicSnetAddressPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: publicSnetAddressPrefix
      destinationPortRange: '*'
    }
  }
  {
    name: 'AllowOutboundToInternet'
    properties: {
      priority: 1100
      access: 'Allow'
      direction: 'Outbound'
      protocol: '*'
      sourceAddressPrefix: publicSnetAddressPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '*'
    }
  }
  {
    name: 'DenyAllOutbound'
    properties: {
      priority: 3096
      access: 'Deny'
      direction: 'Outbound'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
]

// Deploy resources
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/virtualnetworks?pivots=deployment-language-bicep
// The subnets must be deployed as properties of the VNET due to: https://github.com/Azure/bicep/issues/2469#issuecomment-829469822
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: union(baseTags, {domain: domains.network, resource: 'vnet'})
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    
    subnets: union(
      [
        {
          name: computeSnetName
          properties: {
            addressPrefix: computeSnetAddressPrefix
            networkSecurityGroup: {
              id: computeNSG.id
            }
            privateEndpointNetworkPolicies: 'Disabled'
            serviceEndpoints: [
              {
                service: 'Microsoft.KeyVault'
              }
              {
                service: 'Microsoft.Storage'
              }
            ]
          }
        }
      ], 
      // Conditionally add the public subnet to the vnet
      includePublic ? [
        {
          name: publicSnetName
          properties: {
            addressPrefix: publicSnetAddressPrefix  
            networkSecurityGroup: {
              id: publicNSG.id
            }
            privateEndpointNetworkPolicies: 'Disabled'
            serviceEndpoints: [
              {
                service: 'Microsoft.KeyVault'
              }
              {
                service: 'Microsoft.Storage'
              }
            ]
          }
        }
      ] : []
    )
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/virtualnetworks/subnets?pivots=deployment-language-bicep
// resource computeSnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
//   name: computeSnetName
//   parent: vnet
//   properties: {
//     addressPrefix: computeSnetAddressPrefix
//     networkSecurityGroup: {
//       id: computeNSG.id
//     }
//     privateEndpointNetworkPolicies: 'Enabled'
//     serviceEndpoints: [
//       {
//         service: 'Microsoft.KeyVault'
//       }
//       {
//         service: 'Microsoft.Storage'
//       }
//     ]
//   }
// }

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/virtualnetworks/subnets?pivots=deployment-language-bicep
// resource publicSnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = if (includePublic) {
//   name: publicSnetName
//   parent: vnet
//   properties: {
//     addressPrefix: publicSnetAddressPrefix
//     networkSecurityGroup: {
//       id: publicNSG.id
//     }
//     privateEndpointNetworkPolicies: 'Enabled'
//     serviceEndpoints: [
//       {
//         service: 'Microsoft.KeyVault'
//       }
//       {
//         service: 'Microsoft.Storage'
//       }
//     ]
//   }
// }

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/networksecuritygroups?pivots=deployment-language-bicep
resource computeNSG 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: computeNSGName
  location: location
  tags: union(baseTags, {domain: domains.network, identifier: 'compute', resource: 'nsg'})
  properties: {
    securityRules: concat(computeInboundRules, computeOutboundRules)
  }
}

// Conditionally create the public NSG
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/networksecuritygroups?pivots=deployment-language-bicep
resource publicNSG 'Microsoft.Network/networkSecurityGroups@2023-04-01' = if (includePublic) {
  name: publicNSGName
  location: location
  tags: union(baseTags, {domain: domains.network, identifier: 'public', resource: 'nsg'})
  properties: {
    securityRules: concat(publicInboundRules, publicOutboundRules)
  }
}

// Bicep doesn't support conditional definition of outputs. So we do this trick to define `public` iff `includePublic` is true.
// var _computeSubnetId = {compute: computeSnet.id}
// var _publicSubnetId = includePublic ? { public: publicSnet.id} : {}
// var _subnetIds = union(_computeSubnetId, _publicSubnetId)

// output vnetId string = vnet.id
// output subnetIds object = _subnetIds
var _computeSubnetId = {compute: vnet.properties.subnets[0].id}
var _publicSubnetId = includePublic ? { public: vnet.properties.subnets[1].id} : {}
var _subnetIds = union(_computeSubnetId, _publicSubnetId)

output vnetId string = vnet.id
output subnetIds object = _subnetIds
