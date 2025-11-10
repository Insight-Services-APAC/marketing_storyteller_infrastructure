#!/bin/bash
set -e

echo "🚀 Setting up Marketing Storyteller development environment..."

# Install Bicep CLI
echo "📦 Installing Bicep CLI..."
az bicep install

# Install PowerShell modules for Azure
echo "📦 Installing PowerShell modules..."
pwsh -Command "Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser -Repository PSGallery"

# Install Redis CLI
echo "📦 Installing Redis CLI..."
sudo apt-get update
sudo apt-get install -y redis-tools

# Create helper scripts directory
mkdir -p ~/.local/bin

# Create connection helper script for SANDBOX environment
cat > ~/.local/bin/connect-sandbox-db <<'EOF'
#!/bin/bash
# Connect to sandbox PostgreSQL database
RESOURCE_GROUP="rg-marketingstory-sandbox-aue"
SERVER_NAME="psql-marketingstory-sandbox-aue"

echo "🔌 Connecting to PostgreSQL (sandbox)..."
az postgres flexible-server connect \
  --name $SERVER_NAME \
  --admin-user psqladmin \
  --database-name marketingstory
EOF

chmod +x ~/.local/bin/connect-sandbox-db

# Create Redis connection helper for SANDBOX
cat > ~/.local/bin/connect-sandbox-redis <<'EOF'
#!/bin/bash
# Connect to sandbox Redis cache
RESOURCE_GROUP="rg-marketingstory-sandbox-aue"
REDIS_NAME="redis-marketingstory-sandbox-aue"

echo "🔌 Getting Redis connection info (sandbox)..."
REDIS_KEY=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query primaryKey -o tsv)
REDIS_HOST=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query hostName -o tsv)

echo "Connecting to redis://$REDIS_HOST:6380"
redis-cli -h $REDIS_HOST -p 6380 -a "$REDIS_KEY" --tls
EOF

chmod +x ~/.local/bin/connect-sandbox-redis

# Add helper scripts to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Create quick deployment aliases
cat >> ~/.bashrc <<'EOF'

# Marketing Storyteller aliases
alias deploy-sandbox='./scripts/deploy.sh -e sandbox'
alias deploy-dev='./scripts/deploy.sh -e dev'
alias deploy-prod='./scripts/deploy.sh -e prod'
alias validate-infra='./scripts/validate.sh'
alias show-outputs='az deployment sub show --name marketing-storyteller --query properties.outputs'

# Azure quick commands
alias az-login='az login --use-device-code'
alias az-list-rgs='az group list --query "[].{Name:name, Location:location}" -o table'
EOF

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "📝 Available commands:"
echo "  connect-sandbox-db    - Connect to PostgreSQL (sandbox)"
echo "  connect-sandbox-redis - Connect to Redis (sandbox)"
echo "  deploy-sandbox        - Deploy to sandbox environment (recommended for Codespaces)"
echo "  deploy-dev            - Deploy to dev environment (private endpoints)"
echo "  deploy-prod           - Deploy to production environment"
echo "  validate-infra        - Validate Bicep templates"
echo ""
echo "🔐 Don't forget to run 'az login' to authenticate with Azure"
echo ""
