# Monitoring & Observability PRD
**Last Updated: 2026-04-20 12:46:08**

##      PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.
## ðŸ”’ Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

---

## 1. Monitoring Stack

### Tools
- **Error Tracking:** Sentry (frontend + backend)
- **Performance:** Railway/Cloudflare Pages Analytics  
- **Uptime:** UptimeRobot
- **Logs:** Railway/Cloudflare Pages Logs
- **Business Metrics:** Google Analytics 4

---

## 2. Key Metrics & Thresholds

### Error Metrics

| Metric | Target | Alert Threshold | Action |
|--------|--------|----------------|--------|
| Error Rate | < 0.1% | > 10 errors/min | Slack alert |
| P0 Errors | 0 | Any P0 error | Page on-call |
| Affected Users | < 1% | > 5% users | Investigate immediately |

### Performance Metrics

| Metric | Target (p95) | Alert Threshold | Action |
|--------|--------------|----------------|--------|
| API Response Time | < 500ms | > 1s | Slack #engineering |
| Page Load Time | < 2s | > 3s | Review performance |
| Database Queries | < 200ms | > 1s | Optimize SQL |

### Business Metrics

- **Daily Active Users (DAU)**
- **Invoices Created** per day
- **POS Transactions** per day
- **Revenue Processed**
- **Sync Errors** (offline  †’online)

---

## 3. Health Checks

### Backend Endpoint

**URL:** `GET /api/health`

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-01-20T23:56:00Z",
  "version": "1.0.0",
  "services": {
    "database": "up",
    "redis": "not_configured"
  }
}
```

**Monitoring:** Pinged every 5 minutes by UptimeRobot

---

## 4. Alerting Rules

### Slack Alerts (#engineering)

- Error rate > 10/min
- API p95 > 1s  
- Deploy succeeded/failed
- Database CPU > 80%

### PagerDuty (On-call)

- System down (3+ health check failures)
- P0 error detected
- Data corruption detected

---

## 5. Logging Standards

### Log Format (JSON)

```json
{
  "level": "info",
  "timestamp": "2026-01-20T23:56:00Z",
  "service": "products-api",
  "message": "Product created",
  "context": {
    "entity_id": "uuid-123",
    "user_id": "uuid-456",
    "product_id": "uuid-789",
    "correlation_id": "req-xyz"
  }
}
```

### Log Levels

- **DEBUG:** Development only
- **INFO:** Normal operations
- **WARN:** Unusual but handled
- **ERROR:** Needs attention
- **FATAL:** System-critical

---

## 6. Dashboards

### Sentry (Errors)
- **URL:** `sentry.io/zerpai`
- **View:** Error trends, stack traces, affected users
- **Filters:** By environment, release, error type

### Railway/Cloudflare Pages Analytics (Performance)
- **URL:** `Railway/Cloudflare Pages.com/analytics`
- **Metrics:** Page views, load time, Core Web Vitals
- **Filters:** By page, country, device

### Custom Business Dashboard
- **Tool:** Google Data Studio or Metabase
- **Data:** DAU, revenue, transactions
- **Refresh:** Real-time or hourly

---

## 7. Incident Response

**Severity:** P0 (Critical)   †’ P3 (Low)

**Response Times:**
- P0: Immediate
- P1: < 2 hours
- P2: < 24 hours
- P3: Next sprint

**Runbooks:** `docs/runbooks/`

---

## 8. Performance Optimization

### When to Optimize

- API p95 exceeds 1s consistently
- Page load > 3s
- Database queries > 500ms
- User complaints about slowness

### Optimization Checklist

- [ ] Add database indexes
- [ ] Implement caching (Redis)
- [ ] Optimize N+1 queries
- [ ] Compress images
- [ ] Code splitting (frontend)
- [ ] CDN for static assets

---

## 9. Review Schedule

**Daily:** Check error dashboard (< 5 min)  
**Weekly:** Review performance trends (30 min)  
**Monthly:** Deep dive on metrics, create action items  
**Quarterly:** Review alerting rules, update thresholds

---

**Document Owner:** DevOps Team  
**Next Review Date:** 2026-04-20


---

## Strict Structure + Handoff Merge Governance (2026-05-24)

1. Canonical placement mandatory:
- Business code -> `lib/modules/<domain>/...`
- App infra -> `lib/core/...` or `lib/app/...`
- Cross-domain reusable UI -> `lib/shared/widgets/...`
- Cross-domain services -> `lib/shared/services/...`

2. File/folder creation controls:
- Confirm owner domain before creating files/folders.
- No new legacy roots or ambiguous sink files/folders.
- New `shared/` items require real cross-domain reuse justification.

3. Incoming handoff merge protocol:
- Backup first: `backups/refactor-batches/<timestamp>-<scope>/`.
- Map every inbound file/folder to canonical destination before merge.
- Use compatibility shims for moved active paths until import-zero proof.
- No destructive delete in same batch as move/rewire.

4. Mandatory verification gates:
- Frontend touched -> `dart analyze` touched scope.
- Backend touched -> `npm.cmd run build` in `backend/`.
- Route/deeplink-affecting changes -> route smoke checks.

5. Mandatory audit trail:
- Update root `log.md` with moved files, shim status, verifications, risks.
- Keep handoff backups/handoff folders until explicit approval to delete.

6. Auto-reject merge if any true:
- analyze/build failures,
- unresolved ownership ambiguity,
- schema/DTO drift vs `current schema.md`,
- route regression without safe fallback.
