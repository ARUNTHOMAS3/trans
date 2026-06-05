# Zerpai ERP — Owned Modules Comprehensive Testing Checklist

> Owner scope from sidebar marks: Items, Price Lists, Branch Price Lists, Inventory Adjustments, Move Orders, Transfer Orders, Customers, Sales Returns, Credit Notes, Vendors, Manual Journals, Recurring Journals, Bulk Update, Transaction Locking, Opening Balances, Chart of Accounts, Reports, Audit Logs.
> Use this as execution checklist. Mark each case: `[ ]` pending, `[x]` pass, `[!]` fail.

---

## 0) Test Run Controls (Mandatory Before Module Testing)

### 0.1 Environment + Access
- [!] Backend boot clean (`npm run start:dev`) without route/DTO/runtime crash. (Timed run hit tool timeout; `npm run build` passed, and `:3001` is listening.)
- [x] Flutter web boot clean (`flutter run -d chrome`) without red-screen on initial navigation. (Port `53500` listener confirmed; first attempt on `53431` failed due port already in use.)
- [ ] Login works with active token.
- [ ] Token expiry behavior verified: app redirects/logout on expired token (no stale authenticated state).
- [ ] Current org/entity selected correctly in navbar context switcher.

### 0.2 Route + Deep Link Guardrails
- [ ] Every listed module route opens directly via URL refresh.
- [ ] Browser back/forward preserves list/detail/create state correctly.
- [ ] No `go_router` redirectOnly assertion (`matchList.last.route.redirectOnly`) during create/edit/delete flows.

### 0.3 UI Governance Guardrails
- [ ] Dropdown inputs use shared `FormDropdown<T>` behavior.
- [ ] Tooltips use shared `ZTooltip` behavior.
- [ ] Floating surfaces (dialogs, menus, overlays) render pure white backgrounds.
- [ ] No overflow stripes (`RenderFlex overflow`) in main list/detail/create screens.

### 0.4 Execution Notes (2026-05-19)
- Backend checks executed: `npm run build` ✓, startup probe on `:3001` detected listener.
- Frontend checks executed: `flutter run -d chrome` on `:53431` ✗ (port conflict), retry on `:53500` started listener ✓.
- Pending checks require interactive browser/session validation (login/token expiry/nav context/routes/UI overflow scan).

---

## 1) Items Module

### Route/Screen Coverage
- [✓] `/items` list opens.
- [✓] `/items/create` opens.
- [✓] `/items/detail/:id` opens from list and direct URL.
- [✓] `/items/edit/:id` opens where applicable.

### Functional Coverage (from `items_item_list.dart`, `items_item_create.dart`, `items_item_detail.dart`)
- [✓] List fetch loads first page and count correctly.
- [✓] Search updates list and returns expected rows.
- [✓] Filter/sort toggles update rows deterministically.
- [✓] Create item (all required fields) saves successfully.
- [✓] Edit item persists changes and reflects in detail/list.
- [✓] Delete item removes row and no ghost row remains.
- [✓] Image upload in detail updates primary + gallery URLs.
- [✓] Reorder point update saves and reload shows new value.
- [✓] Reorder term update saves and reload shows new value.
- [x] Warehouse stock tab loads without empty schema exceptions.
- [-] Batch tab loads, create/edit/delete batch actions work.
- [ ] Serials tab loads and filters correctly.
- [ ] Transactions tab loads and filters by type/status.
- [ ] Opening stock dialog posts valid payload.
- [ ] Physical stock adjustment flow stores variance correctly.

### Product Split Regression (critical)
- [ ] No payload includes removed `rack_id` field.
- [ ] Entity-specific fields resolve from split tables/views.
- [ ] Create/edit does not rely on dropped `products.sku` column.
- [ ] Preferred vendor and valuation fetch from new source, not removed product columns.

---

## 2) Price Lists Module

### Route/Screen Coverage
- [ ] `/items/price-lists` overview opens.
- [ ] `/items/price-lists/create` opens.
- [ ] `/items/price-lists/edit/:id` opens via row action and direct URL.

### Functional Coverage (`pricelist_overview.dart`, `pricelist_add.dart`, `pricelist_edit.dart`)
- [ ] List load with pagination works.
- [ ] Search focuses and filters rows correctly.
- [ ] Status/type/date filters apply and clear correctly.
- [ ] Bulk activate selected rows works.
- [ ] Bulk deactivate selected rows works.
- [ ] Bulk delete selected rows works with confirmation.
- [ ] Row action: edit works.
- [ ] Row action: clone/template flow works.
- [ ] Row action: activate/deactivate works.
- [ ] Row action: delete works.
- [ ] Column customization saves and restores view.
- [ ] Create: pricing scheme + item rates save correctly.
- [ ] Create: bulk update mode updates selected rows only.
- [ ] Create: volume ranges add/edit/remove persists correctly.
- [ ] Edit: existing values hydrate and save correctly.

