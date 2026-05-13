# Live Status Page Setup Plan

This plan outlines how to set up a professional, real-time status page to monitor the uptime of Zerpai ERP (Frontend, API, Database, and Cache).

## Proposed Architecture

We will use a decoupled monitoring strategy to ensure the status page itself remains available even if the ERP goes down.

1. **Backend Monitor**: Use the existing `/health` endpoint in NestJS to verify DB and Redis health.
2. **External Dashboard**: BetterStack (Better Uptime) or Uptime Kuma to ingest these health signals and display them.
3. **ERP Integration**: Add a "System Status" link in the Zerpai Admin Settings.

---

## Proposed Changes

### 1. Backend [ALREADY IMPLEMENTED]
The backend already contains a `/health` endpoint at `backend/src/modules/health/health.controller.ts`. 
- **Verifies**: Supabase connectivity, Redis reachable, and environment state.
- **Action**: No code changes needed here, just the URL to monitor.

### 2. Monitoring Setup (Manual Steps)
I recommend **BetterStack** for its professional "Zoho-style" aesthetic and ease of use.

#### **A. Set up Uptime Monitors**
Create three monitors on the chosen platform:
- **ERP Frontend**: Monitor the Vercel production URL (e.g., `https://zerpai-erp-one.vercel.app`).
- **ERP API**: Monitor the backend API health endpoint (e.g., `https://api.zerpai.com/health`).
- **Database**: Monitor the Supabase project endpoint.

#### **B. Configure Status Page**
Create a public or private status page aggregating these monitors.
- **URL**: Suggest `status.zerpai.com` or similar.
- **Components**: Group them into "Frontend", "Systems" (API), and "Database".

### 3. ERP Integration
#### [NEW] [status_page_link.dart](file:///e:/zerpai-new/lib/modules/settings/shared/status_page_link.dart)
Create a reusable status link or card for the Settings overview.

#### [MODIFY] [settings_page.dart](file:///e:/zerpai-new/lib/modules/settings/presentation/settings_page.dart)
Add a "System Health" button that opens the live status page in a new tab.

---

## Open Questions

> [!IMPORTANT]
> 1. **Public vs Private**: Do you want this status page to be viewable by all users, or only by Organization Admins?
> 2. **Provider Preference**: Are you okay with using **BetterStack** (managed, zero maintenance, free tier) or would you prefer a self-hosted **Uptime Kuma** (requires a Docker container/VPS)?
> 3. **Notification Channels**: Where should uptime alerts go? (Slack, WhatsApp, Email, or SMS).

---

## Verification Plan

### Automated Checks
- `curl https://<api-url>/health` to ensure the health endpoint returns `{"status": "ok"}`.
- Verify the Status Page reflects "Up" when the services are running.

### Manual Verification
- Manually trigger a "down" state (e.g., by stopping the backend dev server) and verify the status page updates within 1-3 minutes.
- Verify the link within Zerpai ERP opens the correct status dashboard.
