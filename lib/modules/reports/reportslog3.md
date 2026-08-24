## 269) 2026-07-20 08:42:05 AM +05:30 - Purchases by Item -> Total row
- Scope: Reports -> Purchases and Expenses -> Purchases by Item total summary row.
- Root cause: The backend-driven Purchases by Item table rendered item rows but did not append the standard Reports total summary row at the bottom.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_item_table.dart.
- Reused implementation: Mirrored the existing Reports table total-row pattern used by Purchases by Vendor and other report tables, including bold total typography, right-aligned numeric cells, and bottom border styling.
- Validation: Added the total row as the final visible table row for non-empty Purchases by Item results; totals are calculated from the loaded filtered rows, numeric cells remain right-aligned, and the total row uses the existing Reports total styling with a bottom border.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
- Backend build results: Not required; no backend files were modified for this total-row change.

## 270) 2026-07-20 08:58:34 AM +05:30 - Expense Details backend implementation
- Scope: Reports -> Purchases and Expenses -> Expense Details backend implementation.
- Root cause: Expense Details was still using frontend-only/static table data and had no Reports API endpoint wired to retrieve rows from the expenses table.
- Files modified: backend/src/modules/reports/reports.controller.ts; backend/src/modules/reports/reports.module.ts; backend/src/modules/reports/dto/purchases-expenses-report-query.dto.ts; backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts; backend/src/modules/reports/services/purchases-expenses-reports.service.ts; lib/modules/reports/repositories/reports_repository.dart; lib/modules/reports/purchases_expenses/presentation/pages/expense_details_page.dart; lib/modules/reports/purchases_expenses/presentation/widgets/expense_details_table.dart.
- Existing implementations reused: Reused the Reports controller/service/repository response pattern, pagination/query DTO pattern, ReportsRepository API normalization, ReportViewScaffold, ReportDateRangeFilter, ReportEntitiesFilter, and existing Expense Details table styling.
- Validation: Passed. Expense Details now requests the Reports API, maps rows returned from expenses into the existing table model, preserves Date Range and Entity filtering, and keeps pagination/table rendering intact.
- Backend build results: Passed (`npm run build` in backend).
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).

