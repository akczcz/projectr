// params
param aksPrincipalId string
param vnetName string
param location string

// vars
var netContributorRole = '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')}'

// resources Virtual Network
//resource net 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
//  name: vnetName
//}

// create role assignment acrPullRole to AKS nodepool's objectid to acr instance
resource aksVirtualNetworkRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
name: guid(net.id, aksPrincipalId, netContributorRole)
scope: net
properties: {
  principalId: aksPrincipalId
  roleDefinitionId: netContributorRole
  }
}

resource net 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  tags: {}
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: 'aks-development'
        properties: {
          addressPrefix: '10.2.24.0/21'
          privateEndpointNetworkPolicies: 'enabled'
          privateLinkServiceNetworkPolicies: 'enabled'
        }
      }
      {
        name: 'aks-staging'
        properties: {
          addressPrefix: '10.2.32.0/21'
          privateEndpointNetworkPolicies: 'enabled'
          privateLinkServiceNetworkPolicies: 'enabled'
        }
      }
      {
        name: 'aks-prod'
        properties: {
          addressPrefix: '10.2.40.0/21'
          privateEndpointNetworkPolicies: 'enabled'
          privateLinkServiceNetworkPolicies: 'enabled'
        }
      }

    ]
  }
}

// Outputs
output subnetdevelopment string = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetName, 'aks-development')
output subnetstaging string = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetName, 'aks-staging')
output subnetprod string = resourceId('Microsoft.Network/VirtualNetworks/subnets', vnetName, 'aks-prod')
