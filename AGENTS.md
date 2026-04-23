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
