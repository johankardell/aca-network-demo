targetScope = 'subscription'

param location string = 'swedencentral'
param publicKey string
param vmName string = 'vm-demo'
param adminUsername string = 'adminuser'
param rgName string = 'rg-aca-demo-v2'
param vnetName string = 'vnet-demo'
param acaName string = 'aca-demo'
param infraRg string = 'rg-aca-demo-v2-infra'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

module vnet 'modules/vnet.bicep' = {
  scope: resourceGroup
  name: 'vnet'
  params: {
    location: location
    vnetName: vnetName
  }
}

module vm 'modules/vm.bicep' = {
  scope: resourceGroup
  name: 'vm'
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    subnetId: vnet.outputs.vmSubnet
    publicKey: publicKey
  }
}

module logAnalytics 'modules/loganalytics.bicep' = {
  scope: resourceGroup
  name: 'loganalytics'
  params: {
    name: 'log-aca-network-demo'
    location: location
  }
}

module aca 'modules/aca.bicep' = {
  scope: resourceGroup
  name: 'aca'
  params: {
    location: location
    subnetId: vnet.outputs.acaSubnet
    laCustomerId: logAnalytics.outputs.customerId
    laSharedKey: logAnalytics.outputs.sharedKey
    envname: acaName
    infraRg: infraRg
  }
}
