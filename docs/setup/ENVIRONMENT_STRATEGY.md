# Environment Strategy - Sandbox, Dev, Prod

**Last Updated**: November 10, 2025  
**Status**: Active

## 🎯 Overview

Marketing Storyteller infrastructure supports **three environments** with different purposes, costs, and security profiles:

1. **Sandbox** - Personal development with public endpoints
2. **Dev** - Team development with private endpoints (production-like)
3. **Prod** - Production workload with full hardening

---

## 📊 Environment Comparison

| Aspect | Sandbox | Dev | Prod |
|--------|---------|-----|------|
| **Purpose** | Personal development, learning, POCs | Team development, integration testing | Production workload |
| **Users** | Individual developers | Development team | End users + ops team |
| **Cost/Month** | ~$64 | ~$299 | ~$500+ |
| **Network** | Public endpoints | Private endpoints | Private endpoints + WAF |
| **Access** | Anywhere (Codespaces, local) | VPN/Bastion required | Ops team only (MFA) |
| **Data** | Test/synthetic data only | Sanitized prod data | Production data |
| **SKUs** | Basic/Burstable | Standard/General Purpose | Premium/Zone-redundant |
| **HA** | Disabled | Enabled | Zone-redundant |
| **Backups** | 7 days | 14 days | 30+ days, geo-redundant |
| **Monitoring** | Minimal | Full monitoring + alerts | 24/7 monitoring + PagerDuty |
| **Compliance** | None | Internal policies | SOC 2, ISO 27001 |
| **Deployment** | Manual or GitHub Codespaces | CI/CD pipeline | CI/CD with approvals |

---

## 🏖️ Sandbox Environment

### Purpose
Personal development, experimentation, learning, and proof-of-concepts in a developer's **personal Azure subscription**.

### Key Characteristics

**Network Architecture**:
```
Developer (Codespaces/Local) → Internet → Azure Public Endpoints
                                          ├── PostgreSQL (firewall + SSL)
                                          ├── Redis (SSL + access keys)
                                          ├── Storage (HTTPS + SAS tokens)
                                          └── Key Vault (Azure AD auth)
```

**Security Approach**:
- ✅ Public endpoints with **firewall rules**
- ✅ **SSL/TLS enforcement** on all services
- ✅ **Managed identities** where possible
- ✅ **Azure AD authentication** for Key Vault
- ✅ **Test data only** (no production data)

**Cost Optimization**:
- Basic/Burstable SKUs (lowest cost)
- Single-region deployment
- No high availability
- Minimal backup retention (7 days)
- No geo-redundancy
- Shared OpenAI service (recommended)

### Resource Specifications

| Resource | SKU/Configuration | Monthly Cost (AUD) |
|----------|-------------------|-------------------|
| **App Service** | B1 (1 core, 1.75 GB) | ~$13 |
| **PostgreSQL** | B_Standard_B1ms (Burstable, 1 vCore, 2GB) | ~$13 |
| **Redis** | Basic C0 (250 MB) | ~$16 |
| **Storage** | Standard_LRS (32 GB) | ~$5 |
| **Key Vault** | Standard | ~$2 |
| **Application Insights** | Pay-as-you-go | ~$5 |
| **Log Analytics** | Pay-as-you-go | ~$10 |
| **OpenAI** | Use existing (shared) | ~$0 |
| **Private Endpoints** | Disabled | ~$0 |
| **TOTAL** | | **~$64/month** |

**Visual Studio Enterprise Credits**: $150/month covers 100% of sandbox costs! ✨

### When to Use Sandbox

✅ **Use Sandbox When**:
- Developing on personal Azure subscription
- Testing new features locally
- Learning Azure services
- Running POCs or experiments
- Using GitHub Codespaces
- Cost is a primary concern
- Need quick setup/teardown

❌ **Don't Use Sandbox For**:
- Team development (use dev)
- Integration testing with other teams (use dev)
- Production data (never!)
- Customer-facing workloads (use prod)
- Compliance testing (use dev/prod)

### Deployment

