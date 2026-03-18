# UI Rules

## Tokens

- Use `app_theme.dart` tokens only for colors, spacing, and typography.
- Primary blue: `#0088FF`.
- Success green: `#28A745`.
- Input border: `#E0E0E0`.
- Page background: `#FFFFFF`.
- Modal, dropdown, menu, popover, date-picker, and overlay surface background: `#FFFFFF`.
- Table header background: `#F5F5F5`.
- Required-field red: `#D32F2F`.

## Text Case

- Page titles: Title Case.
- Section headings: Title Case.
- Buttons: Title Case.
- Form labels and helper text: sentence case.
- Validation messages: sentence case.
- Table headers: Title Case in general UI governance; follow the specific table-header style required by the module if the PRD calls for all-caps visual headers.
- Data values: preserve as entered unless the value is an identifier such as SKU or GSTIN.
- Do not use all caps as a visual style except for standard abbreviations and approved table-header treatments.

## Component Choices

- Use `MenuAnchor` and `MenuItemButton` for action menus.
- Use `FormDropdown` for form selections. Do not replace it with `DropdownButton` or a menu-style action trigger.
- Use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` for standard reusable date input flows instead of introducing new raw `showDatePicker(...)` calls.
- Set explicit white backgrounds for dialogs, sheets, popup menus, dropdown overlays, floating calendars, and similar surfaces instead of relying on inherited Material surface tinting.
- Use Lucide icons by default.
- Keep labels aligned in a fixed-width column when building creation and edit forms.

## Layout Expectations

- Zoho-style split: dark left navigation, light main canvas.
- Keep cards, forms, and tables visually quiet; use whitespace over heavy borders.
- Inputs should be rectangular with slight corner radius and light borders.