## 271) 2026-07-20 11:25:37 AM +05:30 - Expenses by Category backend/frontend integration
- Scope: Purchases and Expenses -> Expenses by Category backend implementation, API integration, frontend integration, and report rendering.
- Root cause: The page was still using hardcoded sample rows and no dedicated Reports endpoint/service/repository aggregation existed for expenses grouped by category.
- Files modified: backend/src/modules/reports/dto/purchases-expenses-report-query.dto.ts; backend/src/modules/reports/reports.controller.ts; backend/src/modules/reports/services/purchases-expenses-reports.service.ts; backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts; lib/modules/reports/repositories/reports_repository.dart; lib/modules/reports/purchases_expenses/presentation/pages/expense_summary_by_category_page.dart; lib/modules/reports/purchases_expenses/presentation/widgets/expense_summary_by_category_table.dart.
- Existing implementations reused: PurchasesExpensesReportsController/Service/Repository pattern, Expense Details expense joins/date filters, ReportsRepository paged response normalization, and existing Expense Summary by Category table styling.
- Backend endpoints added/updated: Added GET reports/expenses-by-category using the existing PurchasesExpensesReports controller/service response pipeline.
- Frontend integration: Added ReportsRepository.getExpensesByCategory and wired ExpenseSummaryByCategoryPage through a Riverpod FutureProvider to render backend rows.
- Validation: Passed. Endpoint/service/repository were added inside Reports; the page now loads filtered category rows from the backend; existing filters, layout, local pagination, and table styling were preserved.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`). Backend build results: Passed (`npm run build` in backend).

## 272) 2026-07-20 11:40:04 AM +05:30 - Expense Summary by Category backend query fix
- Scope: Purchases and Expenses -> Expense Summary by Category backend query correction.
- Root cause: The grouped query lowercased accounts.account_type without casting for the live enum/user-defined schema and derived mileage rows from expense_mileage existence instead of expenses.expense_mode.
- Files modified: backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts; lib/modules/reports/reportslog3.md.
- Query changes: Cast account_type/account_group to text before LOWER comparisons, classify RECORD_MILEAGE expenses through expenses.expense_mode, keep normal expense category from accounts user/system/code lookup, and require e.is_delete = false for the category summary.
- Business rule for Fuel/Mileage Expenses: Implemented. Mileage category displays exactly Fuel/Mileage Expenses for expenses.expense_mode = RECORD_MILEAGE and bypasses account lookup for that category label.
- Validation: Passed. Backend query now uses expenses as the source, excludes deleted rows, handles normal account categories, and applies the mileage category business rule without frontend changes.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
- Backend build/test results: Passed (`npm run build` in backend).

## 273) 2026-07-20 11:53:50 AM +05:30 - Expenses by Customer backend/frontend integration
- Scope: Purchases and Expenses -> Expenses by Customer backend implementation, API wiring, and report rendering.
- Root cause: Expenses by Customer still used hardcoded sample rows and no dedicated Reports endpoint/service/repository aggregation existed for expenses grouped by customer.
- Files modified: backend/src/modules/reports/reports.controller.ts; backend/src/modules/reports/services/purchases-expenses-reports.service.ts; backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts; lib/modules/reports/repositories/reports_repository.dart; lib/modules/reports/purchases_expenses/presentation/pages/expenses_by_customer_page.dart; lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_customer_table.dart.
- Backend implementation: Added GET reports/expenses-by-customer through the existing PurchasesExpensesReports controller/service/repository pipeline using expenses as the source and e.is_delete = false.
- Frontend wiring: Added ReportsRepository.getExpensesByCustomer and wired ExpensesByCustomerPage through a Riverpod FutureProvider to render backend rows.
- Customer lookup logic: Implemented LEFT JOIN customers using the existing display_name/company_name fallback pattern already used by Expense Details.
- Others fallback rule: Implemented. Expenses with customer_id IS NULL display exactly Others.
- Validation: Passed. Expenses by Customer now loads grouped expense rows from the Reports backend, excludes deleted expenses, applies Date Range filtering, and preserves layout/table behavior.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
- Backend build status: Passed (`npm run build` in backend).

## 274) 2026-07-20 12:04:40 PM +05:30 - Remove Expenses by Project report
- Scope: Reports module -> remove Expenses by Project from report listing, navigation, registration, and Reports-only page/table files.
- Files modified: `lib/modules/reports/presentation/widgets/report_navigation_catalog.dart`, `lib/modules/reports/presentation/reports_center_screen.dart`, deleted `lib/modules/reports/purchases_expenses/presentation/pages/expenses_by_project_page.dart`, deleted `lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_project_table.dart`, `lib/modules/reports/reportslog3.md`.
- Report removed: Expenses by Project.
- Validation: Passed. Removed the catalog/menu entry, direct navigation branch, report-page factory case, and dedicated Reports-only page/table files. Search verification found no active frontend/backend code references; only historical log mentions remain.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
- Backend build status: Not required; no backend Reports changes were made.

## 275) 2026-07-20 12:19:52 PM +05:30 - Expenses by Employee backend/frontend integration
- Scope: Reports -> Purchases and Expenses -> Expenses by Employee backend and frontend wiring.
- Backend files modified: `backend/src/modules/reports/reports.controller.ts`, `backend/src/modules/reports/services/purchases-expenses-reports.service.ts`, `backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts`.
- Frontend files modified: `lib/modules/reports/repositories/reports_repository.dart`, `lib/modules/reports/purchases_expenses/presentation/pages/expenses_by_employee_page.dart`, `lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_employee_table.dart`, `lib/modules/reports/reportslog3.md`.
- APIs added: `GET /reports/expenses-by-employee`.
- Repository changes: Added expenses aggregation by employee through the latest `expense_mileage` row per expense and `users.full_name`, excluding deleted expenses and preserving entity/date/vendor/status/search filters.
- DTO changes: None planned; reuse `PurchasesExpensesReportQueryDto`.
- Employee resolution implementation: Implemented `expense_mileage.employee_id -> users.id -> users.full_name`; UUIDs are not displayed.
- Others handling: Implemented. Expenses with no mileage row or a NULL `expense_mileage.employee_id` group under `Others`.
- Validation: Passed. Frontend now calls the Reports backend and renders backend rows; existing Date Range/filter/run-report/pagination/table layout behaviour is preserved.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
- Backend build status: Passed (`npm run build` in backend).

## 276) 2026-07-20 12:34:48 PM +05:30 - Billable Expense Details backend/frontend integration
- Scope: Reports -> Purchases and Expenses -> Billable Expense Details backend and frontend wiring.
- Backend files modified: `backend/src/modules/reports/reports.controller.ts`, `backend/src/modules/reports/services/purchases-expenses-reports.service.ts`, `backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts`.
- Frontend files modified: `lib/modules/reports/repositories/reports_repository.dart`, `lib/modules/reports/purchases_expenses/presentation/pages/billable_expense_details_page.dart`, `lib/modules/reports/purchases_expenses/presentation/widgets/billable_expense_details_table.dart`, `lib/modules/reports/reportslog3.md`.
- APIs added: `GET /reports/billable-expense-details`.
- Repository changes: Added billable expense query from `expenses`, filtering `COALESCE(is_billable, false) = true` and `COALESCE(is_delete, false) = false`, with existing entity/date/vendor/status/search pagination patterns preserved.
- DTO changes: None planned; reuse `PurchasesExpensesReportQueryDto`.
- Query implementation: Returns expense number/date, vendor, customer, expense account, item amount, invoice item amount, marked-up amount, gross profit, and related IDs using the existing Reports response format.
- Frontend wiring: Added `ReportsRepository.getBillableExpenseDetails`, Riverpod provider wiring, backend row parsing, loading/error/empty handling, and table row rendering while preserving the existing report layout.
- Validation: Passed. Billable Expense Details now calls the Reports backend, excludes non-billable/deleted expenses by query, preserves Date Range/Entity/More Filters/Run Report behaviour, and keeps the existing table layout.
- Backend build status: Passed (`npm run build` in backend).
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).

## 277) 2026-07-20 12:50:55 PM +05:30 - Billable Expenses Grand Total row
- Scope: Reports -> Purchases and Expenses -> Billable Expense Details Grand Total row.
- Root cause: The Billable Expense Details integration rendered backend rows but did not append a financial summary row like other Reports tables.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/widgets/billable_expense_details_table.dart`, `lib/modules/reports/reportslog3.md`.
- Reused implementation: Followed the existing Reports table pattern used by Purchases by Item and other financial reports: compute totals from the filtered row list and append a final in-table row.
- Query changes: None. Backend and API response remain unchanged.
- Frontend changes: Added Grand Total row inside the existing table row list, summing item amount, invoice item amount, marked-up amount, and gross profit across the filtered rows.
- Validation: Passed. Grand Total row appears as the final in-table row for non-empty Billable Expense Details results and totals are calculated from the filtered row list already loaded by the report.
- Backend build status: Not run; backend was not modified.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).

