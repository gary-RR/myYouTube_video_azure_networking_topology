type vmCommonSettingsType = {
  adminUsernam: string
  patchMode: string
  rebootSetting: string
}

param location string=resourceGroup().location
param sshKeyName string
param vnetName string
param vmCommonSettings vmCommonSettingsType
param vmLinuxName string
param dnsServers array = [
  '168.63.129.16'
]

var nicNameLinux='nic-${vmLinuxName}'
var frontendSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'frontendSubnet')

resource sshKey 'Microsoft.Compute/sshPublicKeys@2023-09-01' existing = {
  name: sshKeyName  
}

resource nicLinuxServer1 'Microsoft.Network/networkInterfaces@2020-06-01' =  {
  name: nicNameLinux
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vmLinuxName}vmip'
        properties: {
          privateIPAllocationMethod: 'Dynamic'          
          subnet: {
            id: frontendSubnetId //frontendSubnet.id
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: dnsServers
    }
  }  
}

resource ubuntuVM 'Microsoft.Compute/virtualMachines@2023-09-01' =  {
  name: vmLinuxName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2' // Choose an appropriate VM size
    }
    osProfile: {
      adminUsername: vmCommonSettings.adminUsernam      
      computerName: vmLinuxName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${vmCommonSettings.adminUsernam}/.ssh/authorized_keys'
              keyData: sshKey.properties.publicKey //adminPublicKey
            }
          ]
        }
        patchSettings: {
          patchMode: vmCommonSettings.patchMode
          automaticByPlatformSettings: {
            rebootSetting:vmCommonSettings.rebootSetting
          }
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicLinuxServer1.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output vmPrivateIPAddress string = nicLinuxServer1.properties.ipConfigurations[0].properties.privateIPAddress
output vmId string=ubuntuVM.id
output vmName string=ubuntuVM.name

