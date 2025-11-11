# Lessons Learned - Sandbox Deployment

**Date**: November 11, 2025  
**Environment**: Sandbox  
**Deployment Type**: Initial infrastructure deployment  
**Status**: ✅ Successful

## Executive Summary

Successfully deployed sandbox environment after resolving several Azure-specific configuration issues. All fixes have been applied to dev and prod configurations to prevent similar issues in future deployments.

## Issues Encountered and Resolutions

### 1. App Service Plan SKU Validation Error

**Issue**: Initial configuration used `B1` (Basic tier) SKU for sandbox App Service Plan.

**Error**:
```json
{
  "code": "InvalidTemplate",
  "message": "The provided value for the template parameter 'skuName' is not valid. 
             The value 'B1' is not part of the allowed value(s): 
             'P1V3,P2V3,P3V3,P1V2,P2V2,P3V2,S1,S2,S3'."
}
```

**Root Cause**: The `app-service.bicep` module's allowed SKUs list only includes Standard (S1-S3) and Premium (P1V2-P3V3) tiers. Basic tier is not supported for this configuration.

**Resolution**: Changed sandbox SKU from `B1` to `S1` (cheapest allowed Standard tier).

**Applied To**:
- ✅ Sandbox: `S1` (Standard tier)
- ✅ Dev: `P1V3` (Premium v3 tier)
- ✅ Prod: `P2V3` (Premium v3 tier)

**Files Modified**:
- `src/orchestration/main.bicep` - Line 84

---

### 2. Azure Files Connection String Conflict

**Issue**: Using `AZURE_STORAGE_CONNECTION_STRING` as app setting name caused validation errors.

**Error**:
```json
{
  "code": "BadRequest",
  "message": "The data is not valid (Invalid values supplied for Azure Files related app settings.)"
}
```

**Root Cause**: `AZURE_STORAGE_CONNECTION_STRING` is a reserved app setting name that Azure uses for Azure Files mount points. Using this name triggers Azure Files validation logic, which rejects Key Vault references in this context.

**Resolution**: 
1. Renamed app setting from `AZURE_STORAGE_CONNECTION_STRING` to `BLOB_STORAGE_CONNECTION_STRING`
2. Moved app settings from `siteConfig.appSettings` array to separate `Microsoft.Web/sites/config` child resource
3. Changed format from array of name/value objects to flat object (cleaner syntax)

**Applied To**: All environments (sandbox, dev, prod)

**Files Modified**:
- `src/orchestration/main.bicep` - Line 324
- `src/modules/app-service.bicep` - Lines 95-127

**Code Change**:
```bicep
// Before (caused error)
AZURE_STORAGE_CONNECTION_STRING: '@Microsoft.KeyVault(...)'

// After (works correctly)
BLOB_STORAGE_CONNECTION_STRING: '@Microsoft.KeyVault(...)'
```

---

### 3. Log Retention Below Azure Minimum

**Issue**: Initial configuration set `logRetentionDays: 7` which is below Azure's minimum requirement.

**Root Cause**: Azure Log Analytics Workspace requires minimum 30 days retention.

**Resolution**: Updated all environments to meet minimum retention requirements.

**Applied To**:
- ✅ Sandbox: 30 days (minimum)
- ✅ Dev: 30 days (minimum)
- ✅ Prod: 90 days (recommended for compliance)

**Files Modified**:
- `src/orchestration/main.bicep` - Lines 95, 109, 123

---

### 4. GPT-5 Mini Model Configuration

**Issue**: Initial configuration referenced outdated model version and name.

**Resolution**: 
1. Updated model name from `gpt-4o-mini` to `gpt-5-mini` (current model)
2. Removed hardcoded version `2024-11-01`, now uses empty string to get latest version automatically
3. Updated deployment script to prioritize GPT-5 Mini when detecting existing deployments

**Applied To**: All environments

**Files Modified**:
- `src/modules/openai.bicep` - Lines 47-53
- `scripts/deploy.sh` - Lines 210-230

