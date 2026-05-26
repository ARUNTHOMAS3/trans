# 🎨 Zerpai ERP Design System Audit

## Purpose
This folder contains a comprehensive UI/UX documentation and component audit for the Zerpai ERP system. It serves as the single source of truth for all frontend styling, UI components, interaction patterns, and reusable design elements currently used across the application.

## How to Use This Audit
Developers should refer to these documents before creating any new UI elements. The goal is to maintain visual and structural consistency across all modules.

1. **Check Reusables First**: Always check [components.md](./05_components.md) and `REUSABLES.md` in the project root to see if a component already exists.
2. **Follow Theme Tokens**: Use `AppTheme` tokens from `lib/core/theme/app_theme.dart` instead of hardcoded values.
3. **Consistent Casing**: Follow the Title Case/Sentence case rules documented in [typography.md](./03_typography.md).
4. **Layout Patterns**: Adhere to the responsive layout structures defined in [spacing-layout.md](./04_spacing-layout.md).

## Naming Conventions
- **Files**: `snake_case` (e.g., `sales_order_create.dart`).
- **Classes**: `PascalCase` (e.g., `SalesOrderOverviewScreen`).
- **Constants**: `camelCase` (e.g., `primaryBlue`).

## UI Consistency Rules
- **Pure White Surfaces**: All modal, popup, and overlay surfaces must be pure white (`#FFFFFF`).
- **High Density**: Maintain Zoho-inspired high-density layouts (row heights ~32px-40px).
- **Lucide Icons**: Use Lucide icons for all UI actions; FontAwesome is reserved for brand marks only.

## Folder Structure
- `/design-system-audit`: This documentation folder.
- `lib/core/theme`: Centralized theme tokens.
- `lib/shared/widgets`: Reusable UI primitives.
- `lib/modules/*/presentation`: Module-specific screens and local widgets.

## Responsive Design
The system uses a shared responsive foundation with global breakpoints. Major tables should be horizontally scrollable/resizable, and forms should adapt to available width using `Expanded` or `Flexible` widgets.
