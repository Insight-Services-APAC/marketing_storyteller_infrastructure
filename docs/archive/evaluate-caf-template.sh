#!/bin/bash
# CAF Template Evaluation Script
# Run this in the infrastructure repository to document CAF template structure

set -e

echo "🔍 Marketing Storyteller Infrastructure - CAF Template Evaluation"
echo "================================================================="
echo ""

# Check if caf-temp exists
if [ ! -d "caf-temp" ]; then
    echo "❌ Error: caf-temp/ directory not found"
    echo "Please clone the CAF template first:"
    echo "  git clone https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1.git caf-temp"
    exit 1
fi

echo "✅ Found caf-temp/ directory"
echo ""

# Create evaluation report
REPORT="CAF_EVALUATION_REPORT.md"
echo "# CAF Template Evaluation Report" > "$REPORT"
echo "" >> "$REPORT"
echo "**Date**: $(date +%Y-%m-%d)" >> "$REPORT"
echo "**Evaluator**: $(git config user.name)" >> "$REPORT"
echo "**Source**: [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1)" >> "$REPORT"
echo "" >> "$REPORT"

# 1. Directory Structure
echo "📂 Analyzing directory structure..."
echo "## Directory Structure" >> "$REPORT"
echo "" >> "$REPORT"
echo '```' >> "$REPORT"
tree -L 3 caf-temp/ 2>/dev/null >> "$REPORT" || find caf-temp/ -type d -maxdepth 3 | sort >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

# 2. Bicep Modules
echo "🧩 Analyzing Bicep modules..."
echo "## Bicep Modules Found" >> "$REPORT"
echo "" >> "$REPORT"

if [ -d "caf-temp/bicep/modules" ] || [ -d "caf-temp/modules" ]; then
    MODULE_DIR=$(find caf-temp -type d -name "modules" | head -1)
    echo "**Module Directory**: \`$MODULE_DIR\`" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "| Module | Status | Action |" >> "$REPORT"
    echo "|--------|--------|--------|" >> "$REPORT"
    
    # List all subdirectories in modules
    for module in $(find "$MODULE_DIR" -mindepth 1 -maxdepth 1 -type d | sort); do
        MODULE_NAME=$(basename "$module")
        
        # Categorize modules
        case "$MODULE_NAME" in
            *aks*|*kubernetes*|*k8s*)
                echo "| $MODULE_NAME | ❌ Remove | Not using Kubernetes |" >> "$REPORT"
                ;;
            *acr*|*container*registry*)
                echo "| $MODULE_NAME | ❌ Remove | Not containerizing |" >> "$REPORT"
                ;;
            *apim*|*api*management*)
                echo "| $MODULE_NAME | ❌ Remove | Not needed |" >> "$REPORT"
                ;;
            *frontdoor*|*cdn*|*traffic*)
                echo "| $MODULE_NAME | ❌ Remove | Single region |" >> "$REPORT"
                ;;
            *vpn*|*gateway*|*express*)
                echo "| $MODULE_NAME | ⚠️ Evaluate | May be required by CAF policy |" >> "$REPORT"
                ;;
            *network*|*vnet*|*nsg*)
                echo "| $MODULE_NAME | ✅ Keep | Adapt for Marketing Storyteller |" >> "$REPORT"
                ;;
            *storage*|*blob*)
                echo "| $MODULE_NAME | ✅ Keep | Adapt for document storage |" >> "$REPORT"
                ;;
            *monitor*|*insights*|*log*)
                echo "| $MODULE_NAME | ✅ Keep | Adapt for Application Insights |" >> "$REPORT"
                ;;
            *keyvault*|*vault*)
                echo "| $MODULE_NAME | ✅ Keep | Adapt for secrets |" >> "$REPORT"
                ;;
            *sql*|*database*|*postgres*)
                echo "| $MODULE_NAME | ✅ Keep | May adapt for PostgreSQL |" >> "$REPORT"
                ;;
            *firewall*)
                echo "| $MODULE_NAME | ⚠️ Evaluate | May be required by CAF policy |" >> "$REPORT"
                ;;
            *)
                echo "| $MODULE_NAME | ⚠️ Review | Check if needed |" >> "$REPORT"
                ;;
        esac
    done
else
    echo "⚠️ No modules directory found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 3. GitHub Actions Workflows
echo "🔄 Analyzing GitHub Actions workflows..."
echo "## GitHub Actions Workflows" >> "$REPORT"
echo "" >> "$REPORT"

