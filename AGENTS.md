# Zerpai Agent Rules

## Pure White Surface Rule

- All dialogs, popup menus, dropdown overlays, date pickers, popovers, modal sheets, and similar floating surfaces must default to pure white `#FFFFFF`.
- Do not rely on inherited Material surface tinting, canvas tinting, or non-white theme surface colors for these components unless a design exception is explicitly requested.
- When implementing these components, set explicit white backgrounds for the dialog, popup, overlay, or menu surface rather than assuming the active theme will resolve to white.

## Shared Date Picker Rule

- Use the shared `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the default reusable date picker wherever the anchored/shared picker pattern is possible.
- Do not introduce new raw `showDatePicker(...)` usage for normal business forms, dialogs, tables, or popovers unless the shared picker cannot satisfy a specific technical requirement.
