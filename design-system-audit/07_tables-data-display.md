# 📊 Tables & Data Display Audit

## Table Architecture
- **Structure**: `ZDataTableShell` acts as the primary wrapper.
- **Header**: Fixed, gray background (#F5F5F5), bold `textSecondary` text.
- **Rows**: High density (40px height), alternate row shading (optional), hover highlight.
- **Scroll**: Horizontal scroll is mandatory for tables with 5+ columns.

## Interaction Patterns
- **Resizing**: Columns are horizontally resizable.
- **Sorting**: Triggered by clicking column headers.
- **Selection**: Uses a checkbox in the first column. Row clicking typically opens the Detail pane (Master-Detail transition).
- **Pagination**: 
  - Default: 100 rows per page.
  - Options: 10, 25, 50, 100, 200.
  - Server-side fetching is mandatory.

## Column Types
- **Status Badges**: Used for Invoice status (Draft, Paid, Void, etc.).
- **Action Columns**: Fixed to the right, contains "More" menu or quick actions.
- **Currency**: Right-aligned, formatted via `ZCurrencyDisplay`.

## Loading & Empty States
- **Skeletons**: `SalesOrderTableSkeleton` and generic list skeletons are used during data fetching.
- **Empty State**: Icon + Title + Action button (e.g., "No invoices yet - Create Invoice").

## Inconsistencies
- **Row Heights**: Minor drift between POS tables (32px) and Management tables (40px).
- **Sorting Indicators**: Some tables lack visible sort direction arrows in the header.

## Recommended Standard
Standardize on `ZDataTableShell`. Ensure all tables implement the **Master-Detail Adaptive Pattern** where row selection splits the screen (30/70 split).