```bash
# From Codespaces or local machine
./scripts/deploy.sh -e sandbox -p "YourSecurePassword123!"

# Or with subscription ID
./scripts/deploy.sh -e sandbox -p "YourPassword" -s "your-subscription-id"
```

**Parameter File**: `src/configuration/main.sandbox.bicepparam`

---

## 🔧 Dev Environment

### Purpose
**Team development** and **integration testing** in a **production-like** environment with private networking.

### Key Characteristics

**Network Architecture**:
```
┌─────────────────────────────────────────────────────────────┐
│ Azure VNet: 10.0.0.0/16                                     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │ Private Endpoint Subnet (10.0.1.0/24)              │    │
│  │  • PostgreSQL: 10.0.1.4 (private IP only)          │    │
│  │  • Redis: 10.0.1.5 (private IP only)               │    │
│  │  • Storage: 10.0.1.6 (private IP only)             │    │
│  │  • Key Vault: 10.0.1.7 (private IP only)           │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │ App Service Subnet (10.0.2.0/24)                   │    │
│  │  • App Service VNet integration                    │    │
│  │  • Connects to private endpoints                   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Private DNS Zones:                                         │
│   • privatelink.postgres.database.azure.com                 │
│   • privatelink.redis.cache.windows.net                     │
│   • privatelink.blob.core.windows.net                       │
│   • privatelink.vaultcore.azure.net                         │
└─────────────────────────────────────────────────────────────┘
        ↑
        │ Access via VPN or Bastion
        │
   Developer (VPN) or Bastion Jump Box
```

**Security Approach**:
- ✅ **Private endpoints** (no public IPs)
- ✅ **VNet integration** for App Service
- ✅ **Private DNS zones** for name resolution
- ✅ **VPN or Bastion** for developer access
- ✅ **Managed identities** for all services
- ✅ **Azure AD authentication** everywhere
- ✅ **Sanitized production data** (not real prod data)

**Production Alignment**:
- Matches production network architecture
- Tests VNet integration
- Validates private DNS
- Tests App Service → Database connectivity
- Validates security controls

### Resource Specifications

| Resource | SKU/Configuration | Monthly Cost (AUD) |
|----------|-------------------|-------------------|
| **App Service** | P1V3 (2 cores, 8 GB, VNet integration) | ~$160 |
| **PostgreSQL** | GP_Standard_D2ds_v4 (2 vCores, HA enabled) | ~$90 |
| **Redis** | Standard C1 (1 GB, clustering) | ~$65 |
| **Storage** | Standard_GRS (redundant) | ~$10 |
| **Key Vault** | Standard | ~$2 |
| **Application Insights** | Pay-as-you-go | ~$10 |
| **Log Analytics** | Pay-as-you-go | ~$15 |
| **OpenAI** | Standard (dedicated) | ~$0 + usage |
| **Private Endpoints** | 5 endpoints × $11 | ~$55 |
| **Private DNS Zones** | 5 zones × $0.73 | ~$4 |
| **VPN Gateway (optional)** | Basic | ~$29 |
| **TOTAL (without VPN)** | | **~$411/month** |
| **TOTAL (with VPN)** | | **~$440/month** |

### When to Use Dev

✅ **Use Dev When**:
- Team development and collaboration
- Integration testing with other services
- Testing VNet integration
- Validating private endpoint configuration
- Performance testing
- Pre-production validation
- Testing deployment pipelines

❌ **Don't Use Dev For**:
- Personal development (use sandbox)
- Quick experiments (use sandbox)
- Customer-facing workloads (use prod)
- Production data (use sanitized data only)

### Access Methods

**Option 1: Point-to-Site VPN** (~$29/month)
```bash
# Install VPN client certificate
# Connect to Azure VPN
# Access resources via private IPs
psql -h 10.0.1.4 -U psqladmin -d marketingstory
```

**Option 2: Azure Bastion** (~$183/month)
```bash
# Connect to jump box via Bastion in browser
# From jump box, access resources
az postgres flexible-server connect --name psql-marketingstory-dev-aue
```

**Option 3: Site-to-Site VPN** (if office network exists)
```bash
# Office → Azure via VPN Gateway
# Access from any machine in office
```

