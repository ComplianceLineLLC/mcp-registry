targetScope = 'resourceGroup'

@description('Name of the Container App')
param containerAppName string = 'ca-sonarqube-mcp-dev'

@description('Deployment location')
param location string = resourceGroup().location

@description('Resource ID of the Container Apps Environment')
param environmentId string

@description('Login server of the ACR hosting the image')
param acrLoginServer string

@description('Digest-pinned image reference (e.g. sha256:...) — never a mutable tag, per the plan\'s image supply chain decision')
param imageDigest string

@description('Resource ID of the user-assigned managed identity used for ACR pull')
param managedIdentityId string

@description('SonarQube Server URL')
param sonarQubeUrl string = 'https://sqdev.mycompliancemanagement.com'

@description('Minimum replica count')
param minReplicas int = 1

@description('Maximum replica count')
param maxReplicas int = 2

var imageReference = '${acrLoginServer}/sonarsource/sonarqube-mcp@${imageDigest}'

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        targetPort: 8080
        transport: 'auto'
      }
      registries: [
        {
          server: acrLoginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'sonarqube-mcp'
          image: imageReference
          env: [
            { name: 'SONARQUBE_TRANSPORT', value: 'http' }
            { name: 'SONARQUBE_HTTP_HOST', value: '0.0.0.0' }
            { name: 'SONARQUBE_HTTP_PORT', value: '8080' }
            { name: 'SONARQUBE_URL', value: sonarQubeUrl }
            { name: 'SONARQUBE_READ_ONLY', value: 'true' }
            { name: 'TELEMETRY_DISABLED', value: 'true' }
            { name: 'SONARQUBE_MCP_IN_CONTAINER', value: 'true' }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output containerAppId string = containerApp.id
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
