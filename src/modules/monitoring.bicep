targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Monitoring Module'
metadata description = 'Deploy Log Analytics Workspace and Application Insights'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Required. Name for Log Analytics Workspace.')
param logAnalyticsWorkspaceName string

@description('Required. Name for Application Insights.')
param applicationInsightsName string

@description('Optional. Log Analytics retention in days.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Optional. Log Analytics SKU.')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param sku string = 'PerGB2018'

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
@description('The resource ID of the Log Analytics Workspace.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('The name of the Log Analytics Workspace.')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

@description('The resource ID of the Application Insights.')
output applicationInsightsId string = applicationInsights.id

@description('The name of the Application Insights.')
output applicationInsightsName string = applicationInsights.name

@description('The instrumentation key for Application Insights.')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('The connection string for Application Insights.')
output connectionString string = applicationInsights.properties.ConnectionString
