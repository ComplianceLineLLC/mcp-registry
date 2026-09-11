targetScope = 'resourceGroup'

@description('Name of the existing shared VNet to create the delegated subnet in')
param vnetName string = 'clDEVvNET'

@description('Name of the new subnet, delegated to Microsoft.App/environments')
param subnetName string = 'SonarQubeMCP-Dev-Subnet'

@description('Address prefix for the new subnet')
param addressPrefix string = '20.0.3.160/27'

@description('Resource ID of the existing shared NSG to associate with the subnet')
param networkSecurityGroupId string = '/subscriptions/326c5c7f-73c8-4e8b-b146-d643c06ced0d/resourceGroups/RG-DEV-RouteTable/providers/Microsoft.Network/networkSecurityGroups/NSG-DEVSubscription'

@description('Resource ID of the existing shared route table to associate with the subnet')
param routeTableId string = '/subscriptions/326c5c7f-73c8-4e8b-b146-d643c06ced0d/resourceGroups/RG-DEV-RouteTable/providers/Microsoft.Network/routeTables/DEV-RouteTable'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: addressPrefix
    delegations: [
      {
        name: 'containerapps-delegation'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
    routeTable: {
      id: routeTableId
    }
  }
}

output subnetId string = subnet.id
