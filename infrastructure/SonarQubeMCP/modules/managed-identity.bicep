targetScope = 'resourceGroup'

@description('Name of the user-assigned managed identity for the SonarQube MCP Container App')
param identityName string = 'ethico-sonarqube-mcp-mi-dev'

@description('Deployment location')
param location string = resourceGroup().location

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output identityId string = identity.id
output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
