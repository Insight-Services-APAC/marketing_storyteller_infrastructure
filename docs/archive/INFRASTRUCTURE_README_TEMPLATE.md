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

For application features, Epic 2 implementation details, and business requirements, refer to the application repository.

## Base Template

This infrastructure is based on the CAF-aligned template:

**Source**: [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1)

We have adapted this template by:

- Removing unnecessary modules (AKS, Container Registry, etc.)
- Adding Marketing Storyteller-specific resources
- Customizing for Next.js + PostgreSQL + Redis + Azure OpenAI stack

## Quick Start for Infrastructure Developers

### Current Status

- ✅ Repository created
- ✅ CAF base template cloned to `caf-temp/` directory
- ⏳ **Next Step**: Evaluate and copy relevant files from CAF template

### Evaluation Checklist

Use this checklist to evaluate what to copy from `caf-temp/`:

#### 1. Directory Structure Review

Examine the `caf-temp/` directory structure:

```bash
# List the directory structure
tree -L 3 caf-temp/

# Or if tree is not available:
find caf-temp/ -type d -maxdepth 3 | sort
```

**Look for:**

- `bicep/` or `infrastructure/` directory with Bicep templates
- `modules/` directory with reusable infrastructure components
- `.github/workflows/` directory with CI/CD pipelines
- Parameter files for different environments
- Documentation directories

#### 2. Essential Files to Copy

**Always Copy:**

| File/Directory              | Purpose                      | Action                       |
| --------------------------- | ---------------------------- | ---------------------------- |
| `.github/workflows/`        | CI/CD pipeline templates     | Copy & modify                |
| `.gitignore`                | Git ignore rules             | Copy & extend                |
| `LICENSE`                   | License file                 | Copy if applicable           |
| `bicep/modules/networking/` | VNet, NSG, Private Endpoints | Copy if using CAF networking |
| `bicep/modules/monitoring/` | Log Analytics, App Insights  | Copy & adapt                 |
| `bicep/modules/keyvault/`   | Key Vault templates          | Copy & adapt                 |

**Evaluate for Relevance:**

| File/Directory             | Purpose                 | Keep?                                     |
| -------------------------- | ----------------------- | ----------------------------------------- |
| `bicep/modules/aks/`       | Kubernetes resources    | ❌ Remove (using App Service)             |
| `bicep/modules/acr/`       | Container Registry      | ❌ Remove (not containerizing)            |
| `bicep/modules/apim/`      | API Management          | ❌ Remove (not needed)                    |
| `bicep/modules/frontdoor/` | Azure Front Door        | ❌ Remove (single region)                 |
| `bicep/modules/cdn/`       | CDN resources           | ❌ Remove (internal app)                  |
| `bicep/modules/vpn/`       | VPN Gateway             | ❌ Remove (unless required by CAF policy) |
| `bicep/modules/firewall/`  | Azure Firewall          | ⚠️ Evaluate (may be required by CAF)      |
| `bicep/modules/storage/`   | Storage Account         | ✅ Keep & adapt                           |
| `bicep/modules/sql/`       | SQL Database            | ⚠️ May need for PostgreSQL template       |
| `scripts/`                 | Deployment scripts      | ✅ Keep & adapt                           |
| `docs/`                    | Documentation templates | ✅ Keep & extend                          |

#### 3. Create Marketing Storyteller Modules

**New modules to create** (see Application Docs for details):

| Module          | File                              | Purpose                                  | Priority     |
| --------------- | --------------------------------- | ---------------------------------------- | ------------ |
| App Service     | `bicep/modules/app-service.bicep` | Next.js web app                          | 🔴 Critical  |
| PostgreSQL      | `bicep/modules/postgresql.bicep`  | Database (Flexible Server)               | 🔴 Critical  |
| Redis Cache     | `bicep/modules/redis.bicep`       | BullMQ job queue                         | 🔴 Critical  |
| Azure OpenAI    | `bicep/modules/openai.bicep`      | GPT-4 for AI features                    | 🔴 Critical  |
| Storage Account | `bicep/modules/storage.bicep`     | Document blob storage                    | 🔴 Critical  |
| Key Vault       | `bicep/modules/keyvault.bicep`    | Secrets (adapt from CAF)                 | 🔴 Critical  |
| Monitoring      | `bicep/modules/monitoring.bicep`  | Application Insights (adapt from CAF)    | 🟡 Important |
| Networking      | `bicep/modules/networking.bicep`  | VNet, Private Endpoints (adapt from CAF) | 🟡 Important |

### Step-by-Step Adaptation Guide

#### Step 1: Copy Base Structure

