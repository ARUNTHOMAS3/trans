# 🔄 Workflow-Level UI Consistency Audit

This document audits the visual and interaction consistency across major page archetypes in the Zerpai ERP system. The goal is to ensure a predictable user experience as the user moves between list views, creation forms, and reporting dashboards.

## 1. Page Archetype Comparison

| Feature | List / Overview | Create / Edit | Detail View | Reports | Dashboards |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Toolbar** | Top-right (Table) | Bottom-fixed Footer | Top Action Bar | Shell Header | None (Card-local) |
| **Primary Action** | "+ New" (Top Right) | "Save" (Bottom Right) | "Edit" (Top Left) | "Export" (Top Right) | "Quick Actions" |
| **Search** | Filter Bar (Inline) | None | Search Icon (Global) | Filter Shell | None |
| **Filters** | Next to Search | None | None | Left/Top Sidebar | Date Selector |
| **Navigation** | Breadcrumb / Title | "Back" Button | Breadcrumb / Back | Report Center Link | "Overview" Title |
| **Pagination** | Footer (Numeric) | None | None | None / Inf. Scroll | None |

## 2. Component Placement Inconsistencies

### 🚩 Save/Cancel Positioning
- **Current State**: Most forms use a fixed bottom-right footer (`sales_order_create.dart`). However, some older settings modals may have buttons within the scrollable area.
- **Guideline**: All forms must use a fixed footer to ensure the "Save" action is always visible regardless of form length.

### 🚩 Search & Filter Alignment
- **List Pages**: Search is often the leftmost element in the filter bar.
- **Reports**: Search is often buried in a "Customize Report" slide-out.
- **Recommendation**: Standardize on a "Filter Ribbon" pattern for both List and Report views.

### 🚩 Breadcrumb Behavior
- **Issue**: Some screens use the `pageTitle` in `ZerpaiLayout` as a static label, while others include a clickable "Back" icon next to it.
- **Guideline**: Implement a standard breadcrumb component: `Home / Sales / [Order Number]` for all depth > 1.

## 3. Interaction Patterns

### Keyboard Shortcuts
- **Current State**: Inconsistent. POS-focused modules (Sales) have `F1-F12` mapping, while Settings/Reports rely entirely on mouse.
- **Requirement**: Universal `CMD/CTRL + S` for save and `ESC` for close/cancel across all modules.

### Table Actions
- **List Views**: Actions are often hidden behind a `...` more-menu on each row.
- **Detail Views**: Actions are prominent in a top bar.
- **Conflict**: Moving from a List to a Detail view shifts the user's focus from the "row right-side" to the "top bar". 
- **Guideline**: Maintain "Primary Action" (e.g., Edit) in the same visual quadrant if possible.

## 4. Navigation Predictability

### The "Back" Logic
- **Issue**: The "Back" button sometimes calls `context.pop()` (browser-back) and other times `context.go(AppRoutes.list)` (hard navigation).
- **Risk**: Using `pop()` can lead to unexpected states if the user arrived via a deep-link.
- **Guideline**: Use "Smart Back" logic: If no history, navigate to parent module root; otherwise `pop()`.

## 5. Audit Checklist for New Screens
1. [ ] Is the primary action in the correct quadrant (Bottom Right for Forms, Top Right for Lists)?
2. [ ] Does the "Cancel" action trigger an "Unsaved Changes" dialog if the form is dirty?
3. [ ] Is the search bar consistent with the `ZSearchBar` architecture?
4. [ ] Does the page respect the high-density layout (40px row heights)?
5. [ ] Is the "Back" behavior predictable and deep-link safe?
