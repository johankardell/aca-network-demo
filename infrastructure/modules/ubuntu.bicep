param location string
param vmname string
param subnetid string
param adminUsername string = 'azureuser'
param publicKey string
param enablePublicIp bool = false

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = if (enablePublicIp) {
  name: 'pip-${vmname}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-${vmname}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress : enablePublicIp ?  {
            id: publicIPAddress.id
          } : null
          subnet: {
            id: subnetid
          }
        }
      }
    ]
  }
}


resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmname
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    osProfile: {
      computerName: vmname
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: publicKey
              path: '/home/${adminUsername}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        name: 'name'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
