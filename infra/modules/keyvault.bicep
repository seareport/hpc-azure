// Declare parameters
param basePrefix string
param location string
param subnetIds array
param adminPrincipalIds array
param userPrincipalIds array
param domains object
param baseTags object

var keyvaultAdministratorRole = '00482a5a-887f-4fb3-b363-3b7fe8e74483'
var keyvaultSecretsUserRole = '4633458b-17de-408a-b874-0445c86b69e6'

var keyvaltName = '${basePrefix}-kv'

// https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/2022-07-01/vaults?pivots=deployment-language-bicep
resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyvaltName
  location: location
  // XXX Adding tags throws an error for some reason...
  tags: union(baseTags, {domain: domains.keyvault, resource: 'kv'})
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    accessPolicies: []
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: [for subnetId in subnetIds: {
        id: subnetId
      }]
    }
    publicNetworkAccess: 'disabled'
  }
}



// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments?pivots=deployment-language-bicep
resource adminRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in adminPrincipalIds: if (empty(resourceId('Microsoft.Authorization/roleAssignments', guid(principalId, keyvaultAdministratorRole, keyvault.id)))) {
    name: guid(principalId, keyvaultAdministratorRole, keyvault.id)
    scope: keyvault
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyvaultAdministratorRole)
      principalId: principalId
    }
  }
] 

// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments?pivots=deployment-language-bicep
resource userRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in concat(adminPrincipalIds, userPrincipalIds): if (empty(resourceId('Microsoft.Authorization/roleAssignments', guid(principalId, keyvaultSecretsUserRole, keyvault.id)))) {
    name: guid(principalId, keyvaultSecretsUserRole, keyvault.id)
    scope: keyvault
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyvaultSecretsUserRole)
      principalId: principalId
    }
  }
]

output id string = keyvault.id
