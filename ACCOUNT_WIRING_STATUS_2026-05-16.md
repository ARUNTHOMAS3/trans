# Account Wiring Status (Schema-First)

Date: 2026-05-16  
Source of truth used: `current schema.md`

## 1) Schema-grounded account linkage map

Account FK/columns found in schema:

- `account_transactions.account_id -> accounts.id`
- `branches.gstin_import_export_account_id -> accounts.id`
- `products.sales_account_id -> accounts.id`
- `products.purchase_account_id -> accounts.id`
- `products.inventory_account_id -> accounts.id`
- `composite_items.sales_account_id -> accounts.id`
- `composite_items.purchase_account_id -> accounts.id`
- `composite_items.inventory_account_id -> accounts.id`
- `purchases_purchase_order_items.account_id -> accounts.id`
- `inventory_adjustments.account_id -> accounts.id`
- `inventory_adjustment_account_entries.account_id -> accounts.id`
- `journal_template_items.account_id -> accounts.id`
- `manual_journal_items.account_id -> accounts.id`
- `recurring_journal_items.account_id -> accounts.id`
- `tds_rates.payable_account_id -> accounts.id`
- `tds_rates.receivable_account_id -> accounts.id`

## 2) Current code wiring status (high-level)

### Already wired well

- Products backend persists account IDs:
  - `sales_account_id`
  - `purchase_account_id`
  - `inventory_account_id`
  - File: `backend/src/modules/products/products.service.ts`
- Items + Composite Items models carry same account IDs in payloads.
- Item Create Sales/Purchase uses shared hierarchical `AccountTreeDropdown`.
- Inventory Adjustments has account posting path in backend service.

### Partially wired / needs hardening

- Cross-module account display name normalization is inconsistent across screens.
- Some screens still use local account dropdown patterns instead of shared account-tree parity.
- Transactional UIs often show document activity but not an explicit account/journal mapping per row.
- Account-linked modules (Sales/Purchase/Inventory) need a single explicit server-side mapping policy for which account is posted for each transaction type.

## 3) Immediate normalization already applied in current branch

- Item details transaction table now shows a `JOURNAL ACCOUNT` column using item account mapping by transaction type.
- Lookup name fallback now supports account payload variants (`user_account_name`, `system_account_name`, `account_name`, etc.).

## 4) Remaining wiring work required (repo-wide)

To achieve "every account-connected module wired properly", these are the remaining mandatory tracks:

1. Backend posting contract unification
- Define and enforce account-resolution policy for:
  - sales docs (SO/Invoice/DC/Credit Note)
  - purchase docs (PO/Bill/Vendor Credit)
  - inventory docs (adjustments/transfers/assemblies)
- Ensure posting payload writes/reads consistently from schema account FKs.

2. UI account selector parity
- Move all account selectors to shared tree behavior where applicable.
- Remove shape assumptions (`name` only) and use unified display key fallback.

3. Item/account traceability across modules
- Show effective account (and journal link when available) in detail/overview tables consistently.

4. Verification matrix
- For each account-linked module: create, edit, post, reverse, report read-back.
- Validate account IDs persisted and reflected in reports (`general-ledger`, account transactions).

## 5) Suggested execution sequence (safe)

1. Sales + Purchase document posting account policy (backend first).  
2. Inventory posting account policy (backend).  
3. UI selectors parity + detail/report traceability pass.  
4. End-to-end verification and audit log update.

