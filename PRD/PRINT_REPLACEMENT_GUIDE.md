# Print Statement Replacement Guide

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.
## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

## Files to Fix

### 1. lib/modules/items/repositories/products_repository.dart (5 prints)
- Line 37: `print('⚠️ API fetch failed, using cached products: $e');`
  → `AppLogger.warning('API fetch failed, using cached products', error: e, module: 'products');`

- Line 68: `print('⚠️ Failed to fetch product $id: $e');`
  → `AppLogger.warning('Failed to fetch product', error: e, module: 'products', data: {'productId': id});`

- Line 90: `print('❌ Failed to create product: $e');`
  → `AppLogger.error('Failed to create product', error: e, module: 'products');`

- Line 114: `print('❌ Failed to update product $id: $e');`
  → `AppLogger.error('Failed to update product', error: e, module: 'products', data: {'productId': id});`

- Line 130: `print('❌ Failed to delete product $id: $e');`
  → `AppLogger.error('Failed to delete product', error: e, module: 'products', data: {'productId': id});`

### 2. lib/modules/items/services/products_api_service.dart (4 prints)
- Line 84: Debug payload
- Line 94-95: Error responses
- Line 117-118: Error responses  
- Line 168: Error fetching

### 3. lib/modules/items/services/lookups_api_service.dart (18 prints)
- Lines 13-26: Units API logging
- Lines 34-46: Sync units logging
- Lines 64, 84: Error logging
- Lines 92-103: Categories logging
- Lines 329-342: Generic sync logging

### 4. lib/modules/items/controller/items_controller.dart (3 prints)
- Lines 394, 396, 400: Sync units logging
- Line 411: Check unit usage error
- Line 568: Reorder point error

### 5. lib/modules/items/presentation/ files (5 prints)
- items_items_item_creation.dart: Lines 3112, 3429, 3433
- items_items_item_detail.dart: Line 237
- column_visibility_manager.dart: Lines 46, 59

### 6. lib/shared/widgets/inputs/manage_simple_list_dialog.dart (1 print)
- Line 88: Live sync error

## Total: ~40 print statements to replace

## Recommendation
Replace all with AppLogger calls following the pattern:
- Debug info → `AppLogger.debug()`
- Warnings → `AppLogger.warning()`
- Errors → `AppLogger.error()`
- Always include `module` parameter
- Include relevant `data` for context

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