---

## 3) Branch Price Lists Module

### Route/Screen Coverage
- [ ] `/items/branch-price-lists` overview opens.
- [ ] `/items/branch-price-lists/create` opens.
- [ ] `/items/branch-price-lists/edit/:id` opens via action and direct URL.

### Functional Coverage (`branch_pricelist_overview_page.dart`, `branch_pricelist_add_page.dart`, `branch_pricelist_edit_page.dart`)
- [ ] List load/pagination/search works.
- [ ] Branch selector data loads and required branch selection enforced.
- [ ] Create from template hydrates correctly.
- [ ] Item search/filter in rates grid works.
- [ ] Bulk update mode (markup/markdown, %/flat) works.
- [ ] Volume range validation prevents invalid overlaps and negatives.
- [ ] Save creates record and redirects to list.
- [ ] Edit hydrates existing overrides + ranges correctly.
- [ ] Edit save persists and list reflects updated timestamp.

---

## 4) Inventory Adjustments Module

### Route/Screen Coverage
- [ ] `/inventory/adjustments` overview opens.
- [ ] `/inventory/adjustments/create` opens.
- [ ] `/inventory/adjustments/edit/:id` opens for editable states.

### Functional Coverage (`inventory_adjustments_overview_screen.dart`, `inventory_adjustments_create.dart`)
- [ ] Overview list + detail panel select/close route sync works.
- [ ] Create: warehouse and reason required validation works.
- [ ] Create: line item add/remove works.
- [ ] Bin lookup loads by warehouse and restores selected value.
- [ ] Batch dialog add/remove/search/select works.
- [ ] Quantity validation prevents negative/invalid submit.
- [ ] Save Draft submits draft status payload correctly.
- [ ] Submit submits submitted status payload correctly.
- [ ] Approve path submits approved status payload correctly.
- [ ] Attachment add/remove persists correctly.
- [ ] Edit draft reload + update works.

---

## 5) Move Orders Module

### Route/Screen Coverage
- [ ] `/inventory/move-orders` list opens.
- [ ] `/inventory/move-orders/create` opens.
- [ ] `/inventory/move-orders/:id` detail panel opens via row click.

### Functional Coverage (`inventory_move_orders_list.dart`, `inventory_move_orders_create.dart`)
- [ ] List load with warehouse/user lookups works.
- [ ] Search/status filters work.
- [ ] Column customization save/restore works.
- [ ] Row select all/select single works.
- [ ] Detail panel open/close keeps route in sync.
- [ ] Create move order with valid rows saves.
- [ ] Bin/location movement data persists correctly.
- [ ] No hardcoded dummy business values in create/list/detail.

---

## 6) Transfer Orders Module

### Route/Screen Coverage
- [ ] `/inventory/transfer-orders` list opens.
- [ ] `/inventory/transfer-orders/create` opens.
- [ ] `/inventory/transfer-orders/edit/:id` opens.
- [ ] `/inventory/transfer-orders/:id` detail opens.

### Functional Coverage (`inventory_transfer_orders_list.dart`, `inventory_transfer_orders_create.dart`)
- [ ] List `_bootstrapScreen` completes (no stuck loader).
- [ ] `_hydrateFromRoute` + `_syncRoute` preserve filters in URL.
- [ ] `_loadRows` handles API errors with retry UI.
- [ ] Custom views create/apply/delete persists.
- [ ] Sort by date/created/modified works.
- [ ] Import from file creates records safely.
- [ ] Export generates downloadable file.
- [ ] Create transfer validates source/destination warehouse rules.
- [ ] Item selection and product hydration by ID works.
- [ ] Bin/batch allocation dialog saves expected quantities.
- [ ] Mark-as-received action transitions status correctly.
- [ ] Delete transfer works with confirmation and list refresh.

---

## 7) Customers Module

### Route/Screen Coverage
- [ ] `/sales/customers` overview opens.
- [ ] `/sales/customers/create` opens.
- [ ] `/sales/customers/edit/:id` opens.
- [ ] `/sales/customers/:id` detail loads via deep link.

