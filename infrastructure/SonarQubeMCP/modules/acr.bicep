targetScope = 'resourceGroup'

@description('Name of the Azure Container Registry for the SonarQube MCP image supply chain')
param acrName string

@description('Deployment location')
param location string = resourceGroup().location

@description('ACR SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrId string = acr.id
output acrName string = acr.name
