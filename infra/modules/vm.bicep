param basePrefix string
param location string
param subnetId string
param localIP string
param publicSSHKey string
param adminPrincipalIds array
param userPrincipalIds array
param vmImage object
param vmSku string
param adminUsername string = 'azuser'
param useSpotInstance bool
// param deploymentZone string = '2'

var priority = useSpotInstance ? 'Spot' : 'Regular'
var evictionPolicy = useSpotInstance ? 'Deallocate' : ''

// Resource Names
var publicIpName = '${basePrefix}-pip'
var nicName = '${basePrefix}-nic'
var vmName = '${basePrefix}-vm'

var virtualMachineAdministratorLoginRoleId = '1c0163c0-47e6-4577-8991-ea5c82e286e4'
var virtualMachineUserLoginRoleId = 'fb879df8-f326-4884-b1cf-06f3ad86be52'

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/publicipaddresses?pivots=deployment-language-bicep
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: publicIpName
  location: location
  // zones: [deploymentZone]
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/networkinterfaces?pivots=deployment-language-bicep
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${nicName}-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: localIP
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/2023-03-01/virtualmachines?pivots=deployment-language-bicep
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  // zones: [deploymentZone]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    storageProfile: {
      imageReference: {
        publisher: vmImage.publisher
        offer: vmImage.offer
        sku: vmImage.sku
        version: vmImage.version
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 32
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
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
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false  // true
        storageUri: ''
      }
    }
    priority: priority
    evictionPolicy: evictionPolicy
    billingProfile: {
      maxPrice: useSpotInstance ? -1 : null
    }
  }

}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/2023-03-01/virtualmachines/extensions?pivots=deployment-language-bicep
resource aadsshLoginForLinux 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: virtualMachine
  name: 'AADSSHLoginForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

// Let admins login as sudoers via `az ssh ...`
// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments?pivots=deployment-language-bicep
resource virtualMachineAdministratorLoginRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in adminPrincipalIds: {
    name: guid(principalId, virtualMachineAdministratorLoginRoleId, virtualMachine.id)
    scope: virtualMachine
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', virtualMachineAdministratorLoginRoleId)
      principalId: principalId
      principalType: 'User'
    }
  }
] 

// Let users login as normal users via `az ssh ...`
// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments?pivots=deployment-language-bicep
resource virtualMachineUserLoginRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in userPrincipalIds: {
    name: guid(principalId, virtualMachineUserLoginRoleId, virtualMachine.id)
    scope: virtualMachine
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', virtualMachineUserLoginRoleId)
      principalId: principalId
      principalType: 'User'
    }
  }
]

output id string = virtualMachine.id
output identityPrincipalId string = virtualMachine.identity.principalId
