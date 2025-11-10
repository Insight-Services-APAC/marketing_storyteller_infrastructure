# GitHub Enterprise Codespaces - FAQ

**Last Updated**: November 10, 2025

## Overview

Common questions about using GitHub Codespaces in a GitHub Enterprise organization with personal Azure subscriptions.

---

## ✅ Can I Use Codespaces in My Company's GitHub Enterprise Org?

**Yes!** GitHub Codespaces is **Generally Available (GA)** for GitHub Enterprise Cloud, not a preview feature.

### Status as of November 2025
- ✅ **Production-ready**: GA since August 2021
- ✅ **Enterprise support**: Full support in GitHub Enterprise Cloud
- ✅ **SLA-backed**: Covered by GitHub Enterprise SLA
- ✅ **Security certified**: SOC 2, ISO 27001, etc.

### What You Need to Check

1. **Org Admin Settings**:
   - Your GitHub org admin must have **enabled Codespaces**
   - Check: Organization Settings → Codespaces → "Enable for organization"

2. **Repository Access**:
   - You need repository access (read/write)
   - Org may restrict Codespaces by repository visibility (public/private)

3. **Billing Configuration**:
   - Org can allow **organization-paid** or **user-paid** Codespaces
   - Check when you create: "Billed to [organization]" or "Billed to [your account]"

---

## ✅ Can I Connect to My Personal Azure Subscription?

**Yes, 100%!** This is a very common scenario.

### How It Works

```
┌──────────────────────────────────────────────────────────────┐
│ GitHub Enterprise Org (Company GitHub)                       │
│  ├── Repository: Your infrastructure code                    │
│  └── Codespace: Hosted by GitHub (in GitHub's Azure tenant)  │
│                                                               │
│      ↓ You authenticate with az login                        │
│                                                               │
│ Personal Azure Subscription (Your VS Enterprise Credits)     │
│  ├── Resource Group: rg-marketingstory-dev-aue              │
│  ├── App Service, PostgreSQL, Redis, Storage, etc.          │
│  └── Billed to: Your Visual Studio Enterprise credits       │
└──────────────────────────────────────────────────────────────┘
```

### Key Points

1. **Codespace Location**: Runs in GitHub's infrastructure (Azure East US, West Europe, or Southeast Asia)
2. **Your Azure Resources**: Deployed to **your** subscription (e.g., Australia East)
3. **Authentication**: You `az login` with your personal Microsoft account
4. **Billing Separation**:
   - **Codespace compute/storage**: Billed to GitHub (org or personal)
   - **Azure resources**: Billed to your Visual Studio credits
5. **No Conflict**: These are completely independent

### Visual Studio Enterprise Credits

- ✅ **Works perfectly**: `az login` authenticates with your Microsoft account
- ✅ **$150/month credit**: Sufficient for dev environment (~$240/month normally)
- ✅ **No restrictions**: Use Codespaces or local development, doesn't matter
- ✅ **Credits auto-apply**: Azure resources use your credits first

---

## 🔒 Security & Compliance Concerns

### Company Data in Codespaces?

**Important**: The Codespace runs in **GitHub's Azure tenant**, not your company's.

| What | Where |
|------|-------|
| **Code repository** | Company GitHub Enterprise org |
| **Codespace VM** | GitHub's Azure infrastructure |
| **Your Azure resources** | Your personal Azure subscription |
| **Company data** | Stays in company systems |

**Best Practice**: Don't store company secrets/credentials in Codespaces. Use Azure Key Vault references for secrets.

### Data Residency

- **Codespace location**: GitHub chooses region (US, Europe, Asia)
- **Your Azure resources**: You choose region (e.g., Australia East)
- **Code**: Synced from GitHub (encrypted in transit)

**Note**: If your company has data residency requirements, verify Codespaces region policy with GitHub support.

### Network Isolation

When you enable **private endpoints** in your Azure deployment:
- ✅ Azure resources are **network-isolated** (private IPs only)
- ✅ Codespace can connect via Azure VNet integration
- ✅ Public internet **cannot** access your databases
- ✅ Your company network **cannot** access Codespace (it's in GitHub's tenant)

This is **perfect for dev/test**, but production may require additional controls.

---

## 💰 Who Pays for What?

### Codespaces Billing

**Option 1: Organization Pays** (Recommended for work projects)
- Org admin enables billing for organization
- Usage charged to company GitHub billing
- No personal cost to you

