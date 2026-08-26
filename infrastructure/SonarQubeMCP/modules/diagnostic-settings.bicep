targetScope = 'resourceGroup'

@description('Name of the existing Container App to attach diagnostic settings to')
param containerAppName string

@description('Resource ID of the Log Analytics workspace to send logs/metrics to')
param logAnalyticsWorkspaceId string

resource containerApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: containerAppName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-sonarqube-mcp'
  scope: containerApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
      }
      {
        category: 'ContainerAppSystemLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
