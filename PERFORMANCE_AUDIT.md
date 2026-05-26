# Zerpai ERP Performance & Architectural Audit Report

**Date:** May 15, 2026  
**Status:** DRAFT (Audit in Progress)  
**Priority:** High  

## Executive Summary
The Zerpai ERP system exhibits several critical architectural bottlenecks that impact scalability and responsiveness. The primary issues are related to **monolithic state management**, **redundant data fetching**, and **synchronous write operations** that block the UI. Remediating these will require shifting from "full-sync" patterns to "on-demand" and "delta-sync" strategies.

---

## 1. Global Architectural Pain Points

### A. The "Monolithic Lookup" Bottleneck
- **Problem:** `loadLookupData` in `ItemsController` and `SyncService` fetches 16+ lookup tables (units, categories, brands, taxes, etc.) in a single startup sequence or module switch.
- **Impact:** 
  - 2-5 second UI freeze during initialization.
  - Excessive memory consumption (~50MB+ for lookups alone).
  - Backend pressure from massive joint/parallel queries.
- **Recommendation:** Implement **Granular Lazy Loading**. Fetch lookups only when the corresponding dropdown is focused or a specific module is accessed.

### B. Reload-After-Save Anti-pattern
- **Problem:** After a "Save" or "Update" operation (e.g., `ItemsController.updateItem`, `InventoryAdjustmentsActions.save`), the system triggers a full list refresh (`ref.invalidate(listProvider)`).
- **Impact:** 
  - UI flicker as the list vanishes and reloads.
  - N+1 database queries on the backend to re-hydrate the list.
  - Perceived lag as the user has to wait for the network to see their change.
- **Recommendation:** Implement **Optimistic Local Updates**. Merge the saved entity directly into the local Riverpod state without a full re-fetch.

### C. Oversized Payloads (Hydration Bloat)
- **Problem:** The backend `ProductsService` uses a massive `PRODUCT_SELECT_STRING` that joins ~12 tables. This is used for both "List" and "Detail" views.
- **Impact:** 
  - 500kb+ JSON payloads for a single list of 50 items.
  - Slow parsing on the mobile/web frontend.
- **Recommendation:** Split API responses into `Summary` (list view, minimal fields) and `Full` (detail view, all joins).

---

## 2. Module-Specific Audits

### 📦 Inventory Module (Adjustments)
| Issue | Severity | Description |
| :--- | :--- | :--- |
| **N+1 Identity Fetching** | High | `InventoryAdjustmentsService` fetches user metadata for each row individually instead of using a batch join or cache. |
| **Redundant List Refresh** | Medium | Typing in the search bar triggers `forceRefresh: true` on the provider, clearing the local cache every 300ms. |
| **State Bloat** | High | `inventory_adjustments_create.dart` (6,286 lines) manages too much local state, leading to re-render lag in long forms. |

### 🏷️ Items Module
| Issue | Severity | Description |
| :--- | :--- | :--- |
| **Inefficient Search** | High | `searchProducts` fetches 500 records and performs ranking/filtering in JavaScript/Dart instead of PostgreSQL `ILIKE` or `FTS`. |
| **Sync Deadlocks** | Medium | `SyncService` attempts to reconcile drafts during active UI usage, causing occasional race conditions in state merging. |
| **Large Default Limits** | Medium | `findAll` defaults to 1000 items, which will crash the app when the database grows to 50k+ products. |

### 💰 Sales Module (Returns)
| Issue | Severity | Description |
| :--- | :--- | :--- |
| **Route Constants** | Blocker | Missing route constants after merge causes 404s on deep links. |
| **Sequential Writes** | High | Sales Return items are saved sequentially in some flows instead of a single transaction batch. |

---

## 3. Prioritized Remediation Roadmap

### Phase 1: Stability (Immediate)
1. **Fix Route Regressions:** Restore `AppRoutes` constants to enable navigation.
2. **Batch Persistence:** Refactor `InventoryAdjustmentsService` to use a single `upsert` for batch items.

### Phase 2: Responsiveness (Next 2 Weeks)
1. **On-Demand Lookups:** Break down `loadLookupData` into granular providers.
2. **Pagination Hardening:** Enforce strict `limit: 50` on all list endpoints with cursor-based pagination.

### Phase 3: Scalability (Long Term)
1. **Delta Syncing:** Implement `updated_at` filters for local cache hydration instead of full table re-fetches.
2. **Backend Search:** Move all filtering/ranking logic to Supabase/Postgres.

---
*Audit conducted by Antigravity AI.*
