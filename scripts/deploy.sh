#!/bin/bash

# Marketing Storyteller Infrastructure Deployment Script
# This script deploys the infrastructure to Azure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Parse arguments
ENVIRONMENT=""
POSTGRES_PASSWORD=""
SUBSCRIPTION_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -p|--postgres-password)
            POSTGRES_PASSWORD="$2"
            shift 2
            ;;
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 -e <environment> -p <postgres-password> [-s <subscription-id>]"
            echo ""
            echo "Options:"
            echo "  -e, --environment       Environment to deploy (sandbox|dev|prod)"
            echo "  -p, --postgres-password PostgreSQL administrator password"
            echo "  -s, --subscription      Azure subscription ID (optional)"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Environments:"
            echo "  sandbox - Personal development, public endpoints, low cost (~\$64/month)"
            echo "  dev     - Team development, private endpoints, production-like (~\$299/month)"
            echo "  prod    - Production workload, private endpoints, fully hardened (~\$500+/month)"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$ENVIRONMENT" ]; then
    print_error "Environment is required. Use -e sandbox, -e dev, or -e prod"
    exit 1
fi

if [ "$ENVIRONMENT" != "sandbox" ] && [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    print_error "Environment must be 'sandbox', 'dev', or 'prod'"
    exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
    print_error "PostgreSQL password is required. Use -p <password>"
    exit 1
fi

print_info "Starting deployment for environment: $ENVIRONMENT"

# Login check
print_info "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Logging in..."
    az login
fi

# Set subscription if provided
if [ -n "$SUBSCRIPTION_ID" ]; then
    print_info "Setting subscription to: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
fi

# Display current subscription
CURRENT_SUBSCRIPTION=$(az account show --query name -o tsv)
print_info "Deploying to subscription: $CURRENT_SUBSCRIPTION"

# Validate Bicep template
print_info "Validating Bicep template..."
az bicep build --file src/orchestration/main.bicep

if [ $? -ne 0 ]; then
    print_error "Bicep validation failed"
    exit 1
fi

print_info "Bicep validation successful"

# Get deployment location
LOCATION="australiaeast"
DEPLOYMENT_NAME="marketingstory-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"

# Deploy infrastructure
print_info "Deploying infrastructure..."
print_warning "This may take 15-30 minutes..."

az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file src/orchestration/main.bicep \
    --parameters src/configuration/main.${ENVIRONMENT}.bicepparam \
    --parameters postgresAdminPassword="$POSTGRES_PASSWORD" \
    --verbose

if [ $? -eq 0 ]; then
    print_info "Deployment successful!"
    
    # Get outputs
    print_info "Retrieving deployment outputs..."
    az deployment sub show \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs
else
    print_error "Deployment failed"
    exit 1
fi

print_info "Deployment complete for environment: $ENVIRONMENT"