if [ -d "caf-temp/.github/workflows" ]; then
    echo "**Workflows Found**:" >> "$REPORT"
    echo "" >> "$REPORT"
    for workflow in caf-temp/.github/workflows/*.yml caf-temp/.github/workflows/*.yaml; do
        if [ -f "$workflow" ]; then
            WORKFLOW_NAME=$(basename "$workflow")
            echo "- \`$WORKFLOW_NAME\`" >> "$REPORT"
        fi
    done
else
    echo "⚠️ No workflows found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 4. Parameter Files
echo "⚙️ Analyzing parameter files..."
echo "## Parameter Files" >> "$REPORT"
echo "" >> "$REPORT"

PARAM_FILES=$(find caf-temp -name "*.parameters.json" -o -name "*.bicepparam" 2>/dev/null || true)
if [ -n "$PARAM_FILES" ]; then
    echo "**Parameter files found**:" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "$PARAM_FILES" | while read file; do
        echo "- \`$file\`" >> "$REPORT"
    done
else
    echo "⚠️ No parameter files found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 5. Main Bicep Files
echo "📄 Finding main deployment files..."
echo "## Main Deployment Files" >> "$REPORT"
echo "" >> "$REPORT"

MAIN_FILES=$(find caf-temp -name "main.bicep" -o -name "azuredeploy.bicep" 2>/dev/null || true)
if [ -n "$MAIN_FILES" ]; then
    echo "**Main templates found**:" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "$MAIN_FILES" | while read file; do
        echo "- \`$file\`" >> "$REPORT"
    done
else
    echo "⚠️ No main templates found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 6. Documentation
echo "📚 Checking for documentation..."
echo "## Documentation Files" >> "$REPORT"
echo "" >> "$REPORT"

DOC_FILES=$(find caf-temp -name "README*.md" -o -name "*.md" | grep -E "(docs|README)" 2>/dev/null || true)
if [ -n "$DOC_FILES" ]; then
    echo "**Documentation found**:" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "$DOC_FILES" | while read file; do
        echo "- \`$file\`" >> "$REPORT"
    done
else
    echo "⚠️ No documentation found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 7. Recommendations
echo "## Recommendations" >> "$REPORT"
echo "" >> "$REPORT"
echo "### Files to Copy Immediately" >> "$REPORT"
echo "" >> "$REPORT"
echo "```bash" >> "$REPORT"
echo "# Essential CAF files" >> "$REPORT"
if [ -f "caf-temp/.gitignore" ]; then
    echo "cp caf-temp/.gitignore ." >> "$REPORT"
fi
if [ -d "caf-temp/.github/workflows" ]; then
    echo "cp -r caf-temp/.github/workflows .github/" >> "$REPORT"
fi
if [ -d "caf-temp/scripts" ]; then
    echo "cp -r caf-temp/scripts ." >> "$REPORT"
fi
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "### Modules to Adapt" >> "$REPORT"
echo "" >> "$REPORT"
echo "Based on Marketing Storyteller requirements:" >> "$REPORT"
echo "" >> "$REPORT"
echo "1. **Keep and adapt**: networking, monitoring, keyvault, storage" >> "$REPORT"
echo "2. **Remove**: AKS, ACR, API Management, Front Door, CDN, VPN (unless required)" >> "$REPORT"
echo "3. **Create new**: app-service, postgresql, redis, openai modules" >> "$REPORT"
echo "" >> "$REPORT"

echo "### Next Actions" >> "$REPORT"
echo "" >> "$REPORT"
echo "- [ ] Review this evaluation report" >> "$REPORT"
echo "- [ ] Copy essential files listed above" >> "$REPORT"
echo "- [ ] Create \`bicep/modules/\` directory structure" >> "$REPORT"
echo "- [ ] Copy and adapt relevant CAF modules" >> "$REPORT"
echo "- [ ] Create custom Marketing Storyteller modules" >> "$REPORT"
echo "- [ ] Create main.bicep orchestration file" >> "$REPORT"
echo "- [ ] Create dev.bicepparam and prod.bicepparam files" >> "$REPORT"
echo "- [ ] Update GitHub Actions workflows" >> "$REPORT"
echo "- [ ] Delete caf-temp/ after copying required files" >> "$REPORT"
echo "" >> "$REPORT"

# Summary
echo ""
echo "✅ Evaluation complete!"
echo ""
echo "📋 Report saved to: $REPORT"
echo ""
echo "Next steps:"
echo "  1. Review $REPORT"
echo "  2. Copy recommended files from caf-temp/"
echo "  3. Create custom modules for Marketing Storyteller"
echo "  4. Delete caf-temp/ after copying"
echo ""
echo "For detailed guidance, see:"
echo "  - README.md (this repository)"
echo "  - marketing_storyteller/docs/operations/INFRASTRUCTURE_REPO_SETUP.md"
echo ""