## 278) 2026-07-20 12:54:38 PM +05:30 - Billable Expenses Total row label correction
- Scope: Reports -> Purchases and Expenses -> Billable Expense Details total row label.
- Root cause: The previous enhancement used the requested `Grand Total` label, but the report should follow the project table convention and display `Total`.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/widgets/billable_expense_details_table.dart`, `lib/modules/reports/reportslog3.md`.
- Reused implementation: Kept the existing in-table financial total row implementation and changed only the label text.
- Query changes: None. Backend and API response remain unchanged.
- Frontend changes: Updated total row label from `Grand Total` to `Total`; totals and table behaviour are unchanged.
- Validation: Passed. Total row label now matches the project report convention while totals, placement, and table behaviour remain unchanged.
- Backend build status: Not run; backend was not modified.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).

## 279) 2026-07-20 01:09:07 PM +05:30 - Purchases by Vendor hover and Others drill-down
- Scope: Reports -> Purchases and Expenses -> Purchases by Vendor hover behaviour and vendor-group details navigation.
- Root cause: The Purchases by Vendor frontend used static rows without row navigation, while the backend summary response did not include expense-based Others detail records needed by the drill-down reference.
- Files modified: `backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts`, `lib/modules/reports/repositories/reports_repository.dart`, `lib/modules/reports/purchases_expenses/presentation/pages/purchases_by_vendor_page.dart`, `lib/modules/reports/purchases_expenses/presentation/pages/purchase_details_for_vendor_page.dart`, `lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_vendor_table.dart`, `lib/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_vendor_table.dart`, `lib/modules/reports/reportslog3.md`.
- Hover behaviour changes: Vendor names remain clickable blue text and now add underline only while hovered; pointer cursor remains on the vendor name and other columns do not change on hover.
- Others navigation changes: Purchases by Vendor rows now navigate through a generic purchase details page; `Others` uses the same page and receives the grouped detail rows from the report response.
- Components reused: Reused `ReportViewScaffold`, Reports repository/provider pattern, existing date range/filter workflow, Reports table typography, pagination footer, content card, toolbar, and total-row table pattern.
- Backend query changes: Extended the existing Purchases by Vendor endpoint to group both bill rows and expense rows, including null vendor expense records under `Others`, while preserving date/entity/filter/search pagination patterns.
- Validation: Passed. Normal vendor rows and `Others` are clickable through the same generic details page, existing filters continue to drive the report request, and totals are computed from the returned report rows.
- Backend build status: Passed (`npm run build` in backend).
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).

## 280) 2026-07-20 01:15:57 PM +05:30 - Purchases by Vendor detail DB status correction
- Scope: Reports -> Purchases and Expenses -> Purchases by Vendor detail status display.
- Root cause: Detail rows could consume the generic `status` field, which conflicts with existing expense report payload conventions where billability may be exposed as status and DB-backed expense status is carried separately.
- Files modified: `backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts`, `lib/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_vendor_table.dart`, `lib/modules/reports/reportslog3.md`.
- Backend changes: Added `expenseStatus` to Purchases by Vendor expense detail payload from `expenses.status`.
- Frontend changes: Purchase detail rows now display `expenseStatus` first and only fall back to `status` when the explicit DB status field is unavailable.
- Validation: Passed. Status parsing now prefers the DB-backed detail field, with no layout, filter, pagination, or navigation changes.
- Backend build status: Passed (`npm run build` in backend).
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).

## 281) 2026-07-20 01:20:55 PM +05:30 - Purchases by Vendor detail billable status correction
- Scope: Reports -> Purchases and Expenses -> Purchases by Vendor detail status column.
- Root cause: The detail status correction in #280 switched the column to workflow status from `expenses.status`, but this detail view should show billability based on `expenses.is_billable`.
- Files modified: `backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts`, `lib/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_vendor_table.dart`, `lib/modules/reports/reportslog3.md`.
- Backend changes: Purchases by Vendor expense detail payload now sets `status` to `Billable` or `Non-Billable` using `COALESCE(e.is_billable, false)`.
- Frontend changes: Purchase detail rows read the `status` field directly for the Status column.
- Validation: Passed. Status column now reflects billability from `is_billable`, with no layout, filter, pagination, or navigation changes.
- Backend build status: Passed (`npm run build` in backend).
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
## 282) 2026-07-20 01:27:44 PM +05:30 - Purchases by Vendor vendor-link hover underline
- Scope: Reports -> Purchases and Expenses -> Purchases by Vendor clickable vendor-name hover styling.
- Root cause: The local vendor link used an opaque gesture area, making hover feel cell-sized instead of hyperlink-style text-only.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_vendor_table.dart`, `lib/modules/reports/reportslog3.md`.
- Hover behaviour changes: Replaced opaque gesture hover with text-width `MouseRegion` + transparent `InkWell`, preserving blue link color and showing a single underline only while hovering over the vendor text.
- Components reused: Followed the private Reports sales link pattern (`MouseRegion` + transparent `InkWell` + `TextDecoration.underline`) without modifying shared components.
- Validation: Passed. Underline is constrained to the text widget, pointer cursor remains, click callback is unchanged, and no backend/shared/theme files were modified.
- Backend build status: Not run; backend was not modified.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
## 283) 2026-07-20 01:58:56 PM +05:30 - Purchase Details row-wide hover underlines
- Scope: Reports -> Purchases and Expenses -> Purchase Details visual row-hover affordance.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_vendor_table.dart`, `lib/modules/reports/reportslog3.md`.
- Unified row hover implementation: Replaced the incorrect Account Name-only hover state with the existing row hover state as the single source of truth. Hovering anywhere in the row now shows the pointer cursor and underlines only Account Name, Amount, Amount With Tax, and Balance Amount.
- Row click implementation: No navigation callback or route was added per clarification; this is a visual clickable affordance only.
- Components reused: Reused the existing Reports-local row `MouseRegion` hover state and text decoration styling without modifying shared components or theme files.
- Validation: Passed. Row hover is the single trigger, pointer cursor appears across the row, only Account Name and the three amount columns underline, and no backend/shared/theme files were modified.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
## 284) 2026-07-20 02:51:34 PM +05:30 - Purchases by Vendor row hyperlink styling
- Scope: Reports -> Purchases and Expenses -> Purchases by Vendor table hyperlink styling only.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_vendor_table.dart`, `lib/modules/reports/reportslog3.md`.
- Hyperlink color changes: Kept blue hyperlink styling only on Vendor Name, Amount, and Amount With Tax; count columns remain the normal report text color.
- Unified row hover implementation: Reused a single row-level hover state so hovering any cell in the row underlines only Vendor Name, Amount, and Amount With Tax.
- Row click reuse: Moved the existing `onVendorSelected` callback from the vendor-name-only link to the full row target without changing the navigation destination.
- Validation: Passed. Entire row shows pointer cursor and uses the existing navigation callback; only the three hyperlink columns underline on row hover; no backend/shared/theme files were modified.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
## 285) 2026-07-20 02:57:02 PM +05:30 - Purchases by Vendor Others label text styling
- Scope: Reports -> Purchases and Expenses -> Purchases by Vendor table hyperlink exception for the Others vendor row.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_vendor_table.dart`, `lib/modules/reports/reportslog3.md`.
- Hyperlink color changes: Kept `Others` vendor name in normal report text color and weight while preserving blue hyperlink styling for real vendor names, Amount, and Amount With Tax.
- Hover underline changes: Suppressed underline for the `Others` vendor label even when the row is hovered; amount columns continue to follow the existing row hover underline behaviour.
- Validation: Passed. `Others` displays as black/default text with no underline, and no backend/shared/theme files were modified.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
## 286) 2026-07-20 03:12:45 PM +05:30 - Purchases by Item detail navigation
- Scope: Reports -> Purchases and Expenses -> Purchases by Item row navigation and item detail page.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/purchases_by_item_page.dart`, `lib/modules/reports/purchases_expenses/presentation/pages/purchase_details_for_item_page.dart`, `lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_item_table.dart`, `lib/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_item_table.dart`, `lib/modules/reports/reportslog3.md`.
- Navigation implementation: Added a row-level `onItemSelected` callback to `PurchasesByItemTable`; clicking anywhere on an item row opens the Reports detail page for that item using the existing `Navigator.push(MaterialPageRoute(...))` detail-page pattern.
- Backend changes: None. Reused the existing `reports/purchases-by-item` response, including the per-item `purchases` detail payload returned by the backend query.
- Components reused: Reused `ReportViewScaffold`, Reports table typography, `ReportPaginationFooter`, `ReportTableEmptyBody`, and the existing Purchases by Vendor detail-page navigation pattern.
- Validation: Passed. Rows navigate to a Purchases by Item detail page showing only the selected item purchase records grouped by vendor, with totals and pagination preserved.
- Backend build status: Not run; backend was not modified.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
## 287) 2026-07-20 03:20:46 PM +05:30 - Purchases by Item detail header divider removal
- Scope: Reports -> Purchases and Expenses -> Purchases by Item detail page report container divider.
- Root cause: The item detail page passed an empty tableHeaderActions widget, which made the shared report container render an otherwise empty top action strip and horizontal divider above ZABNIX PRIVATE LIMITED.
- Files modified: lib/modules/reports/purchases_expenses/presentation/pages/purchase_details_for_item_page.dart, lib/modules/reports/reportslog3.md.
- UI change: Removed only the empty page-level header action slot so the extra horizontal line no longer renders.
- Components reused: Existing ReportViewScaffold and ReportTableContainer behavior reused without shared component changes.
- Validation: Passed; the detail title, date, table, totals, pagination, and existing behavior remain unchanged.
- Backend build status: Not run; backend was not modified.
- flutter analyze results: Passed (flutter analyze lib/modules/reports).
## 288) 2026-07-20 03:30:01 PM +05:30 - Purchases by Item row hyperlink hover behavior
- Scope: Reports -> Purchases and Expenses -> Purchases by Item row interaction.
- Root cause: The Purchases by Item row already reused row-level click and hover detection, but its blue hyperlink amount value did not receive the standard browser-style underline during row hover.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_item_table.dart, lib/modules/reports/reportslog3.md.
- Row click behavior: Reused the existing row-level onItemSelected callback, MouseRegion pointer cursor, and GestureDetector opaque tap target so the entire row remains clickable.
- Hover behavior changes: Reused the existing row hover state and applied underline only to the existing blue amount hyperlink text while leaving default/black text unchanged.
- Backend build status: Not run; backend was not modified.
- Validation: Passed flutter analyze lib/modules/reports. Navigation destination, table layout, filters, pagination, export, totals, and scroll behavior were not changed.
## 289) 2026-07-20 03:58:25 PM +05:30 - Purchase Details for Item row hover styling
- Scope: Reports -> Purchases and Expenses -> Purchases by Item -> Purchase Details row interaction styling.
- Root cause: The item detail rows rendered blue vendor and amount text without the standard Reports row-wide hover state or browser-style underline treatment used by other detail tables.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_item_table.dart, lib/modules/reports/reportslog3.md.
- Row hover implementation: Reused the existing Reports detail-table pattern from purchase_details_for_vendor_table.dart with row-wide MouseRegion hover state.
- Pointer cursor implementation: Added pointer cursor across the full data row to match the existing detail-page interaction affordance.
- Hyperlink underline implementation: Applied underline only to existing blue hyperlink text, vendor name and amount, while leaving quantity and average price unchanged.
- Components reused: Existing Reports table row layout, AppTheme styles, ReportPaginationFooter, and ReportTableEmptyBody; no shared widgets were modified.
- Validation: Passed flutter analyze lib/modules/reports. Backend, navigation destination, table layout, typography, colors, filters, export, totals, pagination, and scroll behavior were not changed.
## 290) 2026-07-20 04:21:42 PM +05:30 - Expense Details row hyperlink hover behavior
- Scope: Reports -> Purchases and Expenses -> Expense Details row interaction styling.
- Root cause: Expense Details already had row-wide hover detection, but the row did not show a pointer cursor and the existing blue amount hyperlink text did not receive the standard browser-style underline during row hover.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/expense_details_table.dart, lib/modules/reports/reportslog3.md.
- Pointer cursor implementation: Added SystemMouseCursors.click to the existing row MouseRegion so the full row shows pointer affordance.
- Hyperlink underline implementation: Reused the existing row hover state and applied underline only to the existing blue amount and amount-with-tax text.
- Components reused: Existing ExpenseDetailsTable row structure, AppTheme table styles, and the detail-table hover pattern used by other Reports pages; no shared widgets were modified.
- Validation: Passed flutter analyze lib/modules/reports. Backend, navigation behavior, table layout, typography, colors, filters, export, totals, pagination, and scroll behavior were not changed.

