# Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the Marketing Storyteller infrastructure to Azure.

## Prerequisites

1. **Azure CLI** installed and configured
   ```bash
   # Install Azure CLI
   # Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   
   # Verify installation
   az --version
   ```

2. **Azure Subscription** with appropriate permissions
   - Contributor role or higher at subscription level
   - Ability to create resource groups and resources

3. **Bicep** (included with Azure CLI 2.20.0+)
   ```bash
   # Verify Bicep installation
   az bicep version
   ```

## Quick Start

### 1. Validate Templates

Before deploying, validate all Bicep templates:

```bash
./scripts/validate.sh
```

This will:
- Check all module syntax
- Verify the main orchestration template
- Ensure no compilation errors

### 2. Deploy to Development

```bash
./scripts/deploy.sh \
  -e dev \
  -p 'YourSecurePassword123!' \
  -s 'your-subscription-id'
```

**Parameters:**
- `-e, --environment`: Environment to deploy (`dev` or `prod`)
- `-p, --postgres-password`: PostgreSQL administrator password (must meet complexity requirements)
- `-s, --subscription`: Azure subscription ID (optional, uses current subscription if not specified)

### 3. Deploy to Production

```bash
./scripts/deploy.sh \
  -e prod \
  -p 'YourSecurePassword123!' \
  -s 'your-subscription-id'
```

## Manual Deployment

If you prefer manual deployment or need more control:

### Step 1: Login to Azure

```bash
az login
az account set --subscription <subscription-id>
```

### Step 2: Validate Templates

```bash
# Validate main template
az bicep build --file src/orchestration/main.bicep

# Validate individual modules
az bicep build --file src/modules/monitoring.bicep
az bicep build --file src/modules/storage.bicep
# ... etc
```

### Step 3: Deploy to Subscription

```bash
# Development environment
az deployment sub create \
  --name marketingstory-dev-$(date +%Y%m%d-%H%M%S) \
  --location australiaeast \
  --template-file src/orchestration/main.bicep \
  --parameters src/configuration/main.dev.bicepparam \
  --parameters postgresAdminPassword='YourSecurePassword123!'

# Production environment
az deployment sub create \
  --name marketingstory-prod-$(date +%Y%m%d-%H%M%S) \
  --location australiaeast \
  --template-file src/orchestration/main.bicep \
  --parameters src/configuration/main.prod.bicepparam \
  --parameters postgresAdminPassword='YourSecurePassword123!'
```

### Step 4: Retrieve Outputs

```bash
az deployment sub show \
  --name <deployment-name> \
  --query properties.outputs
```

## Using Existing Azure OpenAI / AI Foundry

In most enterprise environments, you'll want to reuse an existing Azure OpenAI service or AI Foundry hub to:
- Share AI resources across multiple projects
- Avoid quota allocation issues
- Centralize AI governance and cost management

### Configure Existing OpenAI in Dev Environment

1. **Edit** `src/configuration/main.dev.bicepparam`
2. **Uncomment and update** the OpenAI parameters:

```bicep
// Azure OpenAI Configuration
param useExistingOpenAI = true
param existingOpenAIName = 'oai-shared-dev-aue'  // Your OpenAI service name
param existingOpenAIResourceGroup = 'rg-shared-ai-dev-aue'  // Resource group
param existingGPT4DeploymentName = 'gpt-4'  // Deployment name in the service
```

3. **Deploy normally** - the infrastructure will use the existing service instead of creating a new one

### Configure Existing OpenAI in Prod Environment

1. **Edit** `src/configuration/main.prod.bicepparam`
2. **Update** the parameters:

```bicep
param useExistingOpenAI = true
param existingOpenAIName = 'oai-shared-prod-aue'
param existingOpenAIResourceGroup = 'rg-shared-ai-prod-aue'
param existingGPT4DeploymentName = 'gpt-4'
```

### Finding Your Existing OpenAI Service

