param spokeVnetsInfo object[]
param location string

module createSokeVnets 'create_vnet.bicep' = [for vnet in spokeVnetsInfo: {
  name: vnet.name
  scope:resourceGroup()
  params: {
    subnets: vnet.subnets
    vnetAddressPrefixes: vnet.prefix
    vnetName: vnet.name
    location: location
    tags: vnet.tags
  }
}]

output aggregatedVnets array = [for i in range(0, length(spokeVnetsInfo)): {
  vnetName: spokeVnetsInfo[i].name
  subnets: createSokeVnets[i].outputs.subnets
  vnetId: createSokeVnets[i].outputs.vnetId
}]

