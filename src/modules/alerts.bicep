targetScope = 'resourceGroup'

metadata name = 'Marketing Storyteller - Alerts Module'
metadata description = 'Deploy monitoring alerts for critical resources'
metadata version = '1.0.0'
metadata author = 'Insight Services APAC'

// Parameters
@description('Required. Name of the action group for alerts.')
param actionGroupName string

@description('Optional. Location for all resources.')
param location string = 'global'

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Required. Email addresses to send alerts to.')
param alertEmailAddresses array

@description('Optional. SMS phone numbers to send critical alerts.')
param alertSmsNumbers array = []

@description('Required. Resource ID of the App Service to monitor.')
param appServiceId string

@description('Required. Resource ID of the PostgreSQL server to monitor.')
param postgresqlServerId string

@description('Required. Resource ID of the Redis cache to monitor.')
param redisCacheId string

@description('Required. Resource ID of the Application Insights.')
param applicationInsightsId string

@description('Optional. Environment ID for conditional alert configuration.')
@allowed([
  'sandbox'
  'dev'
  'prod'
])
param environmentId string = 'dev'

// Action Group for Email and SMS notifications
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  tags: tags
  properties: {
    groupShortName: substring(actionGroupName, 0, min(length(actionGroupName), 12))
    enabled: true
    emailReceivers: [for (email, i) in alertEmailAddresses: {
      name: 'Email-${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
    smsReceivers: [for (phone, i) in alertSmsNumbers: {
      name: 'SMS-${i}'
      countryCode: '61' // Australia
      phoneNumber: phone
    }]
  }
}

// App Service CPU Alert
resource appServiceCpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-appservice-cpu-high'
  location: location
  tags: tags
  properties: {
    description: 'Alert when App Service CPU usage exceeds 80%'
    severity: environmentId == 'prod' ? 2 : 3
    enabled: true
    scopes: [
      appServiceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricName: 'CpuPercentage'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// App Service Memory Alert
resource appServiceMemoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-appservice-memory-high'
  location: location
  tags: tags
  properties: {
    description: 'Alert when App Service memory usage exceeds 85%'
    severity: environmentId == 'prod' ? 2 : 3
    enabled: true
    scopes: [
      appServiceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighMemory'
          metricName: 'MemoryPercentage'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 85
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// App Service Response Time Alert
resource appServiceResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-appservice-response-time'
  location: location
  tags: tags
  properties: {
    description: 'Alert when App Service response time exceeds 5 seconds'
    severity: environmentId == 'prod' ? 2 : 3
    enabled: true
    scopes: [
      appServiceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'SlowResponse'
          metricName: 'HttpResponseTime'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// App Service HTTP 5xx Errors Alert
resource appServiceErrorsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-appservice-http-errors'
  location: location
  tags: tags
  properties: {
    description: 'Alert when App Service has more than 10 HTTP 5xx errors'
    severity: environmentId == 'prod' ? 1 : 2
    enabled: true
    scopes: [
      appServiceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighErrorRate'
          metricName: 'Http5xx'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 10
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// PostgreSQL CPU Alert
resource postgresqlCpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-postgresql-cpu-high'
  location: location
  tags: tags
  properties: {
    description: 'Alert when PostgreSQL CPU usage exceeds 80%'
    severity: environmentId == 'prod' ? 2 : 3
    enabled: true
    scopes: [
      postgresqlServerId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricName: 'cpu_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// PostgreSQL Memory Alert
resource postgresqlMemoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-postgresql-memory-high'
  location: location
  tags: tags
  properties: {
    description: 'Alert when PostgreSQL memory usage exceeds 85%'
    severity: environmentId == 'prod' ? 2 : 3
    enabled: true
    scopes: [
      postgresqlServerId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighMemory'
          metricName: 'memory_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 85
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// PostgreSQL Storage Alert
resource postgresqlStorageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-postgresql-storage-high'
  location: location
  tags: tags
  properties: {
    description: 'Alert when PostgreSQL storage usage exceeds 85%'
    severity: environmentId == 'prod' ? 1 : 2
    enabled: true
    scopes: [
      postgresqlServerId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighStorage'
          metricName: 'storage_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 85
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Redis Server Load Alert
resource redisServerLoadAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-redis-server-load-high'
  location: location
  tags: tags
  properties: {
    description: 'Alert when Redis server load exceeds 80%'
    severity: environmentId == 'prod' ? 2 : 3
    enabled: true
    scopes: [
      redisCacheId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighServerLoad'
          metricName: 'serverLoad'
          metricNamespace: 'Microsoft.Cache/redis'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Redis Memory Usage Alert
resource redisMemoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-redis-memory-high'
  location: location
  tags: tags
  properties: {
    description: 'Alert when Redis used memory exceeds 85%'
    severity: environmentId == 'prod' ? 2 : 3
    enabled: true
    scopes: [
      redisCacheId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighMemory'
          metricName: 'usedmemorypercentage'
          metricNamespace: 'Microsoft.Cache/redis'
          operator: 'GreaterThan'
          threshold: 85
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Application Insights Availability Alert
resource availabilityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (environmentId == 'prod') {
  name: 'alert-availability-low'
  location: location
  tags: tags
  properties: {
    description: 'Alert when application availability drops below 99%'
    severity: 1
    enabled: true
    scopes: [
      applicationInsightsId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'LowAvailability'
          metricName: 'availabilityResults/availabilityPercentage'
          metricNamespace: 'Microsoft.Insights/components'
          operator: 'LessThan'
          threshold: 99
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Outputs
@description('The resource ID of the action group.')
output actionGroupId string = actionGroup.id

@description('The name of the action group.')
output actionGroupName string = actionGroup.name

@description('The resource IDs of all metric alerts created.')
output alertIds array = [
  appServiceCpuAlert.id
  appServiceMemoryAlert.id
  appServiceResponseTimeAlert.id
  appServiceErrorsAlert.id
  postgresqlCpuAlert.id
  postgresqlMemoryAlert.id
  postgresqlStorageAlert.id
  redisServerLoadAlert.id
  redisMemoryAlert.id
]
