# 🤝 Developer UI/UX Handover Guide

Welcome to the Zerpai ERP frontend development team. To ensure our interface remains professional, high-density, and consistent, please adhere to this guide.

## 1. The Golden Rule of Reusability
**NEVER** create a new widget if a suitable one exists in `lib/shared/widgets`.
- **Buttons**: Use `ZButton`.
- **Inputs**: Use `CustomTextField` or `FormDropdown`.
- **Modals**: Use `ZerpaiConfirmationDialog`.
- **Tables**: Use `ZDataTableShell`.

## 2. Styling Dos and Don'ts
- ✅ **DO**: Use `AppTheme.tokenName` for all colors and text styles.
- ❌ **DON'T**: Use `Colors.blue` or `Color(0xFF...)` inline.
- ✅ **DO**: Follow casing rules: Destinations/Titles = Title Case; Instructions/Labels = Sentence case.
- ❌ **DON'T**: Use ALL CAPS for any UI text (except abbreviations like GST).
- ✅ **DO**: Wrap screens in `ZerpaiLayout` for consistent padding and structure.

## 3. Folder Structure Expectations
- **Core Infrastructure**: `lib/core/` (Theme, Routing, API).
- **Shared Primitives**: `lib/shared/widgets/` (Atoms and Molecules).
- **Feature Modules**: `lib/modules/<module>/`.
- **Module Screens**: `lib/modules/<module>/presentation/<module>_<submodule>_<page>.dart`.
- **Local Widgets**: If a widget is used only within one module, place it in `lib/modules/<module>/presentation/widgets/`.

## 4. State & Interaction
- **State Management**: Use `Riverpod`.
- **Navigation**: Use `GoRouter`. Never use `Navigator.push` directly.
- **Loading**: Always provide visual feedback (Skeleton or ZButton loading state).

## 5. Responsive Strategy
- All tables must be horizontally scrollable.
- Use `Expanded` to prevent horizontal overflow in `Row` widgets.
- Ensure every significant state (e.g., a selected item in a list) is deep-linkable via the URL.

## 6. Prohibited Patterns
- Standard Material `DropdownButton`.
- Standard Material `showDatePicker` (without `ZerpaiDatePicker` wrapper).
- Hardcoded margins/paddings (always use `AppTheme.spaceX`).

---
By following these standards, we ensure that Zerpai ERP remains a premium, enterprise-grade tool. If you encounter a missing UI pattern, propose an addition to the Design System rather than creating a local one-off.
