param envname string
param location string
param laCustomerId string
param laSharedKey string
param subnetId string
param infraRg string
resource acaenv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: envname
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: laCustomerId
        sharedKey: laSharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: subnetId
      internal: false
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    infrastructureResourceGroup: infraRg
  }
}

resource aca 'Microsoft.App/containerApps@2023-05-01' = {
  name: envname
  location: location
  properties: {
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: true
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/k8se/quickstart:latest'
          name: 'simple-hello-world-container'
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
    managedEnvironmentId: acaenv.id
  }
}

// output id string  = acaenv.id
// output defaultDomain string = acaenv.properties.defaultDomain
