# Azure Deployment Checklist

Use this checklist when deploying Marketing Storyteller to Azure.

## Phase 1: Infrastructure Repository Setup

### 1.1 Create Repository

- [ ] Create `marketing_storyteller_infrastructure` repository on GitHub
  ```bash
  gh repo create Insight-Services-APAC/marketing_storyteller_infrastructure \
    --public \
    --description "Azure infrastructure as code for Marketing Storyteller"
  ```
- [ ] Clone repository locally
- [ ] Add infrastructure link to `marketing_storyteller/README.md` (✅ Already done)

### 1.2 Clone CAF Base Template

- [ ] Clone base template to temporary directory
  ```bash
  git clone https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1.git temp-caf
  ```
- [ ] Review template structure
- [ ] Copy relevant files to infrastructure repo
- [ ] Remove temp directory

### 1.3 Remove Unnecessary Modules

Review and remove unused modules from CAF template:

- [ ] Remove AKS/Kubernetes modules (not using containers)
- [ ] Remove Azure Container Registry (not needed)
- [ ] Remove VPN/ExpressRoute (not needed for basic deployment)
- [ ] Remove Azure Front Door (single region only)
- [ ] Remove Azure CDN (internal app)
- [ ] Remove API Management (not needed)
- [ ] Keep networking modules if required by CAF policy

### 1.4 Create Directory Structure

- [ ] Create `bicep/modules/` directory
- [ ] Create `bicep/parameters/` directory
- [ ] Create `.github/workflows/` directory
- [ ] Create `scripts/` directory
- [ ] Create `docs/` directory

### 1.5 Create Bicep Modules

Create these modules in `bicep/modules/`:

- [ ] `app-service.bicep` - Next.js web app
- [ ] `postgresql.bicep` - Database (Flexible Server)
- [ ] `storage.bicep` - Blob storage for documents
- [ ] `redis.bicep` - Cache for BullMQ
- [ ] `openai.bicep` - Azure OpenAI Service
- [ ] `keyvault.bicep` - Secrets management
- [ ] `monitoring.bicep` - Application Insights
- [ ] `networking.bicep` - VNet (if required by CAF)

### 1.6 Create Main Template

- [ ] Create `bicep/main.bicep` - Orchestrates all modules
- [ ] Create `bicep/parameters/dev.bicepparam` - Dev environment config
- [ ] Create `bicep/parameters/prod.bicepparam` - Prod environment config

### 1.7 Create Documentation

- [ ] Create comprehensive `README.md`
- [ ] Add link to application repository
- [ ] Add link to base CAF template
- [ ] Document deployed resources
- [ ] Add deployment instructions

### 1.8 Initial Commit

- [ ] Add all files to git
- [ ] Create initial commit with reference to CAF template
- [ ] Push to GitHub

## Phase 2: Azure Configuration

### 2.1 Create Service Principal

- [ ] Login to Azure CLI
  ```bash
  az login
  ```
- [ ] Set correct subscription
  ```bash
  az account set --subscription <subscription-id>
  ```
- [ ] Create service principal for GitHub Actions
  ```bash
  az ad sp create-for-rbac \
    --name "sp-marketingstory-github-actions" \
    --role contributor \
    --scopes /subscriptions/<subscription-id> \
    --sdk-auth
  ```
- [ ] Save JSON output for GitHub secrets

### 2.2 Create Resource Groups

- [ ] Create development resource group
  ```bash
  az group create \
    --name rg-marketingstory-dev-aue \
    --location australiaeast \
    --tags environment=development application=marketing-storyteller
  ```
- [ ] Create production resource group
  ```bash
  az group create \
    --name rg-marketingstory-prod-aue \
    --location australiaeast \
    --tags environment=production application=marketing-storyteller
  ```

### 2.3 Configure Azure AD App Registrations

- [ ] Create app registration for Development
  - Name: `Marketing Storyteller (Dev)`
  - Redirect URI: `https://app-marketingstory-dev-aue.azurewebsites.net/api/auth/callback/azure-ad`
- [ ] Create app registration for Production
  - Name: `Marketing Storyteller (Prod)`
  - Redirect URI: `https://app-marketingstory-prod-aue.azurewebsites.net/api/auth/callback/azure-ad`
- [ ] Save Client IDs and Client Secrets for Key Vault

