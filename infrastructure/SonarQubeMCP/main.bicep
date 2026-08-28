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

@description('Name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string = 'law-sonarqube-mcp-dev'

@description('Resource ID of the delegated subnet created in task #2 (lives in RG-PolicyManagement, not this resource group)')
param subnetId string = '/subscriptions/326c5c7f-73c8-4e8b-b146-d643c06ced0d/resourceGroups/RG-PolicyManagement/providers/Microsoft.Network/virtualNetworks/clDEVvNET/subnets/SonarQubeMCP-Dev-Subnet'

@description('Name of the Container Apps Environment')
param containerAppsEnvironmentName string = 'cae-sonarqube-mcp-dev'

@description('Name of the Container App')
param containerAppName string = 'ca-sonarqube-mcp-dev'

@description('Digest-pinned SonarQube MCP image reference, promoted in task #3')
param imageDigest string = 'sha256:edf80a38956d7d8de75166c1ae173b73c8a01a9a62038232ce0b75ead7dc450c'

@description('SonarQube Server URL')
param sonarQubeUrl string = 'https://sqdev.mycompliancemanagement.com'

@description('Minimum Container App replica count')
param minReplicas int = 1

@description('Maximum Container App replica count')
param maxReplicas int = 2

@description('Name of the Action Group for monitoring alerts')
param actionGroupName string = 'ag-sonarqube-mcp-dev'

@description('Email address (or distribution group) to notify on alerts')
param notificationEmail string = 'ethico-infra@ethico.com'

@description('CPU percentage threshold to alert on')
param cpuThreshold int = 80

@description('Memory percentage threshold to alert on')
param memoryThreshold int = 80

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

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'deploy-log-analytics'
  scope: rg
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
  }
}

module containerAppsEnvironment 'modules/container-apps-environment.bicep' = {
  name: 'deploy-container-apps-environment'
  scope: rg
  params: {
    environmentName: containerAppsEnvironmentName
    location: location
    subnetId: subnetId
    logAnalyticsWorkspaceName: logAnalytics.outputs.workspaceName
  }
}

module containerApp 'modules/container-app.bicep' = {
  name: 'deploy-container-app'
  scope: rg
  params: {
    containerAppName: containerAppName
    location: location
    environmentId: containerAppsEnvironment.outputs.environmentId
    acrLoginServer: acr.outputs.acrLoginServer
    imageDigest: imageDigest
    managedIdentityId: managedIdentity.outputs.identityId
    sonarQubeUrl: sonarQubeUrl
    minReplicas: minReplicas
    maxReplicas: maxReplicas
  }
}

module diagnosticSettings 'modules/diagnostic-settings.bicep' = {
  name: 'deploy-diagnostic-settings'
  scope: rg
  params: {
    containerAppName: containerAppName
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
  dependsOn: [
    containerApp
  ]
}

module environmentDiagnosticSettings 'modules/environment-diagnostic-settings.bicep' = {
  name: 'deploy-environment-diagnostic-settings'
  scope: rg
  params: {
    environmentName: containerAppsEnvironmentName
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
  dependsOn: [
    containerAppsEnvironment
  ]
}

module actionGroup 'modules/action-group.bicep' = {
  name: 'deploy-action-group'
  scope: rg
  params: {
    actionGroupName: actionGroupName
    notificationEmail: notificationEmail
  }
}

module metricAlerts 'modules/metric-alerts.bicep' = {
  name: 'deploy-metric-alerts'
  scope: rg
  params: {
    containerAppName: containerAppName
    containerAppId: containerApp.outputs.containerAppId
    actionGroupId: actionGroup.outputs.actionGroupId
    cpuThreshold: cpuThreshold
    memoryThreshold: memoryThreshold
  }
}

module logAlert 'modules/log-alert.bicep' = {
  name: 'deploy-log-alert'
  scope: rg
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}

output acrLoginServer string = acr.outputs.acrLoginServer
output acrId string = acr.outputs.acrId
output managedIdentityId string = managedIdentity.outputs.identityId
output managedIdentityClientId string = managedIdentity.outputs.clientId
output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.environmentId
output containerAppFqdn string = containerApp.outputs.containerAppFqdn
output actionGroupId string = actionGroup.outputs.actionGroupId
