param location string
param name string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output customerId string = logAnalyticsWorkspace.properties.customerId
output sharedKey string = listKeys(logAnalyticsWorkspace.id, '2020-03-01-preview').primarySharedKey
