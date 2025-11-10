#!/bin/bash

# Script to check resource group status
# Usage: ./scripts/check-resource-group.sh <environment>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_detail() {
    echo -e "${BLUE}[DETAIL]${NC} $1"
}

# Parse arguments
ENVIRONMENT="${1:-sandbox}"
LOCATION="australiaeast"
LOCATION_ABBR="aue"
RESOURCE_GROUP_NAME="rg-marketingstory-${ENVIRONMENT}-${LOCATION_ABBR}"

print_info "Checking resource group: $RESOURCE_GROUP_NAME"
echo ""

# Check if resource group exists
if az group exists --name "$RESOURCE_GROUP_NAME" | grep -q "true"; then
    print_info "Resource group EXISTS"
    
    # Get resource group details
    RG_DETAILS=$(az group show --name "$RESOURCE_GROUP_NAME" --output json)
    
    echo ""
    print_detail "Location: $(echo $RG_DETAILS | jq -r '.location')"
    print_detail "Provisioning State: $(echo $RG_DETAILS | jq -r '.properties.provisioningState')"
    
    # Get resource count
    RESOURCE_COUNT=$(az resource list --resource-group "$RESOURCE_GROUP_NAME" --query "length(@)" -o tsv)
    print_detail "Resource Count: $RESOURCE_COUNT"
    
    echo ""
    if [ "$RESOURCE_COUNT" -gt 0 ]; then
        print_info "Resources in group:"
        az resource list --resource-group "$RESOURCE_GROUP_NAME" \
            --query "[].{Name:name, Type:type, Location:location}" \
            --output table
        
        echo ""
        print_warning "To delete this resource group and all resources:"
        echo "  az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait"
    else
        print_info "Resource group is empty (no resources deployed)"
        echo ""
        print_info "Safe to delete with:"
        echo "  az group delete --name $RESOURCE_GROUP_NAME --yes"
    fi
else
    print_info "Resource group DOES NOT EXIST"
    echo ""
    print_info "To create this resource group:"
    echo "  az group create --name $RESOURCE_GROUP_NAME --location $LOCATION"
fi

echo ""
print_info "To deploy to this environment:"
echo "  ./scripts/deploy.sh -e $ENVIRONMENT -p 'YourSecurePassword123!'"
