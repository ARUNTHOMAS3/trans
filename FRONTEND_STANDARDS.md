# Frontend Standards

## Core
- Flutter + Riverpod + GoRouter only.
- Use shared controls and AppTheme tokens.
- No hardcoded colors in feature screens/components (`Color(0x...)`, `Colors.*`, hex strings) unless an approved exception is documented.
- If a token is missing, add it in centralized theme files; never patch with module-local literals.

## UI Rules
- pure white floating surfaces
- `FormDropdown<T>` for form dropdowns
- `ZTooltip` for tooltips
- `ZerpaiDatePicker` for standard date inputs
- 4px rounded rectangle action buttons

## Responsiveness
Use shared breakpoints and responsive shells; avoid local overflow hacks.

## Reusable Governance
- Check `REUSABLES.md` before introducing shared UI/helpers.
- Prefer existing reusable components over local one-off implementations.
- If similar UI/logic appears in 2+ touched files, recommend or implement reusable extraction.
