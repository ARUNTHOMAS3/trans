# 🏗️ Visual Architecture Mapping

This document provides a visual representation of the Zerpai ERP frontend architecture, documenting how layouts are composed, how components depend on each other, and how design tokens propagate through the system.

## 1. Layout Hierarchy
The following diagram illustrates the structural composition of a typical ERP screen.

```mermaid
graph TD
    App["App Root"] --> Shell["ZerpaiShell (Global Context)"]
    Shell --> Sidebar["ZerpaiSidebar (Navigation)"]
    Shell --> Content["Content Area"]
    Content --> Page["ZerpaiLayout (Page Wrapper)"]
    Page --> TopBar["TopBar (Search/Global Actions)"]
    Page --> Body["Page Body (Module Content)"]
    
    subgraph "List View Pattern"
        Body --> ListBody["List Content"]
        ListBody --> Search["ZSearchBar (Filters)"]
        ListBody --> Table["ZDataTableShell (Data)"]
        Table --> MasterDetail["SplitView (30/70)"]
    end
    
    subgraph "Form View Pattern"
        Body --> FormBody["Form Content"]
        FormBody --> FormHeader["Gray Header Section (Metadata)"]
        FormHeader --> FormRow["SharedFieldLayout (Inputs)"]
        FormBody --> ItemTable["ZTransactionItemTable (Line Items)"]
        FormBody --> Totals["ZTransactionTotalsSection (Calculations)"]
    end
```

## 2. Shared Widget Dependency Tree
This tree shows how core atomic widgets are composed into higher-order molecules and organisms.

```mermaid
graph TD
    AppTheme["AppTheme (Tokens)"] --> ZButton["ZButton"]
    AppTheme --> CustomTextField["CustomTextField"]
    AppTheme --> FormDropdown["FormDropdown"]
    AppTheme --> ZStatusBadge["ZStatusBadge"]
    
    CustomTextField --> SharedFieldLayout["SharedFieldLayout (Label + Input)"]
    FormDropdown --> SharedFieldLayout
    
    SharedFieldLayout --> ZTransactionItemRow["ZTransactionItemRow (Line Item)"]
    ZTransactionItemRow --> ZTransactionItemTable["ZTransactionItemTable"]
    
    ZButton --> ZSplitActionMenuButton["ZSplitActionMenuButton"]
```

## 3. Theme Dependency Flow
Tokens originate in the core and propagate outward to the presentation layer.

```mermaid
graph LR
    Tokens["AppTheme.dart (Source of Truth)"] --> Widgets["Shared Widgets (lib/shared/widgets)"]
    Widgets --> Modules["Feature Modules (lib/modules)"]
    
    subgraph "Token Flow"
        Colors["Colors (primaryBlue, sidebarColor)"]
        Spacing["Spacing (space8, space16)"]
        Typography["Typography (pageTitle, bodyText)"]
    end
    
    Colors --> Widgets
    Spacing --> Widgets
    Typography --> Widgets
```

## 4. Reusable Component Usage Frequency
*Data based on architectural audit of `lib/modules`.*

| Component | Usage Frequency | Criticality |
| :--- | :--- | :--- |
| `ZButton` | **Extremely High** | Essential |
| `CustomTextField` | **Extremely High** | Essential |
| `FormDropdown` | **High** | Critical |
| `ZerpaiLayout` | **High** | Critical |
| `SharedFieldLayout`| **Medium** | Important |
| `ZerpaiDatePicker` | **Medium** | Important |
| `ZDataTableShell` | **High** | Critical |

## 5. Duplicate Component Clusters
These are areas where "clones" of logic exist across modules, representing prime refactoring targets.

```mermaid
mindmap
  root((Duplicate Clusters))
    List Views
      Status Badges
      Search Bars
      Empty States
    Form Views
      Totals Calculation
      Address Blocks
      Item Rows
    Modals
      Quick Create
      Delete Confirmation
      Preferences
```

## 6. Implementation Priorities
1. **Unify Status Badges**: Centralize the 5+ variants of status badges into `ZStatusBadge`.
2. **Abstract Item Rows**: Extract `SalesOrderItemRow` and `PurchaseOrderItemRow` into a shared `ZTransactionItemRow`.
3. **Standardize Search**: Replace module-level search bars with the high-fidelity `ZSearchBar`.
