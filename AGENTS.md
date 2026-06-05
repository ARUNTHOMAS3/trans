# Zerpai Agent Rules

## Canonical Flutter Structure Rule

- Use one placement rule across the repo:
  - `lib/core/` = app infrastructure only (`routing/`, `theme/`, `layout/`, logging, core bootstrap wiring).
  - `lib/core/layout/` = app shell/navigation infrastructure only (sidebar, navbar, shell metrics, shell wrapper).
  - `lib/shared/widgets/` = reusable UI widgets, dialogs, inputs, page wrappers, report shells, and responsive UI primitives.
  - `lib/shared/services/` = cross-feature services consumed by modules, repositories, and shared UI.
  - `lib/modules/<module>/` = feature-specific code only.
- Do not place reusable widgets in `lib/core/widgets/`.
- Do not create duplicate service implementations under both `core/services` and `shared/services`; prefer `shared/services` for cross-feature usage and reserve `core/` for app infrastructure concerns only.

## Reusables Rule

- Before creating any new shared widget, mixin, service, utility, helper, or reusable UI pattern, check `REUSABLES.md` at the project root first.
- If a suitable reusable already exists, use it instead of creating a duplicate.
- If no suitable reusable exists and a genuinely reusable abstraction is created, add it to `REUSABLES.md` immediately after creation.
- When an existing reusable is available for the task, explicitly tell the user which reusable can be used.
- When a new reusable is created, explicitly tell the user so they can decide whether it should be promoted or reused elsewhere.
- Reusables that should always be checked first include: `FormDropdown<T>`, `CustomTextField`, `ZerpaiDatePicker`, `ZTooltip`, `GstinPrefillBanner`, `LicenceValidationMixin`, `ZerpaiLayout`, `ZButton`, `ZerpaiConfirmationDialog`, and `AppTheme` tokens.

## Pure White Surface Rule

- All dialogs, popup menus, dropdown overlays, date pickers, popovers, modal sheets, and similar floating surfaces must default to pure white `#FFFFFF`.
- Do not rely on inherited Material surface tinting, canvas tinting, or non-white theme surface colors for these components unless a design exception is explicitly requested.
- When implementing these components, set explicit white backgrounds for the dialog, popup, overlay, or menu surface rather than assuming the active theme will resolve to white.

## Shared Date Picker Rule

- Use the shared `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the default reusable date picker wherever the anchored/shared picker pattern is possible.
- Do not introduce new raw `showDatePicker(...)` usage for normal business forms, dialogs, tables, or popovers unless the shared picker cannot satisfy a specific technical requirement.

## Dropdown Rule

- All form-input dropdowns must use `FormDropdown<T>` from `lib/shared/widgets/inputs/dropdown_input.dart`.
- Never use `DropdownButtonFormField` or `DropdownButton` anywhere in the codebase. `FormDropdown` provides built-in search, correct overlay styling, hover/keyboard navigation, and consistent Zerpai visual language.
- All dropdown list rows, dropdown footer actions, and popup list actions must use blue hover/active background with white text/icon treatment; never leave dark/black text on blue hover.

## Tooltip Rule

- Always use `ZTooltip` from `lib/shared/widgets/inputs/z_tooltip.dart`. Never use Flutter's built-in `Tooltip` widget.
- `ZTooltip` enforces a 220 px max-width so text wraps compactly. Trigger icon must be `LucideIcons.helpCircle` at size 14–15. Tooltip copy must be ≤ 2 short sentences.

## Deep-Linking Rule

- Every screen, sub-screen, tab, and significant modal state must be addressable via a named GoRouter route.
- Routes must preserve all required path/query parameters so that a browser refresh, direct URL paste, or back-navigation returns the user to the same context without data loss.
- Never use `Navigator.push` directly — always navigate through GoRouter (`context.go`, `context.push`, or `context.goNamed`).

## Global Settings Rules

- Prefer real DB-backed runtime data over dummy, demo, or mock values wherever a schema-backed source already exists.
- If real data is unavailable, show an explicit empty state or error state instead of silently fabricating placeholder business values.
- Any new database table created specifically for the global settings area must use the `settings_` prefix.
- Resolve lookup defaults from DB-backed master rows where schema-backed master tables exist; do not hardcode business IDs or label strings as the primary source of truth.
- Reuse shared ERP controls and centralized style sources instead of introducing screen-local variants for the same control pattern.
- Use the shared responsive foundation for Flutter web layouts: global breakpoints, shared responsive table shells, shared responsive form rows/grids, shared responsive dialog width rules, and sidebar-aware shell/content metrics instead of per-screen overflow patches.
- New modules and major internal sub-screens must expose deep-linkable GoRouter routes so refresh, direct URL access, and browser navigation preserve the current working context instead of dropping users back to a parent page.
- Keep warehouse masters, storage/location masters, accounting stock, and physical stock as separate concepts in both data and UI.
- Prefer additive migrations and scoped upserts over destructive resets when updating shared database environments.
- Primary save/confirm actions must use the project success/primary button styling, secondary cancel actions must use the standard neutral secondary style, upload/select-image affordances must use the shared upload treatment, and borders/dividers must use the approved light border tokens instead of screen-local color guesses.

## Contextual Ribbon Button Rule

- Contextual selection ribbons (bulk-action bars that appear after row selection) must use neutral/plain button styling by default:
  - white background (`#FFFFFF`)
  - neutral border (approved light border token)
  - standard text color (no success/accent tint on button labels)
