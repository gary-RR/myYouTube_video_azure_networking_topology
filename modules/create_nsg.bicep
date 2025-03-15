param location string=resourceGroup().location
param resourceName string
param securityRulesName string
param priority int=110
param protocol string='Tcp'
param access string='Deny'
param direction string='Inbound'
param sourceAddressPrefix string='*' 
param sourcePortRange string='*'
param destinationAddressPrefix string='10.3.1.0/24'
param destinationPortRange string='22'

resource nsgDenySshAccessToSubnet 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: '${resourceName}-${location}'
  location: location
  properties: {
    securityRules: [
      {
        name: securityRulesName
        properties: {
          priority: priority
          protocol: protocol
          access:  access
          direction: direction
          sourceAddressPrefix: sourceAddressPrefix 
          sourcePortRange: sourcePortRange
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: destinationPortRange         
        }
      }
    ]
  }
}

output nsgId string=nsgDenySshAccessToSubnet.id
output nsgObject object=nsgDenySshAccessToSubnet
