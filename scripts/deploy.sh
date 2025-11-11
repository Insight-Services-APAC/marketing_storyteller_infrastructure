#!/bin/bash

# Marketing Storyteller Infrastructure Deployment Script
# This script deploys the infrastructure to Azure

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root directory
cd "$PROJECT_ROOT"

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
            echo "Usage: $0 -e <environment> [-p <postgres-password>] [-s <subscription-id>]"
            echo ""
            echo "Options:"
            echo "  -e, --environment       Environment to deploy (sandbox|dev|prod)"
            echo "  -p, --postgres-password PostgreSQL administrator password (optional - will prompt)"
            echo "  -s, --subscription      Azure subscription ID (optional)"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Password:"
            echo "  If not provided, you will be prompted to generate or enter a password."
            echo "  The password is used for PostgreSQL and stored in Azure Key Vault."
            echo ""
            echo "Environments:"
            echo "  sandbox - Personal development, public endpoints, low cost (~\$64/month)"
            echo "  dev     - Team development, private endpoints, production-like (~\$299/month)"
            echo "  prod    - Production workload, private endpoints, fully hardened (~\$500+/month)"
            echo ""
            echo "Examples:"
            echo "  $0 -e sandbox                          # Will prompt for password"
            echo "  $0 -e sandbox -p 'MySecure#Pass123'    # Provide password inline"
            echo "  $0 -e dev -s <subscription-id>          # Specific subscription"
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

# Handle PostgreSQL password
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo ""
    print_warning "PostgreSQL Administrator Password Required"
    echo ""
    echo "This password is used for:"
    echo "  • PostgreSQL Flexible Server administrator account"
    echo "  • Stored securely in Azure Key Vault"
    echo "  • Used by the application for database connections"
    echo ""
    echo "Password requirements:"
    echo "  • Minimum 8 characters, maximum 128 characters"
    echo "  • Must contain characters from 3 of these categories:"
    echo "    - Uppercase letters (A-Z)"
    echo "    - Lowercase letters (a-z)"
    echo "    - Numbers (0-9)"
    echo "    - Special characters (!, @, #, $, %, etc.)"
    echo "  • Cannot contain username (postgres)"
    echo ""
    echo "🔒 IMPORTANT: Store this password in your organization's secret management"
    echo "   system (e.g., 1Password, Azure Key Vault, HashiCorp Vault)"
    echo ""
    read -p "Would you like to generate a secure password now? (y/n): " generate_password
    
    if [[ "$generate_password" =~ ^[Yy]$ ]]; then
        # Generate a secure password: 16 chars with mixed case, numbers, and special chars
        POSTGRES_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
        # Ensure it has at least one special char by appending one
        POSTGRES_PASSWORD="${POSTGRES_PASSWORD}@$(openssl rand -base64 4 | tr -d "=+/" | cut -c1-4)"
        echo ""
        print_info "Generated password (copy this now!):"
        echo ""
        echo "    $POSTGRES_PASSWORD"
        echo ""
        print_warning "⚠️  Copy this password to your secret manager NOW!"
        print_warning "⚠️  You will need it for database access and troubleshooting"
        echo ""
        read -p "Press Enter after you have saved the password to continue..."
    else
        echo ""
        read -sp "Enter PostgreSQL password: " POSTGRES_PASSWORD
        echo ""
        if [ -z "$POSTGRES_PASSWORD" ]; then
            print_error "Password cannot be empty"
            exit 1
        fi
    fi
fi

print_info "Starting deployment for environment: $ENVIRONMENT"

# ============================================================================
# Azure OpenAI Configuration Check
# ============================================================================
echo ""
print_info "Checking for existing Azure OpenAI services..."
echo ""

# Search for existing OpenAI services in subscription
OPENAI_SERVICES=$(az cognitiveservices account list --query "[?kind=='OpenAI'].{name:name, resourceGroup:resourceGroup, location:location}" -o json 2>/dev/null)