**Option 2: Personal Account Pays**
- You pay from personal GitHub account
- **Free tier available**: 120 core-hours/month (Free plan) or 180 core-hours/month (Pro plan)
- Example: 2-core machine = 60-90 hours/month free
- After free tier: ~$0.18/hour for 2-core, 8GB RAM machine

### Azure Billing

**Always charged to your Azure subscription** (Visual Studio credits):
- Dev environment: ~$240/month (without private endpoints)
- Dev with private endpoints: ~$299/month
- **Your $150/month VS credits** cover ~62% of dev costs

**Tip**: Delete dev resources when not in use to save credits.

---

## 🚀 Getting Started Checklist

### 1. Verify GitHub Enterprise Access

- [ ] Confirm your org uses **GitHub Enterprise Cloud**
- [ ] Check if Codespaces is enabled: Settings → Codespaces
- [ ] Verify you have repository access (read/write)

### 2. Verify Azure Access

- [ ] Confirm you have a **personal Azure subscription**
- [ ] Verify Visual Studio Enterprise credits are active
- [ ] Check remaining credits: [Azure Portal](https://portal.azure.com) → Subscriptions

### 3. Create Codespace

- [ ] Navigate to repository on GitHub
- [ ] Click **Code** → **Codespaces** tab
- [ ] Click **Create codespace on main**
- [ ] Note billing: "Billed to [organization]" or "Billed to [your account]"
- [ ] Wait 2-3 minutes for environment setup

### 4. Authenticate to Azure

- [ ] Open terminal in Codespace
- [ ] Run `az login`
- [ ] Authenticate with **personal Microsoft account** (Visual Studio subscription)
- [ ] Verify subscription: `az account show`

### 5. Deploy Infrastructure

- [ ] Review parameters: `src/configuration/main.dev.bicepparam`
- [ ] (Optional) Enable private endpoints: Uncomment `param enablePrivateEndpoints = true`
- [ ] Deploy: `./scripts/deploy.sh dev`
- [ ] Monitor deployment in Azure Portal

---

## ❓ Common Questions

### Q: Will my company see what I'm doing in the Codespace?

**A**: Depends on your org's policies:
- ✅ **Code commits**: Visible in GitHub (normal repository access)
- ✅ **Codespace creation**: Org admin can see you created a Codespace
- ❌ **Files in Codespace**: Not visible unless you commit/push
- ❌ **Terminal commands**: Not visible to org
- ❌ **Azure resources**: In your personal subscription, not company's

**Best practice**: Only work on approved projects in company org repositories.

### Q: Can I use Codespaces for personal projects?

**A**: Yes, but:
- ✅ Use **personal repositories** (not company org)
- ✅ Create Codespace from your personal account
- ✅ Bill to your personal GitHub account (free tier available)
- ❌ **Don't mix** company and personal work in same Codespace

### Q: What if my company blocks Codespaces?

**Alternatives**:
1. **Local Dev Containers**: Use VS Code + Docker Desktop (see `docs/CODESPACES_SETUP.md`)
2. **Local Tools**: Install Azure CLI, Bicep, etc. manually
3. **Request Access**: Ask IT to enable Codespaces with spending limits

### Q: Can I access company resources from Codespace?

**A**: Depends on network configuration:
- ✅ **Public APIs**: Yes (if allowed by firewall)
- ✅ **Azure public endpoints**: Yes
- ⚠️ **Company VPN**: May not work (Codespace is in GitHub's network)
- ❌ **Company private network**: No (Codespace not in company network)

**For company resources**: Consider local development with VPN instead.

### Q: What happens to my Codespace when I stop working?

- **Stop Codespace**: Automatically after 30 minutes of inactivity
- **Billing**: Stops when stopped (only storage cost ~$0.07/GB/month)
- **Data**: Preserved (resume anytime)
- **Delete Codespace**: Deletes all files (code is in Git, so safe)

**Tip**: Commit and push your work frequently!

### Q: Is this setup approved for production deployments?

**A**: **Not recommended without review**:
- ⚠️ **Personal subscription**: Production should use company subscription
- ⚠️ **Individual access**: Production needs team access, role separation
- ⚠️ **Visual Studio credits**: Limited budget ($150/month)
- ⚠️ **Support**: Personal subscriptions have limited support

**Recommended**:
- Use this setup for **dev/test/POC only**
- For production: Work with company IT to set up proper Azure subscription, governance, and deployment pipelines

---

## 📊 Cost Comparison

### Scenario 1: Personal Billing + Personal Azure

| Component | Cost/Month | Who Pays |
|-----------|-----------|----------|
| Codespace (2-core, 80hrs) | $14 | You (GitHub) |
| Azure dev resources | $240 | You (VS credits) |
| Azure private endpoints | +$59 | You (VS credits) |
| **Total out-of-pocket** | **$163** | **You** |
| **VS credits cover** | -$150 | **Microsoft** |
| **Actual cost** | **$13-72** | **You** |

### Scenario 2: Org Billing + Personal Azure

| Component | Cost/Month | Who Pays |
|-----------|-----------|----------|
| Codespace (2-core, 80hrs) | $14 | Company (GitHub) |
| Azure dev resources | $240 | You (VS credits) |
| Azure private endpoints | +$59 | You (VS credits) |
| **Total out-of-pocket** | **$149** | **You** |
| **VS credits cover** | -$150 | **Microsoft** |
| **Actual cost** | **$0** | **You** ✨ |

### Scenario 3: Local Dev + Personal Azure

| Component | Cost/Month | Who Pays |
|-----------|-----------|----------|
| Docker Desktop | $0-9* | You |
| Azure dev resources | $240 | You (VS credits) |
| Azure private endpoints | +$59 | You (VS credits) |
| **Total out-of-pocket** | **$149** | **You** |
| **VS credits cover** | -$150 | **Microsoft** |
| **Actual cost** | **$0** | **You** ✨ |

\* Docker Desktop is free for individuals and small businesses (<250 employees, <$10M revenue)

**Recommendation**: If your company pays for Codespaces, you can run this entire dev setup **within your VS Enterprise credits**! 🎉

---

## 🛠️ Troubleshooting

### "Codespaces is not enabled for this organization"

**Solution**:
1. Contact your GitHub org admin
2. Ask them to enable: Settings → Codespaces → Enable
3. They may need to set spending limits

**Alternative**: Fork repository to your personal account, use personal Codespace.

### "You don't have permission to create a codespace"

**Solution**:
1. Verify repository access (need write access)
2. Check org policy: May be restricted to certain teams/repos
3. Contact org admin to request access

### "Cannot authenticate to Azure"

**Solution**:
1. Run `az login` in Codespace terminal
2. Ensure you're using **personal Microsoft account** (not work account)
3. Verify subscription: `az account show`
4. If wrong subscription: `az account set --subscription "Visual Studio Enterprise"`

### "Deployment fails: insufficient quota"

**Solution**:
1. Check VS Enterprise credits remaining: Azure Portal → Cost Management
2. Verify subscription quotas: Azure Portal → Subscriptions → Usage + quotas
3. Consider reducing resources or changing regions

### "Cannot connect to database from Codespace"

**With private endpoints disabled**:
1. Check Azure SQL firewall rules
2. Add Codespace IP to allowed IPs (changes each time Codespace restarts)
3. Consider using `0.0.0.0-255.255.255.255` for dev (not recommended for prod)

**With private endpoints enabled**:
1. Verify VNet created: Azure Portal → Virtual Networks
2. Verify private endpoint: Azure Portal → Private endpoints
3. Test DNS resolution: `nslookup psql-marketingstory-dev-aue.postgres.database.azure.com`
4. Should resolve to `10.0.x.x` (private IP)

---

## 🔗 Additional Resources

- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [GitHub Enterprise Codespaces Billing](https://docs.github.com/en/billing/managing-billing-for-github-codespaces)
- [Visual Studio Enterprise Subscription Benefits](https://visualstudio.microsoft.com/vs/benefits/)
- [Azure Private Link Documentation](https://learn.microsoft.com/en-us/azure/private-link/)

---

## ✅ Summary

**Yes, you can confidently use this setup!**

1. ✅ **GitHub Enterprise Codespaces**: Fully GA, production-ready
2. ✅ **Personal Azure Subscription**: Works perfectly with `az login`
3. ✅ **Visual Studio Credits**: Cover most/all dev costs
4. ✅ **Security**: Proper isolation between company and personal resources
5. ✅ **Cost Effective**: $0-72/month depending on billing setup

**Next Step**: Ask your GitHub org admin if Codespaces is enabled, then create your first Codespace! 🚀
