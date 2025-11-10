# Quick Start: Using the Improved Infrastructure

This guide helps you quickly understand and use the infrastructure improvements.

## 🎯 What's New?

All **7 critical improvements** from the CAF evaluation have been implemented:

1. ✅ **Secrets in Key Vault** - No more passwords in environment variables
2. ✅ **Diagnostic Settings** - Full audit trail for compliance
3. ✅ **Resource Locks** - Production resources protected from deletion
4. ✅ **PostgreSQL HA** - Zone-redundant database for production
5. ✅ **Enhanced Tagging** - CAF-compliant resource tags
6. ✅ **Monitoring Alerts** - 11 alert rules for proactive monitoring

## 🚀 Quick Deployment

### Standard Deployment (No Changes Required)

The improvements are integrated into existing templates. Deploy as usual:

```bash
# Development environment
./scripts/deploy.sh dev

# Production environment
./scripts/deploy.sh prod
```

### Enable Monitoring Alerts (Optional but Recommended)

Edit parameter files to enable alerts:

**For Dev** (`src/configuration/main.dev.bicepparam`):
```bicep
param enableAlerts = true
param alertEmailAddresses = [
  'devteam@insightservices.com'
]
```

**For Prod** (`src/configuration/main.prod.bicepparam`):
```bicep
param enableAlerts = true
param alertEmailAddresses = [
  'oncall@insightservices.com'
  'platform@insightservices.com'
]
param alertSmsNumbers = [
  '0412345678'  // AU format without +61
]
```

## 🔐 Security Changes

### How Secrets Work Now

**Before** (❌ Insecure):
```
App Service Environment Variables:
  DATABASE_URL = "postgresql://user:password@host/db"
  REDIS_URL = "redis://:password@host:6380"
```

**After** (✅ Secure):
```
App Service Environment Variables:
  DATABASE_URL = "@Microsoft.KeyVault(VaultName=kv-xxx;SecretName=database-url)"
  REDIS_URL = "@Microsoft.KeyVault(VaultName=kv-xxx;SecretName=redis-url)"
```

The App Service retrieves secrets from Key Vault using its managed identity - **no passwords visible anywhere!**

## 📊 Monitoring & Alerts

### What Gets Monitored

| Resource | Metrics | Threshold | Severity |
|----------|---------|-----------|----------|
| **App Service** | CPU | > 80% | Warning |
| **App Service** | Memory | > 85% | Warning |
| **App Service** | Response Time | > 5s | Warning |
| **App Service** | HTTP 5xx Errors | > 10 | **Critical** |
| **PostgreSQL** | CPU | > 80% | Warning |
| **PostgreSQL** | Memory | > 85% | Warning |
| **PostgreSQL** | Storage | > 85% | **Critical** |
| **Redis** | Server Load | > 80% | Warning |
| **Redis** | Memory | > 85% | Warning |
| **Availability** | Uptime | < 99% | **Critical** (Prod only) |

### Alert Notification Flow

```
Threshold Exceeded → Azure Monitor → Action Group → Email/SMS → Your Team
```

## 🗂️ Resource Tags

All resources now have CAF-compliant tags:

```bicep
environment: 'dev' | 'prod'
applicationName: 'Marketing Storyteller'
owner: 'Platform Team'
criticality: 'Tier1' (prod) | 'Tier2' (dev)
costCenter: 'Marketing'
businessUnit: 'Digital Marketing'
workloadName: 'MarketingStoryteller'
dataClassification: 'Confidential' (prod) | 'Internal' (dev)
managedBy: 'Bicep IaC'
compliance: 'ISO27001' (prod) | 'None' (dev)
```

**Use Case**: Filter Azure Cost Management by `costCenter` or `businessUnit` to track spending.

## 🔒 Production Protections

### Resource Lock

Production resource group has a `CanNotDelete` lock:

```bash
# This will FAIL in production:
az group delete --name rg-marketingstory-prod-aue
# Error: The resource group is locked

# To delete (requires lock removal first):
az lock delete --name lock-rg-marketingstory-prod-aue \
  --resource-group rg-marketingstory-prod-aue
az group delete --name rg-marketingstory-prod-aue
```

