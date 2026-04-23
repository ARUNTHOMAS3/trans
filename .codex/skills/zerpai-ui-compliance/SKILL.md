---
name: zerpai-ui-compliance
description: Implement and review Zerpai ERP UI against the project's mandatory visual, casing, control, form, and table behaviors. Use when working on Flutter screens, widgets, forms, tables, menus, pagination, or any UI refactor that must match the Zerpai PRD instead of generic Material defaults.
---

# Zerpai Ui Compliance

Use this skill before building or reviewing Zerpai UI. It keeps Flutter output aligned with the PRD's Zoho-inspired interaction model, not just Material defaults.

## Workflow

1. Read `references/ui-rules.md` for text casing, colors, control choices, and layout expectations.
2. Read `references/table-and-form-patterns.md` when the task involves forms, item tables, dropdowns, pagination, or row actions.
3. Check every screen for these failure modes:
   - hardcoded colors or spacing
   - incorrect text case
   - wrong dropdown or menu component
   - missing pagination or numeric-field restrictions
   - table or form behavior that breaks the PRD

## Mandatory Rules

- Use app theme tokens instead of hardcoded visual values unless explicitly approved.
- Modal, popup, dropdown, menu, popover, date-picker, and overlay surfaces must default to pure white `#FFFFFF`; do not rely on inherited Material tinting or non-white theme surfaces unless explicitly requested.
- Use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the default reusable date picker wherever the shared anchored picker pattern is possible.
- Prefer real DB-backed data, DB-backed defaults for lookup masters, explicit empty/error states, and centralized shared UI styling over screen-local business logic or placeholder values.
- Keep primary save/create/confirm buttons, neutral cancel buttons, upload affordances, and border/divider styling aligned with shared project tokens instead of screen-local color variations.
- Use Lucide icons for most UI and reserve FontAwesome for brand icons.
- Use Title Case for destinations and actions, sentence case for instructions and field labels, and preserve user data as entered.
- Use `MenuAnchor` for action menus and `FormDropdown` for form input selections.
- All tables and list views need server-side pagination with a default page size of 100.
- Numeric fields must block alphabetic input.

## Reference Loading

- Use `references/ui-rules.md` for case standards, tokens, and component choices.
- Use `references/table-and-form-patterns.md` for form layout, dropdown behavior, item tables, pagination, and interaction details.
