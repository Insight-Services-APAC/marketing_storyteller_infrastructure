using '../orchestration/main.bicep'

// ============================================================================
// SANDBOX ENVIRONMENT - Personal Development / Testing
// ============================================================================
// Purpose: Low-cost, public endpoints, developer-friendly configuration
// Use Case: Personal Azure subscriptions, learning, POCs, local testing
// Cost: ~$150-200/month (within Visual Studio Enterprise credits)
// Security: Public endpoints with firewall rules, SSL enforcement, dev best practices
// ============================================================================

// Environment
param environmentId = 'sandbox'
param location = 'australiaeast'

// Application
param appNamePrefix = 'marketingstory'

// Tags
param tags = {
  environment: 'sandbox'
  applicationName: 'Marketing Storyteller'
  owner: 'Developer'
  criticality: 'Tier3'
  costCenter: 'Development'
  contactEmail: 'dev@insightservices.com'
  dataClassification: 'Development'
  businessUnit: 'Digital Marketing'
  workloadName: 'MarketingStoryteller'
  managedBy: 'Bicep IaC'
  createdDate: '2024-01'
  compliance: 'None'
  iac: 'Bicep'
  ephemeral: 'true' // Indicates this can be deleted/recreated
}

// ============================================================================
// NETWORKING - Public Endpoints (No Private Endpoints)
// ============================================================================
// Sandbox uses public endpoints for simplicity and compatibility with:
// - GitHub Codespaces
// - Local development
// - Personal Azure subscriptions
// - Remote access from anywhere
// ============================================================================

param enablePrivateEndpoints = false

// ============================================================================
// POSTGRESQL - Development Configuration
// ============================================================================
// Lower SKU for cost savings, public endpoint with firewall rules
// ============================================================================

param postgresAdminUsername = 'psqladmin'
// Note: postgresAdminPassword should be provided at deployment time
// Example: --parameters postgresAdminPassword="DevPassword123!"

// PostgreSQL Specific Settings (if needed - requires module parameter support)
// - SKU: B_Standard_B1ms (Burstable, 1 vCore, 2GB RAM) - ~$13/month
// - Storage: 32 GB (minimum)
// - Backup retention: 7 days (minimum)
// - Geo-redundant backup: Disabled
// - High availability: Disabled
// - SSL enforcement: Enabled (always)
// - Public network access: Enabled with firewall rules

// ============================================================================
// REDIS - Development Configuration
// ============================================================================
// Basic SKU for cost savings, public endpoint with SSL
// ============================================================================

// Redis Specific Settings (if needed - requires module parameter support)
// - SKU: Basic C0 (250 MB cache) - ~$16/month
// - SSL: Required (always)
// - Public network access: Enabled
// - AOF persistence: Disabled (not available in Basic)
// - Clustering: Disabled (not available in Basic)

// ============================================================================
// STORAGE - Development Configuration
// ============================================================================
// Standard LRS for cost savings, public endpoint with firewall
// ============================================================================

// Storage Specific Settings (if needed - requires module parameter support)
// - SKU: Standard_LRS (no redundancy)
// - Public network access: Enabled with firewall
// - Blob versioning: Disabled
// - Change feed: Disabled
// - Soft delete: 7 days

// ============================================================================
// APP SERVICE - Development Configuration
// ============================================================================
// Basic B1 SKU for cost savings
// ============================================================================

// App Service Specific Settings (if needed - requires module parameter support)
// - SKU: B1 (1 core, 1.75 GB RAM) - ~$13/month
// - Always On: Disabled (saves cost)
// - Auto-scale: Disabled
// - VNet integration: Not available on Basic SKU

// Additional App Settings
param additionalAppSettings = {
  NEXTAUTH_URL: 'https://app-marketingstory-sandbox-aue.azurewebsites.net'
  NODE_ENV: 'development'
  DEBUG: 'true'
  LOG_LEVEL: 'debug'
  // Sandbox-specific settings
  ENABLE_ANALYTICS: 'false'
  ENABLE_MONITORING: 'false'
  RATE_LIMIT_ENABLED: 'false'
}

// ============================================================================
// KEY VAULT - Development Configuration
// ============================================================================
// Standard SKU, public endpoint with firewall
// ============================================================================

// Key Vault Access (optional)
// param keyVaultInitialAccessPrincipalId = 'your-service-principal-object-id'

// Key Vault Specific Settings
// - SKU: Standard
// - Public network access: Enabled with firewall
// - Soft delete: 7 days (minimum, cannot disable)
// - Purge protection: Disabled (allows full delete)

// ============================================================================
// AZURE OPENAI - Use Existing (Recommended for Sandbox)
// ============================================================================
// Reuse existing OpenAI service to save cost and quota
// ============================================================================

