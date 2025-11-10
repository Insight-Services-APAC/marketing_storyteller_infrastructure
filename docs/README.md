# Documentation Index

**Last Updated**: November 10, 2025

## 📚 Documentation Structure

### 🚀 Setup Guides (`docs/setup/`)

**Start here for initial setup and onboarding:**

| Document | Purpose | Audience |
|----------|---------|----------|
| **[ENVIRONMENT_STRATEGY.md](setup/ENVIRONMENT_STRATEGY.md)** | **START HERE** - Complete guide to sandbox/dev/prod environments | All users |
| **[QUICK_START_DECISION.md](setup/QUICK_START_DECISION.md)** | Decision tree: Which environment/approach to use? | All users |
| **[DEPLOYMENT_GUIDE.md](setup/DEPLOYMENT_GUIDE.md)** | Step-by-step deployment instructions | Developers |
| **[CODESPACES_SETUP.md](setup/CODESPACES_SETUP.md)** | GitHub Codespaces setup for sandbox development | Developers using Codespaces |
| **[ENTERPRISE_CODESPACES_FAQ.md](setup/ENTERPRISE_CODESPACES_FAQ.md)** | Enterprise + Personal Azure subscription FAQ | Enterprise developers |
| **[CODESPACES_PRIVATE_ENDPOINTS_CLARIFICATION.md](setup/CODESPACES_PRIVATE_ENDPOINTS_CLARIFICATION.md)** | Why Codespaces can't access private endpoints | Technical reference |
| **[USING_EXISTING_OPENAI.md](setup/USING_EXISTING_OPENAI.md)** | How to reuse existing Azure OpenAI services | All users |

### 🔧 Operations (`docs/operations/`)

**Ongoing operations, maintenance, and best practices:**

| Document | Purpose | Audience |
|----------|---------|----------|
| **[DEPLOYMENT_CHECKLIST.md](operations/DEPLOYMENT_CHECKLIST.md)** | Pre/post deployment checklist | Ops team |
| **[CAF_BEST_PRACTICES_EVALUATION.md](operations/CAF_BEST_PRACTICES_EVALUATION.md)** | Cloud Adoption Framework compliance evaluation | Architects, compliance |

### 📖 Quick Reference (root)

**Quick command reference:**

| Document | Purpose |
|----------|---------|
| **[QUICK_REFERENCE.md](../QUICK_REFERENCE.md)** | Common commands for sandbox/dev/prod |

### 📦 Archive (`docs/archive/`)

**Historical/reference documents (not actively maintained):**

- Implementation summaries
- Improvement plans (completed)
- Template references
- Historical setup guides

---

## 🎯 Quick Start Paths

### Personal Development (Visual Studio Credits)

```
1. Read: ENVIRONMENT_STRATEGY.md
2. Read: QUICK_START_DECISION.md
3. Setup: CODESPACES_SETUP.md
3. Deploy: DEPLOYMENT_GUIDE.md (sandbox)
4. Reference: ../QUICK_REFERENCE.md
```

### Team Development (Company Subscription)

```
1. Read: ENVIRONMENT_STRATEGY.md
2. Read: DEPLOYMENT_GUIDE.md
3. Check: DEPLOYMENT_CHECKLIST.md
4. Deploy: dev or prod environment
5. Reference: ../QUICK_REFERENCE.md
```

### Architecture Review

```
1. Read: ENVIRONMENT_STRATEGY.md
2. Review: CAF_BEST_PRACTICES_EVALUATION.md
3. Check: Parameter files in src/configuration/
```

---

## 📂 File Organization

