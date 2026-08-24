## 200) 2026-07-16 03:22:43 PM +05:30 - Receivables -> AR Aging Summary By Invoice Due Date -> As Of dropdown

- Scope:
    - Reports -> Receivables -> AR Aging Summary By Invoice Due Date -> As Of filter.
- Root cause:
    - The As Of filter used a static ReportFilterChip, so it did not open the shared Reports Date Range popup or reuse the standard Date Range preset option list/interactions.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/ar_aging_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter with the common ReportDateRangePresets option source, popup styling, hover behaviour, selected state, and scroll behaviour.
- Validation:
    - Verify AR Aging Summary By Invoice Due Date As Of opens the common Reports dropdown with the standard options.
    - Verify existing As Of dirty/run-report callback behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 201) 2026-07-16 03:30:44 PM +05:30 - AR Aging Summary By Invoice Due Date -> Aging By dropdown standardization

- Scope:
    - Reports -> Receivables -> AR Aging Summary By Invoice Due Date -> Aging By filter.
- Root cause:
    - The Aging By filter used a static ReportFilterChip with cycle-on-click behaviour, so it did not display the shared searchable dropdown, search field, selected tick, or standard blue hover/selected row styling shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/ar_aging_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown with the existing Reports popup, search field, hover styling, selected state, tick icon, and scrollbar behaviour.
- Validation:
    - Verify Aging By opens the shared searchable dropdown with Invoice Due Date and Invoice Date in order.
    - Verify selecting an option preserves the existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 202) 2026-07-16 03:39:36 PM +05:30 - AR Aging Summary By Invoice Due Date -> Entities dropdown standardization

- Scope:
    - Reports -> Receivables -> AR Aging Summary By Invoice Due Date -> Entities filter.
- Root cause:
    - The Entities filter used a static ReportFilterChip with cycle-on-click behaviour, so it did not display the shared searchable multi-select popup, search field, blue checkbox styling, or preserved multi-select state shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/ar_aging_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportEntitiesFilter with the existing Reports multi-select popup, search field, blue checkbox styling, hover behaviour, selected-state handling, and scrollbar behaviour.
- Validation:
    - Verify Entities opens the shared searchable multi-select dropdown with Invoice, Credit Note, and Journal selected by default.
    - Verify individual entity selection/deselection preserves selected values and marks the report filters dirty.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 203) 2026-07-16 03:47:18 PM +05:30 - Receivables -> AR Aging Details -> As Of dropdown

- Scope:
    - Reports -> Receivables -> AR Aging Details -> As Of filter.
- Root cause:
    - The AR Aging Details As Of filter used a static ReportFilterChip, so it did not open the shared Reports Date Range popup or reuse the standard preset option list/interactions.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/ar_aging_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter with the common ReportDateRangePresets option source, popup styling, hover behaviour, selected state, and scroll behaviour.
- Validation:
    - Verify AR Aging Details As Of opens the common Reports Date Range dropdown with standard options.
    - Verify existing As Of dirty/run-report callback behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 204) 2026-07-16 03:53:54 PM +05:30 - AR Aging Details -> Aging By dropdown standardization

- Scope:
    - Reports -> Receivables -> AR Aging Details -> Aging By filter.
- Root cause:
    - The Aging By filter used a static ReportFilterChip with cycle-on-click behaviour, so it did not display the shared searchable dropdown, search field, selected tick, or standard blue hover/selected row styling shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/ar_aging_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown with the existing Reports popup, search field, hover styling, selected state, tick icon, and scrollbar behaviour.
- Validation:
    - Verify Aging By opens the shared searchable dropdown with Invoice Due Date and Invoice Date in order.
    - Verify selecting an option preserves the existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 205) 2026-07-16 03:59:33 PM +05:30 - AR Aging Details -> Entities dropdown standardization

- Scope:
    - Reports -> Receivables -> AR Aging Details -> Entities filter.
- Root cause:
    - The Entities filter used a static ReportFilterChip with cycle-on-click behaviour, so it did not display the shared searchable multi-select popup, search field, blue checkbox styling, or preserved multi-select state shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/ar_aging_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportEntitiesFilter with the existing Reports multi-select popup, search field, blue checkbox styling, hover behaviour, selected-state handling, and scrollbar behaviour.
- Validation:
    - Verify Entities opens the shared searchable multi-select dropdown with options derived from the existing AR Aging Details rows.
    - Verify individual entity selection/deselection preserves selected values and marks the report filters dirty.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 206) 2026-07-16 04:05:36 PM +05:30 - AR Aging Details -> Entities dropdown option correction

- Scope:
    - Reports -> Receivables -> AR Aging Details -> Entities filter options.
- Root cause:
    - The previous AR Aging Details Entities standardization used the existing row transaction types as the option source. The corrected reference requires the report entity filter options to show Invoice, Credit Note, and Journal, with Invoice selected by default.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/ar_aging_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Continued reusing ReportEntitiesFilter for the searchable multi-select popup, search field, blue checkbox styling, hover behaviour, selected-state handling, and scrollbar behaviour.
- Validation:
    - Verify Entities opens the shared multi-select dropdown with Invoice selected and Credit Note/Journal available unchecked.
    - Verify selection/deselection behaviour and dirty-filter marking remain unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 207) 2026-07-16 04:12:24 PM +05:30 - Receivables -> Invoice Details -> Date Range dropdown

- Scope:
    - Reports -> Receivables -> Invoice Details -> Date Range filter.
- Root cause:
    - The Invoice Details Date Range filter used a static ReportFilterChip, so it did not open the shared Reports Date Range popup or reuse the standard preset option list/interactions.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/invoice_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter with the common ReportDateRangePresets option source, popup styling, hover behaviour, selected state, and scroll behaviour.
- Validation:
    - Verify Invoice Details Date Range opens the common Reports Date Range dropdown with standard options.
    - Verify existing Date Range dirty/run-report callback behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 208) 2026-07-16 04:17:45 PM +05:30 - Receivables -> Invoice Details -> Report By dropdown

