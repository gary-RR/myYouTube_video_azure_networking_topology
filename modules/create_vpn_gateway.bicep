param location string=resourceGroup().location
param appName string
param vpnGatewaySubnetId string
param vpnClientAddressPrefix string

var tenanatID=subscription().tenantId
// The following returns "https://login.microsoftonline.com" which is a best practice raher hard coding it
var aadTenantURL=environment().authentication.loginEndpoint
var aadTenant='${aadTenantURL}${tenanatID}'

var aadIssuer='https://sts.windows.net/${tenanatID}/'

// Audience: The Application ID of the "Azure VPN" Microsoft Entra Enterprise App.
// Azure Public: 41b23e61-6c1e-4545-b367-cd054e0ed4b4
// Azure Government: 51bb15d4-3a4f-4ebf-9dca-40096fe32426
// Azure Germany: 538ee9e6-310a-468d-afef-ea97365856a9
// Microsoft Azure operated by 21Vianet: 49f817b6-84ae-4cc0-928c-73f27289b3aa
var aadAudience='41b23e61-6c1e-4545-b367-cd054e0ed4b4'

var resourceNameSuffix=uniqueString(resourceGroup().id)

var gatewayPublicIPName='pip-gateway-${appName}-${resourceNameSuffix}'
var vpnGateWayName='vpn-${appName}-${resourceNameSuffix}'

resource gatewayPublicAddress 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: gatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'  
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: vpnGateWayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'        
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: gatewayPublicAddress.id
          }
          subnet: {
            id: vpnGatewaySubnetId  
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    enableBgp: false
    activeActive: false
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPrefix 
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      vpnClientRootCertificates: []
      vpnClientRevokedCertificates: []      
      radiusServers: []
      vpnClientIpsecPolicies: []
      aadTenant: aadTenant
      aadAudience: aadAudience
      aadIssuer: aadIssuer
    }    
  }
}


output gatewayId string = vpnGateway.id
output vpnGateWayName string=vpnGateWayName



