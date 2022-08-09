// Params
param location string //= resourceGroup().location
param principalId string
param aksIdentityId string
@description('The name of the managed cluster resource.')
param aksClusterName string


// Var
var subscriptionId = subscription().subscriptionId
var uniqueSuffix = substring(uniqueString(subscriptionId), 1, 5)
var publicIP = 'ip-${aksClusterName}${uniqueSuffix}'
var contributor = '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')}'

// Resources
resource publicIp 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: publicIP
  location: location
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'    
  }
}

resource aksIdentityIpRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(publicIp.id, aksIdentityId, contributor)
  scope: publicIp
  properties: {
    principalId: principalId
    roleDefinitionId: contributor
    principalType: 'ServicePrincipal'
  }
}

output aksPip string = publicIp.properties.ipAddress
