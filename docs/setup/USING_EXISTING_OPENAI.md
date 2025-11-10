# Using Existing Azure OpenAI / AI Foundry Services

## Overview

The Marketing Storyteller infrastructure now supports **reusing existing Azure OpenAI services** instead of creating new ones. This is the recommended approach in most enterprise environments.

## Why Reuse Existing OpenAI Services?

✅ **Avoid Quota Issues** - Share quota across multiple projects  
✅ **Centralized Governance** - Manage AI services from a central platform  
✅ **Cost Management** - Better visibility and control of AI spending  
✅ **Faster Deployment** - No need to wait for new OpenAI service provisioning  
✅ **Standardization** - Use organization-wide AI Foundry hubs

## How It Works

The OpenAI module (`src/modules/openai.bicep`) now supports two modes:

### Mode 1: Create New OpenAI Service (Default)
```bicep
param useExistingOpenAI = false
```
- Creates a new Azure OpenAI service
- Deploys GPT-4 model
- Full control over the service

### Mode 2: Use Existing OpenAI Service (Recommended)
```bicep
param useExistingOpenAI = true
param existingOpenAIName = 'oai-shared-dev-aue'
param existingOpenAIResourceGroup = 'rg-shared-ai-dev-aue'
param existingGPT4DeploymentName = 'gpt-4'
```
- References existing Azure OpenAI service
- Uses existing GPT-4 deployment
- App Service gets access via managed identity

## Configuration

### Development Environment

Edit `src/configuration/main.dev.bicepparam`:

```bicep
// Option 1: Use existing OpenAI (recommended)
param useExistingOpenAI = true
param existingOpenAIName = 'oai-shared-dev-aue'
param existingOpenAIResourceGroup = 'rg-shared-ai-dev-aue'
param existingGPT4DeploymentName = 'gpt-4'
```

### Production Environment

Edit `src/configuration/main.prod.bicepparam`:

```bicep
// Option 1: Use existing OpenAI (recommended)
param useExistingOpenAI = true
param existingOpenAIName = 'oai-shared-prod-aue'
param existingOpenAIResourceGroup = 'rg-shared-ai-prod-aue'
param existingGPT4DeploymentName = 'gpt-4'
```

## Finding Your OpenAI Service

### List All OpenAI Services
```bash
az cognitiveservices account list \
  --query "[?kind=='OpenAI'].{Name:name, ResourceGroup:resourceGroup, Location:location}" \
  --output table
```

### Get Service Details
```bash
az cognitiveservices account show \
  --name oai-shared-dev-aue \
  --resource-group rg-shared-ai-dev-aue
```

### List Deployments
```bash
az cognitiveservices account deployment list \
  --name oai-shared-dev-aue \
  --resource-group rg-shared-ai-dev-aue \
  --output table
```

## Deployment Examples

### Using Configuration File
```bash
# Dev with existing OpenAI (configured in main.dev.bicepparam)
./scripts/deploy.sh -e dev -p 'Password123!'

# Prod with existing OpenAI (configured in main.prod.bicepparam)
./scripts/deploy.sh -e prod -p 'Password123!'
```

### Using Command Line Parameters
```bash
# Override at deployment time
az deployment sub create \
  --name marketingstory-dev-$(date +%Y%m%d) \
  --location australiaeast \
  --template-file src/orchestration/main.bicep \
  --parameters src/configuration/main.dev.bicepparam \
  --parameters postgresAdminPassword='Password123!' \
  --parameters useExistingOpenAI=true \
  --parameters existingOpenAIName='oai-shared-dev-aue' \
  --parameters existingOpenAIResourceGroup='rg-shared-ai-dev-aue' \
  --parameters existingGPT4DeploymentName='gpt-4'
```

## What Happens During Deployment

### When Using Existing OpenAI

1. ✅ **Reference** existing OpenAI service (no new service created)
2. ✅ **Read** endpoint and deployment information
3. ✅ **Configure** App Service with OpenAI connection details
4. ✅ **Grant** App Service managed identity access to read OpenAI keys
5. ✅ **Skip** GPT-4 deployment (uses existing deployment)

### When Creating New OpenAI

1. ✅ **Create** new Azure OpenAI service
2. ✅ **Deploy** GPT-4 model with specified capacity
3. ✅ **Configure** App Service with OpenAI connection details
4. ✅ **Grant** App Service managed identity access

## Environment Variables

The App Service will automatically receive these environment variables (same in both modes):

```bash
AZURE_OPENAI_ENDPOINT=https://oai-shared-dev-aue.openai.azure.com/
AZURE_OPENAI_API_KEY=<managed-by-azure>
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
```

## Security & Access

### Permissions Required

To use an existing OpenAI service, the deployment needs:
- **Read access** to the existing OpenAI service
- **Ability to list keys** from the OpenAI service

### App Service Access

The App Service's managed identity will be granted:
- **Cognitive Services OpenAI User** role on the OpenAI service
- Ability to read API keys at runtime

## Troubleshooting

### Error: "Resource not found"
**Cause:** OpenAI service name or resource group is incorrect  
**Solution:** Verify the names with `az cognitiveservices account list`

### Error: "Deployment not found"
**Cause:** GPT-4 deployment doesn't exist in the OpenAI service  
**Solution:** Check deployment names with `az cognitiveservices account deployment list`

### Error: "Insufficient permissions"
**Cause:** Deployment principal doesn't have access to the existing OpenAI service  
**Solution:** Grant Contributor or Cognitive Services Contributor role

## Best Practices

✅ **Dev Environment:** Use shared dev OpenAI service to save quota  
✅ **Prod Environment:** Use dedicated or shared prod OpenAI based on governance  
✅ **Naming:** Use consistent deployment names (e.g., 'gpt-4', 'gpt-35-turbo')  
✅ **Documentation:** Document which projects use which shared services  
✅ **Monitoring:** Track usage by app using Azure Monitor

## Cost Comparison

### Using Shared OpenAI Service
- **Shared Cost:** $0 (included in shared service)
- **App-Specific Cost:** ~$130/month (no OpenAI cost)
- **Total Dev:** ~$130/month
- **Total Prod:** ~$655/month

### Creating New OpenAI Service
- **OpenAI Cost:** ~$70/month (10K TPM dev), ~$70/month (50K TPM prod)
- **App-Specific Cost:** ~$130/month
- **Total Dev:** ~$200/month
- **Total Prod:** ~$725/month

**Savings:** ~$70/month per environment when using shared services

## Migration Path

### From New to Existing OpenAI

1. Deploy initially with new OpenAI service
2. Test the application
3. When ready, update parameter file to use shared service
4. Redeploy
5. Delete the old OpenAI service

### From Existing to New OpenAI

1. Update parameter file: `useExistingOpenAI = false`
2. Redeploy
3. New OpenAI service will be created

## Related Documentation

- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Complete deployment instructions
- [Quick Reference](QUICK_REFERENCE.md) - Common commands
- [Azure OpenAI Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
