# Core Pages Extraction Map (Step 1 Baseline)

Date: 2026-05-22
Status: Planning map created. No `core/pages` file moved yet.

## Objective
Move `lib/core/pages/*` into module-owned or app-shell-owned locations while preserving:
- route paths
n- route names
- current behavior
- temporary compatibility via export shims

## Root Principles
1. `core/pages` must be retired.
2. Settings/business pages move to `lib/modules/settings/**`.
3. Non-business error/system pages move to `lib/app/pages/**` (or `core/system_pages/**`).
4. During migration, keep old `core/pages/*` files as `export` shims until all imports are cut over.

## Current Core Pages Inventory
- error_page.dart
- maintenance_page.dart
- not_found_page.dart
- unauthorized_page.dart
- settings_page.dart
- settings_organization_profile_page.dart
- settings_organization_branding_page.dart
- settings_branch_profile_page.dart
- settings_branches_list_page.dart
- settings_branches_create_page.dart
- settings_branding_page.dart
- settings_locations_page.dart
- settings_locations_create_page.dart
- settings_warehouses_list_page.dart
- settings_warehouses_create_page.dart
- settings_zones_page.dart
- settings_zones_create_page.dart
- settings_zone_bins_page.dart
- settings_roles_page.dart
- settings_user_location_access_editor.dart
- settings_users_roles_support.dart

## Current Import Dependents (must be rewired)
- `lib/core/routing/app_router.dart`
- `lib/modules/settings/users/presentation/pages/settings_users_user_creation.dart`
- `lib/modules/settings/users/presentation/pages/settings_users_user_overview.dart`
- `lib/modules/settings/users/providers/user_access_provider.dart`
- `lib/modules/settings/users_roles/presentation/pages/settings_users_roles_role_creation.dart`
- `lib/core/pages/settings_roles_page.dart`
- `lib/core/pages/settings_user_location_access_editor.dart`

## Proposed Targets

### A. App-level system pages
- `core/pages/error_page.dart` -> `app/pages/error_page.dart`
- `core/pages/maintenance_page.dart` -> `app/pages/maintenance_page.dart`
- `core/pages/not_found_page.dart` -> `app/pages/not_found_page.dart`
- `core/pages/unauthorized_page.dart` -> `app/pages/unauthorized_page.dart`

### B. Settings module pages
- `core/pages/settings_page.dart` -> `modules/settings/presentation/pages/settings_page.dart`
- `core/pages/settings_organization_profile_page.dart` -> `modules/settings/organization/presentation/pages/settings_organization_profile_page.dart`
- `core/pages/settings_organization_branding_page.dart` -> `modules/settings/branding/presentation/pages/settings_organization_branding_page.dart`
- `core/pages/settings_branch_profile_page.dart` -> `modules/settings/organization/presentation/pages/settings_branch_profile_page.dart`
- `core/pages/settings_branches_list_page.dart` -> `modules/settings/organization/presentation/pages/settings_branches_list_page.dart`
- `core/pages/settings_branches_create_page.dart` -> `modules/settings/organization/presentation/pages/settings_branches_create_page.dart`
- `core/pages/settings_branding_page.dart` -> `modules/settings/branding/presentation/pages/settings_branding_page.dart`
- `core/pages/settings_locations_page.dart` -> `modules/settings/organization/presentation/pages/settings_locations_page.dart`
- `core/pages/settings_locations_create_page.dart` -> `modules/settings/organization/presentation/pages/settings_locations_create_page.dart`
- `core/pages/settings_warehouses_list_page.dart` -> `modules/settings/organization/presentation/pages/settings_warehouses_list_page.dart`
- `core/pages/settings_warehouses_create_page.dart` -> `modules/settings/organization/presentation/pages/settings_warehouses_create_page.dart`
- `core/pages/settings_zones_page.dart` -> `modules/settings/organization/presentation/pages/settings_zones_page.dart`
- `core/pages/settings_zones_create_page.dart` -> `modules/settings/organization/presentation/pages/settings_zones_create_page.dart`
- `core/pages/settings_zone_bins_page.dart` -> `modules/settings/organization/presentation/pages/settings_zone_bins_page.dart`
- `core/pages/settings_roles_page.dart` -> `modules/settings/users_roles/presentation/pages/settings_roles_page.dart`
- `core/pages/settings_user_location_access_editor.dart` -> `modules/settings/users/presentation/pages/settings_user_location_access_editor.dart`
- `core/pages/settings_users_roles_support.dart` -> `modules/settings/users_roles/presentation/support/settings_users_roles_support.dart`

## Execution Sequence (Step 2)
1. Create target folders/files for one group at a time.
2. Move files into target paths.
3. Replace old `core/pages/*` files with export shims.
4. Rewire imports in dependents.
5. Verify with:
   - `dart analyze lib/core/routing/app_router.dart lib/modules/settings lib/app`
6. Append `log.md` entry.

## Risk Notes
- Highest risk: `settings_users_roles_support.dart` used by multiple settings screens/providers.
- Moderate risk: `app_router.dart` import rewiring.
- Low risk: system pages (error/not_found/maintenance/unauthorized).
