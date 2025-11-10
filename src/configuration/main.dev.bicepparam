using '../orchestration/main.bicep'

// Environment
param environmentId = 'dev'
param location = 'australiaeast'

// Application
param appNamePrefix = 'marketingstory'

// Tags
param tags = {
  environment: 'dev'
  applicationName: 'Marketing Storyteller'
  owner: 'Platform Team'
  criticality: 'Tier2'
  costCenter: 'Marketing'
  contactEmail: 'platform@insightservices.com'
  dataClassification: 'Internal'
  businessUnit: 'Digital Marketing'
  workloadName: 'MarketingStoryteller'
  managedBy: 'Bicep IaC'
  createdDate: '2024-01'
  compliance: 'None'
  iac: 'Bicep'
}

// PostgreSQL
param postgresAdminUsername = 'psqladmin'
// Note: postgresAdminPassword should be provided at deployment time or from Key Vault
// For example: --parameters postgresAdminPassword="YourSecurePassword123!"

// Additional App Settings (optional)
param additionalAppSettings = {
  NEXTAUTH_URL: 'https://app-marketingstory-dev-aue.azurewebsites.net'
  // Add more environment-specific settings as needed
}

// Key Vault Access (optional)
// param keyVaultInitialAccessPrincipalId = 'your-service-principal-object-id'

// Azure OpenAI Configuration
// Option 1: Use existing OpenAI service (recommended for dev environments)
// Uncomment these lines if you have an existing AI Foundry/OpenAI service
// param useExistingOpenAI = true
// param existingOpenAIName = 'oai-shared-dev-aue'
// param existingOpenAIResourceGroup = 'rg-shared-ai-dev-aue'
// param existingGPT4DeploymentName = 'gpt-4'

// Option 2: Create new OpenAI service (default)
param useExistingOpenAI = false

// Monitoring Alerts (optional)
// Uncomment and configure alert recipients
// param enableAlerts = true
// param alertEmailAddresses = [
//   'platform-team@insightservices.com'
//   'devops@insightservices.com'
// ]
// param alertSmsNumbers = [
//   '0412345678' // AU format without country code
// ]

// ============================================================================
// NETWORKING - Private Endpoints (Production-like Configuration)
// ============================================================================
// Dev environment uses private endpoints to match production architecture
// This enables testing of VNet integration, private DNS, etc.
// For personal development with Codespaces, use 'sandbox' environment instead
// ============================================================================

param enablePrivateEndpoints = true
param vnetAddressPrefix = '10.0.0.0/16'

// ============================================================================
// NOTES FOR DEV ENVIRONMENT
// ============================================================================
// - Use this environment for team development and integration testing
// - Requires VPN or Bastion for access (not compatible with Codespaces)
// - Matches production network architecture
// - Higher cost (~$299/month) but production-like testing
// - For personal development, use 'sandbox' environment instead
// ============================================================================
