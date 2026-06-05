# Account Wiring Gap Matrix (Project-wide)

Date: 2026-05-16  
Schema reference: `current schema.md`

## Verdict

No, account wiring is not yet complete end-to-end across the whole ERP.  
Core reason: Chart of Accounts / General Ledger views read from `account_transactions`, but many business transaction flows still do not write corresponding `account_transactions` rows.

## Source-of-truth observation

- COA/GL visibility is driven by `account_transactions`:
  - `backend/src/modules/reports/reports.service.ts` (`getGeneralLedgerReport`, `getAccountTransactionsReport`, dashboard summaries) reads `account_transactions`.
  - `backend/src/modules/accountant/accountant.service.ts` writes/uses `account_transactions` for journal/opening balance flows.

## Module-by-module status

### 1) Accountant (Journals / opening balances)
- Status: Connected.
- Evidence:
  - Writes to `account_transactions` in `accountant.service.ts`.
  - Chart/ledger usage checks also read `account_transactions`.

### 2) Inventory Adjustments
- Status: Connected (with fallback improvements).
- Evidence:
  - Posts into `account_transactions` in:
    - `postQuantityAdjustment(...)`
    - `postValueAdjustment(...)`
  - Current pass also added fallback from `products.inventory_account_id` when adjustment `account_id` is absent.

### 3) Sales Orders / Sales Docs
- Status: Partially connected.
- Evidence:
  - Sales line account policy resolves and persists account values in `sales_order_items`.
  - But Sales service does not create `account_transactions` rows for sales document posting.
- Impact:
  - Sales-side account selection can exist without corresponding ledger movement in COA/GL.

### 4) Purchase Orders
- Status: Partially connected.
- Evidence:
  - PO item `account_id` now resolves from product purchase account policy.
  - But PO service does not post into `account_transactions`.
- Impact:
  - PO account linkage can be stored but not reflected in GL unless downstream posting flow creates entries.

### 5) Purchase Receives
- Status: Not account-posting connected by schema design.
- Evidence:
  - Current schema for `purchase_receive_items` has no `account_id`.
  - Service updates stock layers/transactions, but not `account_transactions`.
- Impact:
  - Receive events won’t appear in COA unless a separate accounting posting flow is implemented.

### 6) Sales Returns
- Status: Not account-posting connected by schema design.
- Evidence:
  - `sales_return_items` schema has no `account_id`.
  - Service creates returns and items, no `account_transactions` posting.
- Impact:
  - Return actions won’t automatically reflect in GL unless mapped through a dedicated posting policy.

### 7) Bills / Vendor Credits / Credit Notes flows
- Status: Incomplete at backend posting layer.
- Evidence:
  - UI/models include account selection in relevant screens.
  - No unified backend posting engine currently discovered that translates those document actions into `account_transactions` for all such flows.
- Impact:
  - Some entries appear (through journal/inventory paths), others do not.

## Why “some showing, not complete” happens

- Any flow that writes `account_transactions` appears in Chart/GL.
- Any flow that only stores account IDs on document rows (or has no account FK at all) does not automatically appear in Chart/GL.

## Required completion work (strict)

1. Build a unified document-to-ledger posting service that writes balanced `account_transactions` entries for all posted business documents.
2. Define per-document posting policy matrix (Sales Order/Invoice/DC/CN, PO/Bill/VC, Receive/Return, Transfer/Adjustment).
3. Add idempotent posting guards (`source_id + source_type`) and reverse/unpost support.
4. Backfill historical posted docs that lack ledger entries.
5. Add cross-module integration tests asserting:
   - account selection persisted correctly
   - posting creates expected `account_transactions`
   - COA/GL reports reflect the document.

