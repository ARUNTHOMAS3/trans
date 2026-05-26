# App Theme Migration Master Plan

_Last updated: 2026-05-06_

## 1) Objective
Migrate the app to a single token-driven theming system where:
- `entity_id` is the branding scope key.
- `accentBase` comes from `public.branding.accent_color` for the active entity.
- accent shades are generated at runtime (no hardcoded module-level color forks).
- dropdown/popup interaction blue states remain system-blue as a deliberate UX rule.
- Transfer Orders + Move Orders are the first production migration slice.

## 2) Non-Negotiable Rules
- No new hardcoded visual colors in module UI code.
- Use shared theme tokens and shared reusable components from `lib/shared/widgets`.
- Floating surfaces remain pure white (`#FFFFFF`) unless explicitly approved.
- Form dropdowns use `FormDropdown<T>` only.
- Tooltips use `ZTooltip` only.
- Theme fallback order:
  1. entity branding row (`entity_id`)
  2. org fallback (only if entity row missing)
  3. app default accent.

## 3) Branding Data Contract (Target)
### Backend
- Read branding by `entity_id`.
- Upsert branding by `entity_id`.
- Enforce one branding row per entity (`UNIQUE(entity_id)`).
- Preserve compatibility fallback only for missing entity row.

### Frontend
- Active entity from `entityProvider` / session context.
- Settings > Branding updates `accentBase` for active entity.
- App runtime applies generated `AccentScale` everywhere.

## 4) Rollout Phases

## Phase A: Foundations (Core Theme + Providers)
- [ ] Confirm `app_branding_provider.dart` accepts active `entity_id` scoped values.
- [ ] Ensure settings branding save/load uses entity-scoped endpoints.
- [ ] Finalize accent generation utility (`c100..c600`) from one base accent.
- [ ] Map theme primitives in `app_theme.dart` and remove duplicate fallback constants where possible.
- [ ] Keep interaction-blue tokens separate from accent tokens.
- [ ] Add unit tests for accent generation and contrast-safe normalization.

## Phase B: Pilot Modules (Transfer Orders + Move Orders)
- [ ] Transfer Orders create/list screens fully tokenized.
- [ ] Move Orders create/list screens fully tokenized.
- [ ] Button states aligned to token map (primary/success/secondary/disabled/hover).
- [ ] Table row hover, headers, warnings, action menus tokenized.
- [ ] Modal and popover surfaces remain pure white.
- [ ] Scan panel and bulk modal inherit correct theme tokens.
- [ ] Validate no RenderFlex overflow introduced by style updates.

## Phase C: Shared Reusables Migration
- [ ] All shared reusable inputs and dialogs mapped to token set.
- [ ] Remove local color forks inside reusable widgets.
- [ ] Add reusable documentation updates in `REUSABLES.md` for token usage.

## Phase D: Full Module Sweep
- [ ] Inventory module complete.
- [ ] Items module complete.
- [ ] Sales module complete.
- [ ] Purchases module complete.
- [ ] Accountant module complete.
- [ ] Reports module complete.
- [ ] Auth/profile/settings module complete.
- [ ] Printing/mapping/branches/home complete.

## Phase E: Verification + Governance
- [ ] Run color-audit script/report and compare against baseline.
- [ ] CI check for forbidden hardcoded colors in UI files (allowlist only for rare exceptions).
- [ ] Manual QA per module using visual checklist.
- [ ] Update PR template with theme migration checklist.

## 5) Token Mapping Standard (Reference)
- Accent: `accent.c500`
- Accent hover/active: `accent.c600`
- Accent light surface: `accent.c100`
- Accent focus ring: `accent.c400`
- Interaction blue selected/hover (dropdown/menu states): system blue tokens
- Borders/dividers: approved neutral border token only
- Dialog/menu backgrounds: pure white

## 6) Migration Checklist by Project Area

## Core (`lib/core`)
- [ ] `lib/core/theme/app_theme.dart`
- [ ] `lib/core/theme/app_text_styles.dart`
- [ ] `lib/core/constants/app_colors.dart`
- [ ] `lib/core/providers/app_branding_provider.dart`
- [ ] `lib/core/providers/entity_provider.dart`
- [ ] `lib/core/providers/org_settings_provider.dart`
- [ ] `lib/core/pages/settings_organization_branding_page.dart`
- [ ] `lib/core/layout/zerpai_sidebar.dart`
- [ ] `lib/core/layout/zerpai_navbar.dart`
- [ ] `lib/core/layout/zerpai_shell.dart`

