param location string = resourceGroup().location

// CLUSTER GENERAL PARAMS
@description('The name of the managed cluster resource.')
param aksClusterName string

@description('Version of Kubernetes specified when creating the managed cluster.')
param aksKubernetesVersion string = '1.23.8'

@description('The managed cluster SKU.')
param aksSku object = {
  name: 'Basic'
  tier: 'Free' // or 'Paid' for cluster with managementplane SLA
}

@description('AAD group object IDs that will have admin role of the cluster.')
param aksAadAdminGroupObjectIDs array = [
  '00000000-0000-0000-0000-000000000000'
]

@description('The name of Azure Container Registry instance')
param acrName string = 'myacrname'

@description('The name of Azure Container Registry resource group')
param acrRgName string = 'rg-shared'

@description('The name of Virtual Network resource group')
param netRgName string = 'rg-shared'

// DEFAULT AGENT POOL PARAMS
@description('Number of agents (VMs) to host docker containers. Allowed values must be in the range of 0 to 100 (inclusive) for user pools and in the range of 1 to 100 (inclusive) for system pools. The default value is 1.')
@minValue(0)
@maxValue(100)
param aksAgentPoolCount int = 5

@description('Size of agent VMs.')
param aksAgentPoolvmSize string = 'Standard_D8s_v3'

@description('OS Disk Size in GB to be used to specify the disk size for every machine in this master/agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified.')
param aksAgentOsDiskSizeGB int = 0

@description('ID of subnet in which AKS has its nodes')
param vnetSubnetID string  
param vnetName string = 'my-vnet'

// global vars
var tenantId = subscription().tenantId
var subscriptionId = subscription().subscriptionId
var uniqueSuffix = substring(uniqueString(subscriptionId), 1, 5)
var keyVaultCryptoServiceEncryptionUser = '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')}'
var monitoringMetricsPublisher = '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')}'
var reader = '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')}'

// aks vars
var aksNodeResourceGroup = 'rg-aks-${aksClusterName}${uniqueSuffix}'
var aksAgentPoolName = 'default'
var aksDnsPrefix = '${aksClusterName}${uniqueSuffix}'

// object names
var aksName = 'aks-${aksClusterName}${uniqueSuffix}'
var keyvaultName = 'kv-${aksClusterName}${uniqueSuffix}'
var diskEncKeyName = 'dek-${aksClusterName}${uniqueSuffix}'
var diskEncSetName = 'des-${aksClusterName}${uniqueSuffix}'
var logAnalyticsWorkspaceName = 'law-${aksClusterName}${uniqueSuffix}'
var uamiName = 'uami-${aksClusterName}${uniqueSuffix}'

// subnet vars
/*
var testingstage = {
  isdev : aksClusterName == 'dev2' ? otherRgRoleAssignmentNet.outputs.subnetdevelopment : null
  isstage : aksClusterName == 'stage2' ? otherRgRoleAssignmentNet.outputs.subnetstaging : null
  isprod : aksClusterName == 'prod2' ? otherRgRoleAssignmentNet.outputs.subnetprod : null
}
var vnetSubnetID = testingstage.isdev ?? testingstage.isstage ?? testingstage.isprod
*/

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyvaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    enablePurgeProtection: true
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource key 'Microsoft.KeyVault/vaults/keys@2019-09-01' = {
  name: '${kv.name}/${diskEncKeyName}'
  properties: {
    kty: 'RSA'
    keySize: 2048
  }
}

resource des 'Microsoft.Compute/diskEncryptionSets@2020-06-30' = {
  name: diskEncSetName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    activeKey: {
      keyUrl: key.properties.keyUriWithVersion
      sourceVault: {
        id: kv.id
      }
    }
  }
}

resource diskEncryptionSetRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(des.id, kv.id, keyVaultCryptoServiceEncryptionUser)
  scope: kv
  properties: {
    principalId: des.identity.principalId
    roleDefinitionId: keyVaultCryptoServiceEncryptionUser
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
/*
    workspaceCapping: {
      dailyQuotaGb: 1
    }
*/
  }
}

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uamiName
  location: location
}

resource aksDiskEncryptionSetRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(des.id, aksIdentity.id, reader)
  scope: des
  properties: {
    principalId: aksIdentity.properties.principalId
    roleDefinitionId: reader
  }
}


resource aks 'Microsoft.ContainerService/managedClusters@2022-04-01' = {
  name: aksName
  location: location
  dependsOn: [
    otherRgRoleAssignmentNet
  ]
  identity: {
    //type: 'SystemAssigned'
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksIdentity.id}': {}
    }
  }
  sku: aksSku
  properties: {
    kubernetesVersion: aksKubernetesVersion
    enableRBAC: true
    dnsPrefix: aksDnsPrefix
    agentPoolProfiles: [
      {
        name: aksAgentPoolName
        count: aksAgentPoolCount
        mode: 'System'
        vmSize: aksAgentPoolvmSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: false
        osDiskSizeGB: aksAgentOsDiskSizeGB
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        enableNodePublicIP: false
        vnetSubnetID: vnetSubnetID
      }
    ]
    /*servicePrincipalProfile: {
      clientId: 'msi'
    }*/
    nodeResourceGroup: aksNodeResourceGroup
    diskEncryptionSetID: des.id
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    aadProfile: {
      adminGroupObjectIDs: aksAadAdminGroupObjectIDs
      managed: true
    }
    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
        enabled: true
      }
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
    }
  }
}

resource aksMonitoringRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(aks.id, monitoringMetricsPublisher)
  scope: aks
  properties: {
    principalId: aks.properties.addonProfiles.omsagent.identity.objectId
    roleDefinitionId: monitoringMetricsPublisher
    principalType: 'ServicePrincipal'
  }
}

resource aksDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: aks
  name: 'logs2LA'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'kube-apiserver'
        enabled: false
      }
      {
        category: 'kube-audit'
        enabled: false
      }
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'kube-controller-manager'
        enabled: false
      }
      {
        category: 'kube-scheduler'
        enabled: false
      }
      {
        category: 'cluster-autoscaler'
        enabled: false
      }
      {
        category: 'guard'
        enabled: false
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: false
      }
    ]
  }
}


module otherRgRoleAssignment 'otherRgRoleAssignment.bicep' = {
  name: 'otherRgRoleAssignment'
  scope: resourceGroup(acrRgName) 
  params: {
    acrPrincipalId: aks.properties.identityProfile.kubeletidentity
    acrName: acrName
    aksIdentityId: aksIdentity.id
  }
}


module otherRgRoleAssignmentNet 'otherRgRoleAssignmentNet.bicep' = {
  name: 'otherRgRoleAssignmentNet'
  /*
  dependsOn: [
    aksIdentity
  ]
  */
  scope: resourceGroup(netRgName) 
  params: {
//    aksIdentityId: aksIdentity.id
    aksPrincipalId: aksIdentity.properties.principalId
//    kubeletPrincipalId: aks.properties.identityProfile.kubeletidentity
    vnetName: vnetName
    location: location
  }
}


module otherRgRoleAssignmentkv 'otherRgRoleAssignmentKv.bicep' = {
  name: 'otherRgRoleAssignmentKv'
  params: {
    agentPoolPrincipalId: aks.properties.identityProfile.kubeletidentity
    aksIdentityId: aksIdentity.properties.principalId
    kvName: keyvaultName
  }
}



module aksPip 'akspip.bicep' = {
  name: 'aksPip'
  dependsOn: [
    aks
    //aksIdentity
  ]
  scope: resourceGroup(aksNodeResourceGroup) 
  params: {
    principalId: aksIdentity.properties.principalId
    aksClusterName: aksClusterName
    aksIdentityId: aksIdentity.id
    location: location
  }
}


output aksResourceGroup string = resourceGroup().name
output aksName string = aksName
output kvName string = keyvaultName
output aksNodeResourceGroup string = aksNodeResourceGroup
output aksPip string = aksPip.outputs.aksPip
