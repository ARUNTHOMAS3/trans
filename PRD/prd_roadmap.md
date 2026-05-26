# Roadmap & Release Strategy
**Last Updated: 2026-04-20 12:46:08**

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.

## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

---

## 1. Release Timeline (2026)

| Phase | Duration | Scope | Status |
| ----- | -------- | ----- | ------ |
| Phase 1: MVP | Jan - March | Foundation, Items, Sales, Purchases, Accountant | ✅ Completed |
| Phase 2: Scale | April - June | Inventory, Reports, Bulk Ops, Audit Logs | 🏃 In Progress |
| Phase 3: Optimize | July - Sept | Performance, AI Insights, Advanced Filtering | 📅 Planned |
| Phase 4: Expansion | Oct - Dec | Mobile App, Multi-Org Hub, API Ecosystem | 📅 Planned |

---

## 2. Phase 1: MVP (Foundation) - ✅ COMPLETED

**Goal:** Establish the core ERP functionality for a single organization.

**Deliverables:**
- ✅ Core App Shell & Navigation
- ✅ Items (Services, Products, Batches)
- ✅ Sales (Invoices, Credit Notes, Payments)
- ✅ Purchases (Orders, Bills, Receipts)
- ✅ Accounts Management (Chart of Accounts)
- ✅ Reports (Sales, Inventory, GST)
- ✅ Multi-Branch Support (HO, COCO, FOFO)

**Key Features:**

1.  **Item Master**
    - GST classification (HSN/SAC)
    - Pricing (Retail vs Wholesale)
    - Dynamic search and filtering
2.  **Sales Workflow**
    - Standard Invoicing
    - GST calculation engine
    - Basic payment tracking
3.  **Accountant Tools**
    - Manual journals
    - Opening balances

---

## 3. Phase 2: Scale (Performance & Advanced Features) - 🏃 IN PROGRESS

**Goal:** Optimize workflows for high-density usage and add inventory depth.

**Priority Features:**

- [ ] **Advanced Inventory Tracking**
  - Assemblies & Bills of Materials (BOM)
  - Serialized stock tracking
  - Batch/Expiry management enhancements
- [ ] **Low Stock Alerts Dashboard**
  - Email/SMS notifications
  - Dashboard widget
- [ ] **Stock Transfer Between Branches**
  - Transfer request workflow
  - Track in-transit inventory
- [ ] **Bulk Operations 2.0**
  - Mass price updates
  - Bulk stock adjustments from CSV
- [ ] **Audit Logs Dashboard**
  - User activity stream
  - Record history (who changed what and when)

**Performance Targets:**

| Metric | Target | Notes |
| ------------------ | ------------ | ----------------------------- |
| Products | 50,000 | < 25,000 for best performance |
| Concurrent Users | 100 | < 50 typical |
| Branches | Unlimited | < 50 for best UX |
| Transactions/Month | 10,000+ | Varies |

**Exceeding Limits?** Contact for enterprise plan with dedicated infrastructure.

---

## 4. Phase 3: Optimize (AI & Insights) - 📅 PLANNED

**Goal:** Move from "Tracking Data" to "Generating Insights".

**Planned Features:**

- [ ] **AI Inventory Prediction**
  - Predict stock-outs based on seasonal trends
  - Suggested reorder quantities
- [ ] **Automated Bank Reconciliation**
  - OCR for bank statements
  - Auto-matching with invoice payments
- [ ] **Intelligent Search (Omni-Box)**
  - Natural language queries ("Show me top 10 items in Manjeri branch")
  - Quick actions from search bar
- [ ] **Custom Report Builder**
  - Drag-and-drop report columns
  - Save custom filters as private/shared views

---

## 5. Phase 4: Expansion (Ecosystem) - 📅 PLANNED

**Goal:** Mobilize the workforce and open up integration.

**Planned Features:**

- [ ] **Zerpai Mobile App (iOS/Android)**
  - Barcode scanning with camera
  - Quick sales on the go
  - Warehouse status checks
- [ ] **Multi-Organization Hub**
  - Manage multiple distinct businesses from one login
  - Shared masters across organizations
- [ ] **Public API / Developer Portal**
  - Integrate with Shopify/Amazon/Woocommerce
  - Webhooks for order events
- [ ] **Advanced POS Offline Mode**
  - Full local database sync
  - Support for unstable internet connections

---

## 6. Feedback & Iteration Cycle

We follow a 2-week sprint cycle for Phase 2 and Phase 3:
1.  **Build:** Develop features based on prioritized PRD.
2.  **Verify:** Internal QA + Lighthouse/Performance audit.
3.  **Review:** User test with Sahakar team.
4.  **Refine:** Bug fixes and small UX tweaks based on feedback.

---

## Appendix: Version History

| Version | Release Date | Code Name | Key Features |
| ------- | ------------ | --------------- | ----------------------------- |
| v1.0.0 | Jan 2026 | "Foundation" | Initial release, Core modules |
| v1.1.0 | Feb 2026 | "Compliance" | GST Enhancements, Reports |
| v1.2.0 | March 2026 | "Precision" | Advanced Batch/Expiry |
| v2.0.0 | April 2026 | "Velocity" | Parallel processing, Bulk Ops |

---

**Document Owner:** Product Team
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
