# Deployment & Release Management Guide

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.
## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

---

## 1. Overview

This document defines the deployment pipeline, release process, and versioning strategy for Zerpai ERP. It ensures consistent, reliable deployments with minimal downtime.

---

##2. CI/CD Pipeline Architecture

### 2.1 GitHub Actions Workflows

**Pipeline Stages:**

```
Pull Request → dev branch:
  ├─ Format Check
  ├─ Linting
  ├─ Unit Tests
  ├─ Build Verification
  ├─ Security Scan
  └─ Code Coverage Report

Merge to dev:
  ├─ Deploy to Vercel Staging
  ├─ Integration Tests
  └─ Smoke Tests

Merge to main:
  ├─ Create Git Tag
  ├─ Generate Release Notes
  ├─ Run Migrations (manual approval)
  ├─ Deploy to Vercel Production
  ├─ Health Checks
  └─ Monitor (2 hours)
```

### 2.2 CI Configuration Files

**Frontend (Flutter):**
```yaml
# .github/workflows/flutter-ci.yml
name: Flutter CI

on:
  pull_request:
    branches: [dev, main]
  push:
    branches: [dev, main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Format Check
        run: dart format --set-exit-if-changed .
      
      - name: Analyze
        run: flutter analyze
      
      - name: Run Tests
        run: flutter test --coverage
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
      
      - name: Build
        run: flutter build web --release
```

**Backend (NestJS):**
```yaml
# .github/workflows/nest-ci.yml
name: NestJS CI

on:
  pull_request:
    branches: [dev, main]
  push:
    branches: [dev, main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install Dependencies
        run: npm ci
      
      - name: Format Check
        run: npm run format:check
      
      - name: Lint
        run: npm run lint
      
      - name: Run Tests
        run: npm run test:cov
      
      - name: Security Audit
        run: npm audit --audit-level=moderate
      
      - name: Build
        run: npm run build
```

---

## 3. Deployment Environments

### 3.1 Development (Local)

**Purpose:** Individual developer machines

**Configuration:**
- `.env.local` with local Supabase instance
- Hot reload enabled
- Debug logging
- Mock data

**Access:** Localhost only

### 3.2 Staging (Vercel Preview)

**Purpose:** Pre-production testing

**URL:** `https://zerpai-staging.vercel.app`

**Configuration:**
- Separate Supabase staging database
- Production-like data (anonymized)
- Vercel Analytics enabled
- Sentry (test mode)

**Deployment Trigger:** Auto-deploy on merge to `dev`

**Access:** Internal team + selected beta users

### 3.3 Production (Vercel)

**Purpose:** Live user-facing application

**URL:** `https://app.zerpai.com`

**Configuration:**
- Production Supabase database
- Vercel Analytics (full)
- Sentry (production mode)
- All security measures enabled

**Deployment Trigger:** Manual merge to `main` (requires approval)

**Access:** All registered users

---

## 4. Versioning Strategy

### 4.1 Semantic Versioning

**Format:** `MAJOR.MINOR.PATCH`

