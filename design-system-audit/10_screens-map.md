# 🗺️ Screen & Module Map

## Core Modules

### 1. Home
- **Route**: `/:orgId/home`
- **Purpose**: Dashboard overview with key metrics.
- **Main Components**: KPI Cards, Charts, Recent Activities.

### 2. Items (Inventory Master)
- **Route**: `/:orgId/items`
- **Sub-Routes**:
  - `/create`: Item creation form.
  - `/edit/:id`: Item modification.
  - `/report`: Inventory stock reports.
- **Main Components**: `ZDataTableShell`, `HSNSACSearchModal`.

### 3. Sales
- **Route**: `/:orgId/sales`
- **Sub-Modules**:
  - `Customers`: `/:orgId/sales/customers`
  - `Quotations`: `/:orgId/sales/quotations`
  - `Sales Orders`: `/:orgId/sales/orders`
  - `Invoices`: `/:orgId/sales/invoices`
  - `Returns`: `/:orgId/sales/returns`
- **Main Components**: Master-Detail Split, Status Badges, `ZSplitActionMenuButton`.

### 4. Purchases
- **Route**: `/:orgId/purchases`
- **Sub-Modules**:
  - `Vendors`: `/:orgId/purchases/vendors`
  - `Purchase Orders`: `/:orgId/purchases/purchase-orders`
  - `Bills`: `/:orgId/purchases/bills`
- **Main Components**: `ZDataTableShell`, Vendor Selector.

### 5. Settings
- **Route**: `/:orgId/settings`
- **Sub-Modules**:
  - `Organization Profile`: `/:orgId/settings/orgprofile`
  - `Users`: `/:orgId/settings/users`
  - `Roles`: `/:orgId/settings/roles`
  - `Branches/Warehouses`: `/:orgId/settings/branches`
- **Main Components**: `SettingsNavigationSidebar`, `SettingsFixedHeaderLayout`.

## Layout Architecture
- **Wrapper**: `ZerpaiShell` (Handles Global Sidebar).
- **Page Layout**: `ZerpaiLayout` (Handles TopBar and Content Padding).

## Access Roles
- **Admin**: Full access.
- **Manager**: Branch-restricted access.
- **Staff**: Billing-focused restricted access.