```bash
# List all Azure OpenAI services in your subscription
az cognitiveservices account list \
  --query "[?kind=='OpenAI'].{Name:name, ResourceGroup:resourceGroup, Location:location}" \
  --output table

# Get details of a specific OpenAI service
az cognitiveservices account show \
  --name <openai-service-name> \
  --resource-group <resource-group-name>

# List deployments in the OpenAI service
az cognitiveservices account deployment list \
  --name <openai-service-name> \
  --resource-group <resource-group-name> \
  --output table
```

### Manual Deployment with Existing OpenAI

```bash
# Deploy dev with existing OpenAI
az deployment sub create \
  --name marketingstory-dev-$(date +%Y%m%d-%H%M%S) \
  --location australiaeast \
  --template-file src/orchestration/main.bicep \
  --parameters src/configuration/main.dev.bicepparam \
  --parameters postgresAdminPassword='Password123!' \
  --parameters useExistingOpenAI=true \
  --parameters existingOpenAIName='oai-shared-dev-aue' \
  --parameters existingOpenAIResourceGroup='rg-shared-ai-dev-aue' \
  --parameters existingGPT4DeploymentName='gpt-4'
```

### Important Notes

- The App Service will be granted access to read keys from the existing OpenAI service
- Ensure the GPT-4 deployment exists in the shared OpenAI service
- The deployment name must match exactly (default is 'gpt-4')
- The existing OpenAI service must be in the same subscription

## What Gets Deployed

### Development Environment

**Resource Group:** `rg-marketingstory-dev-aue`

| Resource Type | Name | SKU/Tier | Purpose |
|--------------|------|----------|---------|
| App Service Plan | `asp-marketingstory-dev-aue` | P1V3 | Hosts Next.js app |
| App Service | `app-marketingstory-dev-aue` | Linux, Node 20 | Next.js application |
| PostgreSQL | `psql-marketingstory-dev-aue` | Standard_B1ms (Burstable) | Database |
| Storage Account | `stmarketingstorydevaue` | Standard_LRS | Document storage |
| Redis Cache | `redis-marketingstory-dev-aue` | Basic C0 | BullMQ job queue |
| Azure OpenAI | `oai-marketingstory-dev-aue` | S0 (10K TPM) | GPT-4 AI features |
| Key Vault | `kv-marketingstory-dev-aue` | Standard | Secrets management |
| Log Analytics | `law-marketingstory-dev-aue` | PerGB2018 | Monitoring |
| App Insights | `appi-marketingstory-dev-aue` | Standard | Application monitoring |

**Estimated Cost:** ~$200 USD/month

### Production Environment

**Resource Group:** `rg-marketingstory-prod-aue`

| Resource Type | Name | SKU/Tier | Purpose |
|--------------|------|----------|---------|
| App Service Plan | `asp-marketingstory-prod-aue` | P2V3 | Hosts Next.js app |
| App Service | `app-marketingstory-prod-aue` | Linux, Node 20 | Next.js application |
| PostgreSQL | `psql-marketingstory-prod-aue` | Standard_D2s_v3 (GP) | Database |
| Storage Account | `stmarketingstoryprodaue` | Standard_GRS | Document storage |
| Redis Cache | `redis-marketingstory-prod-aue` | Standard C1 | BullMQ job queue |
| Azure OpenAI | `oai-marketingstory-prod-aue` | S0 (50K TPM) | GPT-4 AI features |
| Key Vault | `kv-marketingstory-prod-aue` | Standard | Secrets management |
| Log Analytics | `law-marketingstory-prod-aue` | PerGB2018 | Monitoring |
| App Insights | `appi-marketingstory-prod-aue` | Standard | Application monitoring |

**Estimated Cost:** ~$725 USD/month

## Deployment Outputs

After successful deployment, you'll receive:

