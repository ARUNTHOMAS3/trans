# Disaster Recovery & Business Continuity Plan

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.
## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

---

## 1. Overview

This document outlines the disaster recovery and business continuity procedures for Zerpai ERP. It ensures that in the event of a system failure, data loss, or security breach, the system can be restored with minimal downtime and data loss.

---

## 2. Backup Strategy

### 2.1 Database Backups (Supabase)

**Automated Backups:**
- **Frequency:** Daily automated backups
- **Retention:** 
  - Free tier: 7 days
  - Paid tier: 30+ days
- **Type:** Full database snapshots

**Point-in-Time Recovery (PITR):**
- **Enabled:** Production database only
- **Window:** Last 7 days
- **Use Case:** Recover from accidental deletes, bad migrations

**Manual Backups:**
- **When:** Before major migrations or releases
- **How:** Via Supabase Dashboard → Database → Backups → Create Backup
- **Naming:** `manual_backup_YYYYMMDD_v1.x.x_pre_migration`

**Backup Testing:**
- **Frequency:** Monthly
- **Process:**
  1. Restore latest backup to separate test database
  2. Verify data integrity
  3. Test application connectivity
  4. Document any issues
- **Responsibility:** DevOps team

### 2.2 Code & Configuration Backups

**Git Repository (GitHub):**
- **Primary Protection:** All code version-controlled
- **Branches Protected:** `main` and `dev` require PR reviews
- **Backup:** GitHub provides automatic redundancy

**Environment Variables:**
- **Documentation:** All variables documented in `.env.example`
- **Secure Backup:** 
  - Production secrets stored in AWS Secrets Manager or 1Password Team Vault
  - Weekly export of secrets (encrypted) to secure storage
- **Access Control:** Limited to DevOps lead and CTO only

**Infrastructure as Code:**
- **Vercel Configuration:** `vercel.json` files in repo
- **Future:** Terraform/Pulumi scripts for complete infrastructure recreation

### 2.3 Application Data Backups

**User-Uploaded Files (Cloudflare R2):**
- **Images:** Product images, logos
- **Documents:** Invoice PDFs (future), receipts
- **Backup:** Cloudflare R2 provides 99.999999999% durability
- **Additional Safety:** Weekly sync to AWS S3 Glacier (cold storage)

---

## 3. Recovery Objectives

### 3.1 Metrics

| Metric | Target | Worst-Case Acceptable |
|--------|--------|----------------------|
| **RTO** (Recovery Time Objective) | < 4 hours | 8 hours |
| **RPO** (Recovery Point Objective) | < 24 hours | 48 hours |
| **Critical Data RPO** (Transactions) | < 1 hour | 6 hours |

### 3.2 Critical vs Non-Critical Systems

**Critical (Must Restore First):**
1. Database (Supabase)
2. Backend API (Vercel)
3. Frontend Web App (Vercel)
4. Authentication (Supabase Auth)

**Non-Critical (Can Restore Later):**
1. Analytics dashboards
2. Marketing website
3. Documentation site
4. Email marketing tools

---

## 4. Incident Response Plan

### 4.1 Severity Levels

| Level | Description | Examples | Response Time |
|-------|-------------|----------|---------------|
| **P0** | Critical | System down, data loss, security breach | Immediate (all hands) |
| **P1** | High | Major feature broken, significant user impact | < 2 hours |
| **P2** | Medium | Minor feature broken, workaround available | < 24 hours |
| **P3** | Low | Cosmetic issues, feature requests | Next sprint |

### 4.2 Incident Response Workflow

**Step 1: Detection**
- Monitoring alerts (Sentry, Vercel, Uptime)
- User reports via support
- Internal discovery

**Step 2: Assessment**
- Assign severity level
- Identify impacted users/features
- Estimate resolution time