## Shared Reusables (`lib/shared`)
### Inputs
- [ ] `lib/shared/widgets/inputs/dropdown_input.dart`
- [ ] `lib/shared/widgets/inputs/custom_text_field.dart`
- [ ] `lib/shared/widgets/inputs/text_input.dart`
- [ ] `lib/shared/widgets/inputs/field_label.dart`
- [ ] `lib/shared/widgets/inputs/z_tooltip.dart`
- [ ] `lib/shared/widgets/inputs/zerpai_date_picker.dart`
- [ ] `lib/shared/widgets/inputs/z_date_picker_field.dart`
- [ ] `lib/shared/widgets/inputs/file_upload_button.dart`
- [ ] `lib/shared/widgets/inputs/category_dropdown.dart`
- [ ] `lib/shared/widgets/inputs/warehouse_popover.dart`
- [ ] `lib/shared/widgets/inputs/transaction_series_dropdown.dart`

### Dialogs / Sections / Tables
- [ ] `lib/shared/widgets/dialogs/bulk_items_dialog.dart`
- [ ] `lib/shared/widgets/dialogs/warehouse_change_confirm_dialog.dart`
- [ ] `lib/shared/widgets/dialogs/zerpai_confirmation_dialog.dart`
- [ ] `lib/shared/widgets/sections/attachment_section.dart`
- [ ] `lib/shared/widgets/z_button.dart`
- [ ] `lib/shared/widgets/z_data_table_shell.dart`
- [ ] `lib/shared/widgets/z_row_actions.dart`
- [ ] `lib/shared/widgets/zerpai_layout.dart`

## Modules (`lib/modules`)

### Inventory
- [ ] transfer_orders (create/list)
- [ ] move_orders (create/list)
- [ ] adjustments (create/list/overview + detail panel)
- [ ] picklists (create/edit/update/list)
- [ ] shipments (create/list)
- [ ] packages (create/list)
- [ ] assemblies (creation/overview/widgets)

### Items
- [ ] items (create/list/detail + all sections/report dialogs)
- [ ] pricelist (overview/create/edit variants)
- [ ] item_groups
- [ ] composite_items

### Sales
- [ ] all create screens (SO/invoice/challan/credit note/etc.)
- [ ] generic list screens + table/filter/dialog sections
- [ ] customer create/overview sections
- [ ] sales widgets (`sales_order_item_row`, dialogs)

### Purchases
- [ ] purchase_orders
- [ ] purchase_receives
- [ ] bills
- [ ] vendors (create/list + sections)

### Accountant
- [ ] chart of accounts
- [ ] opening balances
- [ ] settings screens
- [ ] recurring journals (all panels/dialogs)
- [ ] manual journals (all panels/dialogs)

### Other
- [ ] auth screens
- [ ] branches screens
- [ ] home dashboard widgets
- [ ] reports screens
- [ ] printing templates/editor
- [ ] mapping screens
- [ ] settings users/roles pages

## 7) “Definition of Done” per Screen
A screen is complete only when all pass:
- [ ] No hardcoded color literals in screen/widget (except approved constants).
- [ ] All controls derive from theme/reusable tokenized styles.
- [ ] Dropdown selected/hover states are blue system interaction colors.
- [ ] Modals/popup surfaces are pure white.
- [ ] Focus/hover/disabled/error states are consistent.
- [ ] No overflow regressions at desktop widths used in QA.
- [ ] Visual parity check signed off against reference behavior.

## 8) Execution Order (Recommended)
1. Core provider + entity branding contract
2. Transfer Orders
3. Move Orders
4. Shared reusables touched by both modules
5. Inventory remaining screens
6. Items → Sales → Purchases → Accountant → Reports

## 9) Risks and Mitigations
- Risk: hidden hardcoded colors in deep section widgets.
  - Mitigation: module-by-module grep scan before/after (`Color(0x`, `Colors.`).
- Risk: dropdown visual regressions if accent bleeds into interaction blue.
  - Mitigation: lock dropdown state colors to blue tokens.
- Risk: branch divergence during migration.
  - Mitigation: small PR slices per module with mandatory visual QA captures.

## 10) Tracking Cadence
- Daily: update checklist status for active module.
- Per PR: include “Theme Migration Delta” section.
- Weekly: run full color audit and publish diff summary.
