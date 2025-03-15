@description('Custom Role Definition for Public IP Join Action')
param principalId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'PublicIPJoinRole')
  properties: {
    roleName: 'Public IP Join Role'
    description: 'Allows joining resources to a Public IP address'
    permissions: [
      {
        actions: [          
          'Microsoft.Network/virtualNetworks/subnets/write'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
          'Microsoft.Network/virtualNetworks/subnets/read'
          'Microsoft.Network/publicIPAddresses/join/action'
          'Microsoft.Network/publicIPAddresses/write'
          'Microsoft.Network/publicIPAddresses/read'
        ]
        notActions: []
      }
    ]
    assignableScopes: [      
      resourceGroup().id
    ]
  }
}

@description('Assign the custom role to a specific user')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'PublicIPJoinRoleAssignment', '${principalId}')
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: principalId  
    principalType: 'User'
  }
}
