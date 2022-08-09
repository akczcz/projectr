// params
param kvName string
param agentPoolPrincipalId object
param aksIdentityId string

// vars
var keyVaultSecretsUser = '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')}'

// resources
resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
}

resource kvSecretAgentPoolRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kv.id, agentPoolPrincipalId.objectId, keyVaultSecretsUser)
  scope: kv
  properties: {
    principalId: agentPoolPrincipalId.objectId
    roleDefinitionId: keyVaultSecretsUser
  }
}

resource kvSecretRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kv.id, aksIdentityId, keyVaultSecretsUser)
  scope: kv
  properties: {
    principalId: aksIdentityId
    roleDefinitionId: keyVaultSecretsUser
  }
}
