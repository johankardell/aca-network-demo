param location string
param vnetName string
param vnetAddressPrefix string
param subnet1Name string
param subnet1AddressPrefix string
param subnet2Name string
param subnet2AddressPrefix string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1AddressPrefix
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2AddressPrefix
        }
      }
    ]
  }
}

output subnets array = virtualNetwork.properties.subnets 
