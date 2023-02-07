param frontDoorEndpointName string
param frontDoorProfileName string
param frontDoorOriginGroupNameACA string
param frontDoorOriginNameACA string
param frontDoorOriginGroupNameNGINX string
param frontDoorOriginNameNGINX string
param hostNameACA string
param hostNameNGINX string
param wafpolicyName string
param location string
param privateLinkId string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroupACA 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupNameACA
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource frontDoorOriginGroupNGINX 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupNameNGINX
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource frontDoorOriginACA 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginNameACA
  parent: frontDoorOriginGroupACA
  properties: {
    hostName: hostNameACA
    httpPort: 80
    httpsPort: 443
    originHostHeader: hostNameACA
    priority: 1
    weight: 1000
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkId
      }
      privateLinkLocation: location
      requestMessage: 'aca'
    }
  }
}

resource frontDoorOriginNGINX 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginNameNGINX
  parent: frontDoorOriginGroupNGINX
  properties: {
    hostName: hostNameNGINX
    httpPort: 80
    httpsPort: 443
    originHostHeader: hostNameNGINX
    priority: 1
    weight: 1000
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkId
      }
      privateLinkLocation: location
      requestMessage: 'nginx'
    }
  }
}

resource frontDoorRouteACA 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'aca'
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOriginACA // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroupACA.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/aca'
      '/aca/*'

    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    originPath: '/'
  }
}

resource frontDoorRouteNGINX 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'nginx'
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOriginNGINX // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroupNGINX.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/nginx'
      '/nginx/*'

    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    originPath: '/'
  }
}


resource wafpolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: wafpolicyName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    managedRules: {
      managedRuleSets: [
        {
          ruleSetAction: 'Block'
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
        {
          ruleSetAction: 'Block'
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2022-05-01-preview' = {
  parent: frontDoorProfile
  name: 'secpolicy'
  properties: {
    parameters:{
      type: 'WebApplicationFirewall'
      associations: [
        {
          domains:[
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
        ]
        }
      ]
      wafPolicy: {
        id: wafpolicy.id
      }
    }
  }
}