### 2.4 Request Azure OpenAI Access

- [ ] Submit access request for Azure OpenAI Service
- [ ] Wait for approval (may take 1-2 business days)
- [ ] Note approved region (ideally Australia East)

## Phase 3: GitHub Configuration

### 3.1 Configure Infrastructure Repository Secrets

In `marketing_storyteller_infrastructure` repository settings:

- [ ] Add `AZURE_CREDENTIALS` - Service principal JSON
- [ ] Add `AZURE_SUBSCRIPTION_ID` - Subscription ID
- [ ] Add `AZURE_TENANT_ID` - Azure AD tenant ID

### 3.2 Configure Application Repository Secrets

In `marketing_storyteller` repository settings:

- [ ] Add `AZURE_WEBAPP_PUBLISH_PROFILE_DEV` - Download from App Service
- [ ] Add `AZURE_WEBAPP_PUBLISH_PROFILE_PROD` - Download from App Service
- [ ] Add `INFRA_REPO_TOKEN` - GitHub PAT for triggering infrastructure deployments

### 3.3 Create GitHub Actions Workflows

In infrastructure repository:

- [ ] Create `.github/workflows/validate.yml` - Bicep validation on PRs
- [ ] Create `.github/workflows/deploy-dev.yml` - Deploy to development
- [ ] Create `.github/workflows/deploy-prod.yml` - Deploy to production

In application repository:

- [ ] Create `.github/workflows/deploy-dev.yml` - Deploy app to dev after infrastructure
- [ ] Create `.github/workflows/deploy-prod.yml` - Deploy app to prod (manual trigger)

## Phase 4: Development Environment Deployment

### 4.1 Validate Bicep Templates

- [ ] Run local validation
  ```bash
  az deployment group validate \
    --resource-group rg-marketingstory-dev-aue \
    --template-file bicep/main.bicep \
    --parameters bicep/parameters/dev.bicepparam
  ```
- [ ] Fix any validation errors

### 4.2 Deploy Infrastructure to Dev

- [ ] Trigger GitHub Actions workflow OR deploy manually:
  ```bash
  az deployment group create \
    --resource-group rg-marketingstory-dev-aue \
    --template-file bicep/main.bicep \
    --parameters bicep/parameters/dev.bicepparam
  ```
- [ ] Verify all resources created successfully
- [ ] Note any deployment warnings or errors

### 4.3 Configure Key Vault Secrets

Manually add secrets to Key Vault (one-time):

- [ ] `database-url` - PostgreSQL connection string
- [ ] `openai-api-key` - Azure OpenAI API key
- [ ] `redis-password` - Redis access key
- [ ] `nextauth-secret` - Generated secret (use `openssl rand -base64 32`)
- [ ] `azure-ad-client-secret` - From App Registration
- [ ] `sendgrid-api-key` - SendGrid API key (if using email)

### 4.4 Configure Storage Containers

- [ ] Create `story-documents` container (private)
- [ ] Create `enhancement-files` container (private)
- [ ] Configure CORS if needed for direct browser uploads

### 4.5 Deploy Application to Dev

- [ ] Build Next.js application
  ```bash
  npm ci
  npm run build
  ```
- [ ] Deploy to App Service
  ```bash
  az webapp deployment source config-zip \
    --resource-group rg-marketingstory-dev-aue \
    --name app-marketingstory-dev-aue \
    --src build.zip
  ```
- [ ] Monitor deployment logs

### 4.6 Run Database Migrations

- [ ] SSH into App Service or run locally with prod connection string
  ```bash
  export DATABASE_URL="<postgres-connection-string>"
  npm run db:migrate
  ```
- [ ] Seed initial data (roles, sample users)
  ```bash
  npm run db:seed
  ```

### 4.7 Verify Development Deployment

- [ ] Access application URL: https://app-marketingstory-dev-aue.azurewebsites.net
- [ ] Test authentication (Azure AD login)
- [ ] Test Epic 1 features (create story, list stories, etc.)
- [ ] Test Epic 2 features:
  - [ ] Document upload (Story 2.1)
  - [ ] AI processing (Story 2.2)
  - [ ] Background jobs (Story 2.3)
  - [ ] Story generation (Story 2.4)
  - [ ] Enhancement (Story 2.5)
  - [ ] Quality check (Story 2.6)
  - [ ] Draft management (Story 2.7)
  - [ ] Draft review (Story 2.8)
  - [ ] Export (Story 2.9)
