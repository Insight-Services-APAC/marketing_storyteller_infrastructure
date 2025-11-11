targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - App Service Module'
metadata description = 'Deploy Azure App Service for Next.js application'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Required. Name of the App Service Plan.')
param appServicePlanName string

@description('Required. Name of the App Service.')
param appServiceName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. App Service Plan SKU.')
@allowed([
  'P1V3'
  'P2V3'
  'P3V3'
  'P1V2'
  'P2V2'
  'P3V2'
  'S1'
  'S2'
  'S3'
])
param skuName string = 'P1V3'

@description('Optional. Number of worker instances.')
@minValue(1)
@maxValue(10)
param capacity int = 1

@description('Optional. Node.js version.')
param nodeVersion string = '20-lts'

@description('Optional. Application Insights connection string.')
param applicationInsightsConnectionString string = ''

@description('Optional. Application settings.')
param appSettings object = {}

@description('Optional. Enable HTTPS only.')
param httpsOnly bool = true

@description('Optional. Enable detailed error messages.')
param detailedErrorLoggingEnabled bool = true

@description('Optional. Enable HTTP logging.')
param httpLoggingEnabled bool = true

@description('Optional. Enable request tracing.')
param requestTracingEnabled bool = true

@description('Optional. Enable Always On.')
param alwaysOn bool = true

@description('Optional. Resource ID of the Log Analytics workspace for diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('Optional. Enable diagnostic settings.')
param enableDiagnostics bool = true

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: capacity
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
    zoneRedundant: false
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: httpsOnly
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}'
      alwaysOn: alwaysOn
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      detailedErrorLoggingEnabled: detailedErrorLoggingEnabled
      httpLoggingEnabled: httpLoggingEnabled
      requestTracingEnabled: requestTracingEnabled
    }
    publicNetworkAccess: 'Enabled'
  }
}

// App Settings as separate resource to avoid validation issues
resource appServiceSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: appService
  name: 'appsettings'
  properties: union({
    WEBSITE_NODE_DEFAULT_VERSION: '~${nodeVersion}'
    SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
  }, appSettings)
}

// Diagnostic Settings for App Service
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: 'diag-${appService.name}'
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Outputs
@description('The resource ID of the App Service Plan.')
output appServicePlanId string = appServicePlan.id

@description('The name of the App Service Plan.')
output appServicePlanName string = appServicePlan.name

@description('The resource ID of the App Service.')
output appServiceId string = appService.id

@description('The name of the App Service.')
output appServiceName string = appService.name

@description('The default hostname of the App Service.')
output defaultHostname string = appService.properties.defaultHostName

@description('The URL of the App Service.')
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'

@description('The principal ID of the system assigned managed identity.')
output principalId string = appService.identity.principalId

@description('The tenant ID of the system assigned managed identity.')
output tenantId string = appService.identity.tenantId
