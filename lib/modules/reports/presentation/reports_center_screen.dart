import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/modules/reports/advanced_inventory/presentation/pages/batch_details_page.dart';
import 'package:zerpai_erp/modules/reports/advanced_inventory/presentation/pages/serial_number_details_page.dart';
import 'package:zerpai_erp/modules/reports/activity/presentation/pages/reports_system_mails_screen.dart';
import 'package:zerpai_erp/modules/reports/automation/presentation/pages/scheduled_date_based_workflow_rules_page.dart';
import 'package:zerpai_erp/modules/reports/automation/presentation/pages/scheduled_time_based_workflow_actions_page.dart';
import 'package:zerpai_erp/modules/reports/automation/presentation/pages/workflow_execution_logs_page.dart';
import 'package:zerpai_erp/modules/reports/banking/presentation/pages/reports_reconciliation_status_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_navigation_catalog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/reports_search_explorer.dart';
import '../business_overview/presentation/pages/reports_balance_sheet_screen.dart';
import '../accountant/presentation/pages/reports_account_type_summary_page.dart';
import '../accountant/presentation/pages/reports_account_type_transactions_page.dart';
import '../accountant/presentation/pages/reports_detailed_general_ledger_screen.dart';
import '../accountant/presentation/pages/reports_day_book_screen.dart';
import '../accountant/presentation/pages/reports_journal_report_screen.dart';
import '../business_overview/presentation/pages/reports_balance_sheet_schedule_iii_screen.dart';
import '../business_overview/presentation/pages/reports_business_performance_ratios_screen.dart';
import '../business_overview/presentation/pages/reports_cash_flow_statement_screen.dart';
import '../business_overview/presentation/pages/reports_horizontal_profit_and_loss_screen.dart';
import '../business_overview/presentation/pages/reports_horizontal_balance_sheet_screen.dart';
import '../business_overview/presentation/pages/reports_movement_of_equity_screen.dart';
import '../business_overview/presentation/pages/reports_profit_and_loss_schedule_iii_screen.dart';
import 'package:zerpai_erp/modules/reports/providers/sales_report_provider.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

import '../inventory/presentation/pages/assembly_details_page.dart';
import '../inventory/presentation/pages/committed_stock_details_page.dart';
import '../inventory/presentation/pages/inventory_aging_summary_page.dart';
import '../inventory/presentation/pages/inventory_adjustment_details_page.dart';
import '../inventory/presentation/pages/inventory_adjustment_summary_page.dart';
import '../inventory/presentation/pages/inventory_summary_page.dart';
import '../inventory/presentation/pages/inventory_turnover_by_quantity_page.dart';
import '../inventory/presentation/pages/stock_movement_page.dart';
import '../inventory/presentation/pages/stock_summary_page.dart';
import '../inventory_valuation/presentation/pages/abc_classification_page.dart';
import '../inventory_valuation/presentation/pages/fifo_cost_lot_tracking_page.dart';
import '../inventory_valuation/presentation/pages/inventory_turnover_by_amount_page.dart';
import '../inventory_valuation/presentation/pages/landed_cost_summary_page.dart';
import '../inventory_valuation/presentation/pages/weighted_average_costing_summary_page.dart';
import '../payables/presentation/pages/ap_aging_details_page.dart';
import '../payables/presentation/pages/ap_aging_summary_page.dart';
import '../payables/presentation/pages/bill_details_page.dart';
import '../payables/presentation/pages/payable_details_page.dart';
import '../payables/presentation/pages/payable_summary_page.dart';
import '../payables/presentation/pages/payments_made_page.dart';
import '../payables/presentation/pages/purchase_order_details_page.dart';
import '../payables/presentation/pages/purchase_orders_by_item_page.dart';
import '../payables/presentation/pages/purchase_orders_by_vendor_page.dart';
import '../payables/presentation/pages/refund_history_page.dart';
import '../payables/presentation/pages/vendor_balance_summary_page.dart';
import '../payables/presentation/pages/vendor_credits_details_page.dart';
import '../purchases_expenses/presentation/pages/billable_expense_details_page.dart';
import '../purchases_expenses/presentation/pages/expense_details_page.dart';
import '../purchases_expenses/presentation/pages/expense_summary_by_category_page.dart';
import '../purchases_expenses/presentation/pages/expenses_by_customer_page.dart';
import '../purchases_expenses/presentation/pages/expenses_by_employee_page.dart';
import '../purchases_expenses/presentation/pages/purchases_by_item_page.dart';
import '../purchases_expenses/presentation/pages/purchases_by_vendor_page.dart';
import '../receivables/presentation/pages/ar_aging_summary_page.dart';
import '../receivables/presentation/pages/customer_balance_summary_page.dart';
import '../receivables/presentation/pages/ar_aging_details_page.dart';
import '../receivables/presentation/pages/delivery_challan_details_page.dart';
import '../receivables/presentation/pages/invoice_details_page.dart';
import '../receivables/presentation/pages/quote_details_page.dart';
import '../receivables/presentation/pages/receivable_details_page.dart';
import '../receivables/presentation/pages/receivable_summary_page.dart';
import '../receivables/presentation/pages/retainer_invoice_details_page.dart';
import '../receivables/presentation/pages/sales_order_details_page.dart';
import '../payments_received/presentation/pages/credit_note_details_page.dart';
import '../payments_received/presentation/pages/payments_received_page.dart';
import '../payments_received/presentation/pages/refund_history_page.dart';
import '../payments_received/presentation/pages/time_to_get_paid_page.dart';
import '../recurring_invoices/presentation/pages/recurring_invoice_details_page.dart';

import '../sales/presentation/pages/sales_by_customer_customization_page.dart';
import '../sales/presentation/pages/sales_by_customer_transactions_page.dart';
import '../sales/presentation/pages/sales_by_item_page.dart';
import '../taxes/presentation/pages/reports_tax_summary_screen.dart';
import '../taxes/presentation/pages/reports_annual_summary_gstr9_screen.dart';
import '../taxes/presentation/pages/reports_tds_summary_screen.dart';
import '../taxes/presentation/pages/reports_tds_receivable_summary_screen.dart';
import '../taxes/presentation/pages/reports_gstr7_screen.dart';
import '../taxes/presentation/pages/reports_tcs_payable_summary_screen.dart';
import '../taxes/presentation/pages/reports_invoice_furnishing_facility_screen.dart';
import '../taxes/presentation/pages/reports_pmt06_screen.dart';
import '../taxes/presentation/pages/reports_gstr3b_summary_screen.dart';
import '../taxes/presentation/pages/reports_gstr1_outward_supplies_summary_screen.dart';
import '../taxes/presentation/pages/reports_gstr2_inward_supplies_summary_screen.dart';
import '../taxes/presentation/pages/reports_self_invoice_summary_screen.dart';
import '../taxes/presentation/pages/reports_kfca_summary_screen.dart';
import '../sales/presentation/pages/sales_by_salesperson_page.dart';
import '../sales/presentation/pages/sales_summary_page.dart';
import '../sales/presentation/pages/profit_by_item_page.dart';
import '../sales/presentation/pages/sales_channel_integrations_sync_summary_page.dart';
import '../sales/presentation/widgets/sales_by_customer_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