- Scope:
    - Reports -> Receivables -> Invoice Details -> Report By filter.
- Root cause:
    - The Invoice Details Report By filter used a static ReportFilterChip with cycle-on-click behaviour, so it did not display the shared searchable dropdown, search field, selected tick, or standard blue hover/selected row styling shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/invoice_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown with the existing Reports popup, search field, hover styling, selected state, tick icon, and scrollbar behaviour.
- Validation:
    - Verify Report By opens the shared searchable dropdown with Invoice Date and Invoice Due Date in order.
    - Verify selecting an option preserves the existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 209) 2026-07-16 04:24:32 PM +05:30 - Receivables -> Retainer Invoice Details -> Date Range dropdown

- Scope:
    - Reports -> Receivables -> Retainer Invoice Details -> Date Range filter.
- Root cause:
    - The Retainer Invoice Details Date Range filter used a static ReportFilterChip, so it did not open the shared Reports Date Range popup or reuse the standard preset option list/interactions.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/retainer_invoice_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter with the common ReportDateRangePresets option source, popup styling, hover behaviour, selected state, and scroll behaviour.
- Validation:
    - Verify Retainer Invoice Details Date Range opens the common Reports Date Range dropdown with standard options.
    - Verify existing Date Range dirty/run-report callback behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 210) 2026-07-16 04:32:37 PM +05:30 - Receivables -> Sales Order Details -> Date Range dropdown

- Scope:
    - Reports -> Receivables -> Sales Order Details -> Date Range filter.
- Root cause:
    - The Sales Order Details Date Range filter used a static ReportFilterChip, so it did not open the shared Reports Date Range popup or reuse the standard preset option list/interactions.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/sales_order_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter with the common ReportDateRangePresets option source, popup styling, hover behaviour, selected state, and scroll behaviour.
- Validation:
    - Verify Sales Order Details Date Range opens the common Reports Date Range dropdown with standard options.
    - Verify existing Date Range dirty/run-report callback behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 211) 2026-07-16 04:38:34 PM +05:30 - Receivables -> Sales Order Details -> Status dropdown standardization

- Scope:
    - Reports -> Receivables -> Sales Order Details -> Status filter.
- Root cause:
    - The Status filter used a static ReportFilterChip with cycle-on-click behaviour, so it did not display the shared searchable dropdown, search field, selected tick, or standard blue hover/selected row styling shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/sales_order_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown with the existing Reports popup, search field, hover styling, selected state, tick icon, and scrollbar behaviour.
- Validation:
    - Verify Status opens the shared searchable dropdown with the existing All, Open, Closed, and Draft options.
    - Verify selecting an option preserves the existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 212) 2026-07-16 04:43:10 PM +05:30 - Sales Order Details -> Status multi-select design correction

- Scope:
    - Reports -> Receivables -> Sales Order Details -> Status filter.
- Root cause:
    - The previous Status dropdown used the shared single-select searchable dropdown, but the attached reference shows the existing checkbox-style searchable multi-select popup with Sales Order and Invoice status options.
- Files modified:
    - lib/modules/reports/presentation/widgets/report_entities_filter.dart
    - lib/modules/reports/receivables/presentation/pages/sales_order_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportEntitiesFilter for the checkbox-style searchable popup and added a backward-compatible label parameter so existing Entities filters remain unchanged.
- Validation:
    - Verify Sales Order Details Status opens the shared checkbox-style searchable dropdown with the reference status options.
    - Verify selected values are preserved and dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 213) 2026-07-16 04:51:51 PM +05:30 - Receivables -> Delivery Challan Details -> Date Range dropdown

- Scope:
    - Reports -> Receivables -> Delivery Challan Details -> Date Range filter.
- Root cause:
    - The Delivery Challan Details Date Range filter used a static ReportFilterChip, so it did not open the shared Reports Date Range popup or reuse the standard preset option list/interactions.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/delivery_challan_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter with the common ReportDateRangePresets option source, popup styling, hover behaviour, selected state, and scroll behaviour.
- Validation:
    - Verify Delivery Challan Details Date Range opens the common Reports Date Range dropdown with standard options.
    - Verify existing Date Range dirty/run-report callback behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 214) 2026-07-16 04:58:34 PM +05:30 - Reports overlay lifecycle disposed-view guard

- Scope:
    - Reports shared overlay widgets used by Date Range filters, multi-select filters, expanded filter panels, and report tooltips.
- Root cause:
    - Several Reports overlay widgets could still insert, rebuild, focus, or measure overlay content from delayed/post-frame callbacks after the owning page was disposed. On Flutter web this can surface as a disposed EngineFlutterView render assertion.
- Files modified:
    - lib/modules/reports/presentation/widgets/report_date_range_filter.dart
    - lib/modules/reports/presentation/widgets/report_entities_filter.dart
    - lib/modules/reports/presentation/widgets/report_filter_bar.dart
    - lib/modules/reports/presentation/widgets/report_tooltip.dart
    - lib/modules/reports/reportslog.md
- Lifecycle fix:
    - Added mounted/disposal guards around overlay insertion, overlay rebuilds, delayed focus requests, overlay builders, and root overlay lookup.
- Validation:
    - Verify report dropdowns and tooltips still open normally.
    - Verify closing/navigating away with an open Reports overlay no longer schedules stale overlay work.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 215) 2026-07-17 08:20:04 AM +05:30 - Receivables -> Quote Details -> Date Range dropdown

- Scope:
    - Reports -> Receivables -> Quote Details -> Date Range filter.
- Root cause:
    - The Quote Details Date Range filter used a static ReportFilterChip, so it did not open the shared Reports Date Range popup or reuse the standard preset option list/interactions.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/quote_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter with the common ReportDateRangePresets option source, popup styling, hover behaviour, selected state, and scroll behaviour.
