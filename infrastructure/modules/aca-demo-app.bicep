param appname string
param location string
param envId string
param allowInsecure bool = false
param image string
param imageName string

resource academo 'Microsoft.App/containerApps@2022-03-01' = {
  name: appname
  location: location
  properties: {
    managedEnvironmentId: envId
    configuration: {
      ingress: {
        targetPort: 80
        external: true
        allowInsecure: allowInsecure
      }
    }
    template: {
      containers: [
        {
          image: image
          name: imageName
        } ]
      scale: {
        maxReplicas: 10
        minReplicas: 1
      }
    }
  }
}

output uri string = academo.properties.configuration.ingress.fqdn