void openReportFromReportsModule(
  BuildContext context,
  String reportName, {
  String? category,
}) {
  final routePath = reportsReportRoutePath(reportName, category: category);
  if (routePath != null) {
    context.push(routePath);
    return;
  }
  if (category == 'Payables' && reportName == 'Refund History') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PayablesRefundHistoryPage()),
    );
  } else if (reportName == 'Account Transactions') {
    context.push(
      AppRoutes.accountantTransactionsReport,
      extra: {'accountId': 'all'},
    );
  } else if (reportName == 'Daily Sales') {
    context.push(AppRoutes.reportDailySales);
  } else if (reportName == 'Profit and Loss') {
    context.push(AppRoutes.profitAndLoss);
  } else if (reportName == 'Profit and Loss (Schedule III)') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfitAndLossScheduleIIIScreen()),
    );
  } else if (reportName == 'Horizontal Profit and Loss') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HorizontalProfitAndLossScreen()),
    );
  } else if (reportName == 'Cash Flow Statement') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CashFlowStatementScreen()));
  } else if (reportName == 'Balance Sheet') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BalanceSheetScreen()));
  } else if (reportName == 'Horizontal Balance Sheet') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HorizontalBalanceSheetScreen()),
    );
  } else if (reportName == 'Balance Sheet (Schedule III)') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BalanceSheetScheduleIIIScreen()),
    );
  } else if (reportName == 'Business Performance Ratios') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BusinessPerformanceRatiosScreen(),
      ),
    );
  } else if (reportName == 'Movement of Equity') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MovementOfEquityScreen()));
  } else if (reportName == 'General Ledger') {
    context.push(AppRoutes.generalLedger);
  } else if (reportName == 'Trial Balance') {
    context.push(AppRoutes.trialBalance);
  } else if (reportName == 'Sales by Customer') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SalesByCustomerScreen()));
  } else if (reportName == 'Sales by Item') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SalesByItemPage()));
  } else if (reportName == 'Sales by Sales Person') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SalesBySalespersonPage()));
  } else if (reportName == 'Sales Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SalesSummaryPage()));
  } else if (reportName == 'Profit By Item') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfitByItemPage()));
  } else if (reportName == 'Sales Channel Integrations Sync Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SalesChannelIntegrationsSyncSummaryPage(),
      ),
    );
  } else if (reportName == 'Inventory Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InventorySummaryPage()));
  } else if (reportName == 'Committed Stock Details') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommittedStockDetailsPage()),
    );
  } else if (reportName == 'Inventory Aging Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryAgingSummaryPage()),
    );
  } else if (reportName == 'Stock Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StockSummaryPage()));
  } else if (reportName == 'Assembly Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AssemblyDetailsPage()));
  } else if (reportName == 'Stock Movement') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StockMovementPage()));
  } else if (reportName == 'Inventory Adjustment Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryAdjustmentSummaryPage()),
    );
  } else if (reportName == 'Inventory Adjustment Details') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryAdjustmentDetailsPage()),
    );
  } else if (reportName == 'Inventory Turnover By Quantity') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InventoryTurnoverByQuantityPage(),
      ),
    );
  } else if (reportNavigationReportsByCategory['Inventory']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InventoryReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportName == 'Batch Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BatchDetailsPage()));
  } else if (reportName == 'Serial Number Details') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SerialNumberDetailsPage()),
    );
  } else if (reportNavigationReportsByCategory['Advanced Inventory']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryReportPlaceholderScreen(
          reportName: reportName,
          categoryLabel: 'Advanced Inventory',
        ),
      ),
    );
  } else if (reportName == 'Inventory Valuation Summary') {
    context.push(AppRoutes.inventoryValuation);
  } else if (reportName == 'FIFO Cost Lot Tracking') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FifoCostLotTrackingPage()));
  } else if (reportName == 'ABC classification' ||
      reportName == 'ABC Classification') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AbcClassificationPage()));
  } else if (reportName == 'Landed Cost Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LandedCostSummaryPage()));
  } else if (reportName == 'Inventory Turnover By Amount') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryTurnoverByAmountPage()),
    );
  } else if (reportName == 'Weighted Average Costing Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WeightedAverageCostingSummaryPage(),
      ),
    );
  } else if (reportName == 'AR Aging Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ArAgingSummaryPage()));
  } else if (reportName == 'AR Aging Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ArAgingDetailsPage()));
  } else if (reportName == 'Invoice Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InvoiceDetailsPage()));
  } else if (reportName == 'Retainer Invoice Details') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RetainerInvoiceDetailsPage()),
    );
  } else if (reportName == 'Sales Order Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SalesOrderDetailsPage()));
  } else if (reportName == 'Delivery Challan Details') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeliveryChallanDetailsPage()),
    );
  } else if (reportName == 'Quote Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuoteDetailsPage()));
  } else if (reportName == 'Customer Balance Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomerBalanceSummaryPage()),
    );
  } else if (reportName == 'Receivable Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReceivableSummaryPage()));
  } else if (reportName == 'Receivable Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReceivableDetailsPage()));
  } else if (reportNavigationReportsByCategory['Receivables']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReceivablesReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportName == 'Payments Received') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaymentsReceivedPage()));
  } else if (reportName == 'Time to Get Paid') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TimeToGetPaidPage()));
  } else if (reportName == 'Credit Note Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreditNoteDetailsPage()));
  } else if (reportName == 'Refund History') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RefundHistoryPage()));
  } else if (reportNavigationReportsByCategory['Payments Received']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PaymentsReceivedReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportName == 'Recurring Invoices' ||
      reportName == 'Recurring Invoice Details') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecurringInvoiceDetailsPage()),
    );
  } else if (reportNavigationReportsByCategory['Recurring Invoices']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RecurringInvoicesReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportName == 'Vendor Balance Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VendorBalanceSummaryPage()));
  } else if (reportName == 'Payable Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PayableSummaryPage()));
  } else if (reportName == 'Payable Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PayableDetailsPage()));
  } else if (reportName == 'AP Aging Summary') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ApAgingSummaryPage()));
  } else if (reportName == 'AP Aging Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ApAgingDetailsPage()));
  } else if (reportName == 'Bill Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BillDetailsPage()));
  } else if (reportName == 'Vendor Credit Details' ||
      reportName == 'Vendor Credits Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VendorCreditsDetailsPage()));
  } else if (reportName == 'Payments Made') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaymentsMadePage()));
  } else if (reportName == 'Purchase Order Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchaseOrderDetailsPage()));
  } else if (reportName == 'Purchase Orders by Vendor') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PurchaseOrdersByVendorPage()),
    );
  } else if (reportName == 'Purchase Orders by Item' ||
      reportName == 'Purchase Order by Item') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchaseOrdersByItemPage()));
  } else if (reportNavigationReportsByCategory['Payables']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PayablesReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportName == 'Expense Summary by Category' ||
      reportName == 'Expenses by Category') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpenseSummaryByCategoryPage()),
    );
  } else if (reportName == 'Expenses by Customer') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExpensesByCustomerPage()));
  } else if (reportName == 'Expenses by Employee') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExpensesByEmployeePage()));
  } else if (reportName == 'Billable Expense Details') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BillableExpenseDetailsPage()),
    );
  } else if (reportName == 'Expense Details') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExpenseDetailsPage()));
  } else if (reportName == 'Purchases by Item') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchasesByItemPage()));
  } else if (reportName == 'Purchases by Vendor') {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchasesByVendorPage()));
  } else if (reportNavigationReportsByCategory['Purchases and Expenses']
          ?.contains(reportName) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PurchasesExpensesReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportName == 'Tax Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TaxSummaryScreen()),
    );
  } else if (reportName == 'TDS Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TdsSummaryScreen()),
    );
  } else if (reportName == 'Annual Summary (GSTR-9)') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnnualSummaryGstr9Screen()),
    );
  } else if (reportName == 'TDS Receivable Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TdsReceivableSummaryScreen()),
    );
  } else if (reportName == 'GSTR-7 (Return for Tax Deducted at Source)') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Gstr7Screen()),
    );
  } else if (reportName == 'TCS Payable Summary (Form No. 27EQ)') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TcsPayableSummaryScreen()),
    );
  } else if (reportName == 'Invoice Furnishing Facility (IFF)') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InvoiceFurnishingFacilityScreen()),
    );
  } else if (reportName == 'PMT-06 (Self Assessment Basis)') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Pmt06Screen()),
    );
  } else if (reportName == 'GSTR-3B Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Gstr3bSummaryScreen()),
    );
  } else if (reportName == 'Summary of Outward Supplies') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Gstr1OutwardSuppliesSummaryScreen(),
      ),
    );
  } else if (reportName == 'Summary of Inward Supplies') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Gstr2InwardSuppliesSummaryScreen(),
      ),
    );
  } else if (reportName == 'Self-invoice Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelfInvoiceSummaryScreen()),
    );
  } else if (reportName == 'KFC-A Summary') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KfcaSummaryScreen()),
    );
  } else if (reportNavigationReportsByCategory['Taxes']?.contains(reportName) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaxesReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportNavigationReportsByCategory['Banking']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => reportName == 'Reconciliation Status'
            ? const ReconciliationStatusReportScreen()
            : BankingReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportNavigationReportsByCategory['Currency']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CurrencyReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportNavigationReportsByCategory['Activity']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => reportName == 'System Mails'
            ? const SystemMailsReportScreen()
            : ActivityReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportNavigationReportsByCategory['Automation']?.contains(
        reportName,
      ) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AutomationReportPlaceholderScreen(reportName: reportName),
      ),
    );
  } else if (reportNavigationReportsByCategory['Inventory Valuation']?.contains(reportName) ??
      false) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryReportPlaceholderScreen(
          reportName: reportName,
          categoryLabel: 'Inventory Valuation',
        ),
      ),
    );
  }
}