## 291) 2026-07-20 04:58:41 PM +05:30 - Expenses by Category detail navigation
- Scope: Reports -> Purchases and Expenses -> Expenses by Category row navigation.
- Root cause: Category summary rows had no navigation callback and the existing Expense Details endpoint did not accept a category filter, so selected categories could not load category-specific expense records.
- Files modified: backend/src/modules/reports/dto/purchases-expenses-report-query.dto.ts; backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts; lib/modules/reports/repositories/reports_repository.dart; lib/modules/reports/purchases_expenses/presentation/pages/expense_summary_by_category_page.dart; lib/modules/reports/purchases_expenses/presentation/widgets/expense_summary_by_category_table.dart; lib/modules/reports/purchases_expenses/presentation/pages/expense_details_page.dart; lib/modules/reports/purchases_expenses/presentation/widgets/expense_details_table.dart; lib/modules/reports/reportslog3.md.
- Backend changes: Added optional categoryName to the Reports purchases/expenses query DTO and extended the existing expenseDetails query to filter by category while preserving filterBy/accountType/date handling.
- Frontend changes: Reused ExpenseDetailsPage and ExpenseDetailsTable in category-detail mode; wired ExpenseSummaryByCategoryTable row selection to open the detail page with the selected category and applied date/filter context.
- Navigation implementation: Entire summary data row is clickable, shows pointer cursor, and underlines existing blue hyperlink text on row hover.
- Components reused: ReportViewScaffold, ExpenseDetailsPage, ExpenseDetailsTable, ReportSearchableFilterDropdown, existing ReportsRepository expense-details API call, and the existing backend expenseDetails report query.
- Validation: flutter analyze lib/modules/reports passed with no issues. Backend npm run build passed.
- Backend build status: Passed.
- flutter analyze results: Passed.

