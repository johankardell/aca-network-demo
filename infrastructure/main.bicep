targetScope = 'subscription'

var location = 'westeurope'
var rgName = 'aca-network-demo'
var rgNameService1 ='aca-network-demo-service1'
var rgNameService2 ='aca-network-demo-service2'

resource infrastructure 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

resource service1 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNameService1
  location: location
}

resource service2 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNameService2
  location: location
}

module hubVnet 'modules/vnet.bicep' = {
  name: 'vnet-hub'
  scope: resourceGroup(rgName)
  params: {
    location: location
    vnetName: 'vnet-hub'
    vnetAddressPrefix: '10.0.0.0/16'
    subnet1AddressPrefix: '10.0.0.0/24'
    subnet1Name: 'iaas'
    subnet2AddressPrefix: '10.0.1.0/24'
    subnet2Name: 'AzureBastionSubnet'
  }
}

module service1vnet 'modules/vnet.bicep' = {
  name: 'vnet-service1'
  scope: resourceGroup(rgName)
  params: {
    location: location
    vnetName: 'vnet-service1'
    vnetAddressPrefix: '10.1.0.0/16'
    subnet1AddressPrefix: '10.1.0.0/24'
    subnet1Name: 'iaas'
    subnet2AddressPrefix: '10.1.2.0/23'
    subnet2Name: 'aca'
  }
}

module service2vnet 'modules/vnet.bicep' = {
  name: 'vnet-service2'
  scope: resourceGroup(rgName)
  params: {
    location: location
    vnetName: 'vnet-service2'
    vnetAddressPrefix: '10.2.0.0/16'
    subnet1AddressPrefix: '10.2.0.0/24'
    subnet1Name: 'iaas'
    subnet2AddressPrefix: '10.2.2.0/23'
    subnet2Name: 'aca'
  }
}

module logAnalytics 'modules/loganalytics.bicep' = {
  scope: resourceGroup(rgName)
  name: 'loganalytics'
  params: {
    name: 'log-aca-network-demo'
    location: location
  }
}

module aca1 'modules/containerapp.bicep' = {
  scope: resourceGroup(rgNameService1)
  name: 'service1'
  params: {
    envname: 'aca-service1' 
    laCustomerId: logAnalytics.outputs.customerId
    laSharedKey: logAnalytics.outputs.sharedKey
    location: location
    subnetId: service1vnet.outputs.subnets[1].id
  }
}

module aca2 'modules/containerapp.bicep' = {
  scope: resourceGroup(rgNameService2)
  name: 'service2'
  params: {
    envname: 'aca-service2' 
    laCustomerId: logAnalytics.outputs.customerId
    laSharedKey: logAnalytics.outputs.sharedKey
    location: location
    subnetId: service2vnet.outputs.subnets[1].id
  }
}