**Code Change**:
```bicep
// Model configuration
param gpt4ModelName string = 'gpt-5-mini'
param gpt4ModelVersion string = ''  // Empty = use latest available
```

---

### 5. App Service Internal Server Errors

**Issue**: Web App creation failed with transient `InternalServerError` during Bicep deployment.

**Resolution**: 
- Created Web App via Azure CLI successfully
- Modified Bicep module to deploy app settings as separate child resource
- This approach is more resilient and avoids timing/validation issues

**Applied To**: All environments

**Files Modified**:
- `src/modules/app-service.bicep` - Added separate `appServiceSettings` resource

---

## Architecture Patterns Established

### 1. App Settings Deployment Pattern

**Best Practice**: Deploy app settings as separate `Microsoft.Web/sites/config` child resource, not inline in `siteConfig`.

**Benefits**:
- Cleaner separation of concerns
- Avoids Azure Files validation conflicts
- More reliable deployment
- Easier to update settings independently

**Pattern**:
```bicep
// App Service (main resource)
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|${nodeVersion}'
      alwaysOn: alwaysOn
      // NO appSettings here
    }
  }
}

// App Settings (separate child resource)
resource appServiceSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: appService
  name: 'appsettings'
  properties: union({
    WEBSITE_NODE_DEFAULT_VERSION: '~${nodeVersion}'
    SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
  }, appSettings)
}
```

### 2. Reserved App Setting Names to Avoid

**Never Use These Names** (reserved by Azure):
- `AZURE_STORAGE_CONNECTION_STRING` - Reserved for Azure Files
- `WEBSITE_CONTENTAZUREFILECONNECTIONSTRING` - Azure Files mount
- `WEBSITE_CONTENTSHARE` - Azure Files share name
- `AZUREFILESCONNECTIONSTRING` - Azure Files connection

**Safe Alternatives**:
- `BLOB_STORAGE_CONNECTION_STRING` - Application blob storage
- `STORAGE_CONNECTION_STRING` - Generic storage access
- `APP_STORAGE_CONNECTION` - Application-specific storage

### 3. Model Deployment Configuration

**Best Practice**: Don't hardcode model versions, use empty string to get latest.

**Benefits**:
- Automatic updates to latest stable version
- No need to track version numbers
- Azure manages version lifecycle

**Pattern**:
```bicep
param gpt4ModelName string = 'gpt-5-mini'
param gpt4ModelVersion string = ''  // Empty = latest

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  properties: {
    model: {
      name: gpt4ModelName
      version: !empty(gpt4ModelVersion) ? gpt4ModelVersion : null
    }
  }
}
```

---

## Configuration Matrix

### Environment SKU Decisions

| Resource | Sandbox | Dev | Prod | Rationale |
|----------|---------|-----|------|-----------|
| App Service | S1 | P1V3 | P2V3 | S1 cheapest allowed; Premium for scaling |
| PostgreSQL | Standard_B1ms | Standard_B1ms | Standard_D2s_v3 | Burstable for dev; General Purpose for prod |
| Storage | Standard_LRS | Standard_LRS | Standard_GRS | Local redundancy dev; Geo for prod |
| Redis | Basic C0 | Basic C0 | Standard C1 | Basic sufficient dev; Standard for prod SLA |
| Log Retention | 30 days | 30 days | 90 days | Minimum for dev; Extended for compliance |

### Allowed App Service SKUs

Based on `src/modules/app-service.bicep` allowed values:

**Premium v3** (Recommended for production):
- `P1V3` - 2 cores, 8 GB RAM
- `P2V3` - 4 cores, 16 GB RAM
- `P3V3` - 8 cores, 32 GB RAM

**Premium v2** (Legacy):
- `P1V2`, `P2V2`, `P3V2`

**Standard** (Cost-optimized):
- `S1` - 1 core, 1.75 GB RAM (cheapest allowed)
- `S2` - 2 cores, 3.5 GB RAM
- `S3` - 4 cores, 7 GB RAM

