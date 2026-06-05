# Shim Retirement Readiness Report
Date: 2026-05-22

## Scope
- Printing migration shims
- Items import/export rename shims
- Accountant recurring journal rename shim
- Legacy pricelist/branches compatibility shims

## Verified Checks
- Repo-wide reference scans (`rg`)
- Targeted analyzer run on shim folders/files
- Route ownership sanity preserved

## Decision Matrix

### A) Safe to retire now (zero live refs found)
1. `lib/modules/items/items/presentation/sections/report/dialogs/export_items_dialog.dart`
- Type: compatibility shim
- Current target: `items_export_dialog.dart`
- Live references: none
- Risk: low

2. `lib/modules/items/items/presentation/sections/report/dialogs/import_items_dialog.dart`
- Type: compatibility shim
- Current target: `items_import_dialog.dart`
- Live references: none
- Risk: low

3. `lib/modules/accountant/recurring_journals/presentation/widgets/recurring_journal_import_export_dialogs.dart`
- Type: compatibility shim
- Current target: `recurring_journal_data_transfer_dialogs.dart`
- Live references: none
- Risk: low

### B) Keep for now (transitional boundary still intentional)
1. `lib/modules/printing/models/print_template.dart`
2. `lib/modules/printing/repositories/print_template_repository.dart`
3. `lib/modules/printing/services/print_service.dart`
4. `lib/modules/printing/widgets/template_editor.dart`
5. `lib/modules/printing/presentation/pages/printing_templates_overview.dart`
6. `lib/modules/printing/presentation/printing_templates_overview.dart`
- Type: migration compatibility surface for moved settings-owned PDF templates
- Live non-shim imports: none found
- Keep reason: staged migration policy; avoid sudden external/historical path breakage until full app smoke + branch validation window completes
- Risk if deleted now: medium (potential unnoticed out-of-scan references, docs/dev scripts, handoff branch cherry-picks)

### C) Keep (active compatibility domain wrappers)
1. `lib/modules/items/pricelist/*` wrappers
2. `lib/modules/branches/*` wrappers
- Reason: wrappers still part of broader staged ownership convergence and may be referenced across pending batches / unmerged work
- Risk if deleted now: medium-high

## Analyzer Status
- `dart analyze` on scoped shim folders/files: PASS (`No issues found`)

## Recommended Next Execution (safe)
1. Delete Group A shims in one small batch.
2. Re-run full repo analyze + focused route smoke.
3. Keep Group B/C shims until post-smoke signoff and cross-branch import-zero check.
