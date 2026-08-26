targetScope = 'resourceGroup'

@description('Name of the Log Analytics workspace for the SonarQube MCP Container Apps Environment')
param workspaceName string = 'law-sonarqube-mcp-dev'

@description('Deployment location')
param location string = resourceGroup().location

@description('Data retention in days')
param retentionInDays int = 30

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

output workspaceId string = logAnalytics.id
output workspaceName string = logAnalytics.name