- Validation:
    - Verify Quote Details Date Range opens the common Reports Date Range dropdown with standard options.
    - Verify existing Date Range dirty/run-report callback behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 216) 2026-07-17 08:29:35 AM +05:30 - Receivables -> Quote Details -> Report By dropdown

- Scope:
    - Reports -> Receivables -> Quote Details -> Report By filter.
- Root cause:
    - The Quote Details Report By filter used a static ReportFilterChip with cycle-on-click behaviour, so it did not display the shared searchable dropdown, search field, selected tick, or standard blue hover/selected row styling shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/quote_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown with the existing Reports popup, search field, hover styling, selected state, tick icon, and scrollbar behaviour.
- Validation:
    - Verify Report By opens the shared searchable dropdown with Quote Date, Expiry Date, and Created Time in order.
    - Verify selecting an option preserves the existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 217) 2026-07-17 08:38:14 AM +05:30 - Customer Balance Summary -> Stock Movement Date Range alignment

- Scope:
    - Reports -> Receivables -> Customer Balance Summary -> Date Range filter aligned with Inventory -> Stock Movement.
- Root cause:
    - Customer Balance Summary used a static ReportFilterChip for Date Range, so it did not match the combined Stock Movement Date Range control with a searchable filter-type selector and shared Date Range value dropdown.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/customer_balance_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused the same ReportSearchableFilterDropdown plus ReportDateRangeFilter combined-control implementation used by Inventory -> Stock Movement.
- Validation:
    - Verify Customer Balance Summary Date Range visually matches Inventory -> Stock Movement.
    - Verify both combined-control dropdown sections open independently and preserve existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 218) 2026-07-17 08:50:29 AM +05:30 - Receivable Summary -> Stock Movement Date Range alignment

- Scope:
    - Reports -> Receivables -> Receivable Summary -> Date Range filter aligned with Inventory -> Stock Movement Summary.
- Root cause:
    - Receivable Summary used a static ReportFilterChip for Date Range, so it did not match the combined Stock Movement Summary Date Range control with a searchable filter-type selector and shared Date Range value dropdown.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/receivable_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused the same ReportSearchableFilterDropdown plus ReportDateRangeFilter combined-control implementation used by Inventory -> Stock Movement Summary.
- Validation:
    - Verify Receivable Summary Date Range visually matches Inventory -> Stock Movement Summary.
    - Verify both combined-control dropdown sections open independently and preserve existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 219) 2026-07-17 08:58:13 AM +05:30 - Receivable Summary -> Common Date Range dropdown

- Scope:
    - Reports -> Receivables -> Receivable Summary -> Date Range filter corrected to the common Reports Date Range dropdown.
- Root cause:
    - Receivable Summary was aligned to the Stock Movement/Customer Balance combined control, but this report should use the standard standalone common Reports Date Range dropdown.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/receivable_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter, the common Reports Date Range dropdown used by standardized report pages.
- Validation:
    - Verify Receivable Summary Date Range uses the common dropdown instead of the combined Stock Movement-style control.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 220) 2026-07-17 09:06:48 AM +05:30 - Receivable Summary -> Entity dropdown standardization

- Scope:
    - Reports -> Receivables -> Receivable Summary -> Entity dropdown.
- Root cause:
    - Receivable Summary used a static cycling ReportFilterChip for Entities, so it did not show the shared searchable multi-select popup, search field, checkbox styling, or persistent selections shown in the reference.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/receivable_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportEntitiesFilter, the shared Reports searchable multi-select dropdown with checkbox rows and search filtering.
- Validation:
    - Verify Entity dropdown shows the shared searchable multi-select popup.
    - Verify options are derived from the current Receivable Summary row data and selection changes mark filters dirty.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 221) 2026-07-17 09:14:44 AM +05:30 - Receivable Details -> Date Range and Entity dropdown standardization

- Scope:
    - Reports -> Receivables -> Receivable Details -> Date Range and Entity filters standardized to match Receivable Summary.
- Root cause:
    - Receivable Details used static ReportFilterChip controls for Date Range and Entities, so it did not reuse Receivable Summary's common Date Range dropdown or shared searchable multi-select Entity dropdown.
- Files modified:
    - lib/modules/reports/receivables/presentation/pages/receivable_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widgets reused:
    - Reused ReportDateRangeFilter and ReportEntitiesFilter, matching the implementations used by Receivable Summary.
- Validation:
    - Verify Date Range and Entity dropdowns visually match Receivable Summary.
    - Verify Entity options are derived from existing Receivable Details row data and selection changes mark filters dirty.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 222) 2026-07-17 09:25:00 AM +05:30 - Payments Received -> Stock Movement Date Range alignment

- Scope:
    - Reports -> Receivables -> Payments Received -> Payments Received -> Date Range filter aligned with Inventory -> Stock Movement Summary.
- Root cause:
    - Payments Received used a static ReportFilterChip for Date Range, so it did not match the combined Stock Movement Summary Date Range control with a searchable filter-type selector and shared Date Range value dropdown.
- Files modified:
    - lib/modules/reports/payments_received/presentation/pages/payments_received_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused the same ReportSearchableFilterDropdown plus ReportDateRangeFilter combined-control implementation used by Inventory -> Stock Movement Summary.
- Validation:
    - Verify Payments Received Date Range visually matches Inventory -> Stock Movement Summary.
    - Verify both combined-control dropdown sections open independently and preserve existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 223) 2026-07-17 09:31:54 AM +05:30 - Payments Received -> Common Date Range dropdown

- Scope:
    - Reports -> Receivables -> Payments Received -> Payments Received -> Date Range filter corrected to the common Reports Date Range dropdown.
- Root cause:
    - Payments Received was aligned to the Stock Movement combined control, but this report should use the standard standalone common Reports Date Range dropdown.
- Files modified:
    - lib/modules/reports/payments_received/presentation/pages/payments_received_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter, the common Reports Date Range dropdown used by standardized report pages.
