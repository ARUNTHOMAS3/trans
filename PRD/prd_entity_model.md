# Unified Polymorphic Entity Tenancy Model
**Last Updated: 2026-04-20 12:46:08**

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.

## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-03-30
**Last Edited Version:** 2.1

---

## 1. Overview

Zerpai ERP uses a **Unified Polymorphic Entity Tenancy** model. This means that instead of having dedicated columns for `organization_id` or `branch_id` across every business table, we use a single scoping column: `entity_id`.

The `organisation_branch_master` table acts as the registry, containing the `type` discriminator (`'ORG'` or `'BRANCH'`) and the `ref_id` pointing to the actual profile record (`organization` or `branches`).

This single column **replaces** the legacy dual-column pattern `org_id + branch_id`.
> **Legacy Note:** Most tables still contain an `org_id` column for backward compatibility, but it carries a default value of `'00000000-0000-0000-0000-000000000000'` and must NOT be used for active query filtering.

---

## 2. Core Schema

### 2.1 Entity Master (`organisation_branch_master`)
The central registry for all tenant entities.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid (PK) | The canonical `entity_id` used in business tables. |
| `type` | text | `'ORG'` or `'BRANCH'`. |
| `ref_id` | uuid | Foreign key to the profile table (`organization.id` or `branches.id`). |
| `status` | text | `'ACTIVE'`, `'SUSPENDED'`, `'INACTIVE'`. |

### 2.2 Organization Profile (`organization`)
Profile data specific to the main organization (Head Office).

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid (PK) | Internal profile ID. |
| `name` | varchar | Legal business name. |
| `gstin` | varchar | GST registration number. |
| `pan` | varchar | PAN number. |

### 2.3 Branch Profile (`branches`)
Profile data specific to a child branch (FOFO/COCO).

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid (PK) | Internal profile ID. |
| `org_id` | uuid | Link back to the parent organization profile. |
| `name` | varchar | Branch trade name. |
| `branch_code` | varchar | Unique short code for the branch. |

---

## 3. Implementation Patterns

### 3.1 Scoping Query Filter
All business tables MUST be filtered by `entity_id`.

**Backend (NestJS/Drizzle):**
```typescript
const result = await db.select()
  .from(products)
  .where(eq(products.entityId, auth.entityId));
```

**Frontend (Flutter/State):**
```dart
final currentEntityId = ref.watch(authProvider).entityId;
```

### 3.2 Polymorphic Relationship
When identifying which entity owns a record, the check is simple:

1. Look up the `entity_id` in `organisation_branch_master`.
2. Check the `type`.
3. If `type == 'ORG'`, the record belongs to the Head Office.
4. If `type == 'BRANCH'`, the record belongs to a specific branch.

---

## 4. Key Benefits

1. **Flat Scalability**: Adding new entity types (e.g., Franchises, Warehouses) doesn't require schema changes across business tables.
2. **Simplified Indexing**: Every business table uses the same single-column index for tenancy.
3. **Audit Trail Consistency**: Audit logs track `entity_id`, providing a unified view across the entire organization hierarchy.

---

## 5. Migration Strategy (Legacy Deprecation)

| Old Column Pattern | New Column Pattern | Notes |
|-------------------|-------------------|-------|
| `org_id` (uuid) | ❌ Deprecated / Zero-filled | Still exists in Drizzle/Postgres but NOT used for logic |
| `branch_id` (uuid) | ❌ Removed | Replaced by `entity_id` |
| — | `entity_id` uuid NOT NULL | The single canonical scoping column |

---

## 6. PRD References & Overrides

This document overrides any legacy tenancy patterns found in older PRD sections.

| Section | Override Rule |
|---------|---------------|
| **Section 1.2** — Development Philosophy (Auth-Free Dev Stage) | The `org_id` hardcoding in 1.2 is superseded by `entity_id` in production. The architecture remains "Auth-Ready" but now uses entity context. |
| **Section 1.1** — Product Vision (HO → FOFO → COCO) | The entity hierarchy described here IS the FOFO/COCO model. `entity_type = 'ORG'` = HO. `entity_type = 'BRANCH'` = FOFO or COCO branch. |
| **Section 14** — UI/UX Spec (Organization Switcher) | The "Organization Switcher" described in §14.12.20 maps to entity switching in the entity model (switching between HO and branch contexts). |
| **Appendix: Database Schema** | The schema appendix in PRD.md shows old `org_id + branch_id` columns. Refer to this document for the updated column convention. |

---

*Rahul + Antigravity (Architecture Session)*