**Not Allowed**:
- ❌ Basic tier (`B1`, `B2`, `B3`) - Not in allowed list
- ❌ Free tier (`F1`) - Not suitable for production workloads
- ❌ Shared tier (`D1`) - Not suitable for production workloads

---

## Deployment Script Enhancements

### Interactive Features Added

1. **Password Generation**: Secure password generation with option to provide custom password
2. **OpenAI Service Detection**: Automatically finds existing OpenAI/AI Foundry services
3. **Model Deployment Intelligence**: Prioritizes GPT-5 Mini, falls back gracefully
4. **Resource Group Lifecycle**: Options to use existing, delete and recreate, or cancel
5. **Deployment Confirmation**: Shows full deployment context before proceeding

### Model Detection Priority Order

```bash
# Priority order for model selection
1. gpt-5-mini (preferred)
2. gpt-5 (fallback)
3. gpt-4o (fallback)
4. gpt-4 (fallback)
5. First available (last resort)
```

---

## Testing and Validation

### Pre-Deployment Validation

✅ Template validation passes with warnings only  
✅ All SKUs within allowed values  
✅ Resource names meet Azure length requirements (≤24 chars)  
✅ Log retention meets minimums (≥30 days)  
✅ No reserved app setting names used  

### Successful Deployment Outcomes

✅ Resource group created: `rg-marketingstory-sandbox-aue`  
✅ All 8 core resources deployed successfully:
- Log Analytics Workspace
- Application Insights
- Redis Cache
- PostgreSQL Flexible Server
- Key Vault
- Storage Account
- App Service Plan
- App Service (Web App)

✅ Role assignments created for managed identity access  
✅ Key Vault secrets populated with connection strings  
✅ App settings configured with Key Vault references  

---

## Recommendations for Future Deployments

### Before Deploying Dev/Prod

1. **Review SKU choices** - Ensure performance requirements are met
2. **Configure alerts** - Uncomment alert settings in param files
3. **Set up Key Vault access** - Provide service principal IDs if needed
4. **Plan for private endpoints** - Dev/prod use VNet integration
5. **Review OpenAI quota** - Ensure sufficient quota for new deployments or use existing services

### Deployment Checklist

- [ ] Run `./scripts/deploy.sh -e <env>` with correct environment
- [ ] Provide secure PostgreSQL password (or generate one)
- [ ] Choose existing OpenAI service or create new (consider quota)
- [ ] Select appropriate GPT model deployment
- [ ] Confirm deployment details before proceeding
- [ ] Monitor deployment progress (15-30 minutes typical)
- [ ] Verify all resources created successfully
- [ ] Test connectivity to deployed services

### Monitoring After Deployment

1. Check deployment logs in Azure Portal
2. Verify App Service is running
3. Test Key Vault references are resolving
4. Confirm managed identity has required role assignments
5. Validate database connectivity
6. Test OpenAI endpoint accessibility

---

## References

### Documentation
- [Azure App Service Plans](https://learn.microsoft.com/azure/app-service/overview-hosting-plans)
- [Azure Files Integration](https://learn.microsoft.com/azure/app-service/configure-connect-to-azure-storage)
- [Azure OpenAI Models](https://learn.microsoft.com/azure/ai-services/openai/concepts/models)
- [Azure Key Vault References](https://learn.microsoft.com/azure/app-service/app-service-key-vault-references)

### Related Files
- `src/orchestration/main.bicep` - Main infrastructure template
- `src/modules/app-service.bicep` - App Service module
- `src/modules/openai.bicep` - OpenAI module
- `scripts/deploy.sh` - Deployment script
- `src/configuration/main.*.bicepparam` - Environment-specific parameters

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-11 | 1.0 | Initial lessons learned from sandbox deployment |

---

**Author**: Infrastructure Team  
**Last Updated**: November 11, 2025  
**Status**: ✅ Validated and applied to all environments
