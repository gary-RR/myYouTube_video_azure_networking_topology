type vmCommonSettingsType = {
  adminUsernam: string
  patchMode: string
  rebootSetting: string
}

param location string =resourceGroup().location
param appName string='cosmo'

param principalId string

param networkManagerName string='networkManager'

// Parameters for Static Spoke 1 Vnet and Subnets
param spoke1ProdVnetAddressPrefixe string= '10.2.0.0/16'
param spoke1FrontendSubnetName string = 'frontendSubnet'
param spoke1FrontendSubnetPrefix string = '10.2.1.0/24'
param spoke1BackendSubnetName string = 'backendSubnet'
param spoke1BackendSubnetPrefix string = '10.2.2.0/24'
param spoke1bGatewaySubnetName string = 'GatewaySubnet'
param spoke1bGatewaySubnetPrefix string = '10.2.3.0/24'


// Parameters for Static Spoke 2 Subnets Vnet and Subnets
param spoke2ProdVnetAddressPrefixe string= '10.3.0.0/16'
param spoke2FrontendSubnetName string = 'frontendSubnet'
param spoke2FrontendSubnetPrefix string = '10.3.1.0/24'
param spoke2BackendSubnetName string = 'backendSubnet'
param spoke2BackendSubnetPrefix string = '10.3.2.0/24'

// Parameters for Static Spoke 3 Vnet and Subnets Subnets
param spoke3ProdVnetAddressPrefixe string= '10.4.0.0/16'
param spoke3FrontendSubnetName string = 'frontendSubnet'
param spoke3FrontendSubnetPrefix string = '10.4.1.0/24'
param spoke3BackendSubnetName string = 'backendSubnet'
param spoke3BackendSubnetPrefix string = '10.4.2.0/24'


param sshVm1KeyName string
param sshVm2KeyName string
param sshVm3KeyName string

param vm1LinuxName string='vm1-spoke1'
param vm2LinuxName string='vm1-spoke2'
param vm3LinuxName string='vm1-spoke3'

param setupNsgRule bool = false

param vpnClientAddressPrefix string='172.16.201.0/24'
param createGateway bool=false

param vmCommonSettings vmCommonSettingsType = {
  adminUsernam: 'gary'
  patchMode: 'AutomaticByPlatform'
  rebootSetting: 'IfRequired'
}

module assignUserJoinActionRole './modules/create_join_action_role.bicep' = {
  name: 'assignUserJoinActionRole'
  params: {
    principalId: principalId
  }
}

module creatNsgForSpoke2VnetFroned './modules/create_nsg.bicep'= if (setupNsgRule) {  
  name: 'spoke2VnetFrontedendNsg-${location}'
    params: {
    resourceName:'spoke2VnetFrontedendNs'
    securityRulesName:'spoke2VnetFronedendNRulesName' 
    priority:110
    protocol:'Tcp'
    access:'Deny'
    direction:'Inbound'
    sourceAddressPrefix:'*' 
    sourcePortRange:'*'
    destinationAddressPrefix:'10.3.1.0/24'
    destinationPortRange:'22'
  }
}

var spoke1ProdSubnets = [
  {
    name: spoke1FrontendSubnetName
    prefix: spoke1FrontendSubnetPrefix
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }
  {
    name: spoke1BackendSubnetName
    prefix: spoke1BackendSubnetPrefix
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }  
  {
    name: spoke1bGatewaySubnetName
    prefix: spoke1bGatewaySubnetPrefix
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }    
]