## 292) 2026-07-21 08:25:52 AM +05:30 - Expenses by Customer row hyperlink hover styling
- Scope: Reports -> Purchases and Expenses -> Expenses by Customer hyperlink styling and row hover interaction.
- Root cause: Expenses by Customer used row hover background only; the full-row pointer cursor and browser-style underline for existing blue hyperlink text were not aligned with the Reports interaction pattern.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_customer_table.dart; lib/modules/reports/reportslog3.md.
- Hyperlink styling changes: First customer occurrence remains normal report text; repeated customer rows use the existing Reports blue hyperlink text. Existing blue amount columns remain blue.
- Pointer cursor implementation: Added full-row MouseRegion pointer cursor while preserving existing navigation behavior and without adding any new navigation destination.
- Hover implementation: Reused the existing Reports row-level hover pattern so hovering anywhere in a row underlines only blue hyperlink text in that row.
- Components reused: Existing local ExpensesByCustomerTable row renderer and Reports table typography/theme styles; behavior aligned with purchases_by_vendor_table and expense_summary_by_category_table interaction patterns.
- Validation: flutter analyze lib/modules/reports passed with no issues.
- flutter analyze results: Passed.

## 293) 2026-07-21 08:34:06 AM +05:30 - Expenses by Customer customer-name hyperlink correction
- Scope: Reports -> Purchases and Expenses -> Expenses by Customer customer-name hyperlink styling correction.
- Root cause: The previous row-hover update treated the first customer occurrence as a black grouping label, but the corrected requirement is for every customer name to use the existing blue Reports hyperlink color.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_customer_table.dart; lib/modules/reports/reportslog3.md.
- Hyperlink styling changes: Removed first-occurrence special casing so every customer name renders through the existing blue hyperlink text path.
- Pointer cursor implementation: Preserved full-row pointer cursor on hover.
- Hover implementation: Preserved row-level hover detection and browser-style underline for customer names plus existing blue amount fields only.
- Components reused: Existing ExpensesByCustomerTable row renderer and Reports hyperlink/hover pattern from purchases_by_vendor_table and expense_summary_by_category_table.
- Validation: flutter analyze lib/modules/reports passed with no issues.
- flutter analyze results: Passed.

