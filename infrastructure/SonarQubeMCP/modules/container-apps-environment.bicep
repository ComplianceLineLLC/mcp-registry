targetScope = 'resourceGroup'

@description('Name of the Container Apps Environment')
param environmentName string = 'cae-sonarqube-mcp-dev'

@description('Deployment location')
param location string = resourceGroup().location

@description('Resource ID of the delegated subnet for this environment (lives in a different resource group — see infrastructure/SonarQubeMCP/modules/networking.bicep)')
param subnetId string

@description('Name of the existing Log Analytics workspace to send environment logs to')
param logAnalyticsWorkspaceName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: subnetId
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

output environmentId string = containerAppsEnvironment.id
output environmentDefaultDomain string = containerAppsEnvironment.properties.defaultDomain