var spoke2ProdSubnets = [
  {
    name: spoke2FrontendSubnetName
    prefix: spoke2FrontendSubnetPrefix
    nsgInfo:  {
      enable: setupNsgRule ? true : false
      nsgId: setupNsgRule ? creatNsgForSpoke2VnetFroned.outputs.nsgId : null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }
  {
    name: spoke2BackendSubnetName
    prefix: spoke2BackendSubnetPrefix
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }
]

var spoke3ProdSubnets = [
  {
    name: spoke3FrontendSubnetName
    prefix: spoke3FrontendSubnetPrefix
    nsgInfo:  {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }
  {
    name: spoke3BackendSubnetName
    prefix: spoke3BackendSubnetPrefix
    nsgInfo: {
      enable: false
      nsgId: null
    }
    deligationInfo: {
      enable: false
      delegations: [{}]
    }
  }
]

var spoke1ProdName= 'spoke1Prod-${appName}-${resourceNameSuffix}'
var spoke2ProdName= 'spoke2Prod-${appName}-${resourceNameSuffix}'
var spoke3ProdName= 'spoke3Prod-${appName}-${resourceNameSuffix}'

var resourceNameSuffix=uniqueString(resourceGroup().id)

var spokeVnetsInfo= [  
  {
    name: spoke1ProdName
    subnets: spoke1ProdSubnets
    prefix: spoke1ProdVnetAddressPrefixe
    tags: {}
  }
  {
    name: spoke2ProdName
    subnets: spoke2ProdSubnets
    prefix: spoke2ProdVnetAddressPrefixe
    tags: {}
  }
  {
    name: spoke3ProdName
    subnets: spoke3ProdSubnets
    prefix: spoke3ProdVnetAddressPrefixe
    tags: {}
  }
]

module createSpokeVnets './modules/create_spokes.bicep'= {
  name: 'createSpokeVnets'  
  params: {
    location: location
    spokeVnetsInfo: spokeVnetsInfo
  }
}

module createVpnGateway './modules/create_vpn_gateway.bicep' = if(createGateway) {
  name: 'createVpnGateway'
  params: {
    vpnClientAddressPrefix: vpnClientAddressPrefix
    appName: appName
    location: location
    vpnGatewaySubnetId: createSpokeVnets.outputs.aggregatedVnets[0].subnets[2].id
  }
  
}

// Define the vmsInfo array with VM-specific information
var vmsInfo = [
  {
    baseName: vm1LinuxName
    sshKeyName: sshVm1KeyName
  }
  {
    baseName: vm2LinuxName
    sshKeyName: sshVm2KeyName
  }
  {
    baseName: vm3LinuxName
    sshKeyName: sshVm3KeyName
  }
]

// Single module deployment using a loop over vmsInfo
module createVms './modules/create_vm.bicep' = [for (vmInfo, i) in vmsInfo: {
  name: '${vmInfo.baseName}-module'
  // scope: resourceGroup (uncomment if needed)
  params: {
    sshKeyName: vmInfo.sshKeyName
    vmCommonSettings: vmCommonSettings
    vmLinuxName: '${vmInfo.baseName}-${appName}-${resourceNameSuffix}'
    vnetName: createSpokeVnets.outputs.aggregatedVnets[i].vnetName
    location: location
  }
}]

module networkManager './modules/setup_network_manager.bicep' = {
  name: '${networkManagerName}-${appName}-${resourceNameSuffix}'
  scope: resourceGroup() 
  params: {
    location: location    
    staticVnetGroup: [
      createSpokeVnets.outputs.aggregatedVnets[0].vnetId
      createSpokeVnets.outputs.aggregatedVnets[1].vnetId
      createSpokeVnets.outputs.aggregatedVnets[2].vnetId
    ]
    
  }

}

//
// In order to deploy a Connectivity or Security configruation, the /commit endpoint must be called or a Deployment created in the Portal. 
// This DeploymentScript resource executes a PowerShell script which calls the /commit endpoint and monitors the status of the deployment.
//
module deploymentScriptConnectivityConfigs 'modules/deploy_script.bicep' = {
  name: 'ds-${location}-connectivityconfigs'
  scope: resourceGroup()  
  params: {
    location: location
    userAssignedIdentityId: networkManager.outputs.userAssignedIdentityId
    configurationId: networkManager.outputs.connectivityConfigurationId
    configType: 'Connectivity'
    networkManagerName: networkManager.outputs.networkManagerName
    deploymentScriptName: 'ds-${location}-connectivityconfigs'
  }
}

output vm1PrivateIPAddress string=createVms[0].outputs.vmPrivateIPAddress   //createSpoke1Vm1.outputs.vmPrivateIPAddress
output vm2PrivateIPAddress string=createVms[1].outputs.vmPrivateIPAddress 
output vm3PrivateIPAddress string=createVms[2].outputs.vmPrivateIPAddress  //createSpoke2Vm1.outputs.vmPrivateIPAddress
output vpnGateWayName string=createVpnGateway.outputs.vpnGateWayName