String reportsNavigationSlug(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('&', 'and');
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

List<String> get _reportsRouteCategories => <String>[
  'All Reports',
  'Favorites',
  'Shared Reports',
  'Scheduled Reports',
  ...reportNavigationCategories,
];

String? reportsResolveCategory(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final slug = reportsNavigationSlug(trimmed);
  for (final category in _reportsRouteCategories) {
    if (category == trimmed || reportsNavigationSlug(category) == slug) {
      return category;
    }
  }
  return null;
}

String reportsCategoryRoutePath(String category) {
  final resolved = reportsResolveCategory(category) ?? category;
  if (resolved == 'All Reports') return AppRoutes.reports;
  return '${AppRoutes.reports}/category/${reportsNavigationSlug(resolved)}';
}

String? reportsCategoryForReport(String reportName, {String? category}) {
  final resolvedCategory = reportsResolveCategory(category);
  if (resolvedCategory != null &&
      reportNavigationReportsByCategory[resolvedCategory]?.contains(
            reportName,
          ) ==
          true) {
    return resolvedCategory;
  }

  for (final entry in reportNavigationReportsByCategory.entries) {
    if (entry.value.contains(reportName)) return entry.key;
  }

  if (reportName == 'ABC classification') return 'Inventory Valuation';
  if (reportName == 'Vendor Credit Details') return 'Payables';
  if (reportName == 'Expenses by Category') return 'Purchases and Expenses';
  return resolvedCategory;
}

String? reportsReportNameFromSlug(String? reportSlug, {String? category}) {
  final slug = reportSlug?.trim();
  if (slug == null || slug.isEmpty) return null;
  final resolvedCategory = reportsResolveCategory(category);
  final scopedReports = resolvedCategory == null
      ? const <String>[]
      : reportNavigationReportsByCategory[resolvedCategory] ?? const <String>[];

  for (final reportName in scopedReports) {
    if (reportsNavigationSlug(reportName) == slug) return reportName;
  }

  for (final reports in reportNavigationReportsByCategory.values) {
    for (final reportName in reports) {
      if (reportsNavigationSlug(reportName) == slug) return reportName;
    }
  }

  return null;
}

String? reportsReportRoutePath(String reportName, {String? category}) {
  if (reportName == 'Account Transactions') {
    return AppRoutes.accountantTransactionsReport;
  }
  if (reportName == 'Daily Sales') return AppRoutes.reportDailySales;
  if (reportName == 'Profit and Loss') return AppRoutes.profitAndLoss;
  if (reportName == 'General Ledger') return AppRoutes.generalLedger;
  if (reportName == 'Trial Balance') return AppRoutes.trialBalance;
  if (reportName == 'Inventory Valuation Summary') {
    return AppRoutes.inventoryValuation;
  }

  final resolvedCategory = reportsCategoryForReport(
    reportName,
    category: category,
  );
  if (resolvedCategory == null) return null;
  return '${reportsCategoryRoutePath(resolvedCategory)}/report/${reportsNavigationSlug(reportName)}';
}

Widget? buildReportsModuleReportPage(String reportName, {String? category}) {
  if (category == 'Payables' && reportName == 'Refund History') {
    return const PayablesRefundHistoryPage();
  }

  switch (reportName) {
    case 'Profit and Loss (Schedule III)':
      return const ProfitAndLossScheduleIIIScreen();
    case 'Horizontal Profit and Loss':
      return const HorizontalProfitAndLossScreen();
    case 'Cash Flow Statement':
      return const CashFlowStatementScreen();
    case 'Balance Sheet':
      return const BalanceSheetScreen();
    case 'Horizontal Balance Sheet':
      return const HorizontalBalanceSheetScreen();
    case 'Balance Sheet (Schedule III)':
      return const BalanceSheetScheduleIIIScreen();
    case 'Business Performance Ratios':
      return const BusinessPerformanceRatiosScreen();
    case 'Movement of Equity':
      return const MovementOfEquityScreen();
    case 'Account Type Summary':
      return const AccountTypeSummaryPage();
    case 'Account Type Transactions':
      return const AccountTypeTransactionsPage();
    case 'Day Book':
      return const DayBookScreen();
    case 'Detailed General Ledger':
      return const DetailedGeneralLedgerScreen();
    case 'Journal Report':
      return const JournalReportScreen();
    case 'Sales by Customer':
      return const SalesByCustomerScreen();
    case 'Sales by Item':
      return const SalesByItemPage();
    case 'Sales by Sales Person':
      return const SalesBySalespersonPage();
    case 'Sales Summary':
      return const SalesSummaryPage();
    case 'Profit By Item':
      return const ProfitByItemPage();
    case 'Sales Channel Integrations Sync Summary':
      return const SalesChannelIntegrationsSyncSummaryPage();
    case 'Inventory Summary':
      return const InventorySummaryPage();
    case 'Committed Stock Details':
      return const CommittedStockDetailsPage();
    case 'Inventory Aging Summary':
      return const InventoryAgingSummaryPage();
    case 'Stock Summary':
      return const StockSummaryPage();
    case 'Assembly Details':
      return const AssemblyDetailsPage();
    case 'Stock Movement':
      return const StockMovementPage();
    case 'Inventory Adjustment Summary':
      return const InventoryAdjustmentSummaryPage();
    case 'Inventory Adjustment Details':
      return const InventoryAdjustmentDetailsPage();
    case 'Inventory Turnover By Quantity':
      return const InventoryTurnoverByQuantityPage();
    case 'FIFO Cost Lot Tracking':
      return const FifoCostLotTrackingPage();
    case 'ABC classification':
    case 'ABC Classification':
      return const AbcClassificationPage();
    case 'Landed Cost Summary':
      return const LandedCostSummaryPage();
    case 'Inventory Turnover By Amount':
      return const InventoryTurnoverByAmountPage();
    case 'Weighted Average Costing Summary':
      return const WeightedAverageCostingSummaryPage();
    case 'AR Aging Summary':
      return const ArAgingSummaryPage();
    case 'AR Aging Details':
      return const ArAgingDetailsPage();
    case 'Invoice Details':
      return const InvoiceDetailsPage();
    case 'Retainer Invoice Details':
      return const RetainerInvoiceDetailsPage();
    case 'Sales Order Details':
      return const SalesOrderDetailsPage();
    case 'Delivery Challan Details':
      return const DeliveryChallanDetailsPage();
    case 'Quote Details':
      return const QuoteDetailsPage();
    case 'Customer Balance Summary':
      return const CustomerBalanceSummaryPage();
    case 'Receivable Summary':
      return const ReceivableSummaryPage();
    case 'Receivable Details':
      return const ReceivableDetailsPage();
    case 'Payments Received':
      return const PaymentsReceivedPage();
    case 'Time to Get Paid':
      return const TimeToGetPaidPage();
    case 'Credit Note Details':
      return const CreditNoteDetailsPage();
    case 'Refund History':
      return const RefundHistoryPage();
    case 'Recurring Invoices':
    case 'Recurring Invoice Details':
      return const RecurringInvoiceDetailsPage();
    case 'Vendor Balance Summary':
      return const VendorBalanceSummaryPage();
    case 'Payable Summary':
      return const PayableSummaryPage();
    case 'Payable Details':
      return const PayableDetailsPage();
    case 'AP Aging Summary':
      return const ApAgingSummaryPage();
    case 'AP Aging Details':
      return const ApAgingDetailsPage();
    case 'Bill Details':
      return const BillDetailsPage();
    case 'Vendor Credit Details':
    case 'Vendor Credits Details':
      return const VendorCreditsDetailsPage();
    case 'Payments Made':
      return const PaymentsMadePage();
    case 'Purchase Order Details':
      return const PurchaseOrderDetailsPage();
    case 'Purchase Orders by Vendor':
      return const PurchaseOrdersByVendorPage();
    case 'Purchase Orders by Item':
    case 'Purchase Order by Item':
      return const PurchaseOrdersByItemPage();
    case 'Expense Summary by Category':
    case 'Expenses by Category':
      return const ExpenseSummaryByCategoryPage();
    case 'Expenses by Customer':
      return const ExpensesByCustomerPage();
    case 'Expenses by Employee':
      return const ExpensesByEmployeePage();
    case 'Billable Expense Details':
      return const BillableExpenseDetailsPage();
    case 'Expense Details':
      return const ExpenseDetailsPage();
    case 'Purchases by Item':
      return const PurchasesByItemPage();
    case 'Purchases by Vendor':
      return const PurchasesByVendorPage();
  }

  if (reportNavigationReportsByCategory['Inventory']?.contains(reportName) ??
      false) {
    return InventoryReportPlaceholderScreen(reportName: reportName);
  }
  if (reportNavigationReportsByCategory['Receivables']?.contains(reportName) ??
      false) {
    return ReceivablesReportPlaceholderScreen(reportName: reportName);
  }
  if (reportNavigationReportsByCategory['Payments Received']?.contains(
        reportName,
      ) ??
      false) {
    return PaymentsReceivedReportPlaceholderScreen(reportName: reportName);
  }
  if (reportNavigationReportsByCategory['Recurring Invoices']?.contains(
        reportName,
      ) ??
      false) {
    return RecurringInvoicesReportPlaceholderScreen(reportName: reportName);
  }
  if (reportNavigationReportsByCategory['Payables']?.contains(reportName) ??
      false) {
    return PayablesReportPlaceholderScreen(reportName: reportName);
  }
  if (reportNavigationReportsByCategory['Purchases and Expenses']?.contains(
        reportName,
      ) ??
      false) {
    return PurchasesExpensesReportPlaceholderScreen(reportName: reportName);
  }
  if (reportName == 'Tax Summary') {
    return const TaxSummaryScreen();
  }
  if (reportName == 'TDS Summary') {
    return const TdsSummaryScreen();
  }
  if (reportName == 'Annual Summary (GSTR-9)') {
    return const AnnualSummaryGstr9Screen();
  }
  if (reportName == 'TDS Receivable Summary') {
    return const TdsReceivableSummaryScreen();
  }
  if (reportName == 'GSTR-7 (Return for Tax Deducted at Source)') {
    return const Gstr7Screen();
  }
  if (reportName == 'TCS Payable Summary (Form No. 27EQ)') {
    return const TcsPayableSummaryScreen();
  }
  if (reportName == 'Invoice Furnishing Facility (IFF)') {
    return const InvoiceFurnishingFacilityScreen();
  }
  if (reportName == 'PMT-06 (Self Assessment Basis)') {
    return const Pmt06Screen();
  }
  if (reportName == 'GSTR-3B Summary') {
    return const Gstr3bSummaryScreen();
  }
  if (reportName == 'Summary of Outward Supplies') {
    return const Gstr1OutwardSuppliesSummaryScreen();
  }
  if (reportName == 'Summary of Inward Supplies') {
    return const Gstr2InwardSuppliesSummaryScreen();
  }
  if (reportName == 'Self-invoice Summary') {
    return const SelfInvoiceSummaryScreen();
  }
  if (reportName == 'KFC-A Summary') {
    return const KfcaSummaryScreen();
  }
  if (reportNavigationReportsByCategory['Taxes']?.contains(reportName) ??
      false) {
    return TaxesReportPlaceholderScreen(reportName: reportName);
  }
  if (reportName == 'Reconciliation Status') {
    return const ReconciliationStatusReportScreen();
  }
  if (reportNavigationReportsByCategory['Banking']?.contains(reportName) ??
      false) {
    return BankingReportPlaceholderScreen(reportName: reportName);
  }
  if (reportNavigationReportsByCategory['Currency']?.contains(reportName) ??
      false) {
    return CurrencyReportPlaceholderScreen(reportName: reportName);
  }
  if (reportName == 'System Mails') {
    return const SystemMailsReportScreen();
  }
  if (reportNavigationReportsByCategory['Activity']?.contains(reportName) ??
      false) {
    return ActivityReportPlaceholderScreen(reportName: reportName);
  }
  if (reportNavigationReportsByCategory['Automation']?.contains(reportName) ??
      false) {
    return AutomationReportPlaceholderScreen(reportName: reportName);
  }
  if (reportName == 'Batch Details') {
    return const BatchDetailsPage();
  }
  if (reportName == 'Serial Number Details') {
    return const SerialNumberDetailsPage();
  }
  if (reportNavigationReportsByCategory['Advanced Inventory']?.contains(
        reportName,
      ) ??
      false) {
    return InventoryReportPlaceholderScreen(
      reportName: reportName,
      categoryLabel: 'Advanced Inventory',
    );
  }
  if (reportNavigationReportsByCategory['Inventory Valuation']?.contains(
        reportName,
      ) ??
      false) {
    return InventoryReportPlaceholderScreen(
      reportName: reportName,
      categoryLabel: 'Inventory Valuation',
    );
  }

  return null;
}

class ReportsCenterScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  final String? initialCategory;

  const ReportsCenterScreen({
    super.key,
    this.initialSearchQuery,
    this.initialCategory,
  });

  @override
  ConsumerState<ReportsCenterScreen> createState() =>
      _ReportsCenterScreenState();
}