- Validation:
    - Verify Payments Received Date Range uses the common dropdown instead of the combined Stock Movement-style control.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 224) 2026-07-17 09:39:38 AM +05:30 - Payments Received -> Transaction Type dropdown standardization

- Scope:
    - Reports -> Receivables -> Payments Received -> Payments Received -> Transaction Type dropdown.
- Root cause:
    - Payments Received used a static cycling ReportFilterChip for Transaction Type, so it did not show the shared searchable dropdown, search field, blue selected row, or blue selected tick shown in the reference.
- Files modified:
    - lib/modules/reports/payments_received/presentation/pages/payments_received_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown, the shared Reports searchable single-select dropdown.
- Validation:
    - Verify Transaction Type opens the shared searchable dropdown with the existing options unchanged.
    - Verify selecting an option preserves existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 225) 2026-07-17 09:45:23 AM +05:30 - Payments Received -> Transaction Type option labels

- Scope:
    - Reports -> Receivables -> Payments Received -> Payments Received -> Transaction Type dropdown option labels.
- Root cause:
    - Payments Received reused the shared searchable dropdown, but its page-local Transaction Type options still showed Payment and Refund instead of the reference labels Invoice Payment and Retainer Payment.
- Files modified:
    - lib/modules/reports/payments_received/presentation/pages/payments_received_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Continued reusing ReportSearchableFilterDropdown with the existing shared popup, search, hover, selected row, and tick styling.
- Validation:
    - Verify Transaction Type opens the shared searchable dropdown with All, Invoice Payment, and Retainer Payment in order.
    - Verify selecting an option preserves existing dirty-filter/run-report behaviour.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 226) 2026-07-17 09:49:53 AM +05:30 - Payments Received -> Transaction Type dropdown height

- Scope:
    - Reports -> Receivables -> Payments Received -> Payments Received -> Transaction Type dropdown popup height.
- Root cause:
    - The page-level Transaction Type dropdown configuration used a compact menuMaxHeight, making the shared searchable popup feel too short for the reference layout.
- Files modified:
    - lib/modules/reports/payments_received/presentation/pages/payments_received_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Continued reusing ReportSearchableFilterDropdown; only the Payments Received page-level menuMaxHeight was adjusted.
- Validation:
    - Verify Transaction Type popup has more vertical space and keeps the shared search, hover, selected row, and tick styling.
    - Verify existing dropdown options and callback behaviour remain unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 227) 2026-07-17 10:01:41 AM +05:30 - Payments Received -> Credit Note Details -> Common Date Range dropdown

- Scope:
    - Reports -> Payments Received -> Credit Note Details -> Date Range filter.
- Root cause:
    - Credit Note Details used a static ReportFilterChip for Date Range, so it did not reuse the common Reports Date Range dropdown used by most report pages.
- Files modified:
    - lib/modules/reports/payments_received/presentation/pages/credit_note_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter, the common Reports Date Range dropdown implementation.
- Validation:
    - Verify Credit Note Details Date Range uses the common Reports dropdown styling and popup behaviour.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 228) 2026-07-17 10:09:32 AM +05:30 - Payments Received -> Refund History -> Common Date Range dropdown

- Scope:
    - Reports -> Payments Received -> Refund History -> Date Range filter.
- Root cause:
    - Refund History used a static ReportFilterChip for Date Range, so it did not reuse the common Reports Date Range dropdown used by most report pages.
- Files modified:
    - lib/modules/reports/payments_received/presentation/pages/refund_history_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter, the common Reports Date Range dropdown implementation.
- Validation:
    - Verify Refund History Date Range uses the common Reports dropdown styling and popup behaviour.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 229) 2026-07-17 11:07:47 AM +05:30 - Report table header typography standardization

- Scope:
    - Reports module table header typography and density alignment with Purchases -> Purchase Orders.
- Root cause:
    - Reports table headers used AppTheme.tableHeader at 13px/600 across report-specific table widgets, while Purchase Orders uses the denser 12px metaHelper-based header typography.
- Files modified:
    - lib/modules/reports/presentation/widgets/report_table_typography.dart
    - Reports table/header files across Activity, Business Overview, Sales, Receivables, Payments Received, Payables, Purchases & Expenses, Inventory, Inventory Valuation, Recurring Invoices, Reports Center, and Reports shared widgets were migrated from AppTheme.tableHeader to the Reports-only typography helper.
    - lib/modules/reports/reportslog.md
- Shared typography reused:
    - Reused AppTheme.metaHelper with Purchase Orders header weight through ReportTableTypography.header; no global theme or Purchase Orders files were modified.
- Validation:
    - Verified old AppTheme.tableHeader text-style references were removed from Reports while AppTheme.tableHeaderBg color references remained unchanged.
    - Verified the change is typography-only: no backend, provider, filtering, pagination, export, print, sorting, row data, row layout, column ordering, or color changes were intentionally made.
    - Verified flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 230) 2026-07-17 11:45:17 AM +05:30 - Reports dropdown popup positioning

- Scope:
    - Reports module filter dropdown popup positioning for Reports-owned overlays.
- Root cause:
    - Reports-owned popup overlays used local x-offset clamping or centered alignment, so dropdowns did not consistently prefer opening toward available right-side space before falling back left.
- Files modified:
    - lib/modules/reports/presentation/widgets/report_popup_positioning.dart
    - lib/modules/reports/presentation/widgets/report_date_range_filter.dart
    - lib/modules/reports/presentation/widgets/report_entities_filter.dart
    - lib/modules/reports/presentation/widgets/report_group_by_section.dart
    - lib/modules/reports/presentation/widgets/report_compare_section.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Added a Reports-only popup positioning helper and reused it from existing Reports-owned overlay dropdown widgets; global/shared FormDropdown remains unmodified per approval boundary.
- Validation:
    - Verify Reports-owned filter popups open toward the right when space is available, fall back left near viewport edges, and remain visible without clipping.
    - Verify existing dropdown styling, contents, selection, search, callbacks, filtering, and report generation remain unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 231) 2026-07-17 12:16:23 PM +05:30 - Recurring Invoice Details -> Common Date Range dropdown

