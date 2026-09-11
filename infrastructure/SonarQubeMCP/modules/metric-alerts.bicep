targetScope = 'resourceGroup'

@description('Name of the Container App to monitor')
param containerAppName string

@description('Resource ID of the Container App to monitor')
param containerAppId string

@description('Resource ID of the Action Group to notify')
param actionGroupId string

@description('CPU percentage threshold to alert on')
param cpuThreshold int = 80

@description('Memory percentage threshold to alert on')
param memoryThreshold int = 80

// Three separate alert rules rather than one multi-criteria rule - Azure metric alert
// criteria under "allOf" require ALL conditions to breach simultaneously to fire, which
// isn't what we want for "CPU high OR memory high OR a restart happened".

resource restartCountAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${containerAppName}-restarts'
  location: 'global'
  properties: {
    description: 'Fires when the SonarQube MCP Container App restarts a replica'
    severity: 2
    enabled: true
    scopes: [
      containerAppId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'RestartCountCriterion'
          metricName: 'RestartCount'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
          dimensions: []
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${containerAppName}-cpu'
  location: 'global'
  properties: {
    description: 'Fires when the SonarQube MCP Container App CPU usage exceeds the threshold'
    severity: 2
    enabled: true
    scopes: [
      containerAppId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CpuCriterion'
          metricName: 'CpuPercentage'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: cpuThreshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          dimensions: []
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

resource memoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${containerAppName}-memory'
  location: 'global'
  properties: {
    description: 'Fires when the SonarQube MCP Container App memory usage exceeds the threshold'
    severity: 2
    enabled: true
    scopes: [
      containerAppId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'MemoryCriterion'
          metricName: 'MemoryPercentage'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: memoryThreshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          dimensions: []
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}