```
docs/
├── setup/                          # Setup and onboarding guides
│   ├── ENVIRONMENT_STRATEGY.md     # ⭐ START HERE
│   ├── QUICK_START_DECISION.md     # Decision tree
│   ├── DEPLOYMENT_GUIDE.md         # Deployment steps
│   ├── CODESPACES_SETUP.md         # Codespaces setup
│   ├── ENTERPRISE_CODESPACES_FAQ.md
│   ├── CODESPACES_PRIVATE_ENDPOINTS_CLARIFICATION.md
│   └── USING_EXISTING_OPENAI.md
│
├── operations/                     # Operational guides
│   ├── DEPLOYMENT_CHECKLIST.md     # Deployment checklist
│   └── CAF_BEST_PRACTICES_EVALUATION.md
│
├── README.md                       # This file (documentation index)
│
└── archive/                        # Historical documents
    ├── README.md
    ├── 3-TIER_IMPLEMENTATION_SUMMARY.md
    ├── CODESPACES_IMPLEMENTATION_SUMMARY.md
    ├── IMPROVEMENT_ACTION_PLAN.md
    ├── IMPROVEMENTS_COMPLETED.md
    └── [other historical docs]

../QUICK_REFERENCE.md               # Quick commands (at root level)
```

---

## 🔍 Find What You Need

### "I want to deploy for the first time"
→ Start: [ENVIRONMENT_STRATEGY.md](setup/ENVIRONMENT_STRATEGY.md)  
→ Then: [DEPLOYMENT_GUIDE.md](setup/DEPLOYMENT_GUIDE.md)

### "I want to use GitHub Codespaces"
→ Start: [CODESPACES_SETUP.md](setup/CODESPACES_SETUP.md)  
→ FAQ: [ENTERPRISE_CODESPACES_FAQ.md](setup/ENTERPRISE_CODESPACES_FAQ.md)

### "Which environment should I use?"
→ Start: [QUICK_START_DECISION.md](setup/QUICK_START_DECISION.md)  
→ Details: [ENVIRONMENT_STRATEGY.md](setup/ENVIRONMENT_STRATEGY.md)

### "I want to reuse an existing OpenAI service"
→ Guide: [USING_EXISTING_OPENAI.md](setup/USING_EXISTING_OPENAI.md)

### "I need deployment commands"
→ Quick: [../QUICK_REFERENCE.md](../QUICK_REFERENCE.md)  
→ Detailed: [DEPLOYMENT_GUIDE.md](setup/DEPLOYMENT_GUIDE.md)

### "I need to validate before production"
→ Checklist: [DEPLOYMENT_CHECKLIST.md](operations/DEPLOYMENT_CHECKLIST.md)  
→ Best Practices: [CAF_BEST_PRACTICES_EVALUATION.md](operations/CAF_BEST_PRACTICES_EVALUATION.md)

---

## 📝 Documentation Maintenance

### Active Documents (Keep Updated)

**Setup Guides** (`docs/setup/`):
- Update when infrastructure changes
- Update when new environments added
- Review quarterly for accuracy

**Operations** (`docs/operations/`):
- Update checklist with lessons learned
- Review CAF evaluation annually
- Add new operational procedures as needed

**Quick Reference** (`docs/QUICK_REFERENCE.md`):
- Update when commands change
- Keep synchronized with scripts

### Archive Policy

Move to `docs/archive/` when:
- ✅ Document is historical/reference only
- ✅ Content is superseded by newer docs
- ✅ Implementation is complete (e.g., improvement plans)
- ✅ Template/example no longer in active use

**Do not delete** - keep for historical reference.

---

## 🔗 External Links

- **Application Repository**: [marketing_storyteller](https://github.com/Insight-Services-APAC/marketing_storyteller)
- **CAF Template Source**: [APAC-DIA-LandingZones-Platform-Deployment-Tier1](https://github.com/Insight-Services-APAC/APAC-DIA-LandingZones-Platform-Deployment-Tier1)
- **Azure Documentation**: [docs.microsoft.com/azure](https://docs.microsoft.com/azure)
- **GitHub Codespaces**: [docs.github.com/codespaces](https://docs.github.com/codespaces)

---

## ✨ Summary

| Folder | Purpose | Maintenance |
|--------|---------|-------------|
| **setup/** | Getting started, onboarding | Update with changes |
| **operations/** | Ongoing operations | Update with lessons learned |
| **archive/** | Historical reference | Read-only |
| **root (../)** | Quick reference | Keep current |

**Start here**: [docs/setup/ENVIRONMENT_STRATEGY.md](setup/ENVIRONMENT_STRATEGY.md) 🚀
