# Quick Reference - Environment Commands

## 🏖️ Sandbox (Personal Development)

**Purpose**: Personal Azure subscription, Codespaces compatible, low cost

```bash
# Deploy sandbox
./scripts/deploy.sh -e sandbox -p "YourPassword123!"

# Connect to PostgreSQL
connect-sandbox-db

# Connect to Redis
connect-sandbox-redis

# Delete resources (save costs)
az group delete --name rg-marketingstory-sandbox-aue --yes
```

**Cost**: ~$64/month (within VS Enterprise $150 credits)  
**Network**: Public endpoints + firewall + SSL  
**Codespaces**: ✅ Yes

---

## 🔧 Dev (Team Development)

**Purpose**: Company Azure subscription, private endpoints, production-like

```bash
# Deploy dev (requires VPN/Bastion)
./scripts/deploy.sh -e dev -p "YourPassword123!"

# Connect via VPN first, then:
az postgres flexible-server connect \
  --name psql-marketingstory-dev-aue \
  --admin-user psqladmin \
  --database-name marketingstory
```

**Cost**: ~$299/month (company pays)  
**Network**: Private endpoints (10.0.0.0/16)  
**Codespaces**: ❌ No (VPN required)

---

## 🚀 Prod (Production)

**Purpose**: Company Azure subscription, production workload

```bash
# Deploy prod (via CI/CD recommended)
./scripts/deploy.sh -e prod -p "ProductionPassword"
```

**Cost**: ~$500-2,400/month (company pays)  
**Network**: Private endpoints + WAF  
**Codespaces**: ❌ No (restricted access)

---

## 🎯 Quick Decision Tree

```
┌─ Where is your Azure subscription? ─┐
│                                      │
├─ Personal (VS credits)               │
│  └─→ Use SANDBOX                     │
│      • Codespaces: Yes               │
│      • Cost: $0 (within credits)     │
│                                      │
├─ Company (team subscription)         │
│  └─→ Use DEV for development         │
│      • Codespaces: No                │
│      • Cost: $299/month              │
│      • Access: VPN/Bastion           │
│                                      │
└─ Company (production)                │
   └─→ Use PROD                        │
       • Codespaces: No                │
       • Cost: $500+/month             │
       • Access: Restricted            │
```

---

## 📊 Cost Comparison

| Environment | Cost/Month | VS Credits Cover | Out-of-Pocket |
|-------------|------------|------------------|---------------|
| Sandbox     | $64        | ✅ Yes ($150)    | **$0** ✨     |
| Dev         | $299       | ⚠️ Partial       | ~$149         |
| Prod        | $500+      | ❌ No            | $500+         |

---

## 🔗 Documentation

- **Environment Strategy**: [`docs/setup/ENVIRONMENT_STRATEGY.md`](docs/setup/ENVIRONMENT_STRATEGY.md)
- **Sandbox + Codespaces**: [`docs/setup/CODESPACES_SETUP.md`](docs/setup/CODESPACES_SETUP.md)
- **Deployment Guide**: [`docs/setup/DEPLOYMENT_GUIDE.md`](docs/setup/DEPLOYMENT_GUIDE.md)
- **Documentation Index**: [`docs/README.md`](docs/README.md)

---

## ⚡ Most Common Commands

```bash
# Sandbox (from Codespaces)
deploy-sandbox                    # Deploy sandbox environment
connect-sandbox-db                # Connect to PostgreSQL
connect-sandbox-redis             # Connect to Redis
az group delete --name rg-marketingstory-sandbox-aue --yes  # Delete all

# Dev (from VPN/Bastion)
deploy-dev                        # Deploy dev environment
# Then connect via VPN

# All environments
validate-infra                    # Validate Bicep templates
az-login                          # Login to Azure
az-list-rgs                       # List resource groups
```
