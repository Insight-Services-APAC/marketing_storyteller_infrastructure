# Azure Deployment Plan - Marketing Storyteller

## Overview

This document outlines the deployment strategy for Marketing Storyteller to Azure, using a separate infrastructure repository following CAF (Cloud Adoption Framework) alignment.

## Repository Structure

### Application Repository (Current)

- **Name**: `marketing_storyteller`
- **Purpose**: Application code, business logic, tests
- **Repository**: https://github.com/Insight-Services-APAC/marketing_storyteller

### Infrastructure Repository (New)

- **Name**: `marketing_storyteller_infrastructure`
- **Purpose**: Azure infrastructure as code (Bicep templates)
- **Base Template**: https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1
- **Strategy**: Clone CAF-aligned template, remove unnecessary features

## Linking Repositories

### 1. Git Submodules (Recommended)

Add infrastructure as a submodule to the application repository:

```bash
# In marketing_storyteller repository
git submodule add https://github.com/Insight-Services-APAC/marketing_storyteller_infrastructure.git infrastructure
```

**Pros:**

- Infrastructure versioned with application
- Easy to sync deployment with code changes
- Single clone gets both repos

**Cons:**

- Requires submodule commands
- Slightly more complex for new developers

### 2. Repository References in Documentation

Link repositories via documentation only (simpler approach):

- Add infrastructure repo link to README.md
- Reference application repo in infrastructure README
- Use GitHub Actions to coordinate deployments

**Pros:**

- Simpler git workflow
- Clear separation of concerns
- Independent versioning

**Cons:**

- Manual coordination required
- No automatic version linking

## Infrastructure Components Needed

Based on Epic 2 features, you'll need:

### Core Azure Services

1. **App Service (Web App)**
   - Runtime: Node.js 20 LTS
   - Plan: Premium V3 (P1V3 minimum for production)
   - Environment: Dev + Prod

2. **Azure Database for PostgreSQL**
   - Version: 16.1 (Flexible Server)
   - SKU: Burstable B1ms (Dev), General Purpose (Prod)
   - Features: Point-in-time restore, automated backups

3. **Azure Storage Account**
   - Purpose: Blob storage for uploaded documents
   - Tier: Standard (LRS for Dev, GRS for Prod)
   - Containers: `story-documents`, `enhancement-files`

4. **Azure OpenAI Service**
   - Model: GPT-4 deployment
   - Region: Australia East (or closest with GPT-4)
   - Quota: 10K tokens/min (Dev), 50K+ (Prod)

5. **Azure Cache for Redis**
   - Purpose: BullMQ job queue
   - Tier: Basic C0 (Dev), Standard C1+ (Prod)
   - Features: Persistence enabled

6. **Azure Key Vault**
   - Purpose: Secrets management
   - Secrets: DB passwords, API keys, auth secrets

7. **Application Insights**
   - Purpose: Monitoring, logging, performance tracking
   - Retention: 30 days (Dev), 90+ days (Prod)

8. **Azure Entra ID (Azure AD)**
   - Purpose: SSO authentication
   - App Registration: Marketing Storyteller (Dev + Prod)

### Networking (from CAF Template)

- Virtual Network (if required by Landing Zone policy)
- Private Endpoints (for Prod PostgreSQL, Storage, Redis)
- Network Security Groups

### Optional (Can Remove from Template)

- Azure Kubernetes Service (not needed - using App Service)
- Azure Container Registry (not needed unless containerizing)
- Azure Front Door (not needed unless multi-region)
- Azure CDN (not needed for internal app)

## Environment Strategy

### Development Environment

- **Resource Group**: `rg-marketingstory-dev-aue`
- **App Service**: `app-marketingstory-dev-aue`
- **PostgreSQL**: `psql-marketingstory-dev-aue`
- **Storage**: `stmarketingstorydevaue`
- **Redis**: `redis-marketingstory-dev-aue`
- **Key Vault**: `kv-marketingstory-dev-aue`
- **OpenAI**: `oai-marketingstory-dev-aue`

### Production Environment

