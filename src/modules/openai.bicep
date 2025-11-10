targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Azure OpenAI Module'
metadata description = 'Deploy or reference existing Azure OpenAI Service with GPT-4 deployment'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Optional. Use existing Azure OpenAI Service instead of creating new.')
param useExistingOpenAI bool = false

@description('Optional. Resource ID of existing Azure OpenAI Service (required if useExistingOpenAI is true).')
param existingOpenAIResourceId string = ''

@description('Optional. Name of existing Azure OpenAI Service (required if useExistingOpenAI is true).')
param existingOpenAIName string = ''

@description('Optional. Resource group of existing Azure OpenAI Service (required if useExistingOpenAI is true).')
param existingOpenAIResourceGroup string = ''

@description('Required. Name of the Azure OpenAI Service (used only when creating new).')
param openAIName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Azure OpenAI SKU.')
@allowed([
  'S0'
])
param sku string = 'S0'

@description('Optional. Public network access.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Optional. Deploy GPT-4 model (only applies when creating new OpenAI service).')
param deployGPT4 bool = true

@description('Optional. GPT-4 deployment name.')
param gpt4DeploymentName string = 'gpt-4'

@description('Optional. GPT-4 model version.')
param gpt4ModelVersion string = 'turbo-2024-04-09'

@description('Optional. GPT-4 capacity (tokens per minute in thousands).')
@minValue(1)
@maxValue(100)
param gpt4Capacity int = 10

// Reference existing OpenAI service
resource existingOpenAI 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = if (useExistingOpenAI) {
  name: existingOpenAIName
  scope: resourceGroup(existingOpenAIResourceGroup)
}

// Azure OpenAI Account (create new)
resource openAI 'Microsoft.CognitiveServices/accounts@2024-10-01' = if (!useExistingOpenAI) {
  name: openAIName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: openAIName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4 Deployment (only when creating new OpenAI)
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (!useExistingOpenAI && deployGPT4) {
  parent: openAI
  name: gpt4DeploymentName
  sku: {
    name: 'Standard'
    capacity: gpt4Capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: gpt4ModelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
}

// Outputs
@description('The resource ID of the Azure OpenAI Service.')
output openAIId string = useExistingOpenAI ? existingOpenAI.id : openAI.id

@description('The name of the Azure OpenAI Service.')
output openAIName string = useExistingOpenAI ? existingOpenAI.name : openAI.name

@description('The endpoint of the Azure OpenAI Service.')
output endpoint string = useExistingOpenAI ? existingOpenAI.properties.endpoint : openAI.properties.endpoint

@description('The primary key for the Azure OpenAI Service.')
output primaryKey string = useExistingOpenAI ? existingOpenAI.listKeys().key1 : openAI.listKeys().key1

@description('The GPT-4 deployment name.')
output gpt4DeploymentName string = gpt4DeploymentName
