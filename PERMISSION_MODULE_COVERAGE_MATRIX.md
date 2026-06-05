# Permission Module Coverage Matrix

Last Updated: 2026-05-30
Owner: Codex + Zerpai Team

## Coverage Summary

- Role matrix legacy keys discovered: `53`
- Legacy keys mapped to canonical prefixes: `54`
- Missing legacy mappings: `0`
- Extra mapping keys (beyond role matrix): `1` (`recurring_journals`)
- Canonical permission definitions in registry: `190`

## Legacy Key Mapping Status

All role-matrix keys in
`lib/modules/settings/users_roles/providers/role_permission_scheme.dart`
are mapped in:
`lib/core/auth/permission_registry.dart` via
`legacyPermissionPrefixesByKey`.

Mapped domains:
- Items + Pricing
- Inventory
- Sales
- Purchases
- Accounts + Accountant
- Settings + Compliance
- Reports + Shell (dashboard/documents/audit logs)

## Runtime Permission Check Status

Runtime permission checks now flow through capability service in:
- Route guard level (`lib/app/routing/app_router.dart`)
- Shared wrappers (`lib/modules/auth/widgets/permission_wrapper.dart`)
- Sidebar/settings/nav gating
- Module-level action gating (accounts/items/purchases/settings touched paths)

No direct `PermissionService.hasModuleAction(...)` usage remains in:
- `lib/app`
- `lib/modules`

## Canonical Format Status

Canonical format frozen and implemented:
- `module.resource.action`

Examples:
- `sales.invoice.view`
- `inventory.transfer.approve`
- `settings.roles.edit`
- `reports.audit_log.view`

## Residual Gaps (Non-blocking)

- Navigation metadata (`app/navigation/*`) still stores legacy-style module keys
  for action-agnostic sidebar wiring; runtime permission engine still resolves
  correctly via central mapping.
- Registry can be further expanded for deeper report-category granularity if
  you want per-report permissions split beyond `reports.center.*`.

## Verification Commands

```powershell
rg -n "PermissionService\.hasModuleAction\(" lib/app lib/modules
flutter test test/core/auth/permission_resolver_test.dart test/core/auth/capability_service_test.dart
dart analyze lib/core/auth/permission_registry.dart lib/core/auth/permission_resolver.dart lib/core/auth/capability_service.dart test/core/auth/permission_resolver_test.dart test/core/auth/capability_service_test.dart
```