- **Resource Group**: `rg-marketingstory-prod-aue`
- **App Service**: `app-marketingstory-prod-aue`
- **PostgreSQL**: `psql-marketingstory-prod-aue`
- **Storage**: `stmarketingstoryprodaue`
- **Redis**: `redis-marketingstory-prod-aue`
- **Key Vault**: `kv-marketingstory-prod-aue`
- **OpenAI**: `oai-marketingstory-prod-aue`

## Bicep Template Adaptation Strategy

### Step 1: Clone Base Template

```bash
# Create new repository
gh repo create Insight-Services-APAC/marketing_storyteller_infrastructure --public

# Clone locally
git clone https://github.com/Insight-Services-APAC/marketing_storyteller_infrastructure.git

# Add reference to base template in README
echo "Based on: https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1" >> README.md
```

### Step 2: Remove Unnecessary Modules

Review the CAF template and remove:

- AKS-related modules (if present)
- Container registry modules
- VPN/ExpressRoute configurations (unless required)
- Multi-region deployments
- Any governance/policy modules not needed

### Step 3: Add Marketing Storyteller Modules

Create new Bicep modules for:

- `modules/app-service.bicep` - Next.js web app
- `modules/postgresql.bicep` - Database
- `modules/storage.bicep` - Document storage
- `modules/redis.bicep` - Job queue
- `modules/openai.bicep` - AI service
- `modules/keyvault.bicep` - Secrets
- `modules/monitoring.bicep` - Application Insights

### Step 4: Create Main Deployment

- `main.bicep` - Orchestrates all modules
- `parameters/dev.bicepparam` - Dev environment config
- `parameters/prod.bicepparam` - Prod environment config

## CI/CD Integration

### Application Repository (marketing_storyteller)

**GitHub Actions Workflow**: `.github/workflows/deploy.yml`

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-infrastructure:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Infrastructure Deployment
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.INFRA_REPO_TOKEN }}
          script: |
            github.rest.actions.createWorkflowDispatch({
              owner: 'Insight-Services-APAC',
              repo: 'marketing_storyteller_infrastructure',
              workflow_id: 'deploy-bicep.yml',
              ref: 'main',
              inputs: {
                environment: 'dev'
              }
            })

  deploy-application:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install dependencies
        run: npm ci
      - name: Build application
        run: npm run build
      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v3
        with:
          app-name: app-marketingstory-dev-aue
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

### Infrastructure Repository (marketing_storyteller_infrastructure)

**GitHub Actions Workflow**: `.github/workflows/deploy-bicep.yml`

```yaml
name: Deploy Azure Infrastructure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - prod

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Bicep
        uses: azure/arm-deploy@v1
        with:
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          resourceGroupName: rg-marketingstory-${{ github.event.inputs.environment }}-aue
          template: ./main.bicep
          parameters: ./parameters/${{ github.event.inputs.environment }}.bicepparam
          failOnStdErr: false
```

## Epic 2 Features - Azure Service Mapping

| Feature                         | Azure Service            | Configuration                            |
| ------------------------------- | ------------------------ | ---------------------------------------- |
| **Story 2.1**: Document Upload  | Storage Account (Blob)   | Container: `story-documents`, 50MB limit |
| **Story 2.2**: AI Processing    | Azure OpenAI (GPT-4)     | Deployment: `gpt-4`, 10K TPM             |
| **Story 2.3**: Background Jobs  | Redis + App Service      | BullMQ workers, 4 concurrent jobs        |
| **Story 2.4**: Story Generation | Azure OpenAI (GPT-4)     | Max tokens: 4000                         |
| **Story 2.5**: Enhancement      | Storage + OpenAI         | Enhancement files container              |
| **Story 2.6**: Quality Check    | Azure OpenAI (GPT-4)     | Quality analysis prompts                 |
| **Story 2.7**: Draft Management | PostgreSQL               | Stories table, status enum               |
| **Story 2.8**: Draft Review     | PostgreSQL + App Service | Review workflow                          |
| **Story 2.9**: Export           | App Service              | Markdown download                        |

## Database Migration Strategy

### Initial Setup

