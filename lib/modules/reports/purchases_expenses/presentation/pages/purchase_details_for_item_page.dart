import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_item_table.dart';

class PurchaseDetailsForItemPage extends StatefulWidget {
  final String itemName;
  final String dateLabel;
  final List<PurchaseDetailsForItemRow> rows;

  const PurchaseDetailsForItemPage({
    super.key,
    required this.itemName,
    required this.dateLabel,
    required this.rows,
  });

  @override
  State<PurchaseDetailsForItemPage> createState() =>
      _PurchaseDetailsForItemPageState();
}

class _PurchaseDetailsForItemPageState
    extends State<PurchaseDetailsForItemPage> {
  static const int _pageSize = 20;
  int _page = 1;

  String get _title => 'Purchases by Item - ${widget.itemName}';

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Purchases and Expenses > Purchases by Item',
      reportTitle: _title,
      dateLabel: widget.dateLabel,
      companyName: '',
      filters: const [],
      showFilterBar: false,
      contentTitle: _title,
      contentSubtitle: widget.dateLabel,
      showSettings: false,
      showSchedule: false,
      showDownload: false,
      showPrint: false,
      showReload: true,
      onExport: () {},
      onReload: () {},
      onRefresh: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      isLoading: false,
      isEmpty: widget.rows.isEmpty,
      emptyTitle: 'No purchase records found',
      emptyMessage: 'There are no purchase records for this item.',
      currentNavigationCategory: 'Purchases and Expenses',
      currentNavigationReport: 'Purchases by Item',
      onReportSelected: (reportName, category) {
        openReportFromReportsModule(context, reportName, category: category);
      },
      settingsTooltip: 'Customize the purchases by item detail report.',
      reportContent: PurchaseDetailsForItemTable(
        rows: widget.rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}