- Scope:
    - Reports -> Recurring Invoices -> Recurring Invoice Details -> Date Range filter.
- Root cause:
    - Recurring Invoice Details used a static ReportFilterChip for Date Range, so it did not reuse the common Reports Date Range dropdown used by most report pages.
- Files modified:
    - lib/modules/reports/recurring_invoices/presentation/pages/recurring_invoice_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter, the common Reports Date Range dropdown implementation.
- Validation:
    - Verify Recurring Invoice Details Date Range uses the common Reports dropdown styling and popup behaviour.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 232) 2026-07-17 12:22:46 PM +05:30 - Recurring Invoice Details -> Report By dropdown standardization

- Scope:
    - Reports -> Recurring Invoices -> Recurring Invoice Details -> Report By filter.
- Root cause:
    - Recurring Invoice Details used a static ReportFilterChip for Report By, so it did not reuse the shared searchable single-select Reports dropdown.
- Files modified:
    - lib/modules/reports/recurring_invoices/presentation/pages/recurring_invoice_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown with the existing shared searchable popup, hover, selected row, and blue tick styling.
- Validation:
    - Verify Report By opens the shared searchable dropdown with Next Invoice Date, Last Invoice Date, and Expiry Date.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 233) 2026-07-17 12:25:20 PM +05:30 - Recurring Invoice Details -> Report By dropdown height

- Scope:
    - Reports -> Recurring Invoices -> Recurring Invoice Details -> Report By dropdown popup height.
- Root cause:
    - The page-level Report By dropdown configuration used a compact menuMaxHeight, making the shared searchable popup feel too short for the search field plus all options.
- Files modified:
    - lib/modules/reports/recurring_invoices/presentation/pages/recurring_invoice_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Continued reusing ReportSearchableFilterDropdown; only the Recurring Invoice Details page-level menuMaxHeight was adjusted.
- Validation:
    - Verify Report By popup has more vertical space and keeps the shared search, hover, selected row, and tick styling.
    - Verify existing dropdown options and callback behaviour remain unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 234) 2026-07-17 12:36:12 PM +05:30 - Vendor Balance Summary -> Stock Movement Date Range reuse

- Scope:
    - Reports -> Payables -> Vendor Balance Summary -> Date Range filter.
- Root cause:
    - Vendor Balance Summary used a static ReportFilterChip for Date Range, so it did not reuse the combined Stock Movement Date Range control requested as the reference.
- Files modified:
    - lib/modules/reports/payables/presentation/pages/vendor_balance_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused the same ReportSearchableFilterDropdown plus ReportDateRangeFilter combined-control implementation used by Inventory -> Stock Movement.
- Validation:
    - Verify Vendor Balance Summary Date Range visually matches the Stock Movement combined filter control.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 235) 2026-07-17 12:49:39 PM +05:30 - AP Aging Details -> As Of dropdown standardization

- Scope:
    - Reports -> Payables -> AP Aging Details -> As Of filter.
- Root cause:
    - AP Aging Details used a static ReportFilterChip for As Of, so it did not reuse the common Reports Date Range dropdown used by standardized As Of filters elsewhere.
- Files modified:
    - lib/modules/reports/payables/presentation/pages/ap_aging_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter, the common Reports dropdown implementation for date/as-of filters.
- Validation:
    - Verify AP Aging Details As Of opens the common Reports dropdown with standard options, hover state, selected row, and popup styling.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 236) 2026-07-17 12:54:02 PM +05:30 - AP Aging Summary -> As Of dropdown standardization

- Scope:
    - Reports -> Payables -> AP Aging Summary -> As Of filter.
- Root cause:
    - AP Aging Summary used a static ReportFilterChip for As Of, so it did not reuse the common Reports Date Range dropdown used by standardized As Of filters elsewhere.
- Files modified:
    - lib/modules/reports/payables/presentation/pages/ap_aging_summary_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportDateRangeFilter, the common Reports dropdown implementation for date/as-of filters.
- Validation:
    - Verify AP Aging Summary As Of opens the common Reports dropdown with standard options, hover state, selected row, and popup styling.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 237) 2026-07-17 02:02:56 PM +05:30 - AP Aging Details -> Aging By dropdown standardization

- Scope:
    - Reports -> Payables -> AP Aging Details -> Aging By filter.
- Root cause:
    - AP Aging Details used a static cycling ReportFilterChip for Aging By, so it did not reuse the shared searchable single-select Reports dropdown used by standardized Aging By filters elsewhere.
- Files modified:
    - lib/modules/reports/payables/presentation/pages/ap_aging_details_page.dart
    - lib/modules/reports/reportslog.md
- Shared widget reused:
    - Reused ReportSearchableFilterDropdown with the existing shared searchable popup, hover, selected row, and blue tick styling.
- Validation:
    - Verify Aging By opens the shared searchable dropdown with Bill Due Date and Bill Date options.
    - Verify existing dirty-filter/run-report behaviour remains unchanged.
    - Verify flutter analyze lib/modules/reports --no-pub passes.
- flutter analyze results:
    - Passed: flutter analyze lib/modules/reports --no-pub reported no issues.

## 238) 2026-07-17 02:11:07 PM +05:30 - AP Aging Details -> Entity dropdown standardization

- Timestamp: 2026-07-17 02:11:07 PM +05:30
- Scope: AP Aging Details -> Entity dropdown standardization
- Root cause: The Entity filter used a static cycling `ReportFilterChip`, so it could not render the shared searchable dropdown popup with checkbox rows shown in the Reports reference.
- Files modified: `lib/modules/reports/payables/presentation/pages/ap_aging_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportEntitiesFilter` from the Reports module.
- Validation: Passed: Entity filter now reuses `ReportEntitiesFilter` with the reference searchable checkbox popup and preserves existing dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 239) 2026-07-17 02:29:09 PM +05:30 - Bill Details -> Common Date Range dropdown