```bash
# Run migrations on first deployment
npm run db:migrate

# Seed initial data (roles, users)
npm run db:seed
```

### Migration in CI/CD

Add to GitHub Actions:

```yaml
- name: Run Database Migrations
  run: |
    export DATABASE_URL="${{ secrets.DATABASE_URL }}"
    npm run db:migrate
```

## Environment Variables Configuration

### Required Secrets in Azure Key Vault

```bash
# Database
DATABASE_URL=postgresql://user:pass@psql-marketingstory-dev-aue.postgres.database.azure.com:5432/marketing_storyteller

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://oai-marketingstory-dev-aue.openai.azure.com/
AZURE_OPENAI_API_KEY=<from-key-vault>
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4

# Azure Blob Storage
AZURE_STORAGE_CONNECTION_STRING=<from-key-vault>
AZURE_STORAGE_ACCOUNT_NAME=stmarketingstorydevaue

# Redis (BullMQ)
REDIS_HOST=redis-marketingstory-dev-aue.redis.cache.windows.net
REDIS_PORT=6380
REDIS_PASSWORD=<from-key-vault>
REDIS_TLS=true

# Auth (Azure AD)
NEXTAUTH_URL=https://app-marketingstory-dev-aue.azurewebsites.net
NEXTAUTH_SECRET=<from-key-vault>
AZURE_AD_CLIENT_ID=<from-app-registration>
AZURE_AD_CLIENT_SECRET=<from-key-vault>
AZURE_AD_TENANT_ID=<your-tenant-id>

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING=<from-key-vault>
```

### App Service Configuration

Map Key Vault secrets to App Service environment variables:

```bicep
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(SecretUri=https://kv-marketingstory-dev-aue.vault.azure.net/secrets/database-url/)'
        }
        // ... other settings
      ]
    }
  }
}
```

## Cost Estimation

### Development Environment (Monthly)

- App Service (P1V3): ~$100
- PostgreSQL (B1ms): ~$15
- Storage (Standard LRS): ~$5
- Redis (Basic C0): ~$17
- Azure OpenAI (10K TPM): ~$50 (usage-based)
- Key Vault: ~$1
- Application Insights: ~$10
- **Total**: ~$200/month

### Production Environment (Monthly)

- App Service (P2V3): ~$200
- PostgreSQL (GP Gen5 2vCore): ~$150
- Storage (Standard GRS): ~$20
- Redis (Standard C1): ~$75
- Azure OpenAI (50K TPM): ~$250 (usage-based)
- Key Vault: ~$1
- Application Insights: ~$30
- **Total**: ~$725/month

## Next Steps

1. **Create Infrastructure Repository**

   ```bash
   gh repo create Insight-Services-APAC/marketing_storyteller_infrastructure --public
   ```

2. **Clone CAF Template**

   ```bash
   git clone https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1.git temp-caf
   # Copy relevant files to marketing_storyteller_infrastructure
   # Remove unnecessary modules
   ```

3. **Link Repositories**
   - Add infrastructure repo link to this repository's README
   - Add application repo link to infrastructure README
   - Optional: Add as git submodule

4. **Configure Azure**
   - Create service principal for GitHub Actions
   - Set up resource groups
   - Configure Azure AD app registrations

5. **Adapt Bicep Templates**
   - Remove unused modules (AKS, Container Registry, etc.)
   - Add Marketing Storyteller modules
   - Create parameter files for Dev/Prod

6. **Set Up CI/CD**
   - Create GitHub Actions workflows
   - Configure secrets in GitHub
   - Test deployment to Dev environment

7. **Deploy to Dev**
   - Run infrastructure deployment
   - Deploy application code
   - Run database migrations
   - Verify all Epic 2 features work

8. **Deploy to Prod**
   - Repeat process for production environment
   - Configure custom domain (if needed)
   - Set up monitoring alerts

## References

- **Base CAF Template**: https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1
- **Application Repository**: https://github.com/Insight-Services-APAC/marketing_storyteller
- **Azure Bicep Documentation**: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/
- **Next.js Azure Deployment**: https://nextjs.org/docs/deployment#self-hosting
