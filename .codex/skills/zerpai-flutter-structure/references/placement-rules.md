# Placement Rules

## Decision Tree

1. If the file is app infrastructure, place it in `lib/core/`.
2. If it is a reusable provider or model shared across features, place it in `lib/shared/`.
3. If it belongs to one business feature, place it in `lib/modules/<module>/`.
4. If it is a test, mirror the source path under `test/`.

## Core vs Shared vs Modules

- `lib/core/`: router, theme, sidebar, navbar, API client, storage, logging, common widgets, utilities, extensions.
- `lib/shared/`: shared providers and shared models only.
- `lib/modules/`: feature-specific models, repositories, providers, controllers, and presentation.

## Required Module Pattern

```text
lib/modules/<module>/
├── models/
├── providers/
├── repositories/
├── controllers/        # optional
└── presentation/
    └── widgets/
```

## Naming

- Use `snake_case`.
- Feature screens: `<module>_<submodule>_<entity>_<page>.dart` where practical.
- Examples:
  - `sales_customers_customer_creation.dart`
  - `items_pricelist_pricelist_overview.dart`
  - `accountant_chart_of_accounts_creation.dart`

## Routing

- Keep routes in `lib/core/routing/app_router.dart`.
- Match URL shape to the module hierarchy, for example:
  - `/home`
  - `/items/pricelists`
  - `/sales/customers`

## Sidebar Hierarchy To Respect

- Home
- Items
- Inventory
- Sales
- Purchases
- Reports
- Accounts
- Documents

Additions outside this structure should be utilities or infrastructure modules, not ad hoc business folders.
