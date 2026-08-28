targetScope = 'resourceGroup'

@description('Name of the existing Container Apps Environment to attach diagnostic settings to')
param environmentName string

@description('Resource ID of the Log Analytics workspace to send logs to')
param logAnalyticsWorkspaceId string

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
}

// Platform-level logs (not app-level) - HTTPLogs shows what Azure's own edge proxy saw for
// each request; SystemLogs shows environment-level events like provisioning and scaling.
// Distinct from modules/diagnostic-settings.bicep, which only covers the Container App's
// AllMetrics (that resource type doesn't expose log categories at all - confirmed via
// `az monitor diagnostic-settings categories list` during the 2026-08-26 investigation).
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-sonarqube-mcp-env'
  scope: environment
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerAppHTTPLogs'
        enabled: true
      }
      {
        category: 'ContainerAppSystemLogs'
        enabled: true
      }
    ]
  }
}