class _ReportsCenterScreenState extends ConsumerState<ReportsCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _reportsScrollController = ScrollController();
  Set<String> _favoriteReports = <String>{};

  String _selectedCategory = 'All Reports';

  static const List<_ReportsShortcutItem> _shortcutItems = [
    _ReportsShortcutItem(
      label: 'Home',
      icon: LucideIcons.home,
      category: 'All Reports',
    ),
    _ReportsShortcutItem(
      label: 'Favorites',
      icon: LucideIcons.star,
      category: 'Favorites',
    ),
    _ReportsShortcutItem(
      label: 'Shared Reports',
      icon: LucideIcons.share2,
      category: 'Shared Reports',
    ),
    _ReportsShortcutItem(
      label: 'Scheduled Reports',
      icon: LucideIcons.clock3,
      category: 'Scheduled Reports',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialCategory = reportsResolveCategory(widget.initialCategory);
    if (initialCategory != null) {
      _selectedCategory = initialCategory;
    }
    final initialQuery = widget.initialSearchQuery?.trim();
    if (initialQuery != null && initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
    }
    _searchController.addListener(_handleSearchChanged);
    _loadFavoriteReports();
  }

  @override
  void didUpdateWidget(covariant ReportsCenterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory == widget.initialCategory) return;

    final nextCategory = reportsResolveCategory(widget.initialCategory);
    if (nextCategory != null && nextCategory != _selectedCategory) {
      setState(() {
        _selectedCategory = nextCategory;
      });
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _sidebarScrollController.dispose();
    _reportsScrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFavoriteReports() async {
    try {
      final favorites = await ref
          .read(reportsRepositoryProvider)
          .getReportFavoriteNames();
      if (!mounted) return;
      setState(() {
        _favoriteReports = favorites;
      });
    } catch (error) {
      AppLogger.error(
        'Failed to load report favorites',
        error: error,
        module: 'reports',
      );
    }
  }

  Future<void> _toggleReportFavorite(String reportName) async {
    final wasFavorite = _favoriteReports.contains(reportName);
    setState(() {
      if (wasFavorite) {
        _favoriteReports = {..._favoriteReports}..remove(reportName);
      } else {
        _favoriteReports = {..._favoriteReports, reportName};
      }
    });

    try {
      final repository = ref.read(reportsRepositoryProvider);
      if (wasFavorite) {
        await repository.removeReportFavorite(reportName);
      } else {
        await repository.saveReportFavorite(reportName);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          if (wasFavorite) {
            _favoriteReports = {..._favoriteReports, reportName};
          } else {
            _favoriteReports = {..._favoriteReports}..remove(reportName);
          }
        });
      }
      AppLogger.error(
        'Failed to toggle report favorite',
        error: error,
        module: 'reports',
      );
    }
  }

  List<String> get _sidebarCategories => reportNavigationCategories;

  List<Map<String, String>> get _allReports {
    final reports = <Map<String, String>>[];
    for (final category in reportNavigationCategories) {
      final categoryReports =
          reportNavigationReportsByCategory[category] ?? const <String>[];
      for (final name in categoryReports) {
        reports.add({
          'name': name,
          'category': category,
          'created_by': 'System Generated',
        });
      }
    }
    return reports;
  }

  List<Map<String, String>> get _visibleReports {
    final query = _searchController.text.trim().toLowerCase();
    final source = _selectedCategory == 'All Reports'
        ? _allReports
        : _selectedCategory == 'Favorites'
        ? _allReports
              .where((report) => _favoriteReports.contains(report['name']))
              .toList(growable: false)
        : _allReports
              .where((report) => report['category'] == _selectedCategory)
              .toList(growable: false);

    if (query.isEmpty) return source;

    return source
        .where(
          (report) =>
              (report['name'] ?? '').toLowerCase().contains(query) ||
              (report['category'] ?? '').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }



  List<Map<String, String>> get _globalSearchReports {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allReports;

    return _allReports
        .where((report) =>
            (report['name'] ?? '').toLowerCase().contains(query) ||
            (report['category'] ?? '').toLowerCase().contains(query))
        .toList(growable: false);
  }

  Map<String, List<Map<String, String>>> get _globalSearchGroupedReports {
    final grouped = <String, List<Map<String, String>>>{};
    for (final report in _globalSearchReports) {
      final category = report['category'] ?? 'All Reports';
      grouped.putIfAbsent(category, () => <Map<String, String>>[]).add(report);
    }
    return grouped;
  }

  void _openReport(Map<String, String> report) {
    final name = report['name'];
    if (name == null) return;
    openReportFromReportsModule(context, name, category: report['category']);
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reports = _visibleReports;

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: AppTheme.bgLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              _ReportsCenterHeader(
                search: ReportsSearchExplorer(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  groupedReports: _globalSearchGroupedReports,
                  onSelected: _openReport,
                  maxWidth: 300,
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: const _ReportsCenterPatternPainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space12,
                      AppTheme.space16,
                      AppTheme.space16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ReportsCenterSidebar(
                          controller: _sidebarScrollController,
                          shortcuts: _shortcutItems,
                          categories: _sidebarCategories,
                          selectedCategory: _selectedCategory,
                          onShortcutSelected: (shortcut) {
                            if (shortcut.category != null) {
                              _selectCategory(shortcut.category!);
                            }
                          },
                          onCategorySelected: _selectCategory,
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: _ReportsCenterTableCard(
                            title: _selectedCategory,
                            count: reports.length,
                            controller: _reportsScrollController,
                            reports: reports,
                            onOpenReport: _openReport,
                            favoriteReports: _favoriteReports,
                            onToggleFavorite: _toggleReportFavorite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsCenterHeader extends StatelessWidget {
  final Widget search;

  const _ReportsCenterHeader({required this.search});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.space16),
          bottomRight: Radius.circular(AppTheme.space16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space20,
        AppTheme.space24,
        AppTheme.space18,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Reports Center', style: AppTheme.pageTitle),
          ),
          Align(alignment: Alignment.center, child: search),
          Align(
            alignment: Alignment.centerRight,
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: AppTheme.backgroundColor,
                  surfaceTintColor: AppTheme.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.space6),
                    side: const BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 44),
                onSelected: (value) {},
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'schedule',
                    padding: EdgeInsets.zero,
                    height: 40,
                    child: _HoverablePopupMenuItemContent(
                      icon: LucideIcons.upload,
                      label: 'Schedule Report Export',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'layout',
                    padding: EdgeInsets.zero,
                    height: 40,
                    child: _HoverablePopupMenuItemContent(
                      icon: LucideIcons.settings,
                      label: 'Configure Report Layout',
                    ),
                  ),
                ],
                child: Container(
                  width: AppTheme.buttonHeight,
                  height: AppTheme.buttonHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.space8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Icon(
                    LucideIcons.moreVertical,
                    size: AppTheme.space18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsCenterSidebar extends StatelessWidget {
  final ScrollController controller;
  final List<_ReportsShortcutItem> shortcuts;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<_ReportsShortcutItem> onShortcutSelected;
  final ValueChanged<String> onCategorySelected;

  const _ReportsCenterSidebar({
    required this.controller,
    required this.shortcuts,
    required this.categories,
    required this.selectedCategory,
    required this.onShortcutSelected,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.05),
            blurRadius: AppTheme.space16,
            offset: const Offset(0, AppTheme.space4),
          ),
        ],
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space12,
            AppTheme.space12,
            AppTheme.space10,
            AppTheme.space12,
          ),
          children: [
            for (final shortcut in shortcuts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space2),
                child: _ReportsCenterNavTile(
                  label: shortcut.label,
                  icon: shortcut.icon,
                  selected: selectedCategory == shortcut.category,
                  onTap: () => onShortcutSelected(shortcut),
                ),
              ),
            const SizedBox(height: AppTheme.space18),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space10,
                0,
                AppTheme.space10,
                AppTheme.space10,
              ),
              child: Text(
                'REPORT CATEGORY',
                style: AppTheme.captionText.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final category in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space2),
                child: _ReportsCenterNavTile(
                  label: category,
                  icon: LucideIcons.folder,
                  selected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportsCenterNavTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReportsCenterNavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.selectionActiveBg : AppTheme.backgroundColor,
      borderRadius: BorderRadius.circular(AppTheme.space8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        hoverColor: selected ? AppTheme.selectionActiveBg : AppTheme.bgHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space10,
            vertical: AppTheme.space10,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppTheme.space18,
                color: selected ? AppTheme.primaryBlue : AppTheme.textSubtle,
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsCenterTableCard extends StatelessWidget {
  final String title;
  final int count;
  final ScrollController controller;
  final List<Map<String, String>> reports;
  final ValueChanged<Map<String, String>> onOpenReport;
  final Set<String> favoriteReports;
  final ValueChanged<String> onToggleFavorite;

  const _ReportsCenterTableCard({
    required this.title,
    required this.count,
    required this.controller,
    required this.reports,
    required this.onOpenReport,
    required this.favoriteReports,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final emptyState = reports.isEmpty
        ? _ReportsCenterEmptyStateSpec.forTitle(title)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.05),
            blurRadius: AppTheme.space16,
            offset: const Offset(0, AppTheme.space4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: emptyState == null
                ? null
                : const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space14,
                AppTheme.space16,
                AppTheme.space14,
              ),
              child: Row(
                children: [
                  Text(title, style: AppTheme.pageTitle.copyWith(fontSize: 18)),
                  if (emptyState == null) ...[
                    const SizedBox(width: AppTheme.space8),
                    Container(
                      width: AppTheme.space24,
                      height: AppTheme.space24,
                      decoration: const BoxDecoration(
                        color: AppTheme.infoBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$count',
                        style: AppTheme.metaHelper.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (emptyState != null)
            Expanded(
              child: ReportEmptyState(
                title: emptyState.title,
                message: emptyState.message,
                illustration: _ReportsCenterEmptyIllustration(
                  kind: emptyState.illustrationKind,
                ),
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space24,
                  AppTheme.space64 + AppTheme.space8,
                  AppTheme.space24,
                  AppTheme.space24,
                ),
                titleStyle: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                messageStyle: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                illustrationGap: AppTheme.space18,
                titleMessageGap: AppTheme.space4,
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.tableHeaderBg,
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight),
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'REPORT NAME',
                      style: ReportTableTypography.header,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'CREATED BY',
                      style: ReportTableTypography.header,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: controller,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: controller,
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final reportName = report['name'] ?? '-';
                    final isFavorite = favoriteReports.contains(reportName);
                    return DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Material(
                        color: AppTheme.backgroundColor,
                        child: InkWell(
                          onTap: () => onOpenReport(report),
                          hoverColor: AppTheme.bgHover,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () =>
                                              onToggleFavorite(reportName),
                                          child: Icon(
                                            isFavorite
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: AppTheme.space14,
                                            color: isFavorite
                                                ? AppTheme.warningOrange
                                                : AppTheme.textSubtle,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.space10),
                                      Expanded(
                                        child: Text(
                                          reportName,
                                          style: AppTheme.linkText.copyWith(
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    report['created_by'] ?? '-',
                                    style: AppTheme.tableCell,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportsCenterEmptyStateSpec {
  final String title;
  final String message;
  final _ReportsCenterEmptyIllustrationKind illustrationKind;

  const _ReportsCenterEmptyStateSpec({
    required this.title,
    required this.message,
    required this.illustrationKind,
  });

  static _ReportsCenterEmptyStateSpec? forTitle(String title) {
    return switch (title) {
      'Shared Reports' => const _ReportsCenterEmptyStateSpec(
        title: "Currently, you don't have any shared reports.",
        message:
            'If someone shares a custom report with you, you will be able to view it here.',
        illustrationKind: _ReportsCenterEmptyIllustrationKind.shared,
      ),
      'Scheduled Reports' => const _ReportsCenterEmptyStateSpec(
        title: "Currently, you don't have any scheduled reports.",
        message: 'Go to a report and schedule it to view it here.',
        illustrationKind: _ReportsCenterEmptyIllustrationKind.scheduled,
      ),
      _ => null,
    };
  }
}

enum _ReportsCenterEmptyIllustrationKind { shared, scheduled }

class _ReportsCenterEmptyIllustration extends StatelessWidget {
  final _ReportsCenterEmptyIllustrationKind kind;

  const _ReportsCenterEmptyIllustration({required this.kind});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 96,
      child: CustomPaint(painter: _ReportsCenterEmptyIllustrationPainter(kind)),
    );
  }
}

class _ReportsCenterEmptyIllustrationPainter extends CustomPainter {
  final _ReportsCenterEmptyIllustrationKind kind;

  const _ReportsCenterEmptyIllustrationPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFE8EEF7);
    final darkFill = Paint()..color = const Color(0xFFD5DFEF);
    final stroke = Paint()
      ..color = const Color(0xFF8FA0BC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final subtleStroke = Paint()
      ..color = const Color(0xFFB8C4D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.86),
      Offset(size.width * 0.9, size.height * 0.86),
      subtleStroke,
    );

    final backBubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.12,
        size.width * 0.32,
        size.height * 0.58,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(backBubble, fill);

    final building = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.32,
        size.width * 0.45,
        size.height * 0.54,
      ),
      const Radius.circular(7),
    );
    canvas.drawRRect(building, darkFill);
    canvas.drawRRect(building, subtleStroke);

    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.58,
        size.width * 0.24,
        size.height * 0.28,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(door, Paint()..color = AppTheme.backgroundColor);
    canvas.drawRRect(door, stroke);
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.67),
      Offset(size.width * 0.58, size.height * 0.67),
      subtleStroke,
    );

    if (kind == _ReportsCenterEmptyIllustrationKind.shared) {
      _drawShare(canvas, size, stroke);
    } else {
      _drawSchedule(canvas, size, stroke);
    }
  }

  void _drawShare(Canvas canvas, Size size, Paint stroke) {
    final nodes = [
      Offset(size.width * 0.72, size.height * 0.32),
      Offset(size.width * 0.59, size.height * 0.42),
      Offset(size.width * 0.75, size.height * 0.52),
    ];
    canvas.drawLine(nodes[0], nodes[1], stroke);
    canvas.drawLine(nodes[1], nodes[2], stroke);
    for (final node in nodes) {
      canvas.drawCircle(node, 5.2, Paint()..color = AppTheme.backgroundColor);
      canvas.drawCircle(node, 5.2, stroke);
    }
  }

  void _drawSchedule(Canvas canvas, Size size, Paint stroke) {
    final clockCenter = Offset(size.width * 0.72, size.height * 0.74);
    canvas.drawCircle(
      clockCenter,
      12,
      Paint()..color = AppTheme.backgroundColor,
    );
    canvas.drawCircle(clockCenter, 12, stroke);
    canvas.drawLine(clockCenter, clockCenter + const Offset(0, -7), stroke);
    canvas.drawLine(clockCenter, clockCenter + const Offset(5, 4), stroke);

    final path = Path()
      ..moveTo(size.width * 0.76, size.height * 0.19)
      ..lineTo(size.width * 0.9, size.height * 0.07)
      ..lineTo(size.width * 0.85, size.height * 0.24)
      ..lineTo(size.width * 0.81, size.height * 0.17);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(
    covariant _ReportsCenterEmptyIllustrationPainter oldDelegate,
  ) {
    return oldDelegate.kind != kind;
  }
}

class _ReportsShortcutItem {
  final String label;
  final IconData icon;
  final String? category;

  const _ReportsShortcutItem({
    required this.label,
    required this.icon,
    required this.category,
  });
}

class _ReportsCenterPatternPainter extends CustomPainter {
  const _ReportsCenterPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final patternPaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const stepX = 86.0;
    const stepY = 72.0;

    for (double y = 22; y < size.height; y += stepY) {
      for (double x = 34; x < size.width; x += stepX) {
        canvas.drawCircle(Offset(x, y), 10, patternPaint);
        canvas.drawLine(
          Offset(x - 22, y + 14),
          Offset(x - 8, y + 4),
          patternPaint,
        );
        canvas.drawLine(
          Offset(x + 16, y - 16),
          Offset(x + 28, y - 2),
          patternPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReceivablesReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const ReceivablesReportPlaceholderScreen({
    super.key,
    required this.reportName,
  });

  @override
  State<ReceivablesReportPlaceholderScreen> createState() =>
      _ReceivablesReportPlaceholderScreenState();
}

class _ReceivablesReportPlaceholderScreenState
    extends State<ReceivablesReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Receivables',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Receivables',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class PaymentsReceivedReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const PaymentsReceivedReportPlaceholderScreen({
    super.key,
    required this.reportName,
  });

  @override
  State<PaymentsReceivedReportPlaceholderScreen> createState() =>
      _PaymentsReceivedReportPlaceholderScreenState();
}

class _PaymentsReceivedReportPlaceholderScreenState
    extends State<PaymentsReceivedReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Payments Received',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Payments Received',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class RecurringInvoicesReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const RecurringInvoicesReportPlaceholderScreen({
    super.key,
    required this.reportName,
  });

  @override
  State<RecurringInvoicesReportPlaceholderScreen> createState() =>
      _RecurringInvoicesReportPlaceholderScreenState();
}

class _RecurringInvoicesReportPlaceholderScreenState
    extends State<RecurringInvoicesReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Recurring Invoices',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Recurring Invoices',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class PayablesReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const PayablesReportPlaceholderScreen({super.key, required this.reportName});

  @override
  State<PayablesReportPlaceholderScreen> createState() =>
      _PayablesReportPlaceholderScreenState();
}

class _PayablesReportPlaceholderScreenState
    extends State<PayablesReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Payables',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Payables',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class PurchasesExpensesReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const PurchasesExpensesReportPlaceholderScreen({
    super.key,
    required this.reportName,
  });

  @override
  State<PurchasesExpensesReportPlaceholderScreen> createState() =>
      _PurchasesExpensesReportPlaceholderScreenState();
}

class _PurchasesExpensesReportPlaceholderScreenState
    extends State<PurchasesExpensesReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Purchases and Expenses',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Purchases and Expenses',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class TaxesReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const TaxesReportPlaceholderScreen({super.key, required this.reportName});

  @override
  State<TaxesReportPlaceholderScreen> createState() =>
      _TaxesReportPlaceholderScreenState();
}

class _TaxesReportPlaceholderScreenState
    extends State<TaxesReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Taxes',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class BankingReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const BankingReportPlaceholderScreen({super.key, required this.reportName});

  @override
  State<BankingReportPlaceholderScreen> createState() =>
      _BankingReportPlaceholderScreenState();
}

class _BankingReportPlaceholderScreenState
    extends State<BankingReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Banking',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Banking',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class CurrencyReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const CurrencyReportPlaceholderScreen({super.key, required this.reportName});

  @override
  State<CurrencyReportPlaceholderScreen> createState() =>
      _CurrencyReportPlaceholderScreenState();
}

class _CurrencyReportPlaceholderScreenState
    extends State<CurrencyReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Currency',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Currency',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class ActivityReportPlaceholderScreen extends StatefulWidget {
  final String reportName;

  const ActivityReportPlaceholderScreen({super.key, required this.reportName});

  @override
  State<ActivityReportPlaceholderScreen> createState() =>
      _ActivityReportPlaceholderScreenState();
}

class _ActivityReportPlaceholderScreenState
    extends State<ActivityReportPlaceholderScreen> {
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Activity',
      reportTitle: widget.reportName,
      dateLabel: 'From 01-07-2026 To 31-07-2026',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: widget.reportName),
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the ${widget.reportName} report.',
      scheduleTooltip: 'Schedule the ${widget.reportName} report.',
      currentNavigationCategory: 'Activity',
      currentNavigationReport: widget.reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: const ReportTableEmptyBody(minHeight: 345),
    );
  }
}

class AutomationReportPlaceholderScreen extends StatelessWidget {
  final String reportName;

  const AutomationReportPlaceholderScreen({
    super.key,
    required this.reportName,
  });

  @override
  Widget build(BuildContext context) {
    if (reportName == 'Scheduled Time Based Workflow Actions') {
      return const ScheduledTimeBasedWorkflowActionsPage();
    }
    if (reportName == 'Workflow Execution Logs') {
      return const WorkflowExecutionLogsPage();
    }
    return const ScheduledDateBasedWorkflowRulesPage();
  }
}

class InventoryReportPlaceholderScreen extends StatelessWidget {
  final String reportName;
  final String categoryLabel;

  const InventoryReportPlaceholderScreen({
    super.key,
    required this.reportName,
    this.categoryLabel = 'Inventory',
  });

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: categoryLabel,
      reportTitle: reportName,
      dateLabel: '',
      companyName: '',
      filters: const <Widget>[],
      showFilterBar: false,
      showReload: true,
      showSchedule: true,
      showInlineRunReportButton: false,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: reportName),
      onReload: () {},
      onRefresh: () {},
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the $reportName report.',
      scheduleTooltip: 'Schedule the $reportName report.',
      currentNavigationCategory: categoryLabel,
      currentNavigationReport: reportName,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == reportName) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: '$reportName is not available yet',
      emptyMessage:
          'This report can be opened from Reports Center and is ready for backend integration.',
      reportContent: const SizedBox.shrink(),
    );
  }
}