- `resourceGroupName` - Name of the created resource group
- `appServiceUrl` - URL of the deployed App Service
- `appServicePrincipalId` - Managed identity principal ID for the app
- `postgresqlServerFqdn` - PostgreSQL server fully qualified domain name
- `keyVaultUri` - Key Vault URI
- `applicationInsightsConnectionString` - App Insights connection string
- `storageAccountName` - Storage account name
- `redisCacheHostname` - Redis cache hostname
- `openAIEndpoint` - Azure OpenAI endpoint

## Post-Deployment Steps

### 1. Configure Application Secrets

Store sensitive configuration in Key Vault:

```bash
# Get Key Vault name
KV_NAME=$(az deployment sub show \
  --name <deployment-name> \
  --query properties.outputs.keyVaultUri.value -o tsv | cut -d'/' -f3 | cut -d'.' -f1)

# Add secrets
az keyvault secret set --vault-name $KV_NAME --name "nextauth-secret" --value "<your-secret>"
az keyvault secret set --vault-name $KV_NAME --name "google-client-id" --value "<your-client-id>"
az keyvault secret set --vault-name $KV_NAME --name "google-client-secret" --value "<your-client-secret>"
```

### 2. Deploy Application Code

Deploy your Next.js application to the App Service:

```bash
# Using Azure App Service deployment
cd <your-app-repository>
npm run build
az webapp deployment source config-zip \
  --resource-group rg-marketingstory-dev-aue \
  --name app-marketingstory-dev-aue \
  --src <path-to-zip>
```

### 3. Initialize Database

Run database migrations:

```bash
# SSH into App Service or run locally with connection string
npm run db:migrate
npm run db:seed  # If you have seed data
```

### 4. Verify Deployment

Check the application:

```bash
# Get App Service URL
az deployment sub show \
  --name <deployment-name> \
  --query properties.outputs.appServiceUrl.value -o tsv
```

Visit the URL in your browser to verify the deployment.

## Troubleshooting

### Deployment Fails

1. **Check Bicep validation:**
   ```bash
   ./scripts/validate.sh
   ```

2. **Review deployment logs:**
   ```bash
   az deployment sub show \
     --name <deployment-name> \
     --query properties.error
   ```

3. **Common issues:**
   - Resource name conflicts (names must be globally unique for some resources)
   - Insufficient permissions
   - Quota limits (especially for Azure OpenAI)

### Azure OpenAI Quota

If you get quota errors:

1. Request quota increase in Azure Portal
2. Choose a different region with available capacity
3. Reduce `gpt4Capacity` parameter temporarily

### PostgreSQL Connection Issues

1. **Verify firewall rules:**
   ```bash
   az postgres flexible-server firewall-rule list \
     --resource-group rg-marketingstory-dev-aue \
     --name psql-marketingstory-dev-aue
   ```

2. **Add your IP if needed:**
   ```bash
   az postgres flexible-server firewall-rule create \
     --resource-group rg-marketingstory-dev-aue \
     --name psql-marketingstory-dev-aue \
     --rule-name AllowMyIP \
     --start-ip-address <your-ip> \
     --end-ip-address <your-ip>
   ```

## Updating Infrastructure

To update existing infrastructure:

1. Modify Bicep templates as needed
2. Validate changes: `./scripts/validate.sh`
3. Deploy with same deployment name or new name
4. Azure will perform an incremental update

## Cleanup

To remove all resources:

```bash
# Development
az group delete --name rg-marketingstory-dev-aue --yes --no-wait

# Production
az group delete --name rg-marketingstory-prod-aue --yes --no-wait
```

**Warning:** This permanently deletes all resources and data!

## Next Steps

- Set up GitHub Actions for CI/CD (see `.github/workflows/` directory)
- Configure custom domains
- Set up monitoring alerts
- Review security recommendations
- Enable backup policies for production

## Support

For issues or questions:
- Check documentation in `docs/operations/`
- Review CAF template examples in `temp-caf/`
- Open an issue in the repository
