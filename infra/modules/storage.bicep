// Declare parameters
param basePrefix string
param identifier string
param location string
param subnetIds array
param domains object
param baseTags object
param readerPrincipals array
param contributorPrincipals array

var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageBlobDataReaderRoleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'

var storageAccountName = '${replace(basePrefix, '-', '')}${identifier}sa'

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/2022-09-01/storageaccounts?pivots=deployment-language-bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: union(baseTags, {domain: domains.storage, identifier: identifier, resource: 'sa'})
  properties: {
    accessTier: 'Hot'                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    allowBlobPublicAccess: false
    isHnsEnabled: true
    isNfsV3Enabled: true
    minimumTlsVersion: 'TLS1_2' 
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: [for subnetId in subnetIds: {
        id: subnetId
      }]
    }
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments?pivots=deployment-language-bicep
resource storageBlobDataContributorRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in contributorPrincipals: {
    name: guid(principalId, storageBlobDataContributorRoleId, storageAccount.id)
    scope: storageAccount
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
      principalId: principalId
      // principalType: 'User'
    }
  }
]

// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments?pivots=deployment-language-bicep
resource storageBlobDataReaderRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in readerPrincipals: {
    name: guid(principalId, storageBlobDataReaderRoleId, storageAccount.id)
    scope: storageAccount
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataReaderRoleId)
      principalId: principalId
      // principalType: 'User'
    }
  }
]
