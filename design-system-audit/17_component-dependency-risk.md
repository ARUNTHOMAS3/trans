# ⚠️ Component Dependency & Risk Analysis

This document identifies architectural "hotspots" in the frontend codebase where high coupling, excessive responsibility, or broad usage creates technical risk.

## 1. High Risk Components (The "Core Pillars")

These components are used in **80% or more** of the application. A regression here impacts the entire ERP.

### ZerpaiLayout
- **Risk Level**: 🔴 **CRITICAL**
- **Responsibilities**: Sidebar integration, Topbar/Search mapping, Global scroll management, Page-level constraints, Adaptive shell metrics.
- **Risk Analysis**: It is the "God Shell". It is tightly coupled with `GoRouter` for active navigation state and the `SidebarProvider`. Any change to its padding or constraint logic can cause overflow errors across all 50+ screens.
- **Instability Factor**: High. Frequently modified to add new global features (e.g., Global Search, Notification Center).

### ZDataTableShell
- **Risk Level**: 🔴 **CRITICAL**
- **Responsibilities**: Custom horizontal scrolling, Sticky header logic, Column resizing, Bulk action state, Pagination integration.
- **Risk Analysis**: It implements complex custom gesture and scroll synchronization logic. It is the primary way users interact with data. Failures here lead to "frozen" tables or misaligned columns.
- **Instability Factor**: Medium. Stable core logic but high sensitivity to Flutter framework updates (scroll physics changes).

### AppTheme
- **Risk Level**: 🔴 **CRITICAL**
- **Responsibilities**: Color tokens, Spacing grid, Typography scales, Global widget themes.
- **Risk Analysis**: Every UI element depends on these tokens. Changing a single color hex or spacing unit cascades through the entire design system.
- **Instability Factor**: Low. Rarely changes, but catastrophic if it does.

## 2. Medium Risk Components (Functional Dependencies)

These are used across multiple modules but are more isolated in scope.

### FormDropdown<T>
- **Risk Level**: 🟡 **HIGH**
- **Responsibilities**: Custom overlay rendering, Search-in-dropdown logic, Selection state, Validation.
- **Risk Analysis**: It is a custom implementation that replaces standard Material dropdowns. Overlay positioning is notorious for "leaking" outside the screen or being clipped by parent scroll views.
- **Instability Factor**: Medium. Complex UI logic involving `CompositedTransformTarget/Follower`.

### ZerpaiDatePicker
- **Risk Level**: 🟡 **MEDIUM**
- **Responsibilities**: Anchored date selection, Date formatting, Validation.
- **Risk Analysis**: Essential for financial transactions. Errors in date parsing or timezone handling can lead to corrupted ledger entries.
- **Instability Factor**: Low. Mostly uses stable `intl` and `Material` pickers under the hood.

## 3. Structural Risks & Anti-Patterns

### 🚩 God-Pages (The "Mega-Files")
- **Component**: `sales_order_create.dart`, `purchases_purchase_orders_create.dart`.
- **Risk**: These files contain 5,000 - 10,000 lines of code. They define hundreds of private methods (e.g., `_buildItemRow`) that should be shared.
- **Impact**: Any change to one transaction type is difficult to port to another, leading to "Feature Drift" where Sales behaves differently than Purchases.

### 🚩 Fragile Master-Detail Splits
- **Component**: Split-view logic in List screens.
- **Risk**: The logic for the 30/70 split is often duplicated with hardcoded width percentages.
- **Impact**: On smaller tablets or high-zoom browsers, the "Master" list often becomes unreadably narrow, but the UI doesn't provide a way to "Collapse" the list.

## 4. Circularity & Coupling Check

| Dependency Path | Circular? | Risk |
| :--- | :--- | :--- |
| `Shared Widgets` -> `AppTheme` | No | Normal |
| `Modules` -> `Shared Widgets` | No | Normal |
| `Shared Widgets` -> `Modules` | **Detected** | **HIGH**: A shared widget should never import a module. (None currently detected in core audit, must remain so). |
| `Controller` -> `UI Widget` | No | Normal (Riverpod pattern) |

## 5. Mitigation Roadmap

1. **Decouple ZerpaiLayout**: Break it into `ZerpaiShell` (infrastructure) and `ZPageWrapper` (content constraints).
2. **Standardize SplitView**: Create a `ZSplitLayout` component that handles the 30/70 logic with a "Collapse" toggle.
3. **Refactor God-Pages**: Extract `ZTransactionItemTable` and `ZTransactionHeader` to share the maintenance burden across Sales and Purchases.
4. **Overlay Hardening**: Review `FormDropdown` overlay logic for edge-of-screen boundary detection.
