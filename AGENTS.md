# Zerpai Agent Rules

## Pure White Surface Rule

- All dialogs, popup menus, dropdown overlays, date pickers, popovers, modal sheets, and similar floating surfaces must default to pure white `#FFFFFF`.
- Do not rely on inherited Material surface tinting, canvas tinting, or non-white theme surface colors for these components unless a design exception is explicitly requested.
- When implementing these components, set explicit white backgrounds for the dialog, popup, overlay, or menu surface rather than assuming the active theme will resolve to white.

## Shared Date Picker Rule

- Use the shared `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the default reusable date picker wherever the anchored/shared picker pattern is possible.
- Do not introduce new raw `showDatePicker(...)` usage for normal business forms, dialogs, tables, or popovers unless the shared picker cannot satisfy a specific technical requirement.

## Global Settings Rules

- Prefer real DB-backed runtime data over dummy, demo, or mock values wherever a schema-backed source already exists.
- If real data is unavailable, show an explicit empty state or error state instead of silently fabricating placeholder business values.
- Resolve lookup defaults from DB-backed master rows where schema-backed master tables exist; do not hardcode business IDs or label strings as the primary source of truth.
- Reuse shared ERP controls and centralized style sources instead of introducing screen-local variants for the same control pattern.
- Keep warehouse masters, storage/location masters, accounting stock, and physical stock as separate concepts in both data and UI.
- Prefer additive migrations and scoped upserts over destructive resets when updating shared database environments.
- Primary save/confirm actions must use the project success/primary button styling, secondary cancel actions must use the standard neutral secondary style, upload/select-image affordances must use the shared upload treatment, and borders/dividers must use the approved light border tokens instead of screen-local color guesses.
