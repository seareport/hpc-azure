targetScope = 'subscription'

@description('The location where you want to deploy these resources. You should typically deploy on `westeurope`')
param location string

@description('A short prefix that will be used for the names of all the resources that are going to be deployed')
param project string

@description('A list of the UUIDs of persons who need to have admin rights')
param adminPrincipalIds array

@description('A list of the UUIDs of persons who need to have normal user rights')
param userPrincipalIds array

@description('SSH Key for the Virtual Machine.')
@secure()
param adminPublicSSHKey string

var vmImages = {
  '2204hpc': {
    publisher: 'microsoft-dsvm'
    offer: 'ubuntu-hpc'
    sku: '2204'
    version: 'latest'
  }
  '2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

// Define the environments and the domains as variables so that we avoid typos
var environments = {
  dev: 'dev'
  oper: 'oper'
  common: 'common'
}

var domains = {
  compute: 'compute'
  visual: 'visual'
  network: 'network'
  keyvault: 'keyvault'
  storage: 'storage'
}

var baseTags = {
  dev: {project: project, location: location, environment: environments.dev}
  oper: {project: project, location: location, environment: environments.oper}
  common: {project: project, location: location, environment: environments.common}
}

var prefixes = {
  operNetwork: '${project}-${environments.oper}-${domains.network}'
  operCompute: '${project}-${environments.oper}-${domains.compute}'
  operVisual: '${project}-${environments.oper}-${domains.visual}'
  devNetwork: '${project}-${environments.dev}-${domains.network}'
  devCompute: '${project}-${environments.dev}-${domains.compute}'
  commonKeyvault: '${project}-${environments.common}-${domains.keyvault}'
  commonStorage: '${project}-${environments.common}-${domains.storage}'
}

var storageAccountIdentifiers = {
  dev: 'dev'
  oper: 'oper'
  pub: 'pub'
}

var resourceGroupNames = {
  operNetwork: '${prefixes.operNetwork}-rg'
  operCompute: '${prefixes.operCompute}-rg'
  operVisual: '${prefixes.operVisual}-rg'
  devNetwork: '${prefixes.devNetwork}-rg'
  devCompute: '${prefixes.devCompute}-rg'
  commonKeyvault: '${prefixes.commonKeyvault}-rg'
  commonStoragePub: '${prefixes.commonStorage}-${storageAccountIdentifiers.pub}-rg'
  commonStorageOper: '${prefixes.commonStorage}-${storageAccountIdentifiers.oper}-rg'
  commonStorageDev: '${prefixes.commonStorage}-${storageAccountIdentifiers.dev}-rg'
}

// Create resource groups
// The fact that we inline them here is a bit ugly, but I couldn't find 
// a neat way to force their creation before the creation dependent resources...
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource operNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.operNetwork
  location: location
  tags: union(baseTags.oper, {domain: domains.network, resource: 'rg'})
}
resource operComputeRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.operCompute
  location: location
  tags: union(baseTags.oper, {domain: domains.compute, resource: 'rg'})
}
resource operVisualRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.operVisual
  location: location
  tags: union(baseTags.oper, {domain: domains.visual, resource: 'rg'})
}
resource devNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.devNetwork
  location: location
  tags: union(baseTags.dev, {domain: domains.network, resource: 'rg'})
}
resource devComputeRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.devCompute
  location: location
  tags: union(baseTags.dev, {domain: domains.compute, resource: 'rg'})
}
resource commonKeyvaultRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.commonKeyvault
  location: location
  tags: union(baseTags.common, {domain: domains.keyvault, resource: 'rg'})
}
resource commonStoragePubRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.commonStoragePub
  location: location
  tags: union(baseTags.common, {domain: domains.storage, identifier: 'pub', resource: 'rg'})
}
resource commonStorageOperRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.commonStorageOper
  location: location
  tags: union(baseTags.common, {domain: domains.storage, identifier: 'oper', resource: 'rg'})
}
resource commonStorageDevRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupNames.commonStorageDev
  location: location
  tags: union(baseTags.common, {domain: domains.storage, identifier: 'dev', resource: 'rg'})
}

module operNet 'modules/network.bicep' = {
  name: 'deployOperNetwork'
  scope: resourceGroup(operNetworkRG.name)
  params:{
    basePrefix: prefixes.operNetwork
    location: location
    baseTags: baseTags.oper
    domains: domains
    includePublic: true
  }
}

