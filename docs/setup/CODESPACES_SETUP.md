# GitHub Codespaces Setup Guide - Sandbox Environment

This guide explains how to use GitHub Codespaces for **sandbox environment** development with public endpoints.

## ⚠️ IMPORTANT: Environment Strategy

This repository supports **three environments**:

| Environment | Network | Codespaces | Use Case |
|-------------|---------|------------|----------|
| **Sandbox** | Public endpoints | ✅ **Yes** | Personal development (this guide) |
| **Dev** | Private endpoints | ❌ No | Team development (VPN required) |
| **Prod** | Private endpoints + WAF | ❌ No | Production (restricted access) |

**This guide covers Sandbox only**. See [`ENVIRONMENT_STRATEGY.md`](ENVIRONMENT_STRATEGY.md) for environment comparison.

### Why Sandbox?

GitHub Codespaces **cannot connect to private endpoints** because:
- Codespaces run in GitHub's Azure tenant (not yours)
- Private endpoints only have private IPs (10.0.x.x)
- No network route between GitHub's network and your VNet

**Solution**: Use **sandbox environment** with public endpoints for Codespaces development.

**See detailed explanation**: [`CODESPACES_PRIVATE_ENDPOINTS_CLARIFICATION.md`](CODESPACES_PRIVATE_ENDPOINTS_CLARIFICATION.md)

---

## 🎯 Overview

**Sandbox + GitHub Codespaces** provides low-cost personal development with:

- ✅ **Pre-configured Tools**: Azure CLI, Bicep, PowerShell, PostgreSQL client, Redis CLI
- ✅ **GitHub Copilot**: Full AI assistance for coding and troubleshooting
- ✅ **Public Endpoints**: Works with Codespaces (firewall rules + SSL for security)
- ✅ **Low Cost**: ~$64/month (within Visual Studio Enterprise credits)
- ✅ **Access Anywhere**: Browser, VS Code desktop, or iPad
- ✅ **Quick Setup**: 2-3 minutes to fully configured environment

---

## 🚀 Quick Start - Deploy Sandbox

### Step 1: Verify Sandbox Configuration

The sandbox environment uses **public endpoints** by default (perfect for Codespaces):

**Parameter File**: `src/configuration/main.sandbox.bicepparam`

```bicep
// Public endpoints enabled (works with Codespaces)
param enablePrivateEndpoints = false

// Use existing OpenAI service (recommended to save cost/quota)
param useExistingOpenAI = true
param existingOpenAIName = 'oai-shared-dev-aue'
param existingOpenAIResourceGroup = 'rg-shared-ai-dev-aue'
```

### Step 2: Deploy Infrastructure

```bash
# Deploy sandbox environment
./scripts/deploy.sh -e sandbox -p "YourSecurePassword123!"

# Or with subscription ID
./scripts/deploy.sh -e sandbox -p "YourPassword" -s "your-subscription-id"
```

This creates:
- App Service (B1 SKU - low cost)
- PostgreSQL (B_Standard_B1ms - burstable)
- Redis (Basic C0 - 250 MB)
- Storage (Standard_LRS)
- Key Vault (Standard)
- Application Insights + Log Analytics

**All with public endpoints + firewall rules + SSL encryption**.

**Cost**: ~$64/month (100% covered by Visual Studio Enterprise credits)

### Step 3: Open in Codespaces

**Option A: From GitHub Web**
1. Go to your repository on GitHub
2. Click the **Code** button
3. Select **Codespaces** tab
4. Click **Create codespace on main**

**Option B: From VS Code Desktop**
1. Install the **GitHub Codespaces** extension
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Select **Codespaces: Create New Codespace**
4. Choose your repository

### Step 4: Wait for Environment Setup

The Codespace will automatically:
- ✅ Install Azure CLI with Bicep extension
- ✅ Install Node.js 20
- ✅ Install PowerShell and Azure modules
- ✅ Install PostgreSQL client
- ✅ Install Redis CLI
- ✅ Configure GitHub Copilot
- ✅ Create helper scripts

This takes ~2-3 minutes on first run.

---

## 🔐 Connecting to Backend Services

Once your Codespace is running, you can connect to private backend services:

### PostgreSQL Database

```bash
# Quick connect helper
connect-dev-db

# Or manually
az postgres flexible-server connect \
  --name psql-marketingstory-dev-aue \
  --admin-user psqladmin \
  --database-name marketingstory
```