- Timestamp: 2026-07-17 02:29:09 PM +05:30
- Scope: Bill Details -> Common Date Range dropdown
- Root cause: Bill Details used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown used by standardized report pages.
- Files modified: `lib/modules/reports/payables/presentation/pages/bill_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Bill Details Date Range now reuses `ReportDateRangeFilter` and preserves existing dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 240) 2026-07-17 02:38:49 PM +05:30 - Bill Details -> Report By dropdown standardization

- Timestamp: 2026-07-17 02:38:49 PM +05:30
- Scope: Bill Details -> Report By dropdown standardization
- Root cause: Bill Details used a static cycling `ReportFilterChip` for Report By, so it did not reuse the shared searchable single-select Reports dropdown shown in the reference.
- Files modified: `lib/modules/reports/payables/presentation/pages/bill_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportSearchableFilterDropdown` from the Reports module.
- Validation: Passed: Bill Details Report By now reuses `ReportSearchableFilterDropdown` with the reference searchable popup, selected row, and blue tick styling.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 241) 2026-07-17 02:47:18 PM +05:30 - Vendor Credit Details UI standardization

- Timestamp: 2026-07-17 02:47:18 PM +05:30
- Scope: Vendor Credit Details UI standardization
- Root cause: Vendor Credits Details used a static Date Range chip and an empty-state table, so it did not match the reference populated report layout.
- Files modified: `lib/modules/reports/payables/presentation/pages/vendor_credits_details_page.dart`, `lib/modules/reports/payables/presentation/widgets/vendor_credits_details_table.dart`, `lib/modules/reports/reportslog.md`
- Shared widgets reused: `ReportViewScaffold`, `ReportDateRangeFilter`, `ReportMoreFiltersPanel`, `ReportTextActionButton`, `ReportCustomizeColumnsButton`, Reports table typography, and Reports pagination/table styling primitives.
- Validation: Passed: Vendor Credits Details now uses the shared Date Range dropdown and renders the reference table row plus total row with existing Reports table styling.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 242) 2026-07-17 02:56:47 PM +05:30 - Vendor Credit Details empty-state table headers

- Timestamp: 2026-07-17 02:56:47 PM +05:30
- Scope: Vendor Credit Details empty-state table headers
- Root cause: Vendor Credits Details did not branch through the shared empty table body pattern, so zero-record rendering could lose the standard headers/body/footer structure.
- Files modified: `lib/modules/reports/payables/presentation/widgets/vendor_credits_details_table.dart`, `lib/modules/reports/reportslog.md`
- Shared widgets reused: `ReportTableEmptyBody` and `ReportPaginationFooter` from the Reports module.
- Validation: Passed: Vendor Credits Details now keeps table headers visible for zero records and renders the shared `ReportTableEmptyBody` plus `ReportPaginationFooter` inside the table layout.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 243) 2026-07-17 03:11:07 PM +05:30 - Payments Made -> Common Date Range dropdown

- Timestamp: 2026-07-17 03:11:07 PM +05:30
- Scope: Payments Made -> Common Date Range dropdown
- Root cause: Payments Made used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown used by standardized report pages.
- Files modified: `lib/modules/reports/payables/presentation/pages/payments_made_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Payments Made Date Range now reuses `ReportDateRangeFilter` and preserves existing dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 244) 2026-07-17 03:16:38 PM +05:30 - Payables Refund History -> Common Date Range dropdown

- Timestamp: 2026-07-17 03:16:38 PM +05:30
- Scope: Payables Refund History -> Common Date Range dropdown
- Root cause: Payables Refund History used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown used by standardized report pages.
- Files modified: `lib/modules/reports/payables/presentation/pages/refund_history_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Payables Refund History Date Range now reuses `ReportDateRangeFilter` and preserves existing dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 245) 2026-07-17 03:25:05 PM +05:30 - Purchase Order Details -> Common Date Range dropdown

- Timestamp: 2026-07-17 03:25:05 PM +05:30
- Scope: Purchase Order Details -> Common Date Range dropdown
- Root cause: Purchase Order Details used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown used by standardized report pages.
- Files modified: `lib/modules/reports/payables/presentation/pages/purchase_order_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Purchase Order Details Date Range now reuses `ReportDateRangeFilter` and preserves existing dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 246) 2026-07-17 03:30:40 PM +05:30 - Purchase Orders by Vendor -> Common Date Range dropdown

- Timestamp: 2026-07-17 03:30:40 PM +05:30
- Scope: Purchase Orders by Vendor -> Common Date Range dropdown
- Root cause: Purchase Orders by Vendor used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown used by standardized report pages.
- Files modified: `lib/modules/reports/payables/presentation/pages/purchase_orders_by_vendor_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Purchase Orders by Vendor Date Range now reuses `ReportDateRangeFilter` and preserves existing dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 247) 2026-07-17 03:39:09 PM +05:30 - Payable Summary -> Common Date Range dropdown

- Timestamp: 2026-07-17 03:39:09 PM +05:30
- Scope: Payable Summary -> Common Date Range dropdown
- Root cause: Payable Summary used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown used by standardized report pages.
- Files modified: `lib/modules/reports/payables/presentation/pages/payable_summary_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Payable Summary Date Range now reuses `ReportDateRangeFilter` and preserves existing dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 248) 2026-07-17 03:54:24 PM +05:30 - Payments Made -> Entity dropdown standardization

- Timestamp: 2026-07-17 03:54:24 PM +05:30
- Scope: Payments Made -> Entity dropdown standardization
- Root cause: Payments Made did not render an Entity filter in the toolbar, so it could not match the shared searchable Reports entity dropdown shown in the reference.
- Files modified: `lib/modules/reports/payables/presentation/pages/payments_made_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportEntitiesFilter` from the Reports module.
- Validation: Passed: Payments Made now renders the shared Reports entity dropdown with preserved dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 249) 2026-07-17 04:00:28 PM +05:30 - Payable Details -> Entity dropdown standardization