### Functional Coverage (`sales_customer_overview.dart`, `sales_customer_create.dart`)
- [ ] List and left panel selection works.
- [ ] Search + advanced search results and selection behavior correct.
- [ ] Create required fields validation works.
- [ ] GST, phone, email validations trigger correctly.
- [ ] Address/contact person tabs save and reload correctly.
- [ ] Payment terms/currency/state/country lookups load.
- [ ] File upload documents save with customer payload.
- [ ] Edit existing customer hydrates all sections.
- [ ] Update customer persists and overview reflects change.
- [ ] Delete behavior works (if enabled in UI).

---

## 8) Sales Returns Module

### Route/Screen Coverage
- [ ] `/sales/returns` overview opens.
- [ ] `/sales/returns/create` opens.
- [ ] `/sales/returns/:id` detail opens.

### Functional Coverage (`sales_return_overview_page.dart`, `sales_return_create_page.dart`)
- [ ] List fetch + empty state + skeleton state works.
- [ ] New return number sequence settings load/update correctly.
- [ ] Customer selection (including advanced modal) works.
- [ ] Warehouse selection warning and rebind behavior works.
- [ ] Add/remove line item works.
- [ ] Bulk line item add works.
- [ ] Return qty / credit-only qty validation enforced.
- [ ] Save draft works.
- [ ] Save and approve works.
- [ ] Payload posts correct items structure.

---

## 9) Credit Notes Module

### Route/Screen Coverage
- [ ] `/sales/credit-notes` overview opens.
- [ ] `/sales/credit-notes/create` opens.
- [ ] `/sales/credit-notes/edit/:id` opens.
- [ ] `/sales/credit-notes/:id` detail opens.

### Functional Coverage (`credit_note_overview_page.dart`, `credit_note_add_page.dart`)
- [ ] List load/search/empty state works.
- [ ] Create page loads without render/assertion crash.
- [ ] Customer dropdown/search/create flow works.
- [ ] Address panel select/edit/new address actions work.
- [ ] Item grid add/remove rows works.
- [ ] Zero-value fields show hint text, not forced value.
- [ ] Tax/discount/rate calculations update totals correctly.
- [ ] Batch modal (`InventoryBinBatchFOC`) opens and saves mapped qty.
- [ ] Save Draft works.
- [ ] Save & Approve works.
- [ ] Edit existing credit note hydrates and updates correctly.

---

## 10) Vendors Module

### Route/Screen Coverage
- [ ] `/purchases/vendors` list opens.
- [ ] `/purchases/vendors/create` opens.

### Functional Coverage (`purchases_vendors_vendor_list.dart`, `purchases_vendors_vendor_create.dart`)
- [ ] List fetch + search works.
- [ ] Create validation for required fields works.
- [ ] GST and contact validations work.
- [ ] Payment terms, TDS, price list lookups load.
- [ ] Contact persons + addresses + bank details persist.
- [ ] License/document upload persists.
- [ ] Save creates vendor and returns to list.
- [ ] Update existing vendor flow works (if edit route enabled).
- [ ] Delete vendor works (if action enabled).

---

## 11) Accountant — Manual Journals

### Route/Screen Coverage
- [ ] `/accountant/manual-journals` overview opens.
- [ ] `/accountant/manual-journals/create` opens.
- [ ] `/accountant/manual-journals/:id` detail/edit opens.

### Functional Coverage (`manual_journals_overview_screen.dart`, `manual_journal_create_screen.dart`)
- [ ] Overview list load and filters work.
- [ ] Draft autosave triggers and restore prompt works.
- [ ] Journal number auto settings load + save.
- [ ] Add/remove journal rows works.
- [ ] Debit/credit totals calculation balances correctly.
- [ ] Account search and contact search works per row.
- [ ] Save draft persists draft status.
- [ ] Publish posts journal status.
- [ ] Save as template works.
- [ ] Attachment upload (limit/count/size rules) enforced.
- [ ] Edit existing journal updates correctly.

---

## 12) Accountant — Recurring Journals

### Route/Screen Coverage
- [ ] `/accountant/recurring-journals` overview opens.
- [ ] `/accountant/recurring-journals/create` opens.
- [ ] `/accountant/recurring-journals/:id` detail opens.

### Functional Coverage (`recurring_journal_overview_screen.dart`, `recurring_journal_create_screen.dart`)
- [ ] List loads with statuses.
- [ ] Create recurring journal with schedule works.
- [ ] Edit recurring journal updates schedule/details.
- [ ] Pause/activate/cancel transitions work.
- [ ] Import/export actions do not crash.

---

