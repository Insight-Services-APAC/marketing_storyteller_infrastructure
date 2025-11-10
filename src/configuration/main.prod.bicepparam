using '../orchestration/main.bicep'

// Environment
param environmentId = 'prod'
param location = 'australiaeast'

// Application
param appNamePrefix = 'marketingstory'

// Tags
param tags = {
  environment: 'prod'
  applicationName: 'Marketing Storyteller'
  owner: 'Platform Team'
  criticality: 'Tier1'
  costCenter: 'Marketing'
  contactEmail: 'platform@insightservices.com'
  dataClassification: 'Confidential'
  businessUnit: 'Digital Marketing'
  workloadName: 'MarketingStoryteller'
  managedBy: 'Bicep IaC'
  createdDate: '2024-01'
  compliance: 'ISO27001'
  iac: 'Bicep'
}

// PostgreSQL
param postgresAdminUsername = 'psqladmin'

// PostgreSQL Admin Password
// SECURITY: This placeholder will be overridden at deployment time via CLI
// Deploy with: ./scripts/deploy.sh -e prod -p "YourSecurePassword123!"
// The actual password should NEVER be committed to source control
param postgresAdminPassword = 'PLACEHOLDER-WILL-BE-OVERRIDDEN-AT-DEPLOYMENT'

// Additional App Settings (optional)
param additionalAppSettings = {
  NEXTAUTH_URL: 'https://app-marketingstory-prod-aue.azurewebsites.net'
  // Add more environment-specific settings as needed
}

// Key Vault Access (optional)
// param keyVaultInitialAccessPrincipalId = 'your-service-principal-object-id'

// Azure OpenAI Configuration
// Option 1: Use existing OpenAI service (recommended for shared prod infrastructure)
// Uncomment these lines if you have an existing AI Foundry/OpenAI service
// param useExistingOpenAI = true
// param existingOpenAIName = 'oai-shared-prod-aue'
// param existingOpenAIResourceGroup = 'rg-shared-ai-prod-aue'
// param existingGPT4DeploymentName = 'gpt-4'

// Option 2: Create new OpenAI service (default)
param useExistingOpenAI = false

// Monitoring Alerts (RECOMMENDED for production)
// Uncomment and configure alert recipients
// param enableAlerts = true
// param alertEmailAddresses = [
//   'platform-team@insightservices.com'
//   'oncall@insightservices.com'
// ]
// param alertSmsNumbers = [
//   '0412345678' // AU format without country code
// ]

// Private Networking (RECOMMENDED for production)
// Uncomment to enable private endpoints for backend services
// This adds ~$59/month and provides full network isolation
// param enablePrivateEndpoints = true
// param vnetAddressPrefix = '10.1.0.0/16'
