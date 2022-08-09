// params
param acrName string
param aksIdentityId string
param acrPrincipalId object

// vars
var acrPullRole = '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')}'

// resources acr
resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' existing = {
  name: acrName
}

// create role assignment acrPullRole to AKS nodepool's objectid to acr instance
resource aksAzureContainerRegistryRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
name: guid(acr.id, aksIdentityId, acrPullRole)
scope: acr
properties: {
  principalId: acrPrincipalId.objectId
  roleDefinitionId: acrPullRole
}
}