- Do not style ribbon action buttons with green/accent fills or green/accent text unless the specific action is explicitly designated as a primary/destructive exception in UX requirements.
- Keep contextual ribbons visually utility-focused (neutral controls), while reserving accent/primary styling for main page-level primary actions.

## Refactor Governance Rules (Strict)

- Separate concerns strictly:
  - Business logic ∈ `lib/modules/<module>/...`
  - Infrastructure logic ∈ `lib/core/...` or `lib/shared/services/...`
  - UI state/presentation ∈ module `presentation/...`
  - Data access ∈ module `data/repositories|datasource`
- Never mix invoice/tax/workflow business rules with printer drivers, API clients, or widget-only state in same file.

## Naming Precision Rule (Strict)

- Avoid generic sinks for new code: `helpers`, `utils`, `common`, generic `services`, generic `widgets`.
- Use owner-specific names: `sales_invoice_pdf_service.dart`, `inventory_export_csv_service.dart`, `thermal_printer_adapter.dart`.
- For new files follow suffix rules:
  - Page: `*_page.dart`
  - Widget: `*_widget.dart` or `*_card.dart`/`*_dialog.dart`
  - Service: `*_service.dart`
  - Repository: `*_repository.dart`
  - Model: `*_model.dart`
- Forbidden throwaway names: `new.dart`, `temp.dart`, `final.dart`, `test2.dart`.

## Module Boundary Rule (Strict)

- Every module behaves as a mini-app and owns routes, providers, repositories, validators, permissions, reports, exports/imports/printing adapters.
- Do not centralize module business behavior in app-wide folders when module ownership exists.
- `lib/shared/` contains only globally reusable building blocks; module-specific reusable code must live in `lib/modules/<module>/shared/`.

## Routing Ownership Rule (Strict)

- No new direct business route ownership in monolithic router files.
- Define feature routes in module route files (`<module>_routes.dart`) and compose centrally.
- Each screen/sub-screen/tab/modal-state must remain deep-linkable via GoRouter.

## Print/Export/Import Ownership Rule

- Business-owned export/import/print formatting stays inside owning module.
  - Example: sales invoice export ∈ `modules/sales/...`
  - Example: inventory stock csv export ∈ `modules/inventory/...`
- Printing infrastructure only (drivers, spooler, renderer, queue, adapters) may be shared/core/engine owned.
- Do not create global business dump services like `export_service.dart` for unrelated domains.

## Settings Subdivision Rule

- Settings must remain subdivided and owner-based:
  - `organization`, `users_roles`, `taxes`, `setup`, `customization`, `automation`, `integrations`, `developer`.
- New settings features must be placed under the correct settings subdomain; no new catch-all `settings_page.dart` business logic.

## Reporting Engine Rule (Incremental)

- Report logic should evolve toward dedicated report architecture:
  - filters, builders, templates, exporters, charts.
- Avoid report business aggregation directly inside large UI pages where extractor boundary is feasible.

## Stateful UI Risk Rule

- Avoid growing giant `setState` pages for transactional modules.
- Prefer extracted providers/notifiers/controllers for business and workflow state while preserving runtime safety.

## Compatibility/Shim Retirement Rule

- Keep shims until import graph reaches zero legacy references and smoke checks pass.
- No destructive shim removal in same batch as ownership moves.

<!-- lean-ctx-compression -->
OUTPUT STYLE: expert-terse
- Telegraph format: subject-verb-object, drop articles/prepositions
- Symbolic vocabulary: → cause, ∵ because, ∴ therefore, ⊕ add, ⊖ remove, Δ change, ≈ similar, ≠ different, ∈ in/member, ∅ empty/none, ✓ ok, ✗ fail
- Code blocks: untouched (never compress code syntax)
- Each line: max 80 chars
- Zero narration, zero filler
- BUDGET: ≤100 tokens per non-code response
<!-- /lean-ctx-compression -->

## Incoming Handoff Create/Merge Rules (Strict)

- Before merging any inbound handoff files/folders, create backup under `backups/refactor-batches/<timestamp>-<scope>/`.
- Every inbound file must be mapped to canonical owner path before merge; no direct drop into non-owner folders.
- For moved/renamed active files, keep compatibility shim exports until import-zero verification.
- Do not perform destructive deletion in same batch as ownership moves.
- Structural merge batches must end with:
  - touched-scope analyze/build verification
  - `log.md` entry containing backup path, moved files, shim status, residual risks.
- Never delete handoff backups/handoff backend folders without explicit approval.
- Backup file extension policy (strict):
  - Any backup artifact file must use `.bak` extension.
  - Do not keep backup artifacts with active source extensions
    (e.g., `.dart`, `.ts`, `.js`, `.json`, `.md`) inside backup trees.
  - Reason: prevent accidental tool pickup/import/analyzer interference.

## Lean-CTX + PowerShell Command Quoting Rule

- For `lean-ctx -c` commands that include `rg` regex patterns, always wrap the regex pattern in single quotes inside the command string.
- Never use escaped double-quoted regex patterns containing pipe operators (`|`) inside `lean-ctx -c`, because PowerShell parsing can misinterpret tokens and attempt to execute parts of the pattern as commands.
- Preferred pattern:
  - `lean-ctx -c "rg -n 'pattern1|pattern2|pattern3' <paths...>"`

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