### Deployment

```bash
# From local machine with VPN or Bastion
./scripts/deploy.sh -e dev -p "YourSecurePassword123!"
```

**Parameter File**: `src/configuration/main.dev.bicepparam`

---

## 🚀 Prod Environment

### Purpose
**Production workload** serving real customers with full security, monitoring, and compliance.

### Key Characteristics

**Network Architecture**:
```
┌─────────────────────────────────────────────────────────────────┐
│ Internet Users                                                  │
│   ↓                                                              │
│ Azure Front Door / Application Gateway (WAF)                    │
│   ↓                                                              │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Azure VNet: 10.1.0.0/16 (Production)                        │ │
│ │                                                              │ │
│ │  ┌────────────────────────────────────────────────────┐    │ │
│ │  │ Private Endpoint Subnet (10.1.1.0/24)              │    │ │
│ │  │  • PostgreSQL: 10.1.1.4 (zone redundant)           │    │ │
│ │  │  • Redis: 10.1.1.5 (cluster mode)                  │    │ │
│ │  │  • Storage: 10.1.1.6 (geo-redundant)               │    │ │
│ │  │  • Key Vault: 10.1.1.7 (premium HSM)               │    │ │
│ │  └────────────────────────────────────────────────────┘    │ │
│ │                                                              │ │
│ │  ┌────────────────────────────────────────────────────┐    │ │
│ │  │ App Service Subnet (10.1.2.0/24)                   │    │ │
│ │  │  • App Service (zone redundant)                    │    │ │
│ │  │  • VNet integration enabled                        │    │ │
│ │  └────────────────────────────────────────────────────┘    │ │
│ │                                                              │ │
│ │  Private DNS Zones + DDoS Protection + NSGs                 │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ Admin Access: Bastion (MFA required) + Privileged Access        │
└─────────────────────────────────────────────────────────────────┘
```

**Security Approach**:
- ✅ **Private endpoints** (mandatory)
- ✅ **WAF** (Application Gateway or Front Door)
- ✅ **DDoS Protection Standard**
- ✅ **Network Security Groups** (NSGs)
- ✅ **Zone redundancy** for HA
- ✅ **Geo-redundant backups**
- ✅ **Azure Defender** enabled
- ✅ **Compliance certifications** (SOC 2, ISO 27001)
- ✅ **MFA required** for all admin access
- ✅ **Privileged Identity Management** (PIM)

### Resource Specifications

| Resource | SKU/Configuration | Monthly Cost (AUD) |
|----------|-------------------|-------------------|
| **App Service** | P1V3 Premium (zone redundant, 3 instances) | ~$480 |
| **PostgreSQL** | GP_Standard_D4ds_v4 (4 vCores, HA, geo-backup) | ~$240 |
| **Redis** | Premium P1 (6 GB, cluster, zone redundant) | ~$580 |
| **Storage** | Premium_GRS (geo-redundant) | ~$50 |
| **Key Vault** | Premium (HSM-backed) | ~$40 |
| **Application Insights** | Enterprise | ~$50 |
| **Log Analytics** | 100 GB/month | ~$300 |
| **OpenAI** | Standard + usage | ~$100+ |
| **Private Endpoints** | 5 endpoints × $11 | ~$55 |
| **Private DNS Zones** | 5 zones × $0.73 | ~$4 |
| **Application Gateway** | WAF V2 | ~$300 |
| **DDoS Protection** | Standard | ~$3,800/month |
| **Azure Bastion** | Standard (for admin access) | ~$183 |
| **TOTAL (without DDoS)** | | **~$2,382/month** |
| **TOTAL (with DDoS)** | | **~$6,182/month** |

**Note**: DDoS Protection Standard is expensive but may be required for compliance. Consider DDoS IP Protection ($20/IP) as alternative.

### When to Use Prod

✅ **Use Prod For**:
- Customer-facing workloads
- Production data
- Revenue-generating applications
- Compliance-required workloads
- 24/7 availability requirements

