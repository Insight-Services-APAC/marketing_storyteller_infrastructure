# Marketing Storyteller - Azure Infrastructure

> Infrastructure as Code (IaC) for deploying Marketing Storyteller to Azure using CAF-aligned Bicep templates.

## Purpose

This repository contains Azure infrastructure templates separate from the application code to:

- **Maintain clear separation of concerns** between application and infrastructure
- **Enable independent versioning** of infrastructure changes
- **Follow Cloud Adoption Framework (CAF)** best practices from APAC-DIA
- **Support multiple environments** (Development, Production) with consistent deployments
- **Facilitate infrastructure reviews** without coupling to application release cycles

## Application Repository

**Application Code**: [marketing_storyteller](https://github.com/Insight-Services-APAC/marketing_storyteller)

For application features, implementation details, and business requirements, refer to the application repository.

## Base Template

This infrastructure is based on the CAF-aligned template:

**Source**: [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1)

We have adapted this template by:

- Removing unnecessary modules (AKS, Container Registry, etc.)
- Adding Marketing Storyteller-specific resources
- Customizing for Next.js + PostgreSQL + Redis + Azure OpenAI stack

## Current Status

- ✅ Repository created
- ✅ CAF base template cloned to `temp-caf/` directory
- ✅ Infrastructure modules created (7 Bicep modules + networking)
- ✅ Main orchestration template completed
- ✅ Parameter files for dev and prod environments
- ✅ Deployment and validation scripts
- ✅ Support for existing Azure OpenAI / AI Foundry services
- ✅ Infrastructure evaluated against CAF best practices
- ✅ GitHub Codespaces configuration for secure development
- ✅ Optional private endpoints for network isolation
- 🚀 **Ready for deployment**

**See:**
- [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md) - Deployment instructions
- [`docs/CODESPACES_SETUP.md`](docs/CODESPACES_SETUP.md) - **NEW**: GitHub Codespaces with private networking
**See:**
- **[📚 Documentation Index](docs/README.md)** - Complete documentation guide
- **[🚀 Quick Start](docs/setup/ENVIRONMENT_STRATEGY.md)** - Start here for setup
- **[⚡ Quick Reference](docs/QUICK_REFERENCE.md)** - Common commands

**Key Documentation:**
- [Environment Strategy](docs/setup/ENVIRONMENT_STRATEGY.md) - Sandbox vs Dev vs Prod
- [Deployment Guide](docs/setup/DEPLOYMENT_GUIDE.md) - Step-by-step deployment
- [Codespaces Setup](docs/setup/CODESPACES_SETUP.md) - GitHub Codespaces for sandbox
- [CAF Best Practices](docs/operations/CAF_BEST_PRACTICES_EVALUATION.md) - Architecture evaluation

## Environment Strategy

This infrastructure supports **three environments**:

| Environment | Purpose | Cost/Month | Network | Codespaces |
|-------------|---------|------------|---------|------------|
| **Sandbox** | Personal development, POCs | ~$64 | Public endpoints | ✅ Yes |
| **Dev** | Team development, testing | ~$299 | Private endpoints | ❌ No (VPN needed) |
| **Prod** | Production workload | ~$500+ | Private + WAF | ❌ No (restricted) |

**👉 Read [`docs/setup/ENVIRONMENT_STRATEGY.md`](docs/setup/ENVIRONMENT_STRATEGY.md)** for detailed comparison and decision guide.

## Development Options

### Option 1: Sandbox + GitHub Codespaces (Recommended for Personal Dev) ⭐

Low-cost personal development with public endpoints and Codespaces support:

```bash
# Open in Codespaces (GitHub UI or VS Code)

# Check resource group status
./scripts/check-resource-group.sh sandbox

# Deploy sandbox environment
./scripts/deploy.sh -e sandbox -p "YourPassword123!"
# The script will prompt if resource group exists:
#   1) Update existing deployment
#   2) Delete and recreate (clean slate)
#   3) Cancel
```

**Benefits**:
- ✅ Full GitHub Copilot support
- ✅ Pre-configured tools (Azure CLI, Bicep, PostgreSQL client, Redis CLI)
- ✅ Works from anywhere (browser or VS Code)
- ✅ Low cost (~$64/month, within VS Enterprise credits)
- ✅ Public endpoints with firewall rules and SSL
- ✅ Perfect for personal Azure subscriptions
- ✅ Resource group management built into deployment script

See [`docs/setup/CODESPACES_SETUP.md`](docs/setup/CODESPACES_SETUP.md) for setup guide.

### Option 2: Dev Environment (Team Development)

Production-like environment with private endpoints for team collaboration:

```bash
# Requires VPN or Bastion access

# Check resource group status
./scripts/check-resource-group.sh dev

# Deploy
./scripts/deploy.sh -e dev -p "YourPassword123!"
```

**Benefits**:
- ✅ Private endpoints (network isolation)
- ✅ VNet integration
- ✅ Production-like architecture
- ✅ Team collaboration
- ⚠️ Requires VPN or Bastion (~$29-183/month extra)

### Option 3: Local Development

```bash
# Clone and work locally
git clone https://github.com/Insight-Services-APAC/marketing_storyteller_infrastructure.git
cd marketing_storyteller_infrastructure
./scripts/deploy.sh dev
```

**Note**: With private endpoints enabled, local development requires VPN or Point-to-Site connection.

## Deployed Resources

### Development Environment

- **Resource Group**: `rg-marketingstory-dev-aue`
- **App Service Plan**: Premium V3 (P1V3)
- **App Service**: Linux, Node.js 20 LTS
- **PostgreSQL Flexible Server**: Burstable B1ms, version 16.1
- **Storage Account**: Standard LRS with containers for documents
- **Azure Cache for Redis**: Basic C0 for BullMQ job queue
- **Azure OpenAI Service**: GPT-4 deployment (10K tokens/min quota)
- **Key Vault**: Standard tier for secrets management
- **Application Insights**: 30-day retention

**Estimated Monthly Cost**: ~$200 USD

### Production Environment

- **Resource Group**: `rg-marketingstory-prod-aue`
- **App Service Plan**: Premium V3 (P2V3)
- **App Service**: Linux, Node.js 20 LTS
- **PostgreSQL Flexible Server**: General Purpose GP_Standard_D2s_v3
- **Storage Account**: Standard GRS with automated backups
- **Azure Cache for Redis**: Standard C1
- **Azure OpenAI Service**: GPT-4 deployment (50K+ tokens/min quota)
- **Key Vault**: Standard tier with access policies
- **Application Insights**: 90-day retention

**Estimated Monthly Cost**: ~$725 USD

## Repository Structure

```
marketing_storyteller_infrastructure/
├── .github/
│   └── workflows/              # CI/CD pipelines (to be created)
│       ├── deploy-dev.yml
│       ├── deploy-prod.yml
│       └── validate.yml
├── bicep/                      # (to be created)
│   ├── modules/
│   │   ├── app-service.bicep   # Next.js web app
│   │   ├── postgresql.bicep    # Database (Flexible Server)
│   │   ├── storage.bicep       # Document blob storage
│   │   ├── redis.bicep         # BullMQ job queue
│   │   ├── openai.bicep        # GPT-4 for AI features
│   │   ├── keyvault.bicep      # Secrets management
│   │   ├── monitoring.bicep    # Application Insights
│   │   └── networking.bicep    # VNet, Private Endpoints (from CAF)
│   ├── main.bicep              # Main orchestration template
│   └── parameters/
│       ├── dev.bicepparam      # Development config
│       └── prod.bicepparam     # Production config
├── scripts/                    # (to be created)
│   ├── deploy.sh
│   └── validate.sh
├── docs/
│   └── operations/             # Setup and deployment documentation
│       ├── AZURE_DEPLOYMENT_PLAN.md
│       ├── DEPLOYMENT_CHECKLIST.md
│       ├── INFRASTRUCTURE_README_TEMPLATE.md
│       └── INFRASTRUCTURE_REPO_SETUP.md
├── temp-caf/                   # CAF template (temporary - for reference)
│   └── [CAF template files]
├── .gitignore
└── README.md                   # This file
```

## Prerequisites

- **Azure CLI** (`az`) version 2.50+
- **Azure subscription** with appropriate permissions
- **GitHub account** with access to deploy workflows
- **Service Principal** for GitHub Actions (to be created)
- **Bicep** (included with Azure CLI)

## Quick Start

**👉 Not sure which option to choose?** See [`docs/QUICK_START_DECISION.md`](docs/QUICK_START_DECISION.md)

### Option 1: GitHub Codespaces (Recommended)

Pre-configured cloud development environment with all tools included:

1. **Check Prerequisites**: Read [`docs/ENTERPRISE_CODESPACES_FAQ.md`](docs/ENTERPRISE_CODESPACES_FAQ.md)
2. **Create Codespace**: Code → Codespaces → Create codespace on main
3. **Deploy**: Follow [`docs/CODESPACES_SETUP.md`](docs/CODESPACES_SETUP.md)

**Cost**: $0 if org pays for Codespaces + within Visual Studio credits

### Option 2: Local Development

Traditional local setup:

1. **Install Prerequisites**: Azure CLI, Bicep, Node.js 20
2. **Clone Repository**: `git clone <repo-url>`
3. **Deploy**: Follow [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md)

**Cost**: $0 + within Visual Studio credits

---

### Legacy: Evaluate CAF Template (Reference Only)

Before creating Bicep modules, evaluate the CAF template structure:

```bash
# Review the CAF template structure
tree -L 3 temp-caf/

# Or if tree is not available:
find temp-caf/ -type d -maxdepth 3 | sort
```

**Key tasks:**

1. Identify modules to copy from CAF template (networking, monitoring, keyvault)
2. Identify modules to remove (AKS, ACR, API Management, etc.)
3. Create custom modules for Marketing Storyteller services
4. Adapt GitHub Actions workflows from CAF template

See [`docs/operations/INFRASTRUCTURE_README_TEMPLATE.md`](docs/operations/INFRASTRUCTURE_README_TEMPLATE.md) for detailed evaluation checklist.

### 2. Local Validation

```bash
# Validate Bicep syntax (after modules are created)
az bicep build --file bicep/main.bicep

# Preview deployment (what-if)
az deployment group what-if \
  --resource-group rg-marketingstory-dev-aue \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.bicepparam
```

### 3. Deploy to Development

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

### 4. Deploy via GitHub Actions

GitHub Actions workflows will be configured to:

- **Validate** Bicep templates on pull requests
- **Deploy to Dev** automatically on merge to `main`
- **Deploy to Prod** with manual approval

## Naming Conventions

Following CAF-compliant naming pattern:

```
<resource-type>-<app-name>-<environment>-<region>
```

**Examples:**

- `app-marketingstory-dev-aue` - App Service
- `psql-marketingstory-dev-aue` - PostgreSQL
- `stmarketingstorydevaue` - Storage Account (no hyphens)
- `redis-marketingstory-dev-aue` - Redis Cache
- `kv-marketingstory-dev-aue` - Key Vault
- `oai-marketingstory-dev-aue` - Azure OpenAI

**Abbreviations:**

- `app` = App Service
- `psql` = PostgreSQL
- `st` = Storage Account
- `redis` = Redis Cache
- `kv` = Key Vault
- `oai` = Azure OpenAI
- `rg` = Resource Group
- `dev` = Development
- `prod` = Production
- `aue` = Australia East

## Integration with Application Repository

**Deployment Flow:**

1. **Infrastructure changes** merged to this repo → triggers infrastructure deployment
2. **Infrastructure deployment** completes → updates resource configurations
3. **Application changes** merged to application repo → triggers app deployment
4. **Application deployment** uses infrastructure outputs (connection strings, URLs)

**Coordination:**

- Infrastructure repo GitHub Actions can trigger application deployment via `repository_dispatch`
- Application repo references this repo in documentation
- Breaking infrastructure changes require coordinated deployment

## Documentation

### Operations Documentation

- **[Azure Deployment Plan](docs/operations/AZURE_DEPLOYMENT_PLAN.md)** - Overall deployment strategy and resource requirements
- **[Infrastructure Setup Guide](docs/operations/INFRASTRUCTURE_REPO_SETUP.md)** - Step-by-step repository setup instructions
- **[Deployment Checklist](docs/operations/DEPLOYMENT_CHECKLIST.md)** - Complete checklist for Azure deployment
- **[Infrastructure README Template](docs/operations/INFRASTRUCTURE_README_TEMPLATE.md)** - Detailed evaluation and setup guide

### External References

- [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1) - Base CAF template
- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Azure App Service for Next.js](https://learn.microsoft.com/en-us/azure/app-service/quickstart-nodejs)
- [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/)

## Next Steps

Follow the deployment checklist in [`docs/operations/DEPLOYMENT_CHECKLIST.md`](docs/operations/DEPLOYMENT_CHECKLIST.md):

### Phase 1: Infrastructure Repository Setup (Current Phase)

- [x] Create `marketing_storyteller_infrastructure` repository
- [x] Clone CAF base template to `temp-caf/`
- [ ] Evaluate CAF template structure
- [ ] Copy relevant files from CAF template
- [ ] Remove unnecessary modules (AKS, ACR, etc.)
- [ ] Create custom Bicep modules for Marketing Storyteller
- [ ] Create main orchestration template
- [ ] Create parameter files for dev/prod

### Phase 2: Azure Configuration

- [ ] Create Service Principal for GitHub Actions
- [ ] Configure GitHub Secrets
- [ ] Create resource groups in Azure
- [ ] Request Azure OpenAI quota

### Phase 3: First Deployment

- [ ] Validate Bicep templates locally
- [ ] Deploy to development environment
- [ ] Test infrastructure resources
- [ ] Deploy application to dev environment

### Phase 4: Production Deployment

- [ ] Review and approve production deployment
- [ ] Deploy to production environment
- [ ] Configure monitoring and alerts
- [ ] Document lessons learned

## Support and Contributing

**For Infrastructure Issues:**

- Open an issue in this repository
- Tag with `infrastructure`, `bicep`, or `deployment`

**For Application Issues:**

- Open an issue in [marketing_storyteller](https://github.com/Insight-Services-APAC/marketing_storyteller)
- Tag with `application`, `bug`, or `feature`

**Questions:**

- Check operations documentation in `docs/operations/`
- Review CAF template examples in `temp-caf/`
- Consult Azure Bicep documentation
- Ask in team communication channels

## License

Copyright © 2025 Insight Services APAC. All rights reserved.

This infrastructure configuration is proprietary and confidential.
