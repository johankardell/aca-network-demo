targetScope = 'subscription'

param location string = deployment().location
var rgName = 'aca-network-demo'
var rgNameService1 = 'aca-network-demo-service1'
var rgNameService2 = 'aca-network-demo-service2'
var rgNameService3 = 'aca-network-demo-service3'

@secure()
param publicKey string

resource infrastructureRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

resource service1RG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNameService1
  location: location
}

resource service2RG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNameService2
  location: location
}

resource service3RG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNameService3
  location: location
}

module hubVnet 'modules/vnet.bicep' = {
  name: 'vnet-hub'
  scope: infrastructureRG
  params: {
    location: location
    vnetName: 'vnet-hub'
    subnets: [
      {
        name: 'iaas'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
    vnetAddressPrefix: '10.0.0.0/16'
  }
}

module service1vnet 'modules/vnet.bicep' = {
  name: 'vnet-service1'
  scope: infrastructureRG
  params: {
    location: location
    vnetName: 'vnet-service1'
    vnetAddressPrefix: '172.16.0.0/16'
    subnets: [
      {
        name: 'iaas'
        properties: {
          addressPrefix: '172.16.0.0/24'
        }
      }
      {
        name: 'pls'
        properties: {
          addressPrefix: '172.16.1.0/24'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'aca'
        properties: {
          addressPrefix: '172.16.2.0/23'
        }
      }
    ]
  }
}

module service2vnet 'modules/vnet.bicep' = {
  name: 'vnet-service2'
  scope: infrastructureRG
  params: {
    location: location
    vnetName: 'vnet-service2'
    vnetAddressPrefix: '10.1.0.0/16'
    subnets: [
      {
        name: 'iaas'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
      {
        name: 'aca'
        properties: {
          addressPrefix: '10.1.2.0/23'
        }
      }
    ]
  }
}

module spoke2tohub 'modules/vnetpeering.bicep' = {
  scope: infrastructureRG
  name: 'spoke2tohub'
  params: {
    destinationVnet: hubVnet.outputs.vnetId
    sourceVnet: '${service2vnet.outputs.vnetName}/spoke2tohub'
  }
}

module hubtospoke2 'modules/vnetpeering.bicep' = {
  scope: infrastructureRG
  name: 'hubtospoke2'
  params: {
    destinationVnet: service2vnet.outputs.vnetId
    sourceVnet: '${hubVnet.outputs.vnetName}/hubtospoke2'
  }
}

module logAnalytics 'modules/loganalytics.bicep' = {
  scope: infrastructureRG
  name: 'loganalytics'
  params: {
    name: 'log-aca-network-demo'
    location: location
  }
}

module aca1 'modules/containerappEnvironment.bicep' = {
  scope: service1RG
  name: 'service1'
  params: {
    envname: 'aca-service1'
    laCustomerId: logAnalytics.outputs.customerId
    laSharedKey: logAnalytics.outputs.sharedKey
    location: location
    subnetId: service1vnet.outputs.subnets[2].id
  }
}

module demoappService1 'modules/aca-demo-app.bicep' = {
  scope: service1RG
  name: 'demoapp1'
  params: {
    appname: 'demoapp1'
    envId: aca1.outputs.id
    location: location
  }
}

module aca2 'modules/containerappEnvironment.bicep' = {
  scope: service2RG
  name: 'service2'
  params: {
    envname: 'aca-service2'
    laCustomerId: logAnalytics.outputs.customerId
    laSharedKey: logAnalytics.outputs.sharedKey
    location: location
    subnetId: service2vnet.outputs.subnets[1].id
  }
}

module aca3app 'modules/aca-demo-app.bicep' = {
  scope: service3RG
  name: 'aca3demoapp'
  params: {
    appname: 'aca3demoapp'
    envId: aca3.outputs.id
    location: location
  }
}

module aca3 'modules/containerappEnvironmentPublic.bicep' = {
  scope: service3RG
  name: 'service3'
  params: {
    envname: 'aca-service3'
    laCustomerId: logAnalytics.outputs.customerId
    laSharedKey: logAnalytics.outputs.sharedKey
    location: location
  }
}

module frontdoor 'modules/frontdoor.bicep' = {
  scope: service3RG
  name: 'fd-demo'
  params: {
    frontDoorProfileName: 'fd-aca3'
    frontDoorEndpointName: 'endpoint'
    frontDoorOriginGroupName: 'aca3-group'
    frontDoorOriginName: 'aca3'
    hostName: aca3app.outputs.uri
  }
}

module bastion 'modules/bastion.bicep' = {
  scope: infrastructureRG
  name: 'bastion'
  params: {
    bastionHostName: 'bastion'
    bastionSubnet: hubVnet.outputs.subnets[1].id
    location: location
    publicIpName: 'pip-bastion'
  }
}

module ubuntu 'modules/ubuntu.bicep' = {
  scope: infrastructureRG
  name: 'ubuntu'
  params: {
    location: location
    subnetid: hubVnet.outputs.subnets[0].id
    vmname: 'ubuntu'
    publicKey: publicKey
  }
}

module ubuntuSvc1 'modules/ubuntu.bicep' = {
  scope: service1RG
  name: 'ubuntuSvc1'
  params: {
    location: location
    subnetid: service1vnet.outputs.subnets[0].id
    vmname: 'ubuntu'
    publicKey: publicKey
  }
}

// resource acaLBService1 'Microsoft.Network/loadBalancers@2020-11-01' existing = {
//   scope: resourceGroup('MC_gentlehill-7cc635dd-rg_gentlehill-7cc635dd_westeurope')
//   name: 'kubernetes'
// }

// module plsService1 'modules/privatelinkservice.bicep' =  {
//   scope: resourceGroup(rgNameService1)
//   name: 'pls-aca-service1'
//   params: {
//     // loadBalancer: acaLBService1
//     location: location
//     privatelinkServiceName: 'pls-aca-service1'
//     subnetId: service1vnet.outputs.subnets[1].id
//   }
//   dependsOn: [
//     infrastructure
//     service1
//     service2
//     aca1
//   ]
// }

// module peService1 'modules/privateendpoint.bicep' = {
//   scope: resourceGroup(rgName)
//   name: 'pe-pls-service1'
//   params: {
//     location: location
//     privateEndpointName: 'pe-pls-service1'
//     privatelinkServiceId: plsService1.outputs.id
//     subnetId: hubVnet.outputs.subnets[0].id
//   }
//   dependsOn: [
//     infrastructure
//     service1
//     service2
//     aca1
//   ]
// }

/* TODO
 Front door with WAF
 AZFW basic in hub
 PLS in spoke1, exposing SLB for ACA. PE in hub.
 PE in spoke1, exposing cosmosdb in spoke2
 DNS zones for privatelink registered in hub for resolution
 Get the external LB for ACA dynamically (not hard coded magic strings)
*/