- Timestamp: 2026-07-17 04:00:28 PM +05:30
- Scope: Payable Details -> Entity dropdown standardization
- Root cause: Payable Details used a static cycling `ReportFilterChip` for Entities, so it did not reuse the shared searchable Reports entity dropdown style.
- Files modified: `lib/modules/reports/payables/presentation/pages/payable_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportEntitiesFilter` from the Reports module.
- Validation: Passed: Payable Details now renders the shared Reports entity dropdown with preserved dirty-filter/run-report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 250) 2026-07-17 04:06:12 PM +05:30 - Payable Details -> Common Date Range dropdown

- Timestamp: 2026-07-17 04:06:12 PM +05:30
- Scope: Payable Details -> Common Date Range dropdown
- Root cause: Payable Details used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/payables/presentation/pages/payable_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Payable Details Date Range now reuses `ReportDateRangeFilter` with the existing Previous Year range preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 251) 2026-07-17 04:18:57 PM +05:30 - Purchases by Vendor report fixes

- Timestamp: 2026-07-17 04:18:57 PM +05:30
- Scope: Purchases by Vendor report fixes
- Root cause: The Purchases by Vendor table used `ListView.separated` which only renders dividers between rows, leaving no divider after the final Total row; the Date Range filter also used a static `ReportFilterChip` instead of the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/purchases_by_vendor_page.dart`, `lib/modules/reports/purchases_expenses/presentation/widgets/purchases_by_vendor_table.dart`, `lib/modules/reports/reportslog.md`
- Shared widgets reused: `ReportDateRangeFilter` from the Reports module; existing Reports table typography and border styling retained.
- Validation: Passed: final Total row now renders the bottom border and Date Range reuses `ReportDateRangeFilter` while preserving existing report behaviour.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 252) 2026-07-17 04:25:30 PM +05:30 - Purchases by Vendor -> Filter By dropdown standardization

- Timestamp: 2026-07-17 04:25:30 PM +05:30
- Scope: Purchases by Vendor -> Filter By dropdown standardization
- Root cause: Purchases by Vendor used a static cycling `ReportFilterChip` for Filter By, so it did not reuse the shared searchable Reports single-select dropdown style.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/purchases_by_vendor_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportSearchableFilterDropdown` from the Reports module.
- Validation: Passed: Filter By now reuses `ReportSearchableFilterDropdown` with existing filter state updates preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 253) 2026-07-17 04:40:41 PM +05:30 - Purchases by Item -> Common Date Range dropdown

- Timestamp: 2026-07-17 04:40:41 PM +05:30
- Scope: Purchases by Item -> Common Date Range dropdown
- Root cause: Purchases by Item used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/purchases_by_item_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Purchases by Item Date Range now reuses `ReportDateRangeFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 254) 2026-07-17 04:50:21 PM +05:30 - Expense Details -> Common Date Range dropdown

- Timestamp: 2026-07-17 04:50:21 PM +05:30
- Scope: Expense Details -> Common Date Range dropdown
- Root cause: Expense Details used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expense_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Expense Details Date Range now reuses `ReportDateRangeFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 255) 2026-07-17 04:57:54 PM +05:30 - Expense Details -> Entity dropdown standardization

- Timestamp: 2026-07-17 04:57:54 PM +05:30
- Scope: Expense Details -> Entity dropdown standardization
- Root cause: Expense Details used a static cycling `ReportFilterChip` for Entities, so it did not reuse the shared searchable Reports entity dropdown style shown in the reference.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expense_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportEntitiesFilter` from the Reports module.
- Validation: Passed: Expense Details Entity now reuses `ReportEntitiesFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 256) 2026-07-18 09:07:23 AM +05:30 - Expenses by Customer -> Common Date Range dropdown

- Timestamp: 2026-07-18 09:07:23 AM +05:30
- Scope: Expenses by Customer -> Common Date Range dropdown
- Root cause: Expenses by Customer used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expenses_by_customer_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Expenses by Customer Date Range now reuses `ReportDateRangeFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 257) 2026-07-18 09:16:12 AM +05:30 - Expense Summary by Category -> Common Date Range dropdown

- Timestamp: 2026-07-18 09:16:12 AM +05:30
- Scope: Expense Summary by Category -> Common Date Range dropdown
- Root cause: Expense Summary by Category used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expense_summary_by_category_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Expense Summary by Category Date Range now reuses `ReportDateRangeFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 258) 2026-07-18 09:24:04 AM +05:30 - Expenses by Project -> Common Date Range dropdown

- Timestamp: 2026-07-18 09:24:04 AM +05:30
- Scope: Expenses by Project -> Common Date Range dropdown
- Root cause: Expenses by Project used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expenses_by_project_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Expenses by Project Date Range now reuses `ReportDateRangeFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.


## 259) 2026-07-18 09:39:00 AM +05:30 - Expenses by Employee -> Common Date Range dropdown

- Timestamp: 2026-07-18 09:39:00 AM +05:30
- Scope: Expenses by Employee -> Common Date Range dropdown
- Root cause: Expenses by Employee used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expenses_by_employee_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Expenses by Employee Date Range now reuses `ReportDateRangeFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.


## 260) 2026-07-18 09:43:38 AM +05:30 - Billable Expense Details -> Common Date Range dropdown

- Timestamp: 2026-07-18 09:43:38 AM +05:30
- Scope: Billable Expense Details -> Common Date Range dropdown
- Root cause: Billable Expense Details used a static `ReportFilterChip` for Date Range, so it did not reuse the common Reports Date Range dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/billable_expense_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportDateRangeFilter` from the Reports module.
- Validation: Passed: Billable Expense Details Date Range now reuses `ReportDateRangeFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 261) 2026-07-18 09:57:17 AM +05:30 - Expense Summary by Category -> Filter By dropdown standardization

