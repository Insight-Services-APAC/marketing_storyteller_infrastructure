# Infrastructure Repository Setup Guide

## Step-by-Step Instructions

### 1. Create Infrastructure Repository

```bash
# Create repository via GitHub CLI
gh repo create Insight-Services-APAC/marketing_storyteller_infrastructure \
  --public \
  --description "Azure infrastructure as code for Marketing Storyteller" \
  --clone

cd marketing_storyteller_infrastructure

# Copy README template from application repository
curl -o README.md https://raw.githubusercontent.com/Insight-Services-APAC/marketing_storyteller/main/docs/operations/INFRASTRUCTURE_README_TEMPLATE.md

# Copy evaluation script from application repository
curl -o evaluate-caf-template.sh https://raw.githubusercontent.com/Insight-Services-APAC/marketing_storyteller/main/docs/operations/evaluate-caf-template.sh
chmod +x evaluate-caf-template.sh
```

### 2. Clone CAF Template

```bash
# Clone the base template to a temporary directory
git clone https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1.git caf-temp

# Run evaluation script to analyze CAF template structure
./evaluate-caf-template.sh

# Review the generated report
cat CAF_EVALUATION_REPORT.md

# Copy relevant structure (adjust based on actual template structure)
cp -r caf-temp/bicep ./
cp -r caf-temp/.github ./
cp caf-temp/.gitignore ./
cp caf-temp/README.md ./README.template.md

# Remove temp directory after copying required files
# (DO NOT delete yet - keep for reference until first deployment succeeds)
```

### 3. Create Initial Repository Structure

```
marketing_storyteller_infrastructure/
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml
│       ├── deploy-prod.yml
│       └── validate.yml
├── bicep/
│   ├── modules/
│   │   ├── app-service.bicep
│   │   ├── postgresql.bicep
│   │   ├── storage.bicep
│   │   ├── redis.bicep
│   │   ├── openai.bicep
│   │   ├── keyvault.bicep
│   │   ├── monitoring.bicep
│   │   └── networking.bicep (from CAF template)
│   ├── main.bicep
│   └── parameters/
│       ├── dev.bicepparam
│       └── prod.bicepparam
├── scripts/
│   ├── deploy.sh
│   └── validate.sh
├── docs/
│   ├── architecture.md
│   └── deployment-guide.md
├── .gitignore
└── README.md
```

### 4. Create README.md

````markdown
# Marketing Storyteller - Azure Infrastructure

Infrastructure as Code (IaC) for deploying Marketing Storyteller to Azure.

## Overview

This repository contains Bicep templates for deploying the Marketing Storyteller application to Azure, following Cloud Adoption Framework (CAF) best practices.

**Base Template**: [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1)

