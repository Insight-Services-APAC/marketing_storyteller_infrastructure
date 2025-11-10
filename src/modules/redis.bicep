targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Redis Cache Module'
metadata description = 'Deploy Azure Cache for Redis for BullMQ job queue'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Required. Name of the Redis Cache.')
param redisCacheName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Redis Cache SKU.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Optional. Redis Cache family.')
@allowed([
  'C'
  'P'
])
param family string = 'C'

@description('Optional. Redis Cache capacity.')
@allowed([
  0
  1
  2
  3
  4
  5
  6
])
param capacity int = 0

@description('Optional. Enable non-SSL port (6379).')
param enableNonSslPort bool = false

@description('Optional. Minimum TLS version.')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minimumTlsVersion string = '1.2'

@description('Optional. Redis version.')
@allowed([
  '6'
  '7'
])
param redisVersion string = '6'

@description('Optional. Resource ID of the Log Analytics workspace for diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('Optional. Enable diagnostic settings.')
param enableDiagnostics bool = true

@description('Optional. Enable private endpoint.')
param enablePrivateEndpoint bool = false

@description('Optional. Subnet ID for private endpoint.')
param privateEndpointSubnetId string = ''

@description('Optional. Private DNS zone ID for Redis.')
param privateDnsZoneId string = ''

@description('Optional. Private endpoint name.')
param privateEndpointName string = '${redisCacheName}-pe'

// Redis Cache
resource redisCache 'Microsoft.Cache/redis@2024-03-01' = {
  name: redisCacheName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
      family: family
      capacity: capacity
    }
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: minimumTlsVersion
    redisVersion: redisVersion
    publicNetworkAccess: 'Enabled'
    redisConfiguration: {
      'maxmemory-policy': 'volatile-lru'
    }
  }
}

// Diagnostic Settings for Redis Cache
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: 'diag-${redisCache.name}'
  scope: redisCache
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ConnectedClientList'
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

// Private Endpoint for Redis
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
          privateLinkServiceId: redisCache.id
          groupIds: [
            'redisCache'
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
        name: 'privatelink-redis-cache-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
@description('The resource ID of the Redis Cache.')
output redisCacheId string = redisCache.id

@description('The name of the Redis Cache.')
output redisCacheName string = redisCache.name

@description('The hostname of the Redis Cache.')
output hostName string = redisCache.properties.hostName

@description('The SSL port of the Redis Cache.')
output sslPort int = redisCache.properties.sslPort

@description('The port of the Redis Cache.')
output port int = redisCache.properties.port

@description('The primary key for the Redis Cache.')
output primaryKey string = redisCache.listKeys().primaryKey

@description('The Redis connection string.')
output connectionString string = '${redisCache.properties.hostName}:${redisCache.properties.sslPort},password=${redisCache.listKeys().primaryKey},ssl=True,abortConnect=False'
