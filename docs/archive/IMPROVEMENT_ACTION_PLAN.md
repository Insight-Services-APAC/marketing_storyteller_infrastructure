# Infrastructure Improvement Action Plan

Based on the CAF Best Practices Evaluation, here's a prioritized action plan.

## 🔴 **Phase 1: Critical Security Fixes (Week 1)**

### Action 1.1: Move Secrets to Key Vault
**Priority:** CRITICAL  
**Effort:** 4-6 hours  
**Impact:** High security improvement

**Implementation:**
1. Create secrets module to populate Key Vault
2. Update App Service to use Key Vault references
3. Remove direct secret exposure from main template

**Files to Modify:**
- `src/modules/keyvault-secrets.bicep` (new)
- `src/orchestration/main.bicep`
- `src/configuration/*.bicepparam`

### Action 1.2: Add Diagnostic Settings
**Priority:** CRITICAL  
**Effort:** 2-3 hours  
**Impact:** Compliance, audit trail, troubleshooting

**Implementation:**
1. Add diagnostic settings to each module
2. Connect to Log Analytics workspace

**Files to Modify:**
- All module files in `src/modules/`

### Action 1.3: Implement Resource Locks
**Priority:** CRITICAL  
**Effort:** 1 hour  
**Impact:** Prevent accidental deletion

**Implementation:**
1. Add lock to production resource group

**Files to Modify:**
- `src/orchestration/main.bicep`

---

## 🟡 **Phase 2: Production Readiness (Week 2-3)**

### Action 2.1: Network Isolation
**Priority:** HIGH  
**Effort:** 8-12 hours  
**Impact:** Security, compliance

**Implementation:**
1. Create VNet module
2. Add VNet integration to App Service
3. Add service endpoints for data services
4. (Optional) Private endpoints for production

**Files to Create:**
- `src/modules/networking.bicep`
- `src/modules/private-endpoint.bicep`

**Files to Modify:**
- `src/orchestration/main.bicep`
- All service modules

### Action 2.2: High Availability for PostgreSQL
**Priority:** HIGH  
**Effort:** 2 hours  
**Impact:** Reliability

**Implementation:**
1. Enable zone-redundant HA for production
2. Enable geo-redundant backup
3. Increase backup retention

**Files to Modify:**
- `src/modules/postgresql.bicep`
- `src/orchestration/main.bicep` (envConfig)

### Action 2.3: Monitoring & Alerts
**Priority:** HIGH  
**Effort:** 4-6 hours  
**Impact:** Operational excellence

**Implementation:**
1. Create alerts module
2. Create action group for notifications
3. Define key metrics to monitor

**Files to Create:**
- `src/modules/alerts.bicep`
- `src/modules/action-group.bicep`

---

## 🟢 **Phase 3: Optimization (Week 4+)**

### Action 3.1: Auto-Scaling
**Priority:** MEDIUM  
**Effort:** 2-3 hours  
**Impact:** Cost optimization

**Implementation:**
1. Add auto-scale settings to App Service Plan
2. Define scale rules based on CPU/memory

**Files to Modify:**
- `src/modules/app-service.bicep`

### Action 3.2: Storage Lifecycle Management
**Priority:** MEDIUM  
**Effort:** 2 hours  
**Impact:** Cost savings

**Implementation:**
1. Add lifecycle policies to storage
2. Auto-tier old documents to cool/archive

**Files to Modify:**
- `src/modules/storage.bicep`

### Action 3.3: Deployment Slots
**Priority:** MEDIUM  
**Effort:** 3-4 hours  
**Impact:** Zero-downtime deployments

**Implementation:**
1. Add staging slot to production App Service
2. Update deployment process for slot swaps

**Files to Modify:**
- `src/modules/app-service.bicep`
- Deployment scripts

---

## Implementation Checklist

### Week 1: Critical Fixes
- [ ] **Day 1-2:** Move secrets to Key Vault
  - [ ] Create keyvault-secrets module
  - [ ] Update main template
  - [ ] Test deployment
  - [ ] Update documentation
  
- [ ] **Day 3:** Add diagnostic settings
  - [ ] Update all modules
  - [ ] Test logging flow
  
- [ ] **Day 4:** Add resource locks
  - [ ] Implement locks for production
  - [ ] Test protection
  
- [ ] **Day 5:** Testing & validation
  - [ ] Full deployment test (dev)
  - [ ] Full deployment test (prod)
  - [ ] Security scan

### Week 2-3: Production Readiness
- [ ] **Week 2:** Network isolation
  - [ ] Create VNet module
  - [ ] Add VNet integration
  - [ ] Test connectivity
  - [ ] Add service endpoints
  
- [ ] **Week 2:** PostgreSQL HA
  - [ ] Update module for HA
  - [ ] Test failover
  
- [ ] **Week 3:** Monitoring & alerts
  - [ ] Create alerts module
  - [ ] Define alert rules
  - [ ] Test notifications
  - [ ] Create runbooks

### Week 4: Optimization
- [ ] Auto-scaling configuration
- [ ] Storage lifecycle policies
- [ ] Deployment slots setup
- [ ] Final testing & documentation

---

## Quick Wins (Can be done today)

1. **Enhanced tagging** (30 mins)
   - Add CAF-recommended tags
   
2. **Update backup retention** (15 mins)
   - Increase prod backup to 35 days
   
3. **Enable geo-backup** (15 mins)
   - Turn on for production PostgreSQL

4. **Documentation updates** (1 hour)
   - Document security improvements
   - Update deployment guide

---

## Success Metrics

### Security
- ✅ Zero secrets in environment variables
- ✅ 100% resources with diagnostic logging
- ✅ All production resources locked

### Reliability
- ✅ 99.9% uptime SLA met
- ✅ Zero data loss in DR scenarios
- ✅ < 1 minute RTO for App Service

### Operations
- ✅ All critical alerts configured
- ✅ < 5 minute MTTA (Mean Time To Acknowledge)
- ✅ Zero-downtime deployments

### Cost
- ✅ Auto-scaling saves 20%+ on compute
- ✅ Storage lifecycle saves 20%+ on storage
- ✅ Right-sized resources (no over-provisioning)

---

## Resource Requirements

### Team
- Infrastructure Engineer: 40 hours
- Security Reviewer: 4 hours
- Application Developer: 8 hours (testing)

### Budget
- No additional Azure costs for Phase 1
- Phase 2: +$50-100/month (HA, geo-backup)
- Phase 3: Potential savings of $50-100/month

### Timeline
- Phase 1: 1 week
- Phase 2: 2 weeks
- Phase 3: 1 week
- **Total: 4 weeks for complete implementation**

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Downtime during migration | Deploy to dev first, use deployment slots |
| Breaking changes | Comprehensive testing, rollback plan |
| Cost overruns | Monitor daily, set budget alerts |
| Skill gaps | Training, documentation, pair programming |
| Timeline delays | Buffer time, prioritize critical items |

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Get approval** for timeline and budget
3. **Create work items** in project tracking system
4. **Assign resources** to each phase
5. **Begin Phase 1** immediately

---

## Questions for Decision

1. **Network Isolation:** Do we need private endpoints or just VNet integration?
2. **Monitoring:** What are acceptable thresholds for alerts?
3. **Backup:** What's the required RPO/RTO for the application?
4. **Budget:** Is the $50-100/month increase for HA acceptable?
5. **Timeline:** Can we dedicate resources for 4 weeks?

---

**Prepared by:** Infrastructure Team  
**Date:** November 10, 2025  
**Review Date:** November 17, 2025
