param basePrefix string
param location string
param subnetId string
param adminUsername string
param subnetName string
param nsgId string

// Resource Names
var ppgName = '${basePrefix}-ppg'
var vmssName = '${basePrefix}-vmss'


// https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/2023-03-01/proximityplacementgroups?pivots=deployment-language-bicep
resource ppg 'Microsoft.Compute/proximityPlacementGroups@2023-03-01' = {
  name: ppgName
  location: location
  properties: {
    intent: {
      vmSizes: [
        'Standard_HB120rs_v3'
        'Standard_HB120-96rs_v3'
        'Standard_HB120-64rs_v3'
        'Standard_HB120-32rs_v3'
        'Standard_HB120rs_v2'
        'Standard_HB120-96rs_v2'
        'Standard_HB120-64rs_v2'
        'Standard_HB120-32rs_v2'
      ]
    }
    proximityPlacementGroupType: 'standard'
  }
  zones: [
    '2'
  ]
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/2023-03-01/virtualmachinescalesets?pivots=deployment-language-bicep
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' = {
  location: location
  name: vmssName
  sku: {
    name: 'Standard_HB120rs_v3'
  }
  identity: {
    type: 'SystemAssigned'
  }
  zones: [
    '2'
  ]
  properties: {
    orchestrationMode: 'Uniform'
    overprovision: true
    proximityPlacementGroup: {
      id: ppg.id
    }
    singlePlacementGroup: false
    virtualMachineProfile: {
      evictionPolicy: 'Delete'
      priority: 'Spot'
      billingProfile: {
        maxPrice: -1
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic-config01'
            properties: {
              enableAcceleratedNetworking: true
              ipConfigurations: [
                {
                  name: '${vmssName}-nic-config-ip-config01'
                  properties: {
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
              networkSecurityGroup: {
                id: nsgId
              }
              primary: true
            }
          }
        ]
      }
      osProfile: {
        adminUsername: adminUsername
        computerNamePrefix: 'asdf'
        linuxConfiguration: {
          disablePasswordAuthentication: true
        }
      }
    }
  }
}