**Application Repository**: [marketing_storyteller](https://github.com/Insight-Services-APAC/marketing_storyteller)

## Deployed Resources

### Development Environment

- Resource Group: `rg-marketingstory-dev-aue`
- App Service Plan: Premium V3 (P1V3)
- Azure Database for PostgreSQL: Burstable B1ms
- Azure Storage Account: Standard LRS
- Azure Cache for Redis: Basic C0
- Azure OpenAI Service: GPT-4 deployment
- Key Vault: Standard
- Application Insights

### Production Environment

- Resource Group: `rg-marketingstory-prod-aue`
- App Service Plan: Premium V3 (P2V3)
- Azure Database for PostgreSQL: General Purpose
- Azure Storage Account: Standard GRS
- Azure Cache for Redis: Standard C1
- Azure OpenAI Service: GPT-4 deployment
- Key Vault: Standard
- Application Insights

## Prerequisites

- Azure CLI (`az`) version 2.50+
- Azure subscription with appropriate permissions
- GitHub account with access to deploy workflows
- Service Principal for GitHub Actions

## Quick Start

### 1. Deploy to Development

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <subscription-id>

# Create resource group
az group create \
  --name rg-marketingstory-dev-aue \
  --location australiaeast

# Deploy infrastructure
az deployment group create \
  --resource-group rg-marketingstory-dev-aue \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.bicepparam
```
````

### 2. Deploy via GitHub Actions

Infrastructure deployments are automated via GitHub Actions:

1. Push changes to `main` branch
2. Navigate to Actions tab
3. Select "Deploy to Development" workflow
4. Click "Run workflow"

## Repository Structure

- `bicep/` - Bicep templates and modules
- `bicep/modules/` - Reusable infrastructure modules
- `bicep/parameters/` - Environment-specific parameters
- `.github/workflows/` - CI/CD pipelines
- `scripts/` - Deployment and utility scripts
- `docs/` - Architecture and deployment documentation

## Configuration

### Required Secrets

Configure these secrets in GitHub repository settings:

```
AZURE_CREDENTIALS          # Service principal JSON
AZURE_SUBSCRIPTION_ID      # Azure subscription ID
AZURE_TENANT_ID           # Azure AD tenant ID
```

### Environment Variables

Set in `.bicepparam` files:

- `appServiceName` - Name of the App Service
- `location` - Azure region (default: australiaeast)
- `environment` - dev or prod
- `postgresqlAdminUsername` - Database admin username
- `openAIDeploymentName` - GPT model deployment name

## Deployment Workflow

1. **Validate**: Bicep templates are validated on pull requests
2. **Preview**: What-if deployment shows changes before applying
3. **Deploy**: Infrastructure is deployed to Azure
4. **Verify**: Health checks ensure successful deployment

## Cost Management

### Development Environment

Estimated monthly cost: ~$200 USD

### Production Environment

Estimated monthly cost: ~$725 USD

See [AZURE_DEPLOYMENT_PLAN.md](../marketing_storyteller/docs/operations/AZURE_DEPLOYMENT_PLAN.md) for detailed breakdown.

## Architecture

![Architecture Diagram](docs/architecture-diagram.png)

See [docs/architecture.md](docs/architecture.md) for detailed architecture documentation.

## Support

For issues related to:

- **Infrastructure**: Open issue in this repository
- **Application**: Open issue in [marketing_storyteller](https://github.com/Insight-Services-APAC/marketing_storyteller)

## License

Copyright © 2025 Insight Services APAC. All rights reserved.

````

### 5. Link Repositories in Application README

Add this section to `marketing_storyteller/README.md`:

```markdown
## Infrastructure

Azure infrastructure for this application is managed in a separate repository:

**Infrastructure Repository**: [marketing_storyteller_infrastructure](https://github.com/Insight-Services-APAC/marketing_storyteller_infrastructure)

The infrastructure uses Bicep templates based on the [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1) CAF-aligned template.

### Deployed Environments

- **Development**: https://app-marketingstory-dev-aue.azurewebsites.net
- **Production**: https://app-marketingstory-prod-aue.azurewebsites.net
````

### 6. Remove Unnecessary CAF Modules

Based on Marketing Storyteller requirements, you can safely remove:

```bash
# Navigate to infrastructure repo
cd marketing_storyteller_infrastructure/bicep/modules

# Remove unnecessary modules (adjust paths based on actual CAF template)
rm -rf kubernetes/          # Not using AKS
rm -rf container-registry/  # Not using ACR
rm -rf vpn/                 # Not needed for basic deployment
rm -rf expressroute/        # Not needed
rm -rf front-door/          # Not needed (single region)
rm -rf cdn/                 # Not needed for internal app
rm -rf firewall/            # May keep if required by CAF policy
rm -rf api-management/      # Not needed
```

### 7. Create Initial Bicep Modules

**Example: App Service Module** (`bicep/modules/app-service.bicep`)

```bicep
@description('Name of the App Service')
param appServiceName string

@description('Location for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
param skuName string = 'P1V3'

@description('App Service Plan capacity')
param skuCapacity int = 1

@description('Environment name')
param environment string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Key Vault name for referencing secrets')
param keyVaultName string

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${appServiceName}-plan'
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
    application: 'marketing-storyteller'
  }
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'NODE_ENV'
          value: environment == 'prod' ? 'production' : 'development'
        }
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/database-url/)'
        }
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/openai-api-key/)'
        }
        {
          name: 'REDIS_PASSWORD'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/redis-password/)'
        }
        {
          name: 'NEXTAUTH_SECRET'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/nextauth-secret/)'
        }
      ]
    }
  }
  tags: {
    environment: environment
    application: 'marketing-storyteller'
  }
}

// Grant App Service access to Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceHostName string = appService.properties.defaultHostName
output appServicePrincipalId string = appService.identity.principalId
```

### 8. Create Main Bicep Template

**`bicep/main.bicep`**

```bicep
targetScope = 'resourceGroup'

@description('Environment name (dev or prod)')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Location for all resources')
param location string = 'australiaeast'

@description('PostgreSQL administrator username')
@secure()
param postgresqlAdminUsername string

@description('PostgreSQL administrator password')
@secure()
param postgresqlAdminPassword string

// Naming convention
var naming = {
  appService: 'app-marketingstory-${environment}-aue'
  postgresql: 'psql-marketingstory-${environment}-aue'
  storage: 'stmarketstory${environment}aue'
  redis: 'redis-marketingstory-${environment}-aue'
  keyVault: 'kv-mstory-${environment}-aue'
  openai: 'oai-marketingstory-${environment}-aue'
  appInsights: 'appi-marketingstory-${environment}-aue'
}

// SKUs per environment
var skus = environment == 'prod' ? {
  appService: 'P2V3'
  postgresql: 'Standard_D2s_v3'
  storage: 'Standard_GRS'
  redis: 'Standard'
  redisCapacity: 1
} : {
  appService: 'P1V3'
  postgresql: 'Standard_B1ms'
  storage: 'Standard_LRS'
  redis: 'Basic'
  redisCapacity: 0
}

// Application Insights
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    appInsightsName: naming.appInsights
    location: location
    environment: environment
  }
}

// Key Vault
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    keyVaultName: naming.keyVault
    location: location
    environment: environment
  }
}

// PostgreSQL Database
module database 'modules/postgresql.bicep' = {
  name: 'database-deployment'
  params: {
    serverName: naming.postgresql
    location: location
    administratorLogin: postgresqlAdminUsername
    administratorLoginPassword: postgresqlAdminPassword
    skuName: skus.postgresql
    environment: environment
    keyVaultName: naming.keyVault
  }
  dependsOn: [
    keyVault
  ]
}

// Storage Account
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    storageAccountName: naming.storage
    location: location
    skuName: skus.storage
    environment: environment
  }
}

// Redis Cache
module redis 'modules/redis.bicep' = {
  name: 'redis-deployment'
  params: {
    redisName: naming.redis
    location: location
    skuName: skus.redis
    skuCapacity: skus.redisCapacity
    environment: environment
    keyVaultName: naming.keyVault
  }
  dependsOn: [
    keyVault
  ]
}

// Azure OpenAI
module openai 'modules/openai.bicep' = {
  name: 'openai-deployment'
  params: {
    openAIName: naming.openai
    location: location
    environment: environment
    keyVaultName: naming.keyVault
  }
  dependsOn: [
    keyVault
  ]
}

// App Service
module appService 'modules/app-service.bicep' = {
  name: 'appservice-deployment'
  params: {
    appServiceName: naming.appService
    location: location
    skuName: skus.appService
    environment: environment
    appInsightsConnectionString: monitoring.outputs.connectionString
    keyVaultName: naming.keyVault
  }
  dependsOn: [
    keyVault
    monitoring
    database
    storage
    redis
    openai
  ]
}

output appServiceUrl string = 'https://${appService.outputs.appServiceHostName}'
output resourceGroupName string = resourceGroup().name
output environment string = environment
```

### 9. Create GitHub Actions Workflow

**`.github/workflows/deploy-dev.yml`**

```yaml
name: Deploy to Development

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Validate Bicep
        run: |
          az deployment group validate \
            --resource-group rg-marketingstory-dev-aue \
            --template-file bicep/main.bicep \
            --parameters bicep/parameters/dev.bicepparam

  deploy:
    needs: validate
    runs-on: ubuntu-latest
    environment: development
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Infrastructure
        uses: azure/arm-deploy@v1
        with:
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          resourceGroupName: rg-marketingstory-dev-aue
          template: ./bicep/main.bicep
          parameters: ./bicep/parameters/dev.bicepparam
          failOnStdErr: false

      - name: Output App Service URL
        run: |
          echo "Application deployed to:"
          az webapp show \
            --name app-marketingstory-dev-aue \
            --resource-group rg-marketingstory-dev-aue \
            --query defaultHostName \
            --output tsv
```

### 10. Initial Commit and Push

```bash
# In marketing_storyteller_infrastructure directory
git add .
git commit -m "Initial infrastructure setup based on CAF template

- Created Bicep modules for App Service, PostgreSQL, Storage, Redis, OpenAI, Key Vault
- Configured Dev and Prod parameter files
- Set up GitHub Actions workflows
- Added documentation

Base template: https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1"

git push origin main
```

## Next Steps

1. **Review CAF Template**: Examine the actual structure of the base template
2. **Customize Modules**: Adapt Bicep modules to match CAF conventions
3. **Configure Secrets**: Set up GitHub secrets for deployment
4. **Test Deployment**: Deploy to dev environment first
5. **Document Changes**: Update architecture docs with actual deployed resources
6. **Production Deployment**: After dev validation, deploy to prod

## Linking Strategy Recommendation

**Use Documentation Links** (recommended for simplicity):

1. Add infrastructure link to `marketing_storyteller/README.md`
2. Add application link to `marketing_storyteller_infrastructure/README.md`
3. Use GitHub Actions `repository_dispatch` to coordinate deployments

This approach is simpler than git submodules and provides clear separation of concerns.
