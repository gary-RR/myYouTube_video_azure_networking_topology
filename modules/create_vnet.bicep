type subnetType = {
  name: string
  prefix: string  
}

param location string=resourceGroup().location
param vnetName string
param vnetAddressPrefixes string
param subnets object[] 
param tags object ={}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefixes
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: union({
        addressPrefix: subnet.prefix
      }, subnet.nsgInfo.enable ? {
        networkSecurityGroup: {
          id: subnet.nsgInfo.nsgId
        }
      } : {}, subnet.deligationInfo.enable ? {       
        delegations: subnet.deligationInfo.delegations
      } : {})
    }]
  }
}


output vnetName string=vnet.name 
output vnetId string = vnet.id
output subnets object[]=vnet.properties.subnets