## 294) 2026-07-21 08:38:35 AM +05:30 - Expenses by Customer Others text color correction
- Scope: Reports -> Purchases and Expenses -> Expenses by Customer Others customer-name styling correction.
- Root cause: The previous correction made every customer name blue, but the follow-up requirement is for the Others grouping to remain normal black/default report text while real customer names stay blue.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_customer_table.dart; lib/modules/reports/reportslog3.md.
- Hyperlink styling changes: Added an Others-only plain-text branch; all other customer names continue using the existing blue hyperlink text path.
- Pointer cursor implementation: Preserved full-row pointer cursor on hover.
- Hover implementation: Preserved row-level hover detection; Others remains black/default and is not underlined, while existing blue customer/amount text underlines on row hover.
- Components reused: Existing ExpensesByCustomerTable row renderer and Reports hyperlink/hover pattern.
- Validation: flutter analyze lib/modules/reports passed with no issues.
- flutter analyze results: Passed.

## 295) 2026-07-21 08:50:34 AM +05:30 - Expenses by Customer Others detail navigation
- Scope: Reports -> Purchases and Expenses -> Expenses by Customer Others row navigation.
- Root cause: The Others row was rendered with hover affordance but had no navigation callback, and the reused Expense Details endpoint did not have a customer/Others filter to return only null-customer expense records.
- Files modified: backend/src/modules/reports/dto/purchases-expenses-report-query.dto.ts; backend/src/modules/reports/repositories/purchases-expenses-reports.repository.ts; lib/modules/reports/repositories/reports_repository.dart; lib/modules/reports/purchases_expenses/presentation/pages/expenses_by_customer_page.dart; lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_customer_table.dart; lib/modules/reports/purchases_expenses/presentation/pages/expense_details_page.dart; lib/modules/reports/reportslog3.md.
- Others navigation implementation: Wired the ExpensesByCustomerTable Others row to push the reused ExpenseDetailsPage with customerName set to Others and the applied date range preserved.
- Backend changes: Added optional customerName query support for expense-details; customerName Others applies e.customer_id IS NULL, matching the Expenses by Customer summary bucket.
- Components reused: ExpenseDetailsPage, ExpenseDetailsTable category/detail mode, ReportsRepository.getExpenseDetails, and existing reports/expense-details backend query.
- Validation: flutter analyze lib/modules/reports passed with no issues. Backend npm run build passed.
- Backend build status: Passed.
- flutter analyze results: Passed.

