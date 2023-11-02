targetScope = 'subscription'

param location string = deployment().location
var rgName = 'aca-network-demo'
var rgNameService1 = 'aca-network-demo-service1'
var rgNameService2 = 'aca-network-demo-service2'
var rgNameService3 = 'aca-network-demo-service3'

@secure()
param publicKey string

param myIp string

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

// Shared networking components

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
    myIp: myIp
  }
}

// Shared log analytics

module logAnalytics 'modules/loganalytics.bicep' = {
  scope: infrastructureRG
  name: 'loganalytics'
  params: {
    name: 'log-aca-network-demo'
    location: location
  }
}

// Demo1

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
  name: 'containerapps-helloworld'
  params: {
    appname: 'containerapps-helloworld'
    envId: aca1.outputs.id
    location: location
    allowInsecure: true
    image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    imageName: 'containerapps-helloworld'
  }
}

module aca1helloworld 'modules/aca-demo-app.bicep' = {
  scope: service1RG
  name: 'nginx-helloworld'
  params: {
    appname: 'nginx-helloworld'
    envId: aca1.outputs.id
    location: location
    image: 'nginxdemos/hello'
    imageName: 'helloworld'
  }
}

module frontdoorSvc1 'modules/frontdoorPrivateLink.bicep' = {
  scope: service1RG
  name: 'fd-aca1'
  params: {
    frontDoorProfileName: 'fd-aca1'
    frontDoorEndpointName: 'aca1endpoint'
    frontDoorOriginGroupNameACA: 'aca1-group'
    frontDoorOriginNameACA: 'aca1'
    frontDoorOriginGroupNameNGINX: 'nginx-group'
    frontDoorOriginNameNGINX: 'nginx'
    hostNameACA: demoappService1.outputs.uri
    hostNameNGINX: aca1helloworld.outputs.uri
    location: location
    wafpolicyName: 'acahelloworldwaf'
    privateLinkId: plsService1.outputs.id
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
    myIp: myIp
  }
}

module plsService1 'modules/privatelinkservice.bicep' =  {
  scope: resourceGroup(rgNameService1)
  name: 'pls-aca-service1'
  params: {
    acaEnvDefaultDomain: aca1.outputs.defaultDomain
    location: location
    privatelinkServiceName: 'pls-aca-service1'
    subnetId: service1vnet.outputs.subnets[1].id
  }
}

module peService1 'modules/privateendpoint.bicep' = {
  scope: resourceGroup(rgName)
  name: 'pe-pls-service1'
  params: {
    location: location
    privateEndpointName: 'pe-pls-service1'
    privatelinkServiceId: plsService1.outputs.id
    subnetId: hubVnet.outputs.subnets[0].id
  }
}

// Demo 2

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

module demoappService2 'modules/aca-demo-app.bicep' = {
  scope: service2RG
  name: 'demoapp2'
  params: {
    appname: 'demoapp2'
    envId: aca2.outputs.id
    location: location
    allowInsecure: true
    image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    imageName: 'containerapps-helloworld'
  }
}

// Demo 3

module aca3app 'modules/aca-demo-app.bicep' = {
  scope: service3RG
  name: 'aca3demoapp'
  params: {
    appname: 'aca3demoapp'
    envId: aca3.outputs.id
    location: location
    image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    imageName: 'containerapps-helloworld'
  }
}

module aca3helloworld 'modules/aca-demo-app.bicep' = {
  scope: service3RG
  name: 'aca3helloworld'
  params: {
    appname: 'aca3helloworld'
    envId: aca3.outputs.id
    location: location
    image: 'nginxdemos/hello'
    imageName: 'nginx-helloworld'
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
    frontDoorEndpointName: 'aca3'
    frontDoorOriginGroupName: 'aca3-group'
    frontDoorOriginName: 'aca3'
    hostName: aca3app.outputs.uri
  }
}


/* TODO
 AZFW basic in hub (Default route not supported for ACA)
 Diagnostic logs from WAF -> log analytics
 PLS in spoke1, exposing SLB for ACA. PE in hub.
 PE in spoke1, exposing cosmosdb in spoke2
 DNS zones for privatelink registered in hub for resolution
*/