### PostgreSQL High Availability

| Feature | Dev | Prod |
|---------|-----|------|
| HA Mode | Disabled | **Zone-Redundant** |
| Geo-Backup | Disabled | **Enabled** |
| Backup Retention | 7 days | **35 days** |
| SKU | Burstable | General Purpose |

**Recovery Time Objective (RTO)**: Zone-redundant HA provides automatic failover in ~60 seconds.

## 📈 Diagnostic Settings

All resources send logs and metrics to Log Analytics:

### View Logs in Azure Portal

1. Navigate to Log Analytics workspace: `law-marketingstory-{env}-aue`
2. Go to **Logs**
3. Run queries:

```kql
// App Service errors in last 24h
AppServiceHTTPLogs
| where TimeGenerated > ago(24h)
| where ScStatus >= 500
| summarize count() by ScStatus, bin(TimeGenerated, 1h)

// PostgreSQL slow queries
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.DBFORPOSTGRESQL"
| where Category == "PostgreSQLLogs"
| where duration_ms > 1000
| project TimeGenerated, query_s, duration_ms
```

## 🔍 Verification After Deployment

### 1. Check Secrets in Key Vault
```bash
az keyvault secret list --vault-name kv-marketingstory-dev-aue --query "[].name"
```
Expected output:
```json
[
  "database-url",
  "redis-url",
  "storage-connection-string",
  "openai-api-key",
  "openai-endpoint",
  "openai-deployment-name"
]
```

### 2. Verify Diagnostic Settings
```bash
az monitor diagnostic-settings list \
  --resource $(az webapp show -n app-marketingstory-dev-aue -g rg-marketingstory-dev-aue --query id -o tsv)
```

### 3. Check Resource Lock (Prod Only)
```bash
az lock list --resource-group rg-marketingstory-prod-aue
```

### 4. Verify PostgreSQL HA (Prod Only)
```bash
az postgres flexible-server show \
  --name psql-marketingstory-prod-aue \
  --resource-group rg-marketingstory-prod-aue \
  --query "highAvailability.mode"
```
Expected: `"ZoneRedundant"`

### 5. Check Alert Rules (If Enabled)
```bash
az monitor metrics alert list \
  --resource-group rg-marketingstory-dev-aue
```

## 🆘 Troubleshooting

### App Service Can't Access Key Vault

**Symptom**: App fails with "Failed to get secret from Key Vault"

**Solution**: Verify managed identity has Key Vault Secrets User role:
```bash
az role assignment list \
  --assignee $(az webapp identity show -n app-marketingstory-dev-aue -g rg-marketingstory-dev-aue --query principalId -o tsv) \
  --scope $(az keyvault show -n kv-marketingstory-dev-aue --query id -o tsv)
```

### Diagnostic Logs Not Appearing

**Symptom**: No logs in Log Analytics after 1 hour

**Solution**: Check diagnostic settings are enabled:
```bash
az monitor diagnostic-settings show \
  --name diag-app-marketingstory-dev-aue \
  --resource $(az webapp show -n app-marketingstory-dev-aue -g rg-marketingstory-dev-aue --query id -o tsv)
```

### Alerts Not Firing

**Symptom**: No emails despite high CPU

**Solution**: 
1. Check action group is configured with valid email
2. Check spam folder for initial confirmation email
3. Verify alert rule is enabled

## 📚 Related Documentation

- [IMPROVEMENTS_COMPLETED.md](./IMPROVEMENTS_COMPLETED.md) - Detailed changelog
- [CAF_BEST_PRACTICES_EVALUATION.md](./CAF_BEST_PRACTICES_EVALUATION.md) - Original assessment
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Full deployment instructions
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Command reference

## 🎓 Key Takeaways

✅ **No code changes required** - Improvements are in the infrastructure  
✅ **Secrets are secure** - Key Vault references eliminate exposure  
✅ **Full audit trail** - Diagnostic settings meet compliance  
✅ **Production protected** - Resource locks + HA + geo-backup  
✅ **Proactive monitoring** - Alerts catch issues before users  

**Ready to deploy!** 🚀
