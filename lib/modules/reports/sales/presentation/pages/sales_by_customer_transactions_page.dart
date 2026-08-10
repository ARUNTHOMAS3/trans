import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

import '../widgets/sales_by_customer_transactions_table.dart';

class SalesByCustomerTransactionsPage extends StatelessWidget {
  final String customerName;
  final String dateLabel;
  final List<Map<String, dynamic>> transactions;
  final void Function(String reportName, String category)? onReportSelected;
  final String categoryLabel;
  final String currentNavigationCategory;
  final String currentNavigationReport;
  final String? reportTitleOverride;
  final Widget? reportContent;

  const SalesByCustomerTransactionsPage({
    super.key,
    required this.customerName,
    required this.dateLabel,
    this.transactions = const <Map<String, dynamic>>[],
    this.onReportSelected,
    this.categoryLabel = 'Sales > Sales by Customer',
    this.currentNavigationCategory = 'Sales',
    this.currentNavigationReport = 'Sales by Customer',
    this.reportTitleOverride,
    this.reportContent,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedReportTitle =
        reportTitleOverride ?? '$customerName - Transactions';

    return ReportViewScaffold(
      categoryLabel: categoryLabel,
      reportTitle: resolvedReportTitle,
      dateLabel: dateLabel,
      companyName: '',
      filters: const <Widget>[],
      showFilterBar: false,
      showSettings: false,
      showSchedule: false,
      showReload: false,
      showRefresh: true,
      showExport: true,
      showClose: true,
      showPrint: true,
      showDownload: true,
      leadingToolbarActions: [
        ReportIconActionButton(
          icon: LucideIcons.share2,
          onPressed: () {},
          tooltip: 'Share',
          useLocalTooltip: true,
        ),
      ],
      onRefresh: () {},
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () => Navigator.of(context).maybePop(),
      currentNavigationCategory: currentNavigationCategory,
      currentNavigationReport: currentNavigationReport,
      onReportSelected: (reportName, category) {
        if (reportName == currentNavigationReport) {
          Navigator.of(context).maybePop();
          return;
        }
        onReportSelected?.call(reportName, category);
      },
      reportContent:
          reportContent ?? SalesByCustomerTransactionsTable(items: transactions),
    );
  }
}