**Step 3: Communication**
```markdown
**Internal:** 
- Post in #incidents Slack channel
- Page on-call engineer (P0/P1)
- Notify leadership (P0)

**External (if user-facing):**
- Status page update: https://status.zerpai.com
- In-app banner: "We're experiencing issues..."
- Email to affected users (P0 only)
```

**Step 4: Mitigation**
- Implement immediate fix or workaround
- Rollback if recent deployment caused issue
- Enable maintenance mode if needed

**Step 5: Resolution**
- Deploy permanent fix
- Verify fix in production
- Monitor for 2 hours post-fix

**Step 6: Post-Mortem**
- Create incident report within 48 hours
- Identify root cause
- Document prevention steps
- Share learnings with team

### 4.3 Incident Runbooks

**Location:** `docs/runbooks/`

**Required Runbooks:**
- `runbook_database_failure.md`
- `runbook_vercel_deployment_rollback.md`
- `runbook_security_breach.md`
- `runbook_data_corruption.md`
- `runbook_supabase_auth_down.md`

**Runbook Template:**
```markdown
# Runbook: [Incident Type]

## Symptoms
- What the user sees
- Error messages
- Monitoring alerts

## Diagnosis Steps
1. Check X
2. Verify Y
3. Inspect Z

## Resolution Steps
1. Do A
2. Execute B
3. Verify C

## Escalation
- If not resolved in X minutes: Page [Person/Team]
- Fallback contact: [Phone/Email]
```

---

## 5. Disaster Scenarios & Recovery Procedures

### 5.1 Scenario: Complete Database Loss

**Probability:** Low (Supabase has multiple safeguards)  
**Impact:** Critical

**Recovery Procedure:**

1. **Immediate Actions (0-15 min):**
   - Activate incident response
   - Enable maintenance mode on frontend
   - Notify all users via status page

2. **Restore from Backup (15 min - 2 hours):**
   ```bash
   # Via Supabase Dashboard
   1. Database > Backups
   2. Select most recent backup
   3. Click "Restore"
   4. Confirm restoration
   ```

3. **Verification (2-3 hours):**
   - Check database connectivity
   - Verify data integrity (row counts, sample queries)
   - Test critical workflows (dashboard load, invoice creation, POS)

4. **Go Live (3-4 hours):**
   - Disable maintenance mode
   - Monitor error rates
   - Communicate resolution to users

**Data Loss:** Up to 24 hours (daily backups)  
**Mitigation:** Enable PITR for production (reduces to < 1 hour loss)

### 5.2 Scenario: Vercel Outage

**Probability:** Low-Medium (Vercel has 99.99% SLA)  
**Impact:** Critical (app unavailable)

**Recovery Procedure:**

**If Vercel is completely down (rare):**
1. **Wait for Vercel status updates:** https://www.vercel-status.com
2. **No action needed:** Vercel handles infrastructure recovery
3. **Estimated RTO:** 1-2 hours (Vercel SLA)

**If specific deployment is broken:**
1. **Rollback to previous version:**
   ```bash
   # Via Vercel Dashboard
   Deployments > [Select Previous] > Promote to Production
   ```
2. **Estimated RTO:** 5-10 minutes

**Failover Plan (Future):**
- Maintain backup deployment on AWS/Azure
- Use DNS failover to redirect traffic
- Requires multi-cloud setup (not in v1.0)

### 5.3 Scenario: Security Breach (Unauthorized Access)

**Probability:** Medium (depends on security posture)  
**Impact:** Critical

**Recovery Procedure:**

1. **Immediate Actions (0-5 min):**
   - Revoke all API keys and JWT tokens
   - Disable affected user accounts
   - Enable maintenance mode

2. **Investigation (5 min - 2 hours):**
   - Review audit logs (who, what, when)
   - Identify compromised data
   - Determine attack vector

3. **Containment (2-4 hours):**
   - Patch security vulnerability
   - Rotate all secrets (database passwords, API keys)
   - Force password reset for all affected users

4. **Notification (4-6 hours):**
   - Notify affected users via email
   - Report to authorities if legally required (data breach laws)
   - Public statement if widespread

