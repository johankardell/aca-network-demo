param envname string
param location string
param laCustomerId string
param laSharedKey string
param subnetId string

resource acaenv 'Microsoft.App/managedEnvironments@2022-03-01' = {
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
      internal: true
    }
  }
}

output id string  = acaenv.id
