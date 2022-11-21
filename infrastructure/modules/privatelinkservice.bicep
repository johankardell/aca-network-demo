param privatelinkServiceName string
param location string
param acaEnvDefaultDomain string
param subnetId string

var uniqueName = split(acaEnvDefaultDomain,'.')[0]

resource acaLBService1 'Microsoft.Network/loadBalancers@2020-11-01' existing = {
  scope: resourceGroup('MC_${uniqueName}-rg_${uniqueName}_${location}')
  name: 'kubernetes-internal'
}

resource privatelinkService 'Microsoft.Network/privateLinkServices@2021-05-01' = {
  name: privatelinkServiceName
  location: location
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: acaLBService1.properties.frontendIPConfigurations[0].id
      }
    ]
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: subnetId
          }
          primary: false
        }
      }
    ]
  }
}

output id string = privatelinkService.id 
