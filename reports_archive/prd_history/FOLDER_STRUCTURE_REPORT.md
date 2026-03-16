# Folder Structure Standardization Report

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.
## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

## 🎯 Objective
Align folder structure to **PRD.md**:
- Sidebar modules: Home, Items, Inventory, Sales, Purchases, Reports, Documents
- File naming: `module_submodule_page.dart`
- Shared widgets in `lib/core/widgets/`
- GoRouter in `lib/core/routing/app_router.dart`

```
lib/modules/[module_name]/
├── controller/
├── models/
├── presentation/
├── repositories/  <-- Standardized
└── services/      <-- Standardized
```

## 🛠 Actions Taken (Historical)

### 1. Fixed `items` Module
- **Action:** Migrated legacy `repo/` directory to `repositories/`.
- **Files Moved:**
  - `items_repository.dart`
  - `item_repository_provider.dart`
  - `supabase_item_repository.dart`
- **Updates:** Updated `ItemsController` to import from new location.
- **Cleanup:** Deleted `repo/` directory.

### 2. Standardized All Modules
This report originally claimed full standardization, but the current repo **does not fully match PRD.md**. The module list and structure need verification against the actual layout.

## ⚠️ Current Gaps (as of now)
- **Missing PRD sidebar modules:** `home/`, `documents/`
- **Extra non-sidebar modules present:** `auth/`, `branches/`, `mapping/`, `settings/`
- **Items sub-modules exist**, but other modules are not consistently nested per PRD structure
- **Shared widgets** still need to be centralized under `lib/core/widgets/` (per PRD.md)

## ✅ Next Step
Re-audit the current repo and update this report with verified module-by-module status.
