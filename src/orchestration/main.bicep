targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Infrastructure Deployment'
metadata description = 'Deploy Marketing Storyteller infrastructure to Azure'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Common Parameters
@description('Required. Location for all resources.')
param location string = 'australiaeast'

@description('Required. Environment ID.')
@allowed([
  'sandbox'
  'dev'
  'prod'
])
param environmentId string

@description('Optional. Application name prefix.')
param appNamePrefix string = 'marketingstory'

@description('Optional. Tags for all resources.')
param tags object = {
  environment: environmentId
  applicationName: 'Marketing Storyteller'
  iac: 'Bicep'
}

// PostgreSQL Parameters
@description('Required. PostgreSQL administrator username.')
param postgresAdminUsername string

@description('Required. PostgreSQL administrator password.')
@secure()
param postgresAdminPassword string

// App Service Parameters
@description('Optional. Additional app settings.')
param additionalAppSettings object = {}

@description('Optional. Key Vault initial access principal ID.')
param keyVaultInitialAccessPrincipalId string = ''

// Azure OpenAI Parameters
@description('Optional. Use existing Azure OpenAI Service instead of creating new.')
param useExistingOpenAI bool = false

@description('Optional. Name of existing Azure OpenAI Service.')
param existingOpenAIName string = ''

@description('Optional. Resource group of existing Azure OpenAI Service.')
param existingOpenAIResourceGroup string = ''

@description('Optional. Existing GPT-4 deployment name in the OpenAI service.')
param existingGPT4DeploymentName string = 'gpt-4'

// Alerts Parameters
@description('Optional. Email addresses to send alerts to.')
param alertEmailAddresses array = []

@description('Optional. SMS phone numbers to send critical alerts (AU format without country code).')
param alertSmsNumbers array = []

@description('Optional. Enable monitoring alerts.')
param enableAlerts bool = true

// Networking Parameters
@description('Optional. Enable private endpoints for backend services.')
param enablePrivateEndpoints bool = false

@description('Optional. Virtual Network address prefix.')
param vnetAddressPrefix string = '10.0.0.0/16'

// ============================================================================
// Variables
// ============================================================================

var locationAbbr = 'aue' // Australia East

// Environment-specific configurations
var envConfig = {
  sandbox: {
    appServiceSku: 'S1'  // Basic tier not allowed, S1 is cheapest Standard tier
    postgresqlSku: 'Standard_B1ms'
    postgresqlTier: 'Burstable'
    postgresqlBackupRetention: 7
    postgresqlGeoRedundantBackup: 'Disabled'
    postgresqlHighAvailability: 'Disabled'
    storageSku: 'Standard_LRS'
    redisSku: 'Basic'
    redisFamily: 'C'
    redisCapacity: 0
    gpt4Capacity: 10
    logRetentionDays: 30  // Minimum allowed by Azure
  }
  dev: {
    appServiceSku: 'P1V3'
    postgresqlSku: 'Standard_B1ms'
    postgresqlTier: 'Burstable'
    postgresqlBackupRetention: 7
    postgresqlGeoRedundantBackup: 'Disabled'
    postgresqlHighAvailability: 'Disabled'
    storageSku: 'Standard_LRS'
    redisSku: 'Basic'
    redisFamily: 'C'
    redisCapacity: 0
    gpt4Capacity: 10
    logRetentionDays: 30
  }
  prod: {
    appServiceSku: 'P2V3'
    postgresqlSku: 'Standard_D2s_v3'
    postgresqlTier: 'GeneralPurpose'
    postgresqlBackupRetention: 35
    postgresqlGeoRedundantBackup: 'Enabled'
    postgresqlHighAvailability: 'ZoneRedundant'
    storageSku: 'Standard_GRS'
    redisSku: 'Standard'
    redisFamily: 'C'
    redisCapacity: 1
    gpt4Capacity: 50
    logRetentionDays: 90
  }
}

var config = envConfig[environmentId]

// Resource names
// Note: Storage (24 char max) and KeyVault (24 char max) use abbreviated names
// Environment abbreviations: sandbox=sbx, dev=dev, prod=prd
var envAbbr = environmentId == 'sandbox' ? 'sbx' : (environmentId == 'prod' ? 'prd' : environmentId)
var names = {
  logAnalytics: 'law-${appNamePrefix}-${environmentId}-${locationAbbr}'
  appInsights: 'appi-${appNamePrefix}-${environmentId}-${locationAbbr}'
  storage: 'stmktstory${envAbbr}${locationAbbr}'  // stmktstorysbxaue = 19 chars ✓
  redis: 'redis-${appNamePrefix}-${environmentId}-${locationAbbr}'
  openai: 'oai-${appNamePrefix}-${environmentId}-${locationAbbr}'
  keyVault: 'kv-mktstory-${envAbbr}-${locationAbbr}'  // kv-mktstory-sbx-aue = 21 chars ✓
  postgresql: 'psql-${appNamePrefix}-${environmentId}-${locationAbbr}'
  appServicePlan: 'asp-${appNamePrefix}-${environmentId}-${locationAbbr}'
  appService: 'app-${appNamePrefix}-${environmentId}-${locationAbbr}'
  actionGroup: 'ag-${appNamePrefix}-${environmentId}-${locationAbbr}'
  vnet: 'vnet-${appNamePrefix}-${environmentId}-${locationAbbr}'
}

