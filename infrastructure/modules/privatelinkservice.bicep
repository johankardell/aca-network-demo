param privatelinkServiceName string
param location string
// param loadBalancer object
param subnetId string

resource privatelinkService 'Microsoft.Network/privateLinkServices@2021-05-01' = {
  name: privatelinkServiceName
  location: location
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: '/subscriptions/e1dbaf8d-ccdb-4dc7-9cf3-a535fb2f98a8/resourceGroups/mc_gentlerock-74ef499f-rg_gentlerock-74ef499f_westeurope/providers/Microsoft.Network/loadBalancers/kubernetes-internal/frontendIPConfigurations/a1a27773a3f004ce2af9a565ab8cad69'
      }
    ]
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            // id: loadBalancer.properties.frontendIPConfigurations[0].properties.subnet.id
            id: subnetId
          }
          primary: false
        }
      }
    ]
  }
}

output id string = privatelinkService.id 
