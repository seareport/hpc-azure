param basePrefix string
param location string
param subnetId string
param adminUsername string = 'azuser'
param publicSSHKey string
param contributorIds array

var VirtualMachineContributorRoleId = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'

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
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      evictionPolicy: 'Delete'
      priority: 'Spot'
      billingProfile: {
        maxPrice: -1
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic-config'
            properties: {
              enableAcceleratedNetworking: true
              ipConfigurations: [
                {
                  name: '${vmssName}-nic-config-ip-config'
                  properties: {
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
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
          ssh: {
            publicKeys: [
              {
                path: format('/home/{0}/.ssh/authorized_keys', adminUsername)
                keyData: publicSSHKey
              }
            ]
          }
        }
      }
      storageProfile:{
        dataDisks: []
        osDisk: {
          createOption: 'FromImage'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        imageReference: {
          publisher: 'microsoft-dsvm'
          offer: 'ubuntu-hpc'
          sku: '2204'
          version: 'latest'
        }
      }

    }
  }
}

// Let Identities scale the VMSS up and down
// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments?pivots=deployment-language-bicep
resource virtualMachineUserLoginRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in contributorIds: {
    name: guid(principalId, VirtualMachineContributorRoleId, vmss.id)
    scope: vmss
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', VirtualMachineContributorRoleId)
      principalId: principalId
      // principalType: 'User'
    }
  }
]
