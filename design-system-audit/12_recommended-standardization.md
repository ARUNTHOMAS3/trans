# 🏆 Recommended Standardization

Based on the audit, the following implementations are selected as the "Gold Standard" for future development.

## 1. Primary Button
- **Component**: `ZButton.primary()`
- **Style**: RoundedRectangleBorder (4px), `accentBase` (Dynamic), `buttonText` (14px, w600).
- **Behavior**: Must show a loading state during async operations. Foreground text must be white if `accentBase` is a light shade.

## 2. Standard Modal / Dialog
- **Component**: `ZerpaiConfirmationDialog`
- **Surface**: Pure White (#FFFFFF).
- **Layout**: Title (Title Case) + Body (Sentence case) + Footer (Cancel/Confirm buttons).

## 3. Form Structure
- **Component**: `FormRow` or `SharedFieldLayout`.
- **Inputs**: `CustomTextField` and `FormDropdown<T>`.
- **Validation**: Inline red text below the field.
- **Labels**: Sentence case above the field. Mandatory asterisks (`*`) must be strictly `#FF0000`.

## 4. Data Table
- **Component**: `ZDataTableShell`.
- **Header**: Gray background (#F5F5F5), `tableHeader` style.
- **Interaction**: Resizable columns, horizontal scroll, Master-Detail transition.

## 5. Screen Layout
- **Component**: `ZerpaiLayout`.
- **Structure**: Sidebar-aware, handles top padding and global search integration automatically. Sidebar "New" buttons must use `accentBase`.

## 6. Spacing Scale
- **Scale**: `8, 16, 24, 32`.
- **Reference**: Always use `AppTheme.spaceX`.

## 7. Typography Hierarchy
- **Header**: `AppTheme.pageTitle` (18px, w600, `#000000`).
- **Sub-header**: `AppTheme.sectionHeader` (15px, w600, `#000000`).
- **Body**: `AppTheme.bodyText` (14px, w400, `#000000`).
- **Table**: `AppTheme.tableHeader` (13px, w600) / `AppTheme.tableCell` (13px, w400, `#000000`).

## 8. Responsive Strategy
- **Web-First**: Prioritize high-density desktop layouts.
- **Adaptive**: Hide non-essential columns on smaller screens; use `SingleChildScrollView` for forms.
- **Deep Linking**: All significant modal states or tabs must be addressable via GoRouter.