```bash
# Create base directory structure
mkdir -p bicep/modules bicep/parameters .github/workflows scripts docs

# Copy essential files from CAF template
cp caf-temp/.gitignore .
cp -r caf-temp/.github/workflows .github/
cp -r caf-temp/scripts .
cp -r caf-temp/docs .

# Copy networking, monitoring, keyvault modules (adapt from CAF)
cp -r caf-temp/bicep/modules/networking bicep/modules/ || echo "Networking module not found - check CAF structure"
cp -r caf-temp/bicep/modules/monitoring bicep/modules/ || echo "Monitoring module not found"
cp -r caf-temp/bicep/modules/keyvault bicep/modules/ || echo "KeyVault module not found"
```

#### Step 2: Review CAF Main Template

Examine the main deployment file:

```bash
# Find the main Bicep file
find caf-temp/ -name "main.bicep" -o -name "azuredeploy.bicep"

# Review its structure
cat caf-temp/bicep/main.bicep
```

**Key things to identify:**

1. **Parameter structure** - How are environments configured?
2. **Module references** - How are child modules called?
3. **Naming conventions** - What naming pattern is used?
4. **Resource dependencies** - How are `dependsOn` relationships set up?
5. **Outputs** - What values are exposed?

#### Step 3: Identify Removable Modules

Search for modules we don't need:

```bash
# List all modules in CAF template
ls -1 caf-temp/bicep/modules/

# Search for AKS references
grep -r "Microsoft.ContainerService" caf-temp/bicep/

# Search for Container Registry
grep -r "Microsoft.ContainerRegistry" caf-temp/bicep/

# Search for API Management
grep -r "Microsoft.ApiManagement" caf-temp/bicep/
```

**Do NOT copy these modules:**

- Any AKS/Kubernetes references
- Container Registry (ACR)
- API Management
- Front Door or Traffic Manager
- Azure CDN
- VPN Gateway (unless required by policy)

#### Step 4: Adapt Existing Modules

For modules we're keeping from CAF, create adapted versions:

**Example: Key Vault**

```bash
# Copy and rename
cp caf-temp/bicep/modules/keyvault/keyvault.bicep bicep/modules/keyvault.bicep

# Edit to customize for Marketing Storyteller
# - Update naming conventions
# - Add specific secrets (database-url, openai-api-key, etc.)
# - Configure access policies for App Service managed identity
```

#### Step 5: Create Custom Modules

Create new Bicep files for Marketing Storyteller services:

```bash
# Create placeholder files for custom modules
touch bicep/modules/app-service.bicep
touch bicep/modules/postgresql.bicep
touch bicep/modules/redis.bicep
touch bicep/modules/openai.bicep
touch bicep/modules/storage.bicep
```

**Get templates from application repository:**

- See `marketing_storyteller/docs/operations/INFRASTRUCTURE_REPO_SETUP.md`
- Contains example Bicep code for each module

#### Step 6: Create Main Template

```bash
# Create main deployment file
touch bicep/main.bicep

# Create parameter files
touch bicep/parameters/dev.bicepparam
touch bicep/parameters/prod.bicepparam
```

#### Step 7: Update GitHub Actions

Adapt CAF CI/CD workflows:

```bash
# Review CAF workflows
ls -la .github/workflows/

# Key workflows to adapt:
# - validate.yml (Bicep validation on PR)
# - deploy-dev.yml (Deploy to development)
# - deploy-prod.yml (Deploy to production with approval)
```

**Customize for Marketing Storyteller:**

- Update resource group names
- Update Azure subscription references
- Add application-specific deployment steps

### Required Azure Resources

Marketing Storyteller needs these Azure services:

| Service                    | SKU (Dev)        | SKU (Prod)         | Purpose             |
| -------------------------- | ---------------- | ------------------ | ------------------- |
| App Service Plan           | P1V3 (Premium)   | P2V3 (Premium)     | Next.js hosting     |
| App Service                | Linux, Node 20   | Linux, Node 20     | Application runtime |
| PostgreSQL Flexible Server | B1ms (Burstable) | GP_Standard_D2s_v3 | Database            |
| Storage Account            | Standard LRS     | Standard GRS       | Document blobs      |
| Azure Cache for Redis      | Basic C0         | Standard C1        | BullMQ queue        |
| Azure OpenAI               | 10K TPM quota    | 50K TPM quota      | GPT-4 AI features   |
| Key Vault                  | Standard         | Standard           | Secrets             |
| Application Insights       | Standard         | Standard           | Monitoring          |

**Monthly Cost Estimate:**

- Development: ~$200 USD
- Production: ~$725 USD

### Naming Conventions

Follow this naming pattern (CAF-compliant):