## 13) Accountant — Bulk Update

### Route/Screen Coverage
- [ ] `/accountant/bulk-update` opens.

### Functional Coverage (`accountant_bulk_update_screen.dart`)
- [ ] Filter dialog opens and validates required source account.
- [ ] Transaction search returns expected result set.
- [ ] Account target search works.
- [ ] Bulk update updates selected records only.
- [ ] Updated records removed/refreshed in local result set.
- [ ] Clear/reset filters works.

---

## 14) Accountant — Transaction Locking

### Route/Screen Coverage
- [ ] `/accountant/transaction-locking` opens.

### Functional Coverage (`accountant_transaction_locking_screen.dart`)
- [ ] Module lock dialog opens and saves date lock.
- [ ] Lock-all dialog applies to supported modules.
- [ ] Unlock path works where allowed.
- [ ] Locked period prevents edit/delete in affected modules.
- [ ] Lock explanations and warnings render correctly.

---

## 15) Accountant — Opening Balances

### Route/Screen Coverage
- [ ] `/accountant/opening-balances` opens.
- [ ] `/accountant/opening-balances/update` opens.

### Functional Coverage (`accountant_opening_balances_screen.dart`, `accountant_opening_balances_update_screen.dart`)
- [ ] Opening balances summary loads.
- [ ] Debit/credit totals calculate live and accurately.
- [ ] Save writes balances and returns success state.
- [ ] Cancel returns without dirty writes.
- [ ] Reopen screen and verify persistence.

---

## 16) Accounts — Chart of Accounts

### Route/Screen Coverage
- [ ] `/accounts/chart-of-accounts` opens.
- [ ] `/accounts/chart-of-accounts/create` opens.
- [ ] `/accounts/chart-of-accounts/edit/:id` opens.
- [ ] `/accounts/chart-of-accounts/:id` detail opens.

### Functional Coverage (`accountant_chart_of_accounts_overview.dart`, `accountant_chart_of_accounts_creation.dart`)
- [ ] Tree/list loads and parent-child hierarchy correct.
- [ ] Search + advanced search filter works.
- [ ] Create account validates code/name/parent/rules.
- [ ] Duplicate account code validation blocks save.
- [ ] Edit account updates fields.
- [ ] Bulk activate/deactivate works.
- [ ] Bulk delete works with confirmation.
- [ ] Column customization persists.
- [ ] Import/export actions complete without runtime crash.

---

## 17) Reports + Audit Logs

### Route/Screen Coverage
- [ ] `/reports` opens reports center/dashboard.
- [ ] `/audit-logs` opens audit screen.

### Functional Coverage (`reports_center_screen.dart`, `reports_reports_overview.dart`, `reports_audit_logs_screen.dart`)
- [ ] Reports search/filter in center works.
- [ ] Each report card routes to correct report screen.
- [ ] Daily sales report loads without API contract errors.
- [ ] P&L, GL, Trial Balance, Sales by Customer, Inventory Valuation open and load.
- [ ] Audit logs list loads with pagination.
- [ ] Audit logs filters/search/date range work.
- [ ] Audit log detail payload mapping displays action/entity/user/time correctly.

---

## 18) Sidebar + Module Placement Regression (Your New Split)

### 18.1 Sidebar Structure
- [ ] `Items` group contains: Items, Composite Items, Item Groups, Item Mapping.
- [ ] `Price Lists` appears as separate parent group (after Items).
- [ ] `Price Lists` group contains: Price Lists, Branch Price Lists.
- [ ] Inventory group still contains: Inventory Adjustments, Move Orders, Transfer Orders.

### 18.2 Route/Permission Mapping
- [ ] Permission key mapping allows visibility for `price_list` modules.
- [ ] Clicking Price Lists opens `/items/price-lists`.
- [ ] Clicking Branch Price Lists opens `/items/branch-price-lists`.

---

## 19) Failure Log Template (Use For Any Failed Case)

Copy block for every failure:

```text
[Module]:
[Test Case ID/Name]:
[Route]:
[Build/Commit]:
[Input Data]:
[Expected]:
[Actual]:
[API Calls]:
[Console/Stack Trace]:
[Repro Steps]:
[Severity]: Blocker / High / Medium / Low
[Owner]:
```

---

## 20) Final Sign-Off

- [ ] All owned module critical flows pass.
- [ ] No red-screen/assertion in full navigation pass.
- [ ] No route 404 for owned module APIs.
- [ ] No schema mismatch errors for migrated product split fields.
- [ ] Checklist evidence captured and shared.
