targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - PostgreSQL Module'
metadata description = 'Deploy Azure Database for PostgreSQL Flexible Server'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Required. Name of the PostgreSQL Flexible Server.')
param serverName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Required. Administrator username.')
@minLength(1)
param administratorLogin string

@description('Required. Administrator password.')
@secure()
@minLength(8)
param administratorPassword string

@description('Optional. PostgreSQL version.')
@allowed([
  '16'
  '15'
  '14'
  '13'
  '12'
  '11'
])
param version string = '16'

@description('Optional. PostgreSQL SKU name.')
param skuName string = 'Standard_B1ms'

@description('Optional. PostgreSQL tier.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param tier string = 'Burstable'

@description('Optional. Storage size in GB.')
@minValue(32)
@maxValue(16384)
param storageSizeGB int = 32

@description('Optional. Backup retention days.')
@minValue(7)
@maxValue(35)
param backupRetentionDays int = 7

@description('Optional. Enable geo-redundant backup.')
param geoRedundantBackup string = 'Disabled'

@description('Optional. Enable high availability.')
param highAvailability string = 'Disabled'

@description('Optional. Public network access.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Optional. Database name to create.')
param databaseName string = 'marketingstory'

@description('Optional. Resource ID of the Log Analytics workspace for diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('Optional. Enable diagnostic settings.')
param enableDiagnostics bool = true

@description('Optional. Enable private endpoint.')
param enablePrivateEndpoint bool = false

@description('Optional. Subnet ID for private endpoint.')
param privateEndpointSubnetId string = ''

@description('Optional. Private DNS zone ID for PostgreSQL.')
param privateDnsZoneId string = ''

@description('Optional. Private endpoint name.')
param privateEndpointName string = '${serverName}-pe'

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: serverName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: tier
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: highAvailability
    }
    network: {
      publicNetworkAccess: publicNetworkAccess
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

// Firewall rule to allow Azure services
resource firewallRuleAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgresServer
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgresServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Diagnostic Settings for PostgreSQL
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: 'diag-${postgresServer.name}'
  scope: postgresServer
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'PostgreSQLLogs'
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

// Private Endpoint for PostgreSQL
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-10-01' = if (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: postgresServer.id
          groupIds: [
            'postgresqlServer'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-10-01' = if (enablePrivateEndpoint && !empty(privateDnsZoneId)) {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-postgres-database-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
@description('The resource ID of the PostgreSQL Flexible Server.')
output serverId string = postgresServer.id

@description('The name of the PostgreSQL Flexible Server.')
output serverName string = postgresServer.name

@description('The FQDN of the PostgreSQL Flexible Server.')
output serverFqdn string = postgresServer.properties.fullyQualifiedDomainName

@description('The name of the database.')
output databaseName string = database.name

@description('The PostgreSQL connection string (without password).')
output connectionStringTemplate string = 'postgresql://${administratorLogin}@${serverName}:PASSWORD_PLACEHOLDER@${postgresServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
