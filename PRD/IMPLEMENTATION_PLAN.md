# ðŸ Implementation Plan - Zerpai ERP

**Last Updated:** 2026-05-15 13:35:00 IST
**Version:** 1.0 (Lifecycle Aligned)

---

## 1. Project Breakdown & Milestones
- **M1: Foundation:** Core architecture, tenancy, and sync engine.
- **M2: Master Data:** Product management and Price List logic.
- **M3: Retail Core:** POS interface and GST Billing.
- **M4: Supply Chain:** Inter-branch transfers and stock control.

---

## 2. Development Phases
- **Phase 1: Alpha:** Single-branch core flows.
- **Phase 2: Beta:** Multi-tenant/Multi-branch pilot.
- **Phase 3: Production:** Scaled rollout with security/auth enabled.

---

## 3. Sprint Planning (Current)
- **Goal:** Finalize Price List logic and POS Keyboard support.
- **Tasks:**
    - [ ] Price List CRUD API.
    - [ ] Dynamic Rate calculation logic.
    - [ ] POS Shortcut Listener (Flutter).

---

## 4. QA & Testing Plan
- **Unit Tests:** Jest (Backend) and Flutter Test.
- **E2E Tests:** Playwright for critical user journeys.
- **Verification:** Acceptance criteria for every PR.

---

## 5. Deployment Plan
- **CI/CD:** GitHub Actions triggers on push to `main` or `develop`.
- **Hosting:** Railway/Cloudflare Pages (API), Supabase (DB/Auth).
- **Rollback:** Automated version rollback via Railway/Cloudflare Pages deployments.

---

## 6. Risk Management
- **Data Sync:** Mitigation via conflict resolution prompts.
- **Tax Accuracy:** Mitigation via exhaustive calculation unit tests.
- **Infrastructure:** Mitigation via managed Supabase/Railway/Cloudflare Pages scaling.


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
