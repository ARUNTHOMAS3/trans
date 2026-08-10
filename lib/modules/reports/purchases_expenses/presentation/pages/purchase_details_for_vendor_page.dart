import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_vendor_table.dart';

class PurchaseDetailsForVendorPage extends StatefulWidget {
  final String vendorName;
  final String dateLabel;
  final String filterBy;
  final List<PurchaseDetailsForVendorRow> rows;

  const PurchaseDetailsForVendorPage({
    super.key,
    required this.vendorName,
    required this.dateLabel,
    required this.filterBy,
    required this.rows,
  });

  @override
  State<PurchaseDetailsForVendorPage> createState() =>
      _PurchaseDetailsForVendorPageState();
}

class _PurchaseDetailsForVendorPageState
    extends State<PurchaseDetailsForVendorPage> {
  static const int _pageSize = 20;
  int _page = 1;

  String get _title => 'Purchase Details For ${widget.vendorName}';

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Purchases and Expenses > Purchases by Vendor',
      reportTitle: _title,
      dateLabel: widget.dateLabel,
      companyName: '',
      filters: const [],
      showFilterBar: false,
      contentTitle: _title,
      contentSubtitle: '${widget.dateLabel}\nFilter By - ${widget.filterBy}',
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
      tableHeaderActions: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportCustomizeColumnsButton(count: 6),
          SizedBox(width: AppTheme.space10),
        ],
      ),
      isLoading: false,
      isEmpty: widget.rows.isEmpty,
      emptyTitle: 'No purchase records found',
      emptyMessage: 'There are no purchase records for this vendor group.',
      currentNavigationCategory: 'Purchases and Expenses',
      currentNavigationReport: 'Purchases by Vendor',
      onReportSelected: (reportName, category) {
        openReportFromReportsModule(context, reportName, category: category);
      },
      settingsTooltip: 'Customize the purchase details report.',
      reportContent: PurchaseDetailsForVendorTable(
        rows: widget.rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}