**Example queries**:
```sql
-- List all tables
\dt

-- Query stories
SELECT id, title, created_at FROM stories LIMIT 10;

-- Check database size
SELECT pg_size_pretty(pg_database_size('marketingstory'));
```

### Redis Cache

```bash
# Quick connect helper
connect-dev-redis

# Or manually
REDIS_KEY=$(az redis list-keys --name redis-marketingstory-dev-aue --resource-group rg-marketingstory-dev-aue --query primaryKey -o tsv)
REDIS_HOST=$(az redis show --name redis-marketingstory-dev-aue --resource-group rg-marketingstory-dev-aue --query hostName -o tsv)

redis-cli -h $REDIS_HOST -p 6380 -a "$REDIS_KEY" --tls
```

**Example commands**:
```bash
# Check Redis info
INFO

# List all keys
KEYS *

# Get queue length
LLEN story:processing:queue

# Monitor real-time commands
MONITOR
```

### Azure Storage

```bash
# List containers
az storage container list \
  --account-name stmarketingstorydevaue \
  --auth-mode login \
  --query "[].name"

# List blobs in a container
az storage blob list \
  --account-name stmarketingstorydevaue \
  --container-name story-documents \
  --auth-mode login \
  --query "[].{Name:name, Size:properties.contentLength}"
```

### Key Vault Secrets

```bash
# List secrets
az keyvault secret list \
  --vault-name kv-marketingstory-dev-aue \
  --query "[].name"

# Get a secret value (requires permission)
az keyvault secret show \
  --vault-name kv-marketingstory-dev-aue \
  --name database-url \
  --query value -o tsv
```

---

## 🛠️ Development Workflow

### 1. Make Infrastructure Changes

Edit Bicep files in the Codespace with full IntelliSense and Copilot assistance:

```bash
# Open a module
code src/modules/postgresql.bicep
```

### 2. Validate Changes

```bash
# Use the validation script
validate-infra

# Or manually validate a specific file
az bicep build --file src/orchestration/main.bicep
```

### 3. Deploy Changes

```bash
# Deploy to development environment
deploy-dev

# Or deploy to production (requires confirmation)
deploy-prod
```

### 4. Verify Deployment

```bash
# Check deployment outputs
show-outputs

# List all resources in the resource group
az resource list \
  --resource-group rg-marketingstory-dev-aue \
  --query "[].{Name:name, Type:type, Location:location}" \
  --output table
```

---

## 🤖 Using GitHub Copilot

GitHub Copilot is pre-installed and configured in the Codespace.

### Copilot Chat Examples

Ask Copilot to help you:

```
@workspace How do I add a new storage container to the infrastructure?
```

```
@workspace What's the best way to configure high availability for PostgreSQL?
```

```
@workspace Help me write a query to find all stories created in the last 7 days
```

### Copilot Inline Suggestions

As you type Bicep code, Copilot provides suggestions:

```bicep
// Type this comment and let Copilot suggest the code:
// Add a firewall rule to allow access from the App Service subnet
```

---

## 📊 Troubleshooting

### Connect to App Service Console

```bash
# Open App Service SSH session (in Azure Portal)
# Or stream logs in the terminal
az webapp log tail \
  --name app-marketingstory-dev-aue \
  --resource-group rg-marketingstory-dev-aue
```

### Check Private Endpoint Connectivity

```bash
# Verify private endpoint status
az network private-endpoint list \
  --resource-group rg-marketingstory-dev-aue \
  --query "[].{Name:name, State:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}" \
  --output table
```

### Test DNS Resolution

```bash
# Check if private DNS is working
nslookup psql-marketingstory-dev-aue.postgres.database.azure.com

# Should resolve to a private IP (10.0.x.x) if private endpoints are enabled
```

### View Diagnostic Logs

```bash
# Query Application Insights for errors
az monitor app-insights query \
  --app appi-marketingstory-dev-aue \
  --analytics-query "
    traces
    | where severityLevel >= 3
    | order by timestamp desc
    | take 10
  " \
  --offset 1h
```

---

## 💰 Cost Breakdown

### Without Private Endpoints (Default)

| Component | Monthly Cost (AUD) |
|-----------|-------------------|
| Infrastructure | ~$240 |
| Codespaces (80 hours/month) | ~$14 |
| **Total** | **~$254** |

### With Private Endpoints

| Component | Monthly Cost (AUD) |
|-----------|-------------------|
| Infrastructure | ~$240 |
| Private Endpoints (5 × $11) | ~$55 |
| Private DNS Zones | ~$4 |
| Codespaces (80 hours/month) | ~$14 |
| **Total** | **~$313** |