class SalesByCustomerScreen extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const SalesByCustomerScreen({super.key, this.startDate, this.endDate});

  @override
  ConsumerState<SalesByCustomerScreen> createState() =>
      _SalesByCustomerScreenState();
}

class _SalesByCustomerScreenState extends ConsumerState<SalesByCustomerScreen> {
  static const List<String> _entityOptions = <String>[
    'Invoice',
    'Credit Note',
    'Sales without invoices',
    'Journal',
  ];

  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;
  List<String> _selectedEntities = const <String>[];
  List<String> _appliedEntities = const <String>[];
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  String _compareWith = 'None';
  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = widget.startDate ?? DateTime(now.year, now.month, 1);
    _endDate =
        widget.endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
  }

  void _markFiltersDirty() {
    _hasPendingFilterChanges = true;
    _isApplyingFilters = false;
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    if (_sameDateTime(_startDate, selection.startDate) &&
        _sameDateTime(_endDate, selection.endDate)) {
      return;
    }
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _markFiltersDirty();
    });
  }

  void _handleEntitiesChanged(List<String> entities) {
    if (_sameStringList(_selectedEntities, entities)) return;
    setState(() {
      _selectedEntities = List<String>.from(entities);
      _markFiltersDirty();
    });
  }

  void _handleFilterControlChanged() {
    setState(_markFiltersDirty);
  }

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareSelection = selection;
      _compareWith = selection.displayValue;
      _refreshKey += 1;
    });
  }

  List<SalesByCustomerComparisonPeriod> _buildComparisonPeriods() {
    if (!_compareSelection.isActive) {
      return const <SalesByCustomerComparisonPeriod>[];
    }

    final count = _compareSelection.count.clamp(1, 5);
    final currentPeriod = SalesByCustomerComparisonPeriod(
      label: _formatComparisonPeriod(_appliedStartDate, _appliedEndDate),
      isCurrent: true,
    );
    final previousPeriods = <SalesByCustomerComparisonPeriod>[];

    if (_compareSelection.compareType == 'Previous Year(s)') {
      for (var offset = count; offset >= 1; offset -= 1) {
        previousPeriods.add(
          SalesByCustomerComparisonPeriod(
            label: _formatComparisonPeriod(
              _shiftDateByYears(_appliedStartDate, -offset),
              _shiftDateByYears(_appliedEndDate, -offset),
            ),
            isCurrent: false,
          ),
        );
      }
    } else {
      final periodDays = _appliedEndDate.difference(_appliedStartDate).inDays + 1;
      for (var offset = count; offset >= 1; offset -= 1) {
        final previousEnd = _appliedStartDate.subtract(
          Duration(days: periodDays * (offset - 1) + 1),
        );
        final previousStart = previousEnd.subtract(Duration(days: periodDays - 1));
        previousPeriods.add(
          SalesByCustomerComparisonPeriod(
            label: _formatComparisonPeriod(previousStart, previousEnd),
            isCurrent: false,
          ),
        );
      }
    }

    final periods = <SalesByCustomerComparisonPeriod>[
      ...previousPeriods,
      currentPeriod,
    ];
    debugPrint('[_buildComparisonPeriods] arrangeLatestFirst: ${_compareSelection.arrangeLatestFirst}, labels: ${periods.map((p) => p.label).toList()}');
    if (_compareSelection.arrangeLatestFirst) {
      final reversedPeriods = periods.reversed.toList(growable: false);
      debugPrint('[_buildComparisonPeriods] reversed labels: ${reversedPeriods.map((p) => p.label).toList()}');
      return reversedPeriods;
    }
    return periods;
  }

  DateTime _shiftDateByYears(DateTime date, int years) {
    final targetYear = date.year + years;
    final lastDayOfTargetMonth = DateTime(targetYear, date.month + 1, 0).day;
    return DateTime(
      targetYear,
      date.month,
      date.day.clamp(1, lastDayOfTargetMonth),
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  String _formatComparisonPeriod(DateTime startDate, DateTime endDate) {
    final formatter = ReportFormatterCache.date('MMM yyyy');
    return '${formatter.format(startDate).toUpperCase()} - ${formatter.format(endDate).toUpperCase()}';
  }

  bool _sameDateTime(DateTime left, DateTime right) {
    return left.isAtSameMomentAs(right);
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _toggleMoreFilters() {
    setState(() {
      _isMoreFiltersOpen = !_isMoreFiltersOpen;
    });
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() {
        _isMoreFiltersOpen = false;
      });
    }
  }

  Future<void> _openCustomerTransactions(Map<String, dynamic> item) async {
    final customerName = item['customerName']?.toString() ?? 'Customer';
    final customerId = item['customerId']?.toString();
    final transactions = customerId == null || customerId.isEmpty
        ? const <Map<String, dynamic>>[]
        : await ref
              .read(reportsRepositoryProvider)
              .getSalesByCustomerTransactions(
                customerId,
                ReportFormatterCache.date('yyyy-MM-dd').format(_appliedStartDate),
                ReportFormatterCache.date('yyyy-MM-dd').format(_appliedEndDate),
              );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SalesByCustomerTransactionsPage(
          customerName: customerName,
          dateLabel:
              'From ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate)} To ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate)}',
          transactions: transactions,
          onReportSelected: (reportName, category) {
            openReportFromReportsModule(
              context,
              reportName,
              category: category,
            );
          },
        ),
      ),
    );
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedEntities = List<String>.from(_selectedEntities);
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<Map<String, dynamic>>> reportRowsAsync,
  ) {
    if (!_isApplyingFilters ||
        reportRowsAsync.isLoading ||
        !reportRowsAsync.hasValue) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isApplyingFilters) return;
      setState(() {
        _isApplyingFilters = false;
        _hasPendingFilterChanges = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\u20B9',
      decimalDigits: 2,
    );
    final reportRowsAsync = ref.watch(
      salesReportRowsProvider(
        SalesReportRequest(
          kind: SalesReportKind.customer,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
          entities: _appliedEntities,
          refreshKey: _refreshKey,
        ),
      ),
    );
    _clearPendingAfterSuccessfulLoad(reportRowsAsync);
    final reportRows =
        reportRowsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final displayDate =
        'From ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate)} To ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate)}';
    final comparisonPeriods = _buildComparisonPeriods();

    return ReportViewScaffold(
      categoryLabel: 'Sales',
      reportTitle: 'Sales by Customer',
      dateLabel: displayDate,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportEntitiesFilter(
          options: _entityOptions,
          initialSelection: _selectedEntities,
          onChanged: _handleEntitiesChanged,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _handleFilterControlChanged,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: 'Sales by Customer'),
      onReload: _runReport,
      onRefresh: _runReport,
      onSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SalesByCustomerCustomizationPage(),
          ),
        );
      },
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      settingsTooltip: 'Customize the Sales by Customer report.',
      scheduleTooltip: 'Schedule the Sales by Customer report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportCompareSection(
            selectedValue: _compareWith,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          SizedBox(width: AppTheme.space10),
          ReportCustomizeColumnsButton(count: 5),
        ],
      ),
      isLoading: reportRowsAsync.isLoading && !reportRowsAsync.hasValue,
      errorMessage: reportRowsAsync.hasError
          ? reportRowsAsync.error.toString()
          : null,
      onRetry: _runReport,
      isEmpty: reportRows.isEmpty,
      emptyTitle: 'No customer sales found',
      emptyMessage:
          'There are no customer sales rows for the selected date range.',
      currentNavigationCategory: 'Sales',
      currentNavigationReport: 'Sales by Customer',
      onReportSelected: (reportName, category) {
        if (reportName == 'Sales by Customer') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: SalesByCustomerTable(
        items: reportRows,
        currencyFormat: currencyFormat,
        onOpenTransactions: _openCustomerTransactions,
        comparisonPeriods: comparisonPeriods,
      ),
    );
  }
}

class _HoverablePopupMenuItemContent extends StatefulWidget {
  final IconData icon;
  final String label;

  const _HoverablePopupMenuItemContent({
    required this.icon,
    required this.label,
  });

  @override
  State<_HoverablePopupMenuItemContent> createState() =>
      _HoverablePopupMenuItemContentState();
}

class _HoverablePopupMenuItemContentState
    extends State<_HoverablePopupMenuItemContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
        color: _isHovered ? AppTheme.primaryBlue : AppTheme.transparent,
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: _isHovered ? AppTheme.backgroundColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.space8),
            Text(
              widget.label,
              style: AppTheme.bodyText.copyWith(
                color: _isHovered ? AppTheme.backgroundColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
