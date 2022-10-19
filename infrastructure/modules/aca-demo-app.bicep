param appname string
param location string
param envId string

resource academo 'Microsoft.App/containerApps@2022-03-01' = {
  name: appname
  location: location
  properties: {
    managedEnvironmentId: envId
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: 'helloworld'
        } ]
      scale: {
        maxReplicas: 10
        minReplicas: 1
      }
    }
  }
}

output uri string = academo.properties.configuration.ingress.fqdn