- [ ] Check Application Insights for logs and metrics
- [ ] Verify Redis job queue is processing

## Phase 5: Production Environment Deployment

### 5.1 Update Production Parameters

- [ ] Review `bicep/parameters/prod.bicepparam`
- [ ] Adjust SKUs for production workload
- [ ] Configure production-grade settings

### 5.2 Deploy Infrastructure to Prod

- [ ] Trigger production deployment workflow (manual approval required)
- [ ] Monitor deployment progress
- [ ] Verify all resources created

### 5.3 Configure Production Key Vault

- [ ] Add all secrets to production Key Vault
- [ ] Use different values than dev (new passwords, different API keys)

### 5.4 Deploy Application to Prod

- [ ] Deploy via GitHub Actions OR manually
- [ ] Run database migrations on production database
- [ ] Do NOT seed sample data (production should start clean)

### 5.5 Production Verification

- [ ] Access production URL
- [ ] Test authentication
- [ ] Create test story end-to-end
- [ ] Verify monitoring and alerts
- [ ] Load test with expected user volume

### 5.6 Configure Custom Domain (Optional)

- [ ] Purchase/configure domain (e.g., storyteller.insight.com)
- [ ] Add custom domain to App Service
- [ ] Configure SSL certificate (managed certificate)
- [ ] Update Azure AD redirect URIs

## Phase 6: Monitoring & Maintenance

### 6.1 Set Up Alerts

In Application Insights:

- [ ] HTTP 5xx errors > 5 in 5 minutes
- [ ] Response time > 3 seconds
- [ ] Failed requests > 10% of total
- [ ] Database connection failures

In Azure Monitor:

- [ ] PostgreSQL CPU > 80%
- [ ] Redis memory > 90%
- [ ] Storage account capacity > 80%
- [ ] App Service memory > 90%

### 6.2 Configure Backup

- [ ] Enable PostgreSQL automated backups (7-day retention minimum)
- [ ] Configure blob storage lifecycle management
- [ ] Test restore procedure from backup

### 6.3 Cost Management

- [ ] Set up budget alerts
- [ ] Review cost analysis weekly
- [ ] Optimize SKUs based on actual usage
- [ ] Consider reserved instances for production

### 6.4 Documentation

- [ ] Document deployment process
- [ ] Create runbook for common operations
- [ ] Document disaster recovery procedure
- [ ] Update architecture diagrams with actual resource names

## Phase 7: Post-Deployment

### 7.1 User Onboarding

- [ ] Create admin accounts for Marketing Managers
- [ ] Invite initial users
- [ ] Conduct training session
- [ ] Provide user documentation

### 7.2 Performance Optimization

- [ ] Review Application Insights performance data
- [ ] Optimize slow queries
- [ ] Implement caching where beneficial
- [ ] Consider CDN for static assets

### 7.3 Security Review

- [ ] Run security scan on deployed application
- [ ] Review network security groups
- [ ] Verify all endpoints use HTTPS
- [ ] Test RBAC enforcement
- [ ] Verify GDPR compliance features

## Rollback Plan

If deployment fails:

### Infrastructure Rollback

- [ ] Delete resource group (destroys all resources)
- [ ] OR redeploy previous working version of Bicep templates

### Application Rollback

- [ ] Revert to previous deployment slot
- [ ] OR redeploy previous Git commit
- [ ] Rollback database migrations if needed

## Support Contacts

- **Azure Support**: [Azure Portal](https://portal.azure.com)
- **OpenAI Support**: openai-support@microsoft.com
- **Infrastructure Issues**: Open issue in `marketing_storyteller_infrastructure` repo
- **Application Issues**: Open issue in `marketing_storyteller` repo

## Success Criteria

Deployment is successful when:

- ✅ All Epic 2 features work in production
- ✅ Authentication via Azure AD works
- ✅ Database migrations completed successfully
- ✅ Monitoring and alerts configured
- ✅ Cost within budget ($200/month dev, $725/month prod)
- ✅ No critical security vulnerabilities
- ✅ Application Insights showing healthy metrics
- ✅ Users can create and publish stories end-to-end
