targetScope = 'resourceGroup'

@description('Name of the Action Group')
param actionGroupName string = 'ag-sonarqube-mcp-dev'

@description('Short name for the Action Group (max 12 chars, shown in SMS/notifications)')
@maxLength(12)
param actionGroupShortName string = 'sqmcpalert'

@description('Email address to notify - a distribution group, membership may change over time')
param notificationEmail string = 'ethico-infra@ethico.com'

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: [
      {
        name: 'InfraDistributionGroup'
        emailAddress: notificationEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
