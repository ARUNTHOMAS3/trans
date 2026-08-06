# ðŸš   Implementation Plan & Roadmap - Zerpai ERP

**Last Updated:** 2026-05-15 13:15:00 IST
**Version:** 2.1 (Lifecycle Aligned)

---

## 1. Project Breakdown & Milestones

| Milestone | Deliverable | Targeted Date |
| :--- | :--- | :--- |
| **M1: Foundation** | Unified Tenancy + Hive Sync Engine | June 15, 2026 |
| **M2: Items & Pricing** | Price List Module + Volume Pricing | July 10, 2026 |
| **M3: Retail Core** | High-Speed POS Interface + GST Billing | August 05, 2026 |
| **M4: Supply Chain** | Inter-branch Transfer Order Workflows | August 25, 2026 |
| **M5: Compliance** | GSTR-1 Automated Export + Audit Logs | September 15, 2026 |
| **M6: Beta Launch** | Multi-branch testing with pilot clients | October 01, 2026 |

---

## 2. Development Phases

### Phase 1: Foundation (Completed/Ongoing)
- [x] Unified Entity Tenancy Migration (`entity_id`).
- [x] Backend Standard Response Interceptor.
- [x] Flutter GoRouter & Riverpod Setup.
- [x] Hive Caching Engine.
- [ ] Automated Background Sync Engine (Offline-to-Online).

### Phase 2: Master Data & Price Lists
- [x] Global Product Master (HO Managed).
- [x] Branch Inventory Overrides.
- [ ] **Price List Module**:
    - [ ] CRUD for Price Lists.
    - [ ] Volume Range Logic.
    - [ ] Branch-specific overrides.
- [x] Customer & Vendor Profiles.

### Phase 3: Sales & POS (High Priority)
- [x] Sales Order & Invoice CRUD.
- [ ] **POS High-Speed Mode**:
    - [ ] Keyboard shortcuts integration.
    - [ ] Barcode scanning support.
    - [ ] Quick-pay (Cash/Card/UPI) flow.
- [x] Delivery Challans.

### Phase 4: Procurement & Stock Control
- [x] Purchase Orders & Bills.
- [x] Purchase Receives (Stock Inward).
- [x] Transfer Orders (Inter-branch).
- [x] Inventory Adjustments.

---

## 3. Sprint Planning & Task Breakdown

### Current Sprint: POS Optimization & Pricing
- **Frontend Tasks:**
    - Implement Keyboard Shortcut Listener for POS.
    - Integrate `FormDropdown` with barcode scanner input.
    - Build Price List selector in Sales Order form.
- **Backend Tasks:**
    - Create Price List CRUD endpoints.
    - Implement pricing hierarchy logic (Priority: Branch > Customer > Global).
- **QA Tasks:**
    - Verify tax calculation accuracy for multi-item invoices.
    - Test Hive synchronization under simulated 3G/Offline conditions.

---

## 4. QA & Testing Strategy
- **Unit Testing:** 80% coverage goal for backend business logic.
- **Integration Testing:** API endpoint verification with test databases.
- **E2E Testing:** Playwright for critical Sales and Inventory browser-based flows.
- **User Acceptance (UAT):** Guided walkthroughs with shop owners for POS usability.

---

## 5. Risk Management

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| **Data Sync Conflict** | High | Implement "Last Write Wins" with user override prompts. |
| **Performance Lag** | Medium | Use `Isolate` for heavy Hive operations; optimize DB indexes. |
| **GST Logic Error** | High | Unit tests for every tax calculation permutation (IGST/CGST/SGST). |
| **API Failure** | Medium | Robust Dio retry interceptors and Hive-fallback. |

---

## 6. Release & Deployment Strategy
1. **Internal Alpha**: Feature-complete Sales and Inventory modules.
2. **Staging (Railway/Cloudflare Pages)**: Continuous deployment for internal stakeholder review.
3. **Beta (Selected Clients)**: Testing multi-branch operations in live retail environments.
4. **Production Release (V1.0)**: Global rollout with Auth and RLS enabled.


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
