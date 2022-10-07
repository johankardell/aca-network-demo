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
        // id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancer.name, loadBalancer.properties.frontendIPConfigurations[0].name)
        // id: '/subscriptions/e03f77d0-d2dc-4b45-bd27-88a486ec5e19/resourceGroups/MC_gentlehill-7cc635dd-rg_gentlehill-7cc635dd_westeurope/providers/Microsoft.Network/loadBalancers/kubernetes/frontendIPConfigurations/5895a1a4-2fa5-4324-9874-f19810fb97b3'
        id: '/subscriptions/e03f77d0-d2dc-4b45-bd27-88a486ec5e19/resourceGroups/mc_wonderfulwater-79a18f17-rg_wonderfulwater-79a18f17_westeurope/providers/Microsoft.Network/loadBalancers/kubernetes-internal/frontendIPConfigurations/aa99c75e3435e42798668e6d2ec459b4'
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