// ============================================================================
// Resource Lock for Production (Prevent accidental deletion)
// ============================================================================

resource resourceGroupLock 'Microsoft.Authorization/locks@2020-05-01' = if (environmentId == 'prod') {
  name: 'lock-${resourceGroup().name}'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevent accidental deletion of production resources'
  }
}

// ============================================================================
// Networking (Optional - Private Endpoints)
// ============================================================================

// Network Module (optional - for private endpoints)
module network '../modules/network.bicep' = if (enablePrivateEndpoints) {
  name: 'deploy-network'
  params: {
    location: location
    tags: tags
    vnetName: names.vnet
    addressPrefixes: [vnetAddressPrefix]
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enableDiagnostics: true
  }
}

// Private DNS Zones (optional - for private endpoints)
module privateDnsZones '../modules/private-dns-zones.bicep' = if (enablePrivateEndpoints) {
  name: 'deploy-private-dns-zones'
  params: {
    location: 'global'
    tags: tags
    vnetId: enablePrivateEndpoints ? network.outputs.vnetId : ''
    deployPostgresZone: true
    deployRedisZone: true
    deployStorageZones: true
    deployKeyVaultZone: true
    deployOpenAIZone: false // OpenAI doesn't support private endpoints yet
  }
}

// Monitoring Module
module monitoring '../modules/monitoring.bicep' = {
  name: 'deploy-monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsWorkspaceName: names.logAnalytics
    applicationInsightsName: names.appInsights
    retentionInDays: config.logRetentionDays
  }
}

// Storage Module
module storage '../modules/storage.bicep' = {
  name: 'deploy-storage'
  params: {
    location: location
    tags: tags
    storageAccountName: replace(names.storage, '-', '') // Remove hyphens for storage account name
    sku: config.storageSku
    containers: [
      'story-documents'
      'enhancement-files'
    ]
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enableDiagnostics: true
    enableBlobPrivateEndpoint: enablePrivateEndpoints
    privateEndpointSubnetId: enablePrivateEndpoints ? network.outputs.privateEndpointSubnetId : ''
    blobPrivateDnsZoneId: enablePrivateEndpoints ? privateDnsZones.outputs.storageBlobPrivateDnsZoneId : ''
  }
}

// Redis Cache Module
module redis '../modules/redis.bicep' = {
  name: 'deploy-redis'
  params: {
    location: location
    tags: tags
    redisCacheName: names.redis
    sku: config.redisSku
    family: config.redisFamily
    capacity: config.redisCapacity
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enableDiagnostics: true
    enablePrivateEndpoint: enablePrivateEndpoints
    privateEndpointSubnetId: enablePrivateEndpoints ? network.outputs.privateEndpointSubnetId : ''
    privateDnsZoneId: enablePrivateEndpoints ? privateDnsZones.outputs.redisPrivateDnsZoneId : ''
  }
}

// Azure OpenAI Module
module openai '../modules/openai.bicep' = {
  name: 'deploy-openai'
  params: {
    location: location
    tags: tags
    openAIName: names.openai
    gpt4Capacity: config.gpt4Capacity
    useExistingOpenAI: useExistingOpenAI
    existingOpenAIName: existingOpenAIName
    existingOpenAIResourceGroup: existingOpenAIResourceGroup
    gpt4DeploymentName: useExistingOpenAI ? existingGPT4DeploymentName : 'gpt-4'
    deployGPT4: !useExistingOpenAI
  }
}

// Key Vault Module
module keyVault '../modules/keyvault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    location: location
    tags: tags
    keyVaultName: names.keyVault
    initialAccessPrincipalId: keyVaultInitialAccessPrincipalId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enableDiagnostics: true
    enablePrivateEndpoint: enablePrivateEndpoints
    privateEndpointSubnetId: enablePrivateEndpoints ? network.outputs.privateEndpointSubnetId : ''
    privateDnsZoneId: enablePrivateEndpoints ? privateDnsZones.outputs.keyVaultPrivateDnsZoneId : ''
  }
}