5. **Recovery (6-24 hours):**
   - Restore from pre-breach backup if data corrupted
   - Implement additional security measures
   - Conduct thorough security audit

### 5.4 Scenario: Accidental Data Deletion

**Probability:** Medium (human error)  
**Impact:** High

**Recovery Procedure:**

**If detected immediately (< 1 hour):**
1. Use Point-in-Time Recovery (PITR):
   ```sql
   -- Restore to timestamp before deletion
   SELECT * FROM products WHERE deleted_at IS NULL;
   ```

**If detected after 1 hour:**
1. Restore affected table from last night's backup
2. Merge with current data (careful of conflicts)
3. Verify restored data

**Prevention:**
- Implement soft deletes for critical tables
- Require confirmation dialogs for bulk deletes
- Limit DELETE permissions in production

---

## 6. Data Retention & Archival

### 6.1 Active Data Retention

**Transactional Data:**
- Keep in primary database indefinitely
- No automatic deletion

**User-Generated Content:**
- Images: Stored in Cloudflare R2, no expiration
- Logs: Retained for 90 days, then archived

### 6.2 Archival Policy

**Trigger:** Data older than 3 years (optional, for very large orgs)

**Process:**
1. Identify old records (last updated > 3 years ago)
2. Export to cold storage (AWS S3 Glacier)
3. Mark as "archived" in primary database (soft delete)
4. Keep metadata for search (date, org, customer)

**Retrieval:** 
- User can request archived data
- Retrieval SLA: 24-48 hours

### 6.3 Legal & Compliance Retention

**GST Records (India):**
- **Minimum:** 7 years from end of fiscal year
- **Storage:** Must remain accessible for audit
- **Deletion:** CANNOT delete before 7 years

**User Data Deletion Requests:**
- Honor within 30 days (GDPR-style)
- Verify identity before deletion
- Retain only what's legally required (e.g., tax records)

---

## 7. Testing & Validation

### 7.1 Disaster Recovery Drills

**Frequency:** Quarterly

**Types:**
1. **Tabletop Exercise:** Team walks through scenario without executing
2. **Partial Drill:** Restore backup to test environment
3. **Full Drill:** Complete production failover (once/year, during low traffic)

###7.2 Backup Integrity Testing

**Monthly:**
- Restore most recent backup to test database
- Run automated integrity checks
- Document success/failure

**Automated Checks:**
```sql
-- Verify row counts
SELECT 'products', COUNT(*) FROM products UNION ALL
SELECT 'customers', COUNT(*) FROM customers UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices;

-- Check for corruption
SELECT tablename, pg_size_pretty(pg_total_relation_size(tablename::regclass))
FROM pg_tables
WHERE schemaname = 'public';
```

---

## 8. Contacts & Escalation

### 8.1 Emergency Contacts

| Role | Name | Phone | Email | Availability |
|------|------|-------|-------|--------------|
| **On-Call Engineer** | [Rotating] | [Number] | oncall@zerpai.com | 24/7 |
| **DevOps Lead** | [Name] | [Number] | devops@zerpai.com | Business hours |
| **CTO** | [Name] | [Number] | cto@zerpai.com | Escalations only |

### 8.2 Vendor Support

| Vendor | Support Contact | SLA | Escalation |
|--------|----------------|-----|------------|
| **Supabase** | support@supabase.io | 4 hours (paid tier) | Via dashboard |
| **Vercel** | vercel.com/support | 1 hour (Enterprise) | Via dashboard |
| **Cloudflare** | enterprise@cloudflare.com | 1 hour | Phone support |

---

## 9. Review & Updates

**This document must be reviewed:**
- Quarterly by DevOps team
- After every P0 incident
- When infrastructure changes (new services added)

**Version History:**
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-20 | Initial version | DevOps Team |

---

**Document Owner:** DevOps/Infrastructure Team  
**Next Review Date:** 2026-04-20
