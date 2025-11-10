targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Key Vault Secrets Module'
metadata description = 'Populate Key Vault with application secrets'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Required. Name of the Key Vault.')
param keyVaultName string

@description('Required. PostgreSQL connection string.')
@secure()
param postgresConnectionString string

@description('Required. Redis connection string.')
@secure()
param redisConnectionString string

@description('Required. Azure Storage connection string.')
@secure()
param storageConnectionString string

@description('Required. Azure OpenAI API key.')
@secure()
param openAIApiKey string

@description('Required. Azure OpenAI endpoint.')
param openAIEndpoint string

@description('Required. Azure OpenAI deployment name.')
param openAIDeploymentName string

@description('Optional. Additional secrets to store.')
@secure()
param additionalSecrets object = {}

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Core application secrets
resource databaseUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'database-url'
  properties: {
    value: postgresConnectionString
    contentType: 'text/plain'
  }
}

resource redisUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'redis-url'
  properties: {
    value: redisConnectionString
    contentType: 'text/plain'
  }
}

resource storageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: storageConnectionString
    contentType: 'text/plain'
  }
}

resource openAIApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: openAIApiKey
    contentType: 'text/plain'
  }
}

resource openAIEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-endpoint'
  properties: {
    value: openAIEndpoint
    contentType: 'text/plain'
  }
}

resource openAIDeploymentNameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-deployment-name'
  properties: {
    value: openAIDeploymentName
    contentType: 'text/plain'
  }
}

// Additional secrets (for future use - e.g., NextAuth, OAuth)
resource additionalSecretsResources 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in items(additionalSecrets): {
  parent: keyVault
  name: secret.key
  properties: {
    value: secret.value
    contentType: 'text/plain'
  }
}]

// Outputs
@description('The resource ID of the Key Vault.')
output keyVaultId string = keyVault.id

@description('The name of the Key Vault.')
output keyVaultName string = keyVault.name

@description('Secret names created.')
output secretNames array = [
  databaseUrlSecret.name
  redisUrlSecret.name
  storageConnectionStringSecret.name
  openAIApiKeySecret.name
  openAIEndpointSecret.name
  openAIDeploymentNameSecret.name
]
