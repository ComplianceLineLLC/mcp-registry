targetScope = 'subscription'

@description('Name of the resource group hosting the SonarQube MCP Server')
param resourceGroupName string = 'rg-ethico-sonarqube-mcp-dev'

@description('Deployment location')
param location string = 'eastus'

@description('Name of the Azure Container Registry for the SonarQube MCP image supply chain')
param acrName string = 'ethicosonarqubecrdev'

@description('ACR SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSkuName string = 'Basic'

@description('Name of the user-assigned managed identity for the SonarQube MCP Container App')
param identityName string = 'ethico-sonarqube-mcp-mi-dev'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

module acr 'modules/acr.bicep' = {
  name: 'deploy-acr'
  scope: rg
  params: {
    acrName: acrName
    location: location
    skuName: acrSkuName
  }
}

module managedIdentity 'modules/managed-identity.bicep' = {
  name: 'deploy-managed-identity'
  scope: rg
  params: {
    identityName: identityName
    location: location
  }
}

module acrRoleAssignment 'modules/acr-role-assignment.bicep' = {
  name: 'deploy-acr-role-assignment'
  scope: rg
  params: {
    acrName: acrName
    principalId: managedIdentity.outputs.principalId
  }
}

output acrLoginServer string = acr.outputs.acrLoginServer
output acrId string = acr.outputs.acrId
output managedIdentityId string = managedIdentity.outputs.identityId
output managedIdentityClientId string = managedIdentity.outputs.clientId