- Timestamp: 2026-07-18 09:57:17 AM +05:30
- Scope: Expense Summary by Category -> Filter By dropdown standardization
- Root cause: Expense Summary by Category used a static cycling `ReportFilterChip` for Filter By, so it did not reuse the shared searchable Reports single-select dropdown style.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expense_summary_by_category_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportSearchableFilterDropdown` from the Reports module.
- Validation: Passed: Expense Summary by Category Filter By now reuses `ReportSearchableFilterDropdown` with existing filter state updates preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 262) 2026-07-18 10:07:41 AM +05:30 - Billable Expense Details -> Entity dropdown standardization

- Timestamp: 2026-07-18 10:07:41 AM +05:30
- Scope: Billable Expense Details -> Entity dropdown standardization
- Root cause: Billable Expense Details used a static cycling `ReportFilterChip` for Entities, so it did not reuse the shared searchable Reports entity dropdown style shown in the reference.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/billable_expense_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportEntitiesFilter` from the Reports module.
- Validation: Passed: Billable Expense Details Entities now reuse `ReportEntitiesFilter` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 263) 2026-07-18 10:15:00 AM +05:30 - Billable Expense Details -> Entity dropdown reusable correction

- Timestamp: 2026-07-18 10:15:00 AM +05:30
- Scope: Billable Expense Details -> Entity dropdown reusable correction
- Root cause: The previous Billable Expense Details entity update reused the checkbox-style entity filter, but this report requires the standard searchable single-select Reports dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/billable_expense_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportSearchableFilterDropdown` from the Reports module.
- Validation: Passed: Billable Expense Details Entities now reuse `ReportSearchableFilterDropdown` with the original option list and existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 264) 2026-07-18 10:22:00 AM +05:30 - Billable Expense Details -> Entity checkbox dropdown correction

- Timestamp: 2026-07-18 10:22:00 AM +05:30
- Scope: Billable Expense Details -> Entity checkbox dropdown correction
- Root cause: Billable Expense Details was corrected to a single-select dropdown, but the required project reference uses the checkbox-style Reports entity dropdown.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/billable_expense_details_page.dart`, `lib/modules/reports/reportslog.md`
- Shared widget reused: `ReportEntitiesFilter` from the Reports module.
- Validation: Passed: Billable Expense Details Entities now use checkbox-style `ReportEntitiesFilter` with Bill and Expense options and existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 265) 2026-07-18 10:31:53 AM +05:30 - Expense Summary by Category -> Account Type dropdown reuse

- Timestamp: 2026-07-18 10:31:53 AM +05:30
- Scope: Expense Summary by Category -> Account Type dropdown reuse
- Root cause: Expense Summary by Category used a static cycling `ReportFilterChip` for Account Type, so it did not reuse the shared searchable Reports single-select dropdown style shown in the reference.
- Files modified: `lib/modules/reports/purchases_expenses/presentation/pages/expense_summary_by_category_page.dart`, `lib/modules/reports/reportslog.md`
- Reusable component reused: `ReportSearchableFilterDropdown` from the Reports module.
- Validation: Passed: Expense Summary by Category Account Type now reuses `ReportSearchableFilterDropdown` with existing dirty-filter/run-report behaviour preserved.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.

## 266) 2026-07-18 11:53:49 AM +05:30 - Remove Last Visited column

- Timestamp: 2026-07-18 11:53:49 AM +05:30
- Scope: Remove Last Visited column from the Reports landing page
- Root cause: The Reports landing page still rendered a Last Visited column and local last-visited lookup even though the column is no longer required.
- Files modified: `lib/modules/reports/presentation/reports_center_screen.dart`, `lib/modules/reports/reportslog.md`
- Shared widgets reused: Existing Reports landing page table/list layout retained; no shared widgets modified.
- Validation: Passed: Last Visited header, cells, local lookup, and report-row field were removed from the Reports landing page with remaining columns reflowing naturally.
- `flutter analyze`: Passed: `flutter analyze lib/modules/reports --no-pub` reported no issues.
## 267) 2026-07-18 01:13:17 PM +05:30 - Context-aware Reports back navigation

- Timestamp: 2026-07-18 01:13:17 PM +05:30
- Scope: Context-aware Reports back navigation
- Root cause: Report navigation mixed Reports-owned MaterialPageRoute pushes with GoRouter pushes for some report entries, and report pages relied on a simple Navigator pop for Back/Close. That inconsistency could lose the immediate report route context and fall back to unrelated app or browser history.
- Files modified: lib/modules/reports/presentation/reports_center_screen.dart, lib/modules/reports/reportslog.md
- Shared navigation reused: Existing Flutter Navigator route stack and the existing Reports openReportFromReportsModule helper.
- Validation: Passed: standard report-to-report navigation now uses the root Flutter Navigator stack, so Back/Close pops to the immediate originating report route while preserving the previous report widget state where Flutter already keeps it alive.
- flutter analyze: Passed: flutter analyze lib/modules/reports --no-pub reported no issues.
## 268) 2026-07-18 01:51:49 PM +05:30 - Reports browser back hierarchy

- Timestamp: 2026-07-18 01:51:49 PM +05:30
- Scope: Reports browser/system Back navigation hierarchy
- Root cause: Reports category selection was local widget state and most report selection used in-memory MaterialPageRoute pushes, so Chrome/system Back did not have URL-backed Reports category/report entries to traverse.
- Files modified: lib/modules/reports/presentation/reports_center_screen.dart; lib/modules/reports/config/routes.dart.
- Shared navigation reused: Existing GoRouter integration exposed by Reports-owned route config and existing Reports page mapping; existing Navigator fallback remains for unknown reports.
- Validation: Passed focused Reports validation. Category selections now push /reports/category/<category>; supported report selections now push /reports/category/<category>/report/<report> or existing report routes, so browser/system Back can traverse report -> category -> Reports when those entries were visited.
- flutter analyze: Full flutter analyze still reports pre-existing non-Reports handoff/pricelist/procurement/purchases issues; focused flutter analyze lib/modules/reports --no-pub passes with no issues.
