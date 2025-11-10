targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Network Module'
metadata description = 'Deploy Virtual Network with subnets for private endpoints'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Required. Name of the Virtual Network.')
param vnetName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Virtual Network address space.')
param addressPrefixes array = [
  '10.0.0.0/16'
]

@description('Optional. Enable DDoS protection.')
param enableDdosProtection bool = false

@description('Optional. DDoS protection plan ID.')
param ddosProtectionPlanId string = ''

@description('Optional. DNS servers for the VNet.')
param dnsServers array = []

@description('Optional. Resource ID of the Log Analytics workspace for diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('Optional. Enable diagnostic settings.')
param enableDiagnostics bool = true

// Subnets configuration
var subnets = [
  {
    name: 'snet-private-endpoints'
    addressPrefix: '10.0.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  {
    name: 'snet-app-services'
    addressPrefix: '10.0.2.0/24'
    delegations: [
      {
        name: 'delegation-app-service'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  }
  {
    name: 'snet-container-apps'
    addressPrefix: '10.0.3.0/23'
    delegations: []
  }
]

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    enableDdosProtection: enableDdosProtection
    ddosProtectionPlan: enableDdosProtection && !empty(ddosProtectionPlanId) ? {
      id: ddosProtectionPlanId
    } : null
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
        privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies ?? 'Enabled'
        delegations: subnet.?delegations ?? []
      }
    }]
  }
}

// Diagnostic Settings for VNet
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: 'diag-${vnet.name}'
  scope: vnet
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'VMProtectionAlerts'
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
@description('The resource ID of the Virtual Network.')
output vnetId string = vnet.id

@description('The name of the Virtual Network.')
output vnetName string = vnet.name

@description('The resource ID of the private endpoints subnet.')
output privateEndpointSubnetId string = vnet.properties.subnets[0].id

@description('The name of the private endpoints subnet.')
output privateEndpointSubnetName string = vnet.properties.subnets[0].name

@description('The resource ID of the app services subnet.')
output appServiceSubnetId string = vnet.properties.subnets[1].id

@description('The name of the app services subnet.')
output appServiceSubnetName string = vnet.properties.subnets[1].name

@description('The resource ID of the container apps subnet.')
output containerAppsSubnetId string = vnet.properties.subnets[2].id

@description('The name of the container apps subnet.')
output containerAppsSubnetName string = vnet.properties.subnets[2].name