module devNet 'modules/network.bicep' = {
  name: 'deployDevNetwork'
  scope: resourceGroup(devNetworkRG.name)
  params:{
    basePrefix: prefixes.devNetwork
    location: location
    baseTags: baseTags.dev
    domains: domains
    includePublic: false
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'deployCommonKeyvault'
  scope: resourceGroup(commonKeyvaultRG.name)
  params:{
    basePrefix: prefixes.commonKeyvault
    location: location
    domains: domains
    baseTags: baseTags.common
    subnetIds: [
      operNet.outputs.subnetIds.compute
      devNet.outputs.subnetIds.compute
      // not sure if we need access to the keyvault from the public SNET. Let's disable for now.
      // operNet.outputs.subnetIds.public
    ]
    adminPrincipalIds: adminPrincipalIds
    userPrincipalIds: concat(
      userPrincipalIds,
      [
        // operComputeVM.outputs.identityPrincipalId
        // devComputeVM.outputs.identityPrincipalId
        // not sure if we need access to the keyvault from the public SNET. Let's disable for now.
        // operVisualVM.outputs.identityPrincipalId
      ]
    )
  }
}

module pubStorage 'modules/storage.bicep' = {
  name: 'deployPubStorageAccount'
  scope: resourceGroup(commonStoragePubRG.name)
  params: {
    basePrefix: prefixes.commonStorage
    identifier: storageAccountIdentifiers.pub
    location: location
    subnetIds: [
      operNet.outputs.subnetIds.compute
      devNet.outputs.subnetIds.compute
      operNet.outputs.subnetIds.public
    ]
    domains: domains
    baseTags: baseTags.common
    readerPrincipals: [
      operVisualVM.outputs.identityPrincipalId
    ]
    contributorPrincipals: [
      operComputeVM.outputs.identityPrincipalId
    ]
  }
}

module operStorage 'modules/storage.bicep' = {
  name: 'deployOperStorageAccount'
  scope: resourceGroup(commonStorageOperRG.name)
  params: {
    basePrefix: prefixes.commonStorage
    identifier: storageAccountIdentifiers.oper
    location: location
    subnetIds: [
      operNet.outputs.subnetIds.compute
      devNet.outputs.subnetIds.compute
      operNet.outputs.subnetIds.public
    ]
    domains: domains
    baseTags: baseTags.common
    readerPrincipals: []
    contributorPrincipals: [
      operComputeVM.outputs.identityPrincipalId
    ]
  }
}

module devStorage 'modules/storage.bicep' = {
  name: 'deployDevStorageAccount'
  scope: resourceGroup(commonStorageDevRG.name)
  params: {
    basePrefix: prefixes.commonStorage
    identifier: storageAccountIdentifiers.dev
    location: location
    subnetIds: [
      devNet.outputs.subnetIds.compute
    ]
    domains: domains
    baseTags: baseTags.common
    readerPrincipals: []
    contributorPrincipals: []
  }
}

// Oper Compute
module operComputeVM 'modules/vm.bicep' = {
  name: 'deployOperComputeVM'
  scope: resourceGroup(operComputeRG.name)
  params: {
    basePrefix: prefixes.operCompute
    location: location
    subnetId: operNet.outputs.subnetIds.compute
    localIP: '10.0.0.4'
    publicSSHKey: adminPublicSSHKey
    vmSku: 'Standard_FX4mds'
    vmImage: vmImages['2204']
    useSpotInstance: true
    adminPrincipalIds: adminPrincipalIds
    userPrincipalIds: userPrincipalIds
  }
}
module operComputeVMSS 'modules/vmss.bicep' = {
  name: 'deployOperComputeVMSS'
  scope: resourceGroup(operComputeRG.name)
  params: {
    basePrefix: prefixes.operCompute
    location: location
    subnetId: operNet.outputs.subnetIds.compute
    publicSSHKey: adminPublicSSHKey
    contributorIds: concat(
      adminPrincipalIds,
      [
        operComputeVM.outputs.identityPrincipalId
      ]
    )
  }
}


// Oper Visual
module operVisualVM 'modules/vm.bicep' = {
  name: 'deployOperVisualVM'
  scope: resourceGroup('${prefixes.operVisual}-rg')
  params: {
    basePrefix: prefixes.operVisual
    location: location
    subnetId: operNet.outputs.subnetIds.public
    localIP: '10.0.1.4'
    publicSSHKey: adminPublicSSHKey
    vmSku: 'Standard_FX4mds'
    vmImage: vmImages['2204']
    useSpotInstance: true
    adminPrincipalIds: adminPrincipalIds
    userPrincipalIds: []
  }
}

// Dev Compute
// module devComputeVM 'modules/vm.bicep' = {
//   name: 'deployDevComputeVM'
//   scope: resourceGroup('${prefixes.devCompute}-rg')
//   params: {
//     basePrefix: prefixes.devCompute
//     location: location
//     subnetId: devNet.outputs.subnetIds.compute
//     localIP: '10.0.0.4'
//     publicSSHKey: adminPublicSSHKey
//     vmSku: 'Standard_FX4mds'
//     vmImage: vmImages['2204']
//     useSpotInstance: true
//     adminPrincipalIds: adminPrincipalIds
//     userPrincipalIds: userPrincipalIds
//   }
// }