if [ -n "$OPENAI_SERVICES" ] && [ "$OPENAI_SERVICES" != "[]" ]; then
    SERVICE_COUNT=$(echo "$OPENAI_SERVICES" | jq '. | length')
    
    if [ "$SERVICE_COUNT" -gt 0 ]; then
        print_info "Found $SERVICE_COUNT existing Azure OpenAI service(s) in your subscription:"
        echo ""
        echo "$OPENAI_SERVICES" | jq -r '.[] | "  • \(.name) (in \(.resourceGroup), \(.location))"'
        echo ""
        print_info "Azure OpenAI has strict quota limits. You can:"
        echo "  1) Use an existing OpenAI service (recommended - share quota)"
        echo "  2) Create a new OpenAI service (requires quota available)"
        echo ""
        read -p "Would you like to use an existing OpenAI service? (y/n): " use_existing_openai
        
        if [[ "$use_existing_openai" =~ ^[Yy]$ ]]; then
            # List services with numbers
            echo ""
            print_info "Available OpenAI services:"
            echo "$OPENAI_SERVICES" | jq -r 'to_entries[] | "\(.key + 1)) \(.value.name) - \(.value.resourceGroup)"'
            echo ""
            read -p "Select service number (or press Enter to create new): " service_number
            
            if [ -n "$service_number" ] && [ "$service_number" -gt 0 ] && [ "$service_number" -le "$SERVICE_COUNT" ]; then
                SELECTED_OPENAI=$(echo "$OPENAI_SERVICES" | jq -r ".[$((service_number - 1))]")
                OPENAI_NAME=$(echo "$SELECTED_OPENAI" | jq -r '.name')
                OPENAI_RG=$(echo "$SELECTED_OPENAI" | jq -r '.resourceGroup')
                
                print_info "Selected: $OPENAI_NAME in $OPENAI_RG"
                
                # Check for GPT-4 deployment
                print_info "Checking for GPT-4 deployments..."
                GPT4_DEPLOYMENTS=$(az cognitiveservices account deployment list \
                    --name "$OPENAI_NAME" \
                    --resource-group "$OPENAI_RG" \
                    --query "[?properties.model.name=='gpt-4' || properties.model.name=='gpt-4-turbo'].name" \
                    -o tsv 2>/dev/null)
                
                if [ -n "$GPT4_DEPLOYMENTS" ]; then
                    print_info "Found GPT-4 deployment(s): $GPT4_DEPLOYMENTS"
                    GPT4_DEPLOYMENT_NAME=$(echo "$GPT4_DEPLOYMENTS" | head -n1)
                    print_info "Will use: $GPT4_DEPLOYMENT_NAME"
                    
                    # Set parameters to use existing OpenAI
                    OPENAI_PARAMS="useExistingOpenAI=true existingOpenAIName=$OPENAI_NAME existingOpenAIResourceGroup=$OPENAI_RG existingGPT4DeploymentName=$GPT4_DEPLOYMENT_NAME"
                else
                    print_warning "No GPT-4 deployment found in this service"
                    print_warning "The deployment will create a new OpenAI service instead"
                    OPENAI_PARAMS=""
                fi
            else
                print_info "Creating new OpenAI service"
                OPENAI_PARAMS=""
            fi
        else
            print_info "Creating new OpenAI service"
            OPENAI_PARAMS=""
        fi
    else
        print_info "No existing OpenAI services found - will create new"
        OPENAI_PARAMS=""
    fi
else
    print_info "No existing OpenAI services found - will create new"
    OPENAI_PARAMS=""
fi

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

# Display current subscription and get details
CURRENT_SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
CURRENT_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Validate Bicep template
print_info "Validating Bicep template..."
az bicep build --file src/orchestration/main.bicep

if [ $? -ne 0 ]; then
    print_error "Bicep validation failed"
    exit 1
fi

print_info "Bicep validation successful"

# Get deployment location and resource group
LOCATION="australiaeast"
LOCATION_ABBR="aue"
DEPLOYMENT_NAME="marketingstory-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"
RESOURCE_GROUP_NAME="rg-marketingstory-${ENVIRONMENT}-${LOCATION_ABBR}"

# Final confirmation before deployment
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    DEPLOYMENT CONFIRMATION                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
print_info "Environment:      $ENVIRONMENT"
print_info "Subscription:     $CURRENT_SUBSCRIPTION_NAME"
print_info "Subscription ID:  $CURRENT_SUBSCRIPTION_ID"
print_info "Resource Group:   $RESOURCE_GROUP_NAME"
print_info "Location:         $LOCATION"
echo ""
print_warning "This deployment will create Azure resources and incur costs."
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirmation

if [[ ! "$confirmation" =~ ^[Yy][Ee][Ss]$ ]]; then
    print_info "Deployment cancelled by user"
    exit 0
fi

echo ""
print_info "Proceeding with deployment..."
echo ""
print_info "Proceeding with deployment..."
echo ""

# Check if resource group exists
print_info "Checking if resource group exists: $RESOURCE_GROUP_NAME"
if az group exists --name "$RESOURCE_GROUP_NAME" | grep -q "true"; then
    print_warning "Resource group '$RESOURCE_GROUP_NAME' already exists"
    echo ""
    echo "What would you like to do?"
    echo "  1) Use existing resource group (update deployment)"
    echo "  2) Delete and recreate resource group (clean deployment)"
    echo "  3) Cancel deployment"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            print_info "Using existing resource group for update deployment"
            ;;
        2)
            print_warning "Deleting existing resource group..."
            az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait
            print_info "Waiting for resource group deletion to complete..."
            # Wait for deletion to complete
            while az group exists --name "$RESOURCE_GROUP_NAME" | grep -q "true"; do
                sleep 5
                echo -n "."
            done
            echo ""
            print_info "Resource group deleted successfully"
            print_info "Creating new resource group..."
            az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
            ;;
        3)
            print_info "Deployment cancelled by user"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Deployment cancelled."
            exit 1
            ;;
    esac
else
    print_info "Creating new resource group: $RESOURCE_GROUP_NAME"
    az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
fi

# Deploy infrastructure
print_info "Deploying infrastructure to resource group: $RESOURCE_GROUP_NAME"
print_warning "This may take 15-30 minutes..."

# Build parameters command
DEPLOY_PARAMS="postgresAdminPassword=$POSTGRES_PASSWORD"
if [ -n "$OPENAI_PARAMS" ]; then
    DEPLOY_PARAMS="$DEPLOY_PARAMS $OPENAI_PARAMS"
fi

az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file src/orchestration/main.bicep \
    --parameters src/configuration/main.${ENVIRONMENT}.bicepparam \
    --parameters $DEPLOY_PARAMS \
    --verbose

if [ $? -eq 0 ]; then
    print_info "Deployment successful!"
    
    # Get outputs
    print_info "Retrieving deployment outputs..."
    az deployment group show \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --query properties.outputs
else
    print_error "Deployment failed"
    exit 1
fi

print_info "Deployment complete for environment: $ENVIRONMENT"
