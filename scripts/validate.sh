#!/bin/bash

# Marketing Storyteller Infrastructure Validation Script
# This script validates Bicep templates without deploying

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

print_info "Validating Bicep templates..."
echo ""

# Validate main template
print_info "Validating main orchestration template..."
if az bicep build --file src/orchestration/main.bicep --outfile /tmp/main.json; then
    print_success "main.bicep is valid"
else
    print_error "main.bicep validation failed"
    exit 1
fi

echo ""

# Validate individual modules
print_info "Validating individual modules..."
MODULES=(
    "monitoring"
    "storage"
    "redis"
    "openai"
    "keyvault"
    "postgresql"
    "app-service"
)

for module in "${MODULES[@]}"; do
    if az bicep build --file "src/modules/${module}.bicep" --outfile "/tmp/${module}.json"; then
        print_success "${module}.bicep is valid"
    else
        print_error "${module}.bicep validation failed"
        exit 1
    fi
done

echo ""
print_success "All Bicep templates are valid!"

# Clean up temp files
rm -f /tmp/*.json

echo ""
print_info "Template structure:"
tree -L 2 src/

echo ""
print_info "To deploy, run:"
echo "  ./scripts/deploy.sh -e dev -p 'YourSecurePassword123!'"
echo "  or"
echo "  ./scripts/deploy.sh -e prod -p 'YourSecurePassword123!'"