**Rules:**
- **MAJOR** (e.g., 1.0.0 → 2.0.0): Breaking API changes, major architectural rewrites
- **MINOR** (e.g., 1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (e.g., 1.0.0 → 1.0.1): Bug fixes, small improvements

**Examples:**
- `v1.0.0` - Initial production release
- `v1.1.0` - Added barcode scanner feature
- `v1.1.1` - Fixed invoice calculation bug
- `v2.0.0` - Migrated to new authentication system (breaking change)

### 4.2 Version Tagging

**Git Tags:**
```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial production release"

# Push tag to remote
git push origin v1.0.0
```

**Automatic Tagging (via CI):**
```yaml
# .github/workflows/release.yml
- name: Create Tag
  if: github.ref == 'refs/heads/main'
  run: |
    VERSION=$(node -p "require('./package.json').version")
    git tag -a "v$VERSION" -m "Release v$VERSION"
    git push origin "v$VERSION"
```

### 4.3 Release Cadence

| Type | Frequency | Day/Time | Notes |
|------|-----------|----------|-------|
| **Patch** | As needed | Any day, off-peak hours | Critical bugs only |
| **Minor** | Every 2 weeks | Friday, 10 AM IST | Regular feature releases |
| **Major** | Quarterly | First Friday of quarter | Breaking changes |

---

## 5. Release Process (Step-by-Step)

### 5.1 Pre-Release Checklist

**1 Week Before Release:**
- [ ] All features for release merged to `dev`
- [ ] All tests passing in staging
- [ ] Release notes draft prepared
- [ ] Database migrations reviewed (if any)
- [ ] Stakeholders notified of release date

**1 Day Before Release:**
- [ ] Code freeze on `dev` branch
- [ ] Final QA testing in staging
- [ ] Backup production database
- [ ] Rollback procedure documented

**Release Day (Morning):**
- [ ] Team standup: review release plan
- [ ] Confirm all checks passed
- [ ] Schedule deployment window (e.g., 10 AM - 12 PM IST)

### 5.2 Deployment Steps

**Step 1: Create Release Branch**
```bash
git checkout dev
git pull origin dev
git checkout -b release/v1.1.0
```

**Step 2: Update Version Numbers**
```bash
# Update package.json (backend)
npm version 1.1.0 --no-git-tag-version

# Update pubspec.yaml (frontend)
# Manually edit version: 1.1.0+2 (version+build)
```

**Step 3: Generate Release Notes**
```bash
# Using conventional-changelog
npx conventional-changelog -p angular -i CHANGELOG.md -s

# Manual additions:
# - Highlight major features
# - Link to documentation
# - Known issues
```

**Step 4: Create Pull Request to Main**
```markdown
Title: Release v1.1.0

Description:
## What's New
- Feature A: Description
- Feature B: Description

## Bug Fixes
- Fixed issue #123
- Fixed issue #456

## Breaking Changes
- None

## Deployment Notes
- Database migration required: `001_add_barcode_column.sql`
- Estimated downtime: 5 minutes
```

**Step 5: Review & Approve**
- Minimum 2 approvals required
- DevOps lead must approve
- All CI checks must pass

**Step 6: Merge to Main**
```bash
git checkout main
git merge release/v1.1.0 --no-ff
git push origin main
```

**Step 7: Run Database Migrations (if needed)**
```bash
# SSH into Vercel/Supabase or use migration tool
npm run migration:run

# Verify migration success
npm run migration:status
```

**Step 8: Deploy to Production**
- Vercel auto-deploys on push to `main`
- Monitor deployment logs
- Wait for "Deployment Ready" status

**Step 9: Post-Deployment Verification**
```bash
# Health check
curl https://app.zerpai.com/api/health

# Smoke tests (automated)
npm run test:smoke:production

# Manual checks:
# - Login works
# - Create invoice works
# - POS works
# - Reports generate
```

**Step 10: Monitor (2 Hours)**
- Watch Sentry for error spikes
- Check Vercel Analytics for traffic
- Monitor user reports in support channel

**Step 11: Post-Release**
- Tag release in Git
- Publish release notes to users
- Update documentation site
- Post in company Slack #announcements

### 5.3 Post-Release Checklist

- [ ] All health checks passed
- [ ] No error spikes in Sentry (< 5 errors in 2 hours)
- [ ] User-facing release notes published
- [ ] Internal team notified
- [ ] Deployment marked as "successful" in tracking sheet
- [ ] Post-mortem scheduled if issues occurred

---

## 6. Rollback Procedures

### 6.1 When to Rollback

**Immediate Rollback Triggers:**
- Error rate > 20 errors/min
- Critical feature completely broken
- Data corruption detected
- Security vulnerability introduced

**Probationary Period:** Monitor for 2 hours post-deployment

### 6.2 Application Rollback (Vercel)

**Via Vercel Dashboard:**
1. Go to Deployments
2. Find previous stable deployment
3. Click "..." menu → "Promote to Production"
4. Confirm promotion

**Estimated Time:** 2-5 minutes

**Via Vercel CLI:**
```bash
# List recent deployments
verceldeployments list --prod

# Rollback to specific deployment
vercel rollback [DEPLOYMENT_URL]
```

### 6.3 Database Migration Rollback

**Prerequisites:**
- Every migration MUST have a rollback script
- Rollback tested in staging before production

**Execute Rollback:**
```bash
# Run rollback migration
npm run migration:rollback

# Verify rollback success
npm run migration:status

# Check data integrity
npm run db:integrity-check
```

**Manual Verification:**
```sql
-- Check affected tables
SELECT COUNT(*) FROM affected_table;

-- Verify foreign keys intact
SELECT constraint_name, table_name
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY';
```

### 6.4 Post-Rollback Actions

1. **Notify users** (if downtime occurred)
2. **Create incident report**
3. **Schedule post-mortem** (within 48 hours)
4. **Fix root cause** before next release attempt
5. **Update deployment checklist** to prevent recurrence

---

## 7. Hotfix Process

**Definition:** Urgent bug fix that can't wait for next release

**Severity:** P0 or P1 only

### 7.1 Hotfix Workflow

```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/fix-critical-bug

# 2. Implement fix
# ... make changes ...

# 3. Test locally
npm run test

# 4. Create PR to main (skip dev)
# - Label: "hotfix"
# - Requires DevOps approval

# 5. Merge to main
git checkout main
git merge hotfix/fix-critical-bug
git push origin main

# 6. Deploy (auto via Vercel)

# 7. Backport to dev
git checkout dev
git merge hotfix/fix-critical-bug
git push origin dev

# 8. Bump version (patch)
# v1.1.0 → v1.1.1
```

### 7.2 Hotfix Versioning

- Always a PATCH version bump
- `v1.1.0` → `v1.1.1`
- Tag immediately after merge

### 7.3 Hotfix Communication

**Template:**
```markdown
**Hotfix Deployed: v1.1.1**

**Issue:** [Brief description of bug]
**Impact:** [Who/what was affected]
**Fix:** [What was changed]
**Deployed:** [Timestamp]
**Status:** Resolved

No user action required.
```

---

## 8. Monitoring Post-Deployment

### 8.1 Key Metrics to Watch

**First 15 Minutes:**
- Error rate (should be < 5 errors)
- Health check endpoint (should return 200)
- Deployment logs (check for warnings)

**First 2 Hours:**
- Unique users (should match usual traffic)
- Average response time (should be < normal + 20%)
- Database query performance

**First 24 Hours:**
- User-reported bugs (support tickets)
- Feature adoption (new features being used?)

### 8.2 Monitoring Tools

| Metric | Tool | Dashboard |
|--------|------|-----------|
| Errors | Sentry | sentry.io/zerpai |
| Performance | Vercel Analytics | vercel.com/analytics |
| Uptime | UptimeRobot | uptimerobot.com/dashboard |
| Logs | Vercel Logs | vercel.com/logs |

### 8.3 Alerting

**Slack Alerts (#deployments channel):**
- Deployment started
- Deployment successful
- Error spike detected
- Health check failed

**Email Alerts (DevOps team):**
- P0 incident
- Deployment failed

**PagerDuty (On-call engineer):**
- System down (health check 3+ failures)
- Error rate > 50/min

---

## 9. Release Notes Template

```markdown
# Release v1.1.0 - January 20, 2026

## 🎉 What's New

### Barcode Scanner Integration
- Scan products directly into POS
- Supports USB and Bluetooth scanners
- [Learn more](https://docs.zerpai.com/barcode-scanner)

### Low Stock Alerts
- Get notified when products hit reorder point
- Dashboard widget shows all low-stock items
- [Learn more](https://docs.zerpai.com/low-stock)

## 🐛 Bug Fixes
- Fixed invoice tax calculation for inter-state transactions (#234)
- Resolved POS crash when offline (#245)
- Improved report generation performance for large datasets (#256)

## 🔧 Improvements
- Faster product search (50% reduction in response time)
- Mobile-responsive invoice creation screen
- Better error messages for failed API calls

## ⚠️ Breaking Changes
None

## 📊 Performance
- Average page load: 1.8s (↓ from 2.1s)
- API p95 latency: 450ms (↓ from 520ms)

## 📚 Documentation
- [Barcode Scanner Guide](https://docs.zerpai.com/barcode)
- [Migration Guide](https://docs.zerpai.com/migration) (if applicable)

## 🙏 Thank You
Thanks to all contributors and users who reported bugs!

---

**Full Changelog**: https://github.com/zerpai/erp/compare/v1.0.0...v1.1.0
```

---

## 10. Deployment Checklist (Quick Reference)

**Pre-Deployment:**
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Migration tested in staging
- [ ] Rollback documented
- [ ] Release notes prepared
- [ ] Team notified

**Deployment:**
- [ ] Backup created
- [ ] Merge to main
- [ ] Migrations run (if needed)
- [ ] Vercel deployment succeeded
- [ ] Health checks passed

**Post-Deployment:**
- [ ] No error spikes (2 hours)
- [ ] Release notes published
- [ ] Documentation updated
- [ ] Team/users notified

---

## 11. Troubleshooting Common Issues

### Issue: CI Build Failing

**Symptoms:** PR can't merge, build errors

**Solutions:**
1. Check GitHub Actions logs
2. Run locally: `flutter build web` or `npm run build`
3. Check for dependency conflicts: `flutter pub get` or `npm install`

### Issue: Migration Fails in Production

**Symptoms:** Deployment succeeds, but app errors on database operations

**Solutions:**
1. Check migration logs in Vercel
2. Manually inspect database schema
3. Rollback migration: `npm run migration:rollback`
4. Fix migration script and redeploy

### Issue: Vercel Deployment Stuck

**Symptoms:** Deployment in "Building" state for > 10 minutes

**Solutions:**
1. Check Vercel status: https://www.vercel-status.com
2. Cancel deployment, try again
3. If persistent, contact Vercel support

---

## 12. Review & Updates

**This document must be reviewed:**
- After every major release (v1.0, v2.0, etc.)
- When CI/CD pipeline changes
- Quarterly with engineering team

**Version History:**
| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-20 | Initial version | Engineering Team |

---

**Document Owner:** Engineering Lead  
**Next Review Date:** 2026-04-20