// Option 1: Use existing OpenAI service (RECOMMENDED for sandbox)
// Uncomment these lines if you have an existing AI Foundry/OpenAI service
param useExistingOpenAI = true
param existingOpenAIName = 'oai-shared-dev-aue'
param existingOpenAIResourceGroup = 'rg-shared-ai-dev-aue'
param existingGPT4DeploymentName = 'gpt-4'

// Option 2: Create new OpenAI service (NOT RECOMMENDED - quota limits)
// Uncomment if you need a dedicated instance (adds ~$0/month base + usage)
// param useExistingOpenAI = false

// ============================================================================
// MONITORING - Minimal Configuration
// ============================================================================
// Basic monitoring without alerts to reduce noise
// ============================================================================

// Monitoring Specific Settings
// - Log Analytics: Pay-as-you-go (very low cost for sandbox)
// - Application Insights: Basic monitoring only
// - Retention: 30 days
// - Alerts: Disabled (or minimal critical alerts only)

// Alerts disabled for sandbox
param enableAlerts = false
// param alertEmailAddresses = [
//   'dev@insightservices.com'
// ]

// ============================================================================
// SECURITY BEST PRACTICES FOR SANDBOX
// ============================================================================
// Even though sandbox uses public endpoints, we still enforce:
// 
// 1. SSL/TLS Enforcement:
//    - PostgreSQL: require_secure_transport = ON
//    - Redis: SSL port 6380 only
//    - Storage: HTTPS required
//    - Key Vault: HTTPS only
//
// 2. Firewall Rules:
//    - PostgreSQL: Allow Azure services + specific IPs (or 0.0.0.0/0 for dev)
//    - Redis: No IP restrictions (protected by access keys)
//    - Storage: Allow Azure services + specific IPs
//    - Key Vault: Allow Azure services + specific IPs
//
// 3. Authentication:
//    - PostgreSQL: Admin password + managed identity (where possible)
//    - Redis: Access keys (rotate regularly)
//    - Storage: SAS tokens + managed identity
//    - Key Vault: Azure AD authentication + RBAC
//
// 4. Data Protection:
//    - Use test/synthetic data only
//    - No production data in sandbox
//    - Regular cleanup of old resources
//
// 5. Cost Management:
//    - Auto-shutdown App Service when not in use
//    - Delete resources when done testing
//    - Monitor costs via Azure Cost Management
//
// 6. Managed Identities:
//    - App Service uses managed identity to access Key Vault
//    - App Service uses managed identity to access Storage
//    - Minimizes secret sprawl
//
// ============================================================================

// ============================================================================
// DEPLOYMENT NOTES
// ============================================================================
// 
// Deploy sandbox environment:
//   ./scripts/deploy.sh sandbox
//
// Or manually:
//   az deployment sub create \
//     --location australiaeast \
//     --template-file src/orchestration/main.bicep \
//     --parameters src/configuration/main.sandbox.bicepparam \
//     --parameters postgresAdminPassword="YourSecurePassword123!"
//
// Estimated Monthly Cost (AUD, Australia East):
//   - App Service (B1):              ~$13
//   - PostgreSQL (B_Standard_B1ms):  ~$13
//   - Redis (Basic C0):              ~$16
//   - Storage (Standard_LRS):        ~$5
//   - Key Vault (Standard):          ~$2
//   - Application Insights:          ~$5
//   - Log Analytics:                 ~$10
//   - OpenAI (existing):             ~$0 (shared)
//   - Private Endpoints:             ~$0 (disabled)
//   ----------------------------------------
//   TOTAL:                           ~$64/month
//
// With Visual Studio Enterprise credits ($150/month): $0 out-of-pocket! ✨
//
// ============================================================================

// ============================================================================
// SANDBOX vs DEV vs PROD
// ============================================================================
// 
// SANDBOX:
//   - Purpose: Personal development, learning, POCs
//   - Cost: ~$64/month (within VS credits)
//   - Network: Public endpoints + firewall rules
//   - SKUs: Basic/Burstable (lowest cost)
//   - HA: Disabled
//   - Backups: 7 days
//   - Monitoring: Minimal
//   - Access: Developer only, from anywhere
//   - Data: Test data only
//
// DEV:
//   - Purpose: Team development, integration testing
//   - Cost: ~$299/month
//   - Network: Private endpoints + VNet
//   - SKUs: Standard/General Purpose
//   - HA: Enabled
//   - Backups: 14 days
//   - Monitoring: Full monitoring + alerts
//   - Access: Team access, VPN/Bastion required
//   - Data: Sanitized production data
//
// PROD:
//   - Purpose: Production workload
//   - Cost: ~$500+/month
//   - Network: Private endpoints + WAF + CDN
//   - SKUs: Premium
//   - HA: Zone-redundant
//   - Backups: 30+ days, geo-redundant
//   - Monitoring: Full monitoring + 24/7 alerts
//   - Access: Ops team only, MFA required
//   - Data: Production data
//
// ============================================================================
