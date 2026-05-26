# 🗄️ Backend Schema Document - Zerpai ERP

**Last Updated:** 2026-05-15 13:30:00 IST
**Version:** 1.0 (Lifecycle Aligned)

---

## 1. Database Overview
- **Type:** PostgreSQL (Supabase) + Drizzle ORM.
- **Tenancy:** Single-database multi-tenant via `entity_id` scoping.
- **Migration:** Drizzle-kit generated SQL migrations.

---

## 2. Table Groups & Purpose

### 2.1 Tenancy & Core
- `organisation_branch_master`: Unified polymorphic entity registry.
- `organization` / `branches`: Profile details for tenants.

### 2.2 Inventory & Items
- `products`: Global item definitions.
- `batch_master`: Batch/Expiry tracking.
- `branch_inventory`: Warehouse-specific stock levels.

### 2.3 Sales & Purchasing
- `customers` / `vendors`: Entity profiles.
- `sales_orders` / `invoices`: Transaction headers.
- `purchase_orders` / `bills`: Procurement headers.

---

## 3. Relationships & Constraints
- **Multi-Tenancy:** `entity_id` is a mandatory FK on all business tables.
- **Primary Keys:** UUID (v4) for all tables.
- **Integrity:** 3NF normalization; FK constraints enforced at DB level.

---

## 4. Enums & Statuses
- **Transaction States:** `Draft`, `Confirmed`, `Invoiced`, `Partially Paid`, `Paid`.
- **User Roles:** `Admin`, `Manager`, `Staff`.
- **Account Groups:** `Assets`, `Liabilities`, `Equity`, `Income`, `Expenses`.

---

## 5. Audit & Metadata Fields
- `created_at` / `updated_at`: Mandatory timestamps.
- `created_by_id` / `updated_by_id`: Actor tracking.
- `is_deleted`: Soft-delete flag (where applicable).

---

## 6. Audit Logging Strategy
- `audit_logs` table records all INSERT/UPDATE/DELETE actions.
- Stores `old_values` and `new_values` as JSONB for detailed history.

---

## 7. Performance & Optimization
- **Indexes:** B-tree indexes on `entity_id` and all frequently searched columns (SKU, Phone).
- **Partitioning:** (Planned V2) for massive audit log tables.

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