❌ **Don't Use Prod For**:
- Development (use sandbox)
- Testing (use dev)
- Experiments (use sandbox)
- Learning (use sandbox)

### Deployment

```bash
# Via CI/CD pipeline with approvals (recommended)
# Or manually from secure admin workstation:
./scripts/deploy.sh -e prod -p "ProductionPassword"
```

**Parameter File**: `src/configuration/main.prod.bicepparam`

---

## 🔄 Migration Path

### Phase 1: Sandbox (Week 1)
```
Developer → Deploy sandbox → Test basic functionality → Iterate quickly
```

**Goal**: Validate infrastructure templates, test basic connectivity, develop features.

### Phase 2: Dev (Week 2-4)
```
Team → Deploy dev with private endpoints → Test VNet integration → Validate production-like config
```

**Goal**: Team testing, integration validation, production readiness assessment.

### Phase 3: Prod (Week 5+)
```
Ops Team → Deploy prod with full security → Migrate data → Go live
```

**Goal**: Production launch with full compliance and monitoring.

---

## 🎓 Decision Guide

### "Which environment should I use?"

**Start with this question**: Where is your Azure subscription?

#### Personal Azure Subscription (Visual Studio Credits)
→ **Use Sandbox**
- Cost: ~$64/month (within VS credits)
- Access: GitHub Codespaces or local
- Network: Public endpoints
- Purpose: Personal development

#### Company Azure Subscription
→ **Use Dev** (for development) or **Prod** (for production)
- Cost: Company pays
- Access: VPN or Bastion
- Network: Private endpoints
- Purpose: Team collaboration or production

### "Can I use GitHub Codespaces?"

**Sandbox**: ✅ Yes (recommended)  
**Dev**: ❌ No (private endpoints require VPN/Bastion)  
**Prod**: ❌ No (production access restricted)

### "What if I want to test private endpoints?"

**Option 1**: Deploy dev environment + use VPN/Bastion  
**Option 2**: Deploy sandbox first, then dev later when ready

### "How much will it cost?"

| Subscription Type | Recommended Environment | Cost/Month | Coverage |
|-------------------|------------------------|------------|----------|
| **Personal (VS Enterprise)** | Sandbox | ~$64 | 100% covered by $150 credits |
| **Personal (Pay-as-you-go)** | Sandbox | ~$64 | Pay full amount |
| **Company** | Dev | ~$299 | Company pays |
| **Company** | Prod | ~$500-2,400 | Company pays |

---

## 📋 Summary

| | Sandbox | Dev | Prod |
|---|---------|-----|------|
| **Use Case** | Personal dev | Team dev | Production |
| **Network** | Public | Private | Private + WAF |
| **Cost** | ~$64 | ~$299 | ~$500+ |
| **Codespaces** | ✅ Yes | ❌ No | ❌ No |
| **Access** | Anywhere | VPN/Bastion | Ops only (MFA) |
| **Data** | Test | Sanitized | Production |
| **Deployment** | Manual | CI/CD | CI/CD + approvals |

**Recommendation**: Start with **sandbox** for personal development, then move to **dev** for team collaboration, finally to **prod** for customer-facing workloads.

---

## 🔗 Related Documentation

- [`docs/DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md) - Deployment instructions
- [`docs/CODESPACES_SETUP.md`](CODESPACES_SETUP.md) - GitHub Codespaces setup (for sandbox)
- [`docs/CODESPACES_PRIVATE_ENDPOINTS_CLARIFICATION.md`](CODESPACES_PRIVATE_ENDPOINTS_CLARIFICATION.md) - Why Codespaces can't access private endpoints
- [`docs/CAF_BEST_PRACTICES_EVALUATION.md`](CAF_BEST_PRACTICES_EVALUATION.md) - Azure best practices evaluation
- Parameter files:
  - [`src/configuration/main.sandbox.bicepparam`](../src/configuration/main.sandbox.bicepparam)
  - [`src/configuration/main.dev.bicepparam`](../src/configuration/main.dev.bicepparam)
  - [`src/configuration/main.prod.bicepparam`](../src/configuration/main.prod.bicepparam)
