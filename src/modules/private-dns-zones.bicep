targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Private DNS Zones Module'
metadata description = 'Deploy Private DNS Zones for private endpoints'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Required. Virtual Network ID to link DNS zones to.')
param vnetId string

@description('Optional. Location for all resources.')
param location string = 'global'

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Deploy PostgreSQL private DNS zone.')
param deployPostgresZone bool = true

@description('Optional. Deploy Redis private DNS zone.')
param deployRedisZone bool = true

@description('Optional. Deploy Storage private DNS zones.')
param deployStorageZones bool = true

@description('Optional. Deploy Key Vault private DNS zone.')
param deployKeyVaultZone bool = true

@description('Optional. Deploy OpenAI private DNS zone.')
param deployOpenAIZone bool = true

// PostgreSQL Private DNS Zone
resource postgresPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (deployPostgresZone) {
  name: 'privatelink.postgres.database.azure.com'
  location: location
  tags: tags
}

resource postgresVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (deployPostgresZone) {
  parent: postgresPrivateDnsZone
  name: 'link-to-vnet'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Redis Private DNS Zone
resource redisPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (deployRedisZone) {
  name: 'privatelink.redis.cache.windows.net'
  location: location
  tags: tags
}

resource redisVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (deployRedisZone) {
  parent: redisPrivateDnsZone
  name: 'link-to-vnet'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Storage Private DNS Zones (Blob, File, Queue, Table)
resource storageBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (deployStorageZones) {
  name: 'privatelink.blob.core.windows.net'
  location: location
  tags: tags
}

resource storageBlobVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (deployStorageZones) {
  parent: storageBlobPrivateDnsZone
  name: 'link-to-vnet'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource storageFilePrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (deployStorageZones) {
  name: 'privatelink.file.core.windows.net'
  location: location
  tags: tags
}

resource storageFileVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (deployStorageZones) {
  parent: storageFilePrivateDnsZone
  name: 'link-to-vnet'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Key Vault Private DNS Zone
resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (deployKeyVaultZone) {
  name: 'privatelink.vaultcore.azure.net'
  location: location
  tags: tags
}

resource keyVaultVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (deployKeyVaultZone) {
  parent: keyVaultPrivateDnsZone
  name: 'link-to-vnet'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// OpenAI Private DNS Zone
resource openAIPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (deployOpenAIZone) {
  name: 'privatelink.openai.azure.com'
  location: location
  tags: tags
}

resource openAIVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (deployOpenAIZone) {
  parent: openAIPrivateDnsZone
  name: 'link-to-vnet'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Outputs
@description('The resource ID of the PostgreSQL private DNS zone.')
output postgresPrivateDnsZoneId string = deployPostgresZone ? postgresPrivateDnsZone.id : ''

@description('The resource ID of the Redis private DNS zone.')
output redisPrivateDnsZoneId string = deployRedisZone ? redisPrivateDnsZone.id : ''

@description('The resource ID of the Storage Blob private DNS zone.')
output storageBlobPrivateDnsZoneId string = deployStorageZones ? storageBlobPrivateDnsZone.id : ''

@description('The resource ID of the Storage File private DNS zone.')
output storageFilePrivateDnsZoneId string = deployStorageZones ? storageFilePrivateDnsZone.id : ''

@description('The resource ID of the Key Vault private DNS zone.')
output keyVaultPrivateDnsZoneId string = deployKeyVaultZone ? keyVaultPrivateDnsZone.id : ''

@description('The resource ID of the OpenAI private DNS zone.')
output openAIPrivateDnsZoneId string = deployOpenAIZone ? openAIPrivateDnsZone.id : ''