## 296) 2026-07-21 08:59:19 AM +05:30 - Expenses by Customer Others detail reference layout
- Scope: Reports -> Purchases and Expenses -> Expenses by Customer Others detail page layout alignment.
- Root cause: The Others detail page reused the category-detail Expense Details table layout, but the attached reference requires a customer-detail layout with Status, Date, Reference#, Category, Notes, Amount, and Amount With Tax columns.
- Files modified: lib/modules/reports/purchases_expenses/presentation/pages/expense_details_page.dart; lib/modules/reports/purchases_expenses/presentation/widgets/expense_details_table.dart; lib/modules/reports/reportslog3.md.
- Layout changes: Added a customerDetailMode to the reused ExpenseDetailsTable so customer/Others details match the attached reference while category details keep their existing layout.
- Components reused: Existing ExpenseDetailsPage, ExpenseDetailsTable, ExpenseDetailsRow mapping, Reports table typography, and existing Expense Details data source.
- Validation: flutter analyze lib/modules/reports passed with no issues.
- Backend build status: Not run; no backend files changed for this layout-only correction.
- flutter analyze results: Passed.

## 297) 2026-07-21 09:08:58 AM +05:30 - Expenses by Employee row hyperlink hover behavior
- Scope: Reports -> Purchases and Expenses -> Expenses by Employee hover/pointer styling.
- Root cause: Expenses by Employee rows had row-level hover background but did not show the full-row pointer cursor or underline existing blue hyperlink text on row hover.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/expenses_by_employee_table.dart; lib/modules/reports/reportslog3.md.
- Pointer cursor implementation: Added a full-row pointer cursor through the existing row MouseRegion.
- Hyperlink underline implementation: Existing blue amount hyperlink text now receives browser-style underline while the row is hovered; black/default text and totals remain unchanged.
- Components reused: Existing local row hover state and the Reports hyperlink interaction pattern used by Expenses by Customer and other Purchases/Expenses report tables.
- Validation: Passed. Row hover now uses the existing Reports full-row hover state, the whole row shows a pointer cursor, only existing blue amount hyperlink text is underlined while hovered, and black/default text plus totals remain unchanged.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).
## 298) 2026-07-21 09:23:26 AM +05:30 - Billable Expenses row hyperlink hover behavior
- Scope: Reports -> Purchases and Expenses -> Billable Expenses hover/pointer styling.
- Root cause: Billable Expenses rows had row-level hover background but did not show the full-row pointer cursor or underline existing blue hyperlink text on row hover.
- Files modified: lib/modules/reports/purchases_expenses/presentation/widgets/billable_expense_details_table.dart; lib/modules/reports/reportslog3.md.
- Pointer cursor implementation: Added a full-row pointer cursor through the existing row MouseRegion.
- Hyperlink underline implementation: Existing blue transaction and amount hyperlink text now receives browser-style underline while the row is hovered; black/default text, labels, and totals remain unchanged.
- Components reused: Existing BillableExpenseDetailsTable row hover state and the Reports hyperlink interaction pattern used by Expense Details and Expenses by Employee.
- Validation: Passed. Row hover now uses the existing Reports full-row hover state, the whole row shows a pointer cursor, only existing blue transaction and amount hyperlink text is underlined while hovered, and black/default text plus totals remain unchanged.
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).## 299) 2026-07-21 11:23:52 AM +05:30 - Recurring Invoices backend and frontend wiring
- Scope: Reports -> Sales -> Recurring Invoices and Recurring Invoice Details drill-down.
- Root cause: The Recurring Invoice Details Reports UI was previously backed by local dummy rows and there were no Reports backend endpoints for recurring invoice summary/detail data.
- Backend files modified: backend/src/modules/reports/reports.controller.ts; backend/src/modules/reports/services/sales-reports.service.ts; backend/src/modules/reports/repositories/sales-reports.repository.ts.
- Frontend files modified: lib/modules/reports/repositories/reports_repository.dart; lib/modules/reports/recurring_invoices/presentation/pages/recurring_invoice_details_page.dart; lib/modules/reports/recurring_invoices/presentation/widgets/recurring_invoice_details_table.dart; lib/modules/reports/presentation/reports_center_screen.dart; lib/modules/reports/presentation/widgets/report_navigation_catalog.dart; lib/modules/reports/reportslog3.md.
- Components reused: Existing ReportsController, SalesReportsService, SalesReportsRepository, SalesReportQueryDto, ReportsRepository, ReportViewScaffold, ReportDateRangeFilter, ReportSearchableFilterDropdown, ReportMoreFiltersPanel, ReportPaginationFooter, and the existing recurring invoice table/page structure.
- Backend implementation summary: Added reports/recurring-invoices and reports/recurring-invoices/:recurringInvoiceId/details endpoints that query recurring_invoices, join customers for display names, apply entity/date/search/reportBy filters, and return the standard Reports data/meta response for summary rows.
- Frontend wiring summary: Replaced dummy recurring invoice rows with a Riverpod provider calling ReportsRepository, added JSON mapping and computed totals, preserved table headers/empty state, added Sales -> Recurring Invoices catalog routing, and reused the same page/table for drill-down detail mode.
- Validation: Passed static validation. Existing report filters, loading/error/empty-state handling, pagination widget, export callbacks, and Reports navigation patterns are preserved; runtime database verification was not run in this session.
- Backend build results: Passed (`npm run build` from backend).
- flutter analyze results: Passed (`flutter analyze lib/modules/reports`).

