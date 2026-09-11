targetScope = 'resourceGroup'

@description('Name of the existing Container App to attach diagnostic settings to')
param containerAppName string

@description('Resource ID of the Log Analytics workspace to send logs/metrics to')
param logAnalyticsWorkspaceId string

resource containerApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: containerAppName
}

// Microsoft.App/containerApps only exposes the AllMetrics category via diagnostic settings —
// console/system logs are NOT valid here (confirmed via
// `az monitor diagnostic-settings categories list --resource-type Microsoft.App/containerApps`).
// Those log categories exist only on Microsoft.App/managedEnvironments, and are already covered
// by the environment's own appLogsConfiguration (see container-apps-environment.bicep) — adding
// them again here would just double-ingest the same logs into the same workspace.
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-sonarqube-mcp'
  scope: containerApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
