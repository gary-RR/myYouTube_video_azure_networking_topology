param networkManagerName string='networkManager'
param location string
param staticVnetGroup array
param staticManagedGroupVnetName string='staticGroup'
param networkManagerConConfigName string='mesh'
param appName string='cosmo'
param managedDeploymentUserName string='meshDeployer'

// Network contributor role
var networkContributoreRoleId=subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
var resourceNameSuffix=uniqueString(resourceGroup().id)

resource networkManager 'Microsoft.Network/networkManagers@2024-01-01'={
  name:  '${networkManagerName}-${appName}-${resourceNameSuffix}'
  location: location
  properties: {
    networkManagerScopeAccesses: [
      'Connectivity'
    ]
    
    networkManagerScopes: {
      subscriptions: [
        '/subscriptions/${subscription().subscriptionId}'
      ]
      managementGroups: []
    }
    
  }
}

resource vnetStaticManagedGroups 'Microsoft.Network/networkManagers/networkGroups@2024-01-01'= {
  name: '${staticManagedGroupVnetName}-${appName}-${resourceNameSuffix}'
  parent: networkManager
  properties: {
    description: 'nanually managed Vnet group'
  }

  resource statciMember 'staticMembers@2024-01-01'=[for member in staticVnetGroup:{
     name: 'sm-${(last(split(member, '/')))}'

     properties: {
       resourceId: member
     }

  }]
}


resource networkManagerConConfig 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-01-01' ={
  name: networkManagerConConfigName
  parent: networkManager  

  properties: {
    appliesToGroups: [{
      groupConnectivity: 'DirectlyConnected'
      networkGroupId: vnetStaticManagedGroups.id
      isGlobal: 'False'           
    }
    
    ]
       
    connectivityTopology: 'Mesh'
    deleteExistingPeering: 'True'
    isGlobal: 'False'
    description: 'Mesh confguration settings.'
  }
}


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${managedDeploymentUserName}-${appName}'
  location: location 
  
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, managedIdentity.name)
  properties: {
    roleDefinitionId: networkContributoreRoleId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output networkManagerName string = networkManager.name
output userAssignedIdentityId string = managedIdentity.id
output connectivityConfigurationId string = networkManagerConConfig.id
output networkGroupId string = vnetStaticManagedGroups.id