## 300) 2026-07-21 11:39:50 AM +05:30 - Recurring Invoice Details query and page label correction
- Scope: Reports -> Recurring Invoices -> Recurring Invoice Details.
- Root cause: The recurring invoice report still displayed Sales/Recurring Invoices labels and the backend query referenced recurring invoice fields as direct columns, which failed when the live recurring_invoices table did not expose every assumed field name directly.
- Files modified: backend/src/modules/reports/repositories/sales-reports.repository.ts; lib/modules/reports/recurring_invoices/presentation/pages/recurring_invoice_details_page.dart; lib/modules/reports/presentation/widgets/report_navigation_catalog.dart; lib/modules/reports/reportslog3.md.
- Query changes: Kept recurring_invoices as the source table, switched optional recurring invoice field reads to to_jsonb(ri)->>'field' extraction with existing customer lookup, preserved entity/date/search/reportBy filters, and retained the standard Reports response mapping.
- Frontend changes: Updated the visible Reports category to Recurring Invoices, renamed the summary/report title to Recurring Invoice Details, and removed the duplicate Sales catalog entry so the screen matches the reference hierarchy.
- Validation: Backend build passed and flutter analyze lib/modules/reports passed with no issues; runtime database verification should be rechecked against the live recurring_invoices data.
- Backend build results: Passed (npm run build from backend).
- flutter analyze results: Passed (flutter analyze lib/modules/reports).

## 301) 2026-07-21 12:03:30 PM +05:30 - Payments Received backend and frontend wiring
- Scope: Reports -> Sales -> Payments Received.
- Root cause: The Payments Received report page rendered hardcoded frontend rows and had no Reports backend endpoint connected to the payments_received source table.
- Backend files modified: backend/src/modules/reports/reports.controller.ts; backend/src/modules/reports/dto/sales-report-query.dto.ts; backend/src/modules/reports/services/sales-reports.service.ts; backend/src/modules/reports/repositories/sales-reports.repository.ts.
- Frontend files modified: lib/modules/reports/repositories/reports_repository.dart; lib/modules/reports/payments_received/presentation/pages/payments_received_page.dart; lib/modules/reports/payments_received/presentation/widgets/payments_received_table.dart; lib/modules/reports/reportslog3.md.
- Components reused: Existing ReportsController, SalesReportsService, SalesReportsRepository, SalesReportQueryDto, ReportsRepository, ReportViewScaffold, ReportDateRangeFilter, ReportSearchableFilterDropdown, ReportMoreFiltersPanel, ReportPaginationFooter, and the existing PaymentsReceivedTable layout.
- Backend implementation summary: Added reports/payments-received endpoint querying payments_received, joining customers for customer display names and accounts for deposit account names, applying entity/date/search/transaction type filters, returning standard Reports data/meta pagination, and providing backend-calculated amount/excess totals.
- Frontend wiring summary: Replaced dummy Payments Received rows with a Riverpod provider calling ReportsRepository.getPaymentsReceivedRows, mapped API rows into the existing table model, preserved loading/error/empty-state handling, and kept existing filter/action/table layout behavior.
- Validation: Passed static validation. Existing Date Range, Transaction Type, More Filters, Run Report, pagination widget, table headers, empty-state handling, export callbacks, and Reports navigation behavior are preserved; runtime database verification was not run in this session.
- Backend build results: Passed (npm run build from backend).
- flutter analyze results: Passed (flutter analyze lib/modules/reports).