**Additional Cost**: ~$59/month (~$708/year)

---

## 🔒 Security Benefits

| Feature | Public Endpoints | Private Endpoints |
|---------|-----------------|-------------------|
| **Database Access** | Internet-exposed with firewall | Private IP only |
| **Redis Access** | Public IP with auth | Private IP only |
| **Storage Access** | Public endpoint | Private IP only |
| **Key Vault Access** | Public endpoint | Private IP only |
| **Network Isolation** | ❌ No | ✅ Yes |
| **Compliance Ready** | ⚠️ Limited | ✅ Yes |
| **Bastion Required** | ❌ No | ❌ No (Codespaces instead) |

---

## 📚 Available Helper Commands

The Codespace includes these pre-configured aliases:

```bash
# Connect to database
connect-dev-db

# Connect to Redis
connect-dev-redis

# Deploy to development
deploy-dev

# Deploy to production
deploy-prod

# Validate infrastructure
validate-infra

# Show deployment outputs
show-outputs

# Azure login
az-login

# List resource groups
az-list-rgs
```

---

## 🌐 VNet Integration (Advanced)

### Network Topology

When `enablePrivateEndpoints = true`:

```
GitHub Codespaces (Azure VNet Integrated)
          │
          ├─── VNet: 10.0.0.0/16
          │     │
          │     ├─── Subnet: snet-private-endpoints (10.0.1.0/24)
          │     │     ├─── PostgreSQL Private Endpoint
          │     │     ├─── Redis Private Endpoint
          │     │     ├─── Storage Private Endpoint
          │     │     └─── Key Vault Private Endpoint
          │     │
          │     ├─── Subnet: snet-app-services (10.0.2.0/24)
          │     │     └─── App Service VNet Integration
          │     │
          │     └─── Subnet: snet-container-apps (10.0.3.0/23)
          │           └─── Reserved for future use
          │
          └─── Private DNS Zones
                ├─── privatelink.postgres.database.azure.com
                ├─── privatelink.redis.cache.windows.net
                ├─── privatelink.blob.core.windows.net
                └─── privatelink.vaultcore.azure.net
```

### Subnet Details

| Subnet | Address Range | Purpose | Delegation |
|--------|--------------|---------|------------|
| **snet-private-endpoints** | 10.0.1.0/24 | Private endpoints (254 IPs) | None |
| **snet-app-services** | 10.0.2.0/24 | App Service VNet integration | Microsoft.Web/serverFarms |
| **snet-container-apps** | 10.0.3.0/23 | Future container apps | None |

---

## 🔄 Migration Path

### Current Setup → Codespaces Only

**Step 1**: Use Codespaces without private endpoints (free GitHub tier)
```bicep
// Leave default settings
param enablePrivateEndpoints = false
```

**Step 2**: Deploy and test in Codespace
```bash
# Open Codespace and deploy
./scripts/deploy.sh dev
```

### Adding Private Endpoints Later

**Step 1**: Enable in parameter file
```bicep
param enablePrivateEndpoints = true
```

**Step 2**: Redeploy infrastructure
```bash
./scripts/deploy.sh dev
```

**Step 3**: Verify connectivity
```bash
connect-dev-db
connect-dev-redis
```

---

## 🆘 Common Issues

### Issue: "Cannot connect to database"

**Solution**: Ensure you're authenticated with Azure
```bash
az login
```

### Issue: "Private endpoint not found"

**Solution**: Verify private endpoints are deployed
```bash
az network private-endpoint list --resource-group rg-marketingstory-dev-aue
```

### Issue: "Codespace can't resolve private DNS"

**Solution**: Check DNS zone configuration
```bash
az network private-dns zone list --resource-group rg-marketingstory-dev-aue
```

### Issue: "Permission denied to Key Vault"

**Solution**: Grant yourself access
```bash
az role assignment create \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Key Vault Secrets User" \
  --scope $(az keyvault show --name kv-marketingstory-dev-aue --query id -o tsv)
```

---

## 📖 Next Steps

1. ✅ **Enable Codespaces** in your GitHub repository
2. ✅ **Decide on private endpoints** (recommended for production-like dev)
3. ✅ **Deploy infrastructure** with your chosen configuration
4. ✅ **Open Codespace** and start developing
5. ✅ **Use Copilot** to accelerate development and troubleshooting

---

## 📚 Additional Resources

- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Azure Private Endpoints](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [GitHub Copilot in Codespaces](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-codespaces)

---

**Ready to get started?** Open a Codespace and run `deploy-dev`! 🚀