// PostgreSQL Module
module postgresql '../modules/postgresql.bicep' = {
  name: 'deploy-postgresql'
  params: {
    location: location
    tags: tags
    serverName: names.postgresql
    administratorLogin: postgresAdminUsername
    administratorPassword: postgresAdminPassword
    skuName: config.postgresqlSku
    tier: config.postgresqlTier
    databaseName: 'marketingstory'
    backupRetentionDays: config.postgresqlBackupRetention
    geoRedundantBackup: config.postgresqlGeoRedundantBackup
    highAvailability: config.postgresqlHighAvailability
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enableDiagnostics: true
    enablePrivateEndpoint: enablePrivateEndpoints
    privateEndpointSubnetId: enablePrivateEndpoints ? network.outputs.privateEndpointSubnetId : ''
    privateDnsZoneId: enablePrivateEndpoints ? privateDnsZones.outputs.postgresPrivateDnsZoneId : ''
  }
}

// Key Vault Secrets Module - Populate secrets
module keyVaultSecrets '../modules/keyvault-secrets.bicep' = {
  name: 'deploy-keyvault-secrets'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    postgresConnectionString: 'postgresql://${postgresAdminUsername}:${postgresAdminPassword}@${postgresql.outputs.serverFqdn}:5432/${postgresql.outputs.databaseName}?sslmode=require'
    redisConnectionString: redis.outputs.connectionString
    storageConnectionString: storage.outputs.connectionString
    openAIApiKey: openai.outputs.primaryKey
    openAIEndpoint: openai.outputs.endpoint
    openAIDeploymentName: openai.outputs.gpt4DeploymentName
  }
}

// App Service Module
module appService '../modules/app-service.bicep' = {
  name: 'deploy-app-service'
  params: {
    location: location
    tags: tags
    appServicePlanName: names.appServicePlan
    appServiceName: names.appService
    skuName: config.appServiceSku
    applicationInsightsConnectionString: monitoring.outputs.connectionString
    appSettings: union({
      // Key Vault references for sensitive data
      DATABASE_URL: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.keyVaultName};SecretName=database-url)'
      REDIS_URL: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.keyVaultName};SecretName=redis-url)'
      BLOB_STORAGE_CONNECTION_STRING: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.keyVaultName};SecretName=storage-connection-string)'
      AZURE_OPENAI_API_KEY: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.keyVaultName};SecretName=openai-api-key)'
      AZURE_OPENAI_ENDPOINT: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.keyVaultName};SecretName=openai-endpoint)'
      AZURE_OPENAI_DEPLOYMENT_NAME: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.keyVaultName};SecretName=openai-deployment-name)'
      // Non-sensitive configuration
      AZURE_STORAGE_ACCOUNT_NAME: storage.outputs.storageAccountName
      KEY_VAULT_URI: keyVault.outputs.vaultUri
      NODE_ENV: environmentId == 'prod' ? 'production' : 'development'
    }, additionalAppSettings)
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enableDiagnostics: true
  }
}

// ============================================================================
// Role Assignments - Grant App Service Access to Azure Resources
// ============================================================================
// Note: Role assignments are deployed at resource group scope
// GUID names use compile-time values to ensure deterministic deployment
// ============================================================================

// Grant App Service access to Key Vault (Key Vault Secrets User role)
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, names.keyVault, names.appService, '4633458b-17de-408a-b874-0445c86b69e6')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: appService.outputs.principalId
    principalType: 'ServicePrincipal'
    description: 'Allow App Service to read secrets from Key Vault'
  }
}

// Grant App Service access to Storage (Storage Blob Data Contributor role)
resource storageBlobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, replace(names.storage, '-', ''), names.appService, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: appService.outputs.principalId
    principalType: 'ServicePrincipal'
    description: 'Allow App Service to read/write blobs in Storage Account'
  }
}

// ============================================================================
// Monitoring Alerts
// ============================================================================
module alerts '../modules/alerts.bicep' = if (enableAlerts && length(alertEmailAddresses) > 0) {
  name: 'deploy-alerts'
  params: {
    location: 'global'
    tags: tags
    actionGroupName: names.actionGroup
    alertEmailAddresses: alertEmailAddresses
    alertSmsNumbers: alertSmsNumbers
    appServiceId: appService.outputs.appServiceId
    postgresqlServerId: postgresql.outputs.serverId
    redisCacheId: redis.outputs.redisCacheId
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    environmentId: environmentId
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the resource group.')
output resourceGroupName string = resourceGroup().name

@description('The App Service URL.')
output appServiceUrl string = appService.outputs.appServiceUrl

@description('The App Service principal ID.')
output appServicePrincipalId string = appService.outputs.principalId

@description('The PostgreSQL server FQDN.')
output postgresqlServerFqdn string = postgresql.outputs.serverFqdn

@description('The Key Vault URI.')
output keyVaultUri string = keyVault.outputs.vaultUri

@description('The Application Insights connection string.')
output applicationInsightsConnectionString string = monitoring.outputs.connectionString

@description('The Storage Account name.')
output storageAccountName string = storage.outputs.storageAccountName

@description('The Redis Cache hostname.')
output redisCacheHostname string = redis.outputs.hostName

@description('The Azure OpenAI endpoint.')
output openAIEndpoint string = openai.outputs.endpoint
