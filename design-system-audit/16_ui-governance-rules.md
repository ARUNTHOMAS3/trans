# ⚖️ UI Governance & Frontend Standards

This document defines the strict governance rules for frontend development within the Zerpai ERP ecosystem. Adherence to these rules is mandatory to maintain code quality, visual consistency, and architectural integrity.

## 1. Directory Governance

### ✅ Allowed Folders for Reusables
- `lib/shared/widgets/`: Atomic and molecular UI components (Buttons, Inputs, Chips).
- `lib/shared/widgets/sections/`: Large, multi-field UI blocks (Address Section, Totals Block).
- `lib/shared/widgets/dialogs/`: Standardized modal overlays and confirmation boxes.
- `lib/core/theme/`: Centralized design tokens (AppTheme).

### ❌ Forbidden Folders for Reusables
- `lib/modules/<module>/presentation/`: NEVER place widgets intended for cross-module use here.
- `lib/core/widgets/`: Reserved for app infrastructure (Sidebar, Topbar) only.

## 2. Widget Creation Rules

### General Principles
- **The Rule of Two**: If a UI pattern appears in **two** or more modules, it MUST be extracted to `lib/shared/widgets`.
- **Pure White Surface Rule**: All floating surfaces (modals, dropdowns, popovers) MUST default to pure white `#FFFFFF`.
- **AppTheme Enforcement**: Hardcoding `Color(0x...)` or `Colors.*` is a blocking error. Only `AppTheme` tokens are permitted.

### New Buttons/Inputs/Tables
1. **Search First**: Check `REUSABLES.md` and `lib/shared/widgets` before creating any input or button.
2. **Extend, Don't Clone**: If `CustomTextField` lacks a feature, add it as an optional parameter rather than creating `MyCustomTextField`.
3. **Density Compliance**: New table components must support the 32px-40px high-density row requirement.

### Modals & Dialogs
- **Confirmation**: Always use `ZerpaiConfirmationDialog` for destructive actions (Delete, Void).
- **Unsaved Changes**: Any form with unsaved state MUST trigger `UnsavedChangesDialog` on exit.
- **Widths**: Use shared responsive width rules (e.g., `maxWidth: 600` for standard forms) instead of hardcoded percentages.

## 3. Naming & Casing Standards
- **Filenames**: `snake_case.dart` (e.g., `sales_order_list.dart`).
- **Classes**: `UpperCamelCase` (e.g., `SalesOrderList`).
- **Variables**: `lowerCamelCase` (e.g., `totalAmount`).
- **UI Labels**: 
  - **Title Case**: For Destinations and Actions (e.g., "Create Sales Order", "Edit Profile").
  - **Sentence case**: For Instructions and Form Labels (e.g., "Enter the customer name", "Billing address").

## 4. State Management Boundaries
- **Provider Scope**: Keep providers as local as possible. Global state is reserved for Auth, Theme, and Org Settings.
- **Controller Logic**: All business logic and API calls MUST reside in a `Controller` or `Notifier`, never inside the `Widget.build` or `onPressed` handlers.
- **Standard Responses**: Frontend models MUST be compatible with the `StandardResponseInterceptor` format `{ data, meta }`.

## 5. Responsive & Accessibility Minimums
- **Breakpoints**: Use global breakpoints from `AppTheme`. Never use `MediaQuery.of(context).size.width < 500`.
- **Touch Targets**: Buttons and interactive elements must have a minimum target of 44x44px (using padding if visual size is smaller).
- **Semantics**: Ensure `TextField` has proper `hintText` and `labelText` for screen readers.

## 6. PR Review Checklist (UI/UX)
- [ ] **Token Check**: Are there any hardcoded colors or font sizes?
- [ ] **Density Check**: Does the layout look correct on a 13-inch laptop (high density)?
- [ ] **Back Logic**: Does the back button correctly handle deep-linked history?
- [ ] **Empty States**: Is there an explicit "No Data" or "Error" state for lists?
- [ ] **Loading States**: Are skeletons implemented for all async operations?
- [ ] **Case Check**: Does the UI follow Title Case/Sentence case rules?

## 7. Anti-Patterns (Detected & Forbidden)

### 🚩 The Mega-Presentation File
- **Description**: Single `.dart` files exceeding 2,000 lines (e.g., `sales_order_create.dart`).
- **Fix**: Extract local private widgets into separate files within a `widgets/` subdirectory of the module.

### 🚩 Local Clone Clusters
- **Description**: Duplicating `_buildStatusBadge` or `_buildSearchBar` in every list file.
- **Fix**: Move to `lib/shared/widgets/z_status_badge.dart`.

### 🚩 Implicit Tenancy
- **Description**: Forgetting to filter a fetch or save by `entityId`.
- **Fix**: Ensure all relevant API calls include the `entity_id` or consume the `@Tenant` context.

### 🚩 Navigation via Navigator.push
- **Description**: Using `Navigator.of(context).push(...)` instead of GoRouter.
- **Fix**: Always use `context.go()` or `context.push()` to ensure deep-linking remains functional.

## 8. Deprecation & Evolution
- When a shared widget is improved, the old version should be marked with `@deprecated` and a plan created to migrate callers within one sprint.
- DO NOT delete shared widgets that are still in use in other branches.
