param privateEndpointName string
param location string
param subnetId string
param privatelinkServiceId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privatelinkServiceId
        }
      }
    ]
  }
}
