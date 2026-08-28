targetScope = 'resourceGroup'

@description('Name of the scheduled query rule')
param alertName string = 'alert-sonarqube-mcp-error-logs'

@description('Deployment location')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace to query')
param logAnalyticsWorkspaceId string

@description('Resource ID of the Action Group to notify')
param actionGroupId string

// Queries ContainerAppConsoleLogs_CL - the legacy custom-log table fed by the environment's
// appLogsConfiguration (task #4), confirmed to have real data flowing. The app's own log
// format uses "INFO"/"WARN" prefixes (confirmed from its startup logs), so "ERROR" is the
// consistent marker to watch for.
resource errorLogAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: alertName
  location: location
  properties: {
    displayName: 'SonarQube MCP - Error-level log entries'
    description: 'Fires when the SonarQube MCP container logs an ERROR-level entry'
    severity: 2
    enabled: true
    scopes: [
      logAnalyticsWorkspaceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'ContainerAppConsoleLogs_CL | where Log_s contains "ERROR"'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroupId
      ]
    }
  }
}