```
<resource-type>-<app-name>-<environment>-<region>

Examples:
- app-marketingstory-dev-aue      (App Service)
- psql-marketingstory-dev-aue     (PostgreSQL)
- st-marketingstory-dev-aue       (Storage - no hyphens)
- redis-marketingstory-dev-aue    (Redis Cache)
- kv-marketingstory-dev-aue       (Key Vault)
- oai-marketingstory-dev-aue      (Azure OpenAI)
```

Abbreviations:

- `app` = App Service
- `psql` = PostgreSQL
- `st` = Storage Account
- `redis` = Redis Cache
- `kv` = Key Vault
- `oai` = Azure OpenAI
- `dev` = Development
- `prod` = Production
- `aue` = Australia East

### Environment Configuration

**Development:**

- Resource Group: `rg-marketingstory-dev-aue`
- Location: `australiaeast`
- Purpose: Testing, feature development
- Data: Can be reset/refreshed

**Production:**

- Resource Group: `rg-marketingstory-prod-aue`
- Location: `australiaeast`
- Purpose: Live marketing team usage
- Data: Persistent, backed up

### Integration with Application Repository

**Deployment Flow:**

1. **Infrastructure changes** merged to this repo → triggers infrastructure deployment
2. **Infrastructure deployment** completes → updates resource configurations
3. **Application changes** merged to application repo → triggers app deployment
4. **Application deployment** uses infrastructure outputs (connection strings, URLs)

**Coordination:**

- Infrastructure repo GitHub Actions can trigger application deployment via `repository_dispatch`
- Application repo references this repo in documentation
- Breaking infrastructure changes require coordinated deployment

### Documentation Checklist

Before proceeding with first deployment:

- [ ] README.md created (this file)
- [ ] Evaluated `caf-temp/` directory structure
- [ ] Identified modules to remove
- [ ] Identified modules to adapt
- [ ] Copied essential CAF files
- [ ] Created custom module placeholders
- [ ] Reviewed CAF naming conventions
- [ ] Understood resource requirements
- [ ] Reviewed GitHub Actions workflows
- [ ] Read application repository docs:
  - [ ] `docs/operations/AZURE_DEPLOYMENT_PLAN.md`
  - [ ] `docs/operations/INFRASTRUCTURE_REPO_SETUP.md`
  - [ ] `docs/operations/DEPLOYMENT_CHECKLIST.md`

### Next Steps

1. **Complete the evaluation:**

   ```bash
   # Review CAF template structure
   tree -L 3 caf-temp/ > caf-structure.txt

   # Document decisions
   echo "CAF Template Evaluation Complete" > EVALUATION.md
   echo "Files copied: [list]" >> EVALUATION.md
   echo "Files removed: [list]" >> EVALUATION.md
   echo "Custom modules created: [list]" >> EVALUATION.md
   ```

2. **Copy relevant CAF files** following Step 1-7 above

3. **Create custom modules** using templates from application repository

4. **Test locally:**

   ```bash
   # Validate Bicep syntax
   az bicep build --file bicep/main.bicep

   # Preview deployment (what-if)
   az deployment group what-if \
     --resource-group rg-marketingstory-dev-aue \
     --template-file bicep/main.bicep \
     --parameters bicep/parameters/dev.bicepparam
   ```

5. **First deployment** to development environment

6. **Update documentation** with actual deployment experience

### Reference Documentation

**Application Repository:**

- [Azure Deployment Plan](https://github.com/Insight-Services-APAC/marketing_storyteller/blob/main/docs/operations/AZURE_DEPLOYMENT_PLAN.md)
- [Infrastructure Setup Guide](https://github.com/Insight-Services-APAC/marketing_storyteller/blob/main/docs/operations/INFRASTRUCTURE_REPO_SETUP.md)
- [Deployment Checklist](https://github.com/Insight-Services-APAC/marketing_storyteller/blob/main/docs/operations/DEPLOYMENT_CHECKLIST.md)

**CAF Base Template:**

- [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1)

**Azure Documentation:**

- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Azure App Service for Next.js](https://learn.microsoft.com/en-us/azure/app-service/quickstart-nodejs)
- [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/)

### Support and Contributing

**For Infrastructure Issues:**

- Open an issue in this repository
- Tag with `infrastructure`, `bicep`, or `deployment`

**For Application Issues:**

- Open an issue in [marketing_storyteller](https://github.com/Insight-Services-APAC/marketing_storyteller)
- Tag with `application`, `bug`, or `feature`

**Questions:**

- Check application repository docs first
- Review CAF template examples
- Consult Azure Bicep documentation
- Ask in #marketing-storyteller Slack channel

---

## License

Copyright © 2025 Insight Services APAC. All rights reserved.

This infrastructure configuration is proprietary and confidential.
