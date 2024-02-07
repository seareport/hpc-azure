targetScope = 'subscription'

param location string
param baseTags object
param domains object
param prefixes object
param storageAccountIdentifiers object

// aaa-oper-network-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource operNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.operNetwork}-rg'
  location: location
  tags: union(baseTags.oper, {domain: domains.network, resource: 'rg'})
}

// aaa-oper-compute-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource operComputeRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.operCompute}-rg'
  location: location
  tags: union(baseTags.oper, {domain: domains.compute, resource: 'rg'})
}

// aaa-oper-visual-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource operVisualRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.operVisual}-rg'
  location: location
  tags: union(baseTags.oper, {domain: domains.visual, resource: 'rg'})
}

// aaa-dev-network-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource devNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.devNetwork}-rg'
  location: location
  tags: union(baseTags.dev, {domain: domains.network, resource: 'rg'})
}

// aaa-dev-compute-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource devComputeRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.devCompute}-rg'
  location: location
  tags: union(baseTags.dev, {domain: domains.compute, resource: 'rg'})
}

// aaa-common-keyvault-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource commonKeyvaultRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.commonKeyvault}-rg'
  location: location
  tags: union(baseTags.common, {domain: domains.keyvault, resource: 'rg'})
}

// aaa-common-storage-pub-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource commonStoragePubRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.commonStorage}${storageAccountIdentifiers.pub}-rg'
  location: location
  tags: union(baseTags.common, {domain: domains.storage, identifier: 'pub', resource: 'rg'})
}

// aaa-common-storage-oper-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource commonStorageOperRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.commonStorage}${storageAccountIdentifiers.oper}-rg'
  location: location
  tags: union(baseTags.common, {domain: domains.storage, identifier: 'oper', resource: 'rg'})
}

// aaa-common-storage-dev-rg
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource commonStorageDevRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefixes.commonStorage}${storageAccountIdentifiers.dev}-rg'
  location: location
  tags: union(baseTags.common, {domain: domains.storage, identifier: 'dev', resource: 'rg'})
}

var resourceGroupNames = {
  operNetworkRG: '${prefixes.operNetwork}-rg'
  operCompute: '${prefixes.operCompute}-rg'
  operVisual: '${prefixes.operVisual}-rg'
  devNetwork: '${prefixes.devNetwork}-rg'
  devCompute: '${prefixes.devCompute}-rg'
  commonKeyvault: '${prefixes.commonKeyvault}-rg'
  commonStoragePub: '${prefixes.commonStorage}-${storageAccountIdentifiers.pub}-rg'
  commonStorageOper: '${prefixes.commonStorage}-${storageAccountIdentifiers.oper}-rg'
  commonStorageDev: '${prefixes.commonStorage}-${storageAccountIdentifiers.dev}-rg'
}

output names object = resourceGroupNames
