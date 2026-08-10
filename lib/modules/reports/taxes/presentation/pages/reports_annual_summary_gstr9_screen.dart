import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/taxes/presentation/widgets/gstr9_annual_summary_content.dart';

class AnnualSummaryGstr9Screen extends StatefulWidget {
  const AnnualSummaryGstr9Screen({super.key});

  @override
  State<AnnualSummaryGstr9Screen> createState() =>
      _AnnualSummaryGstr9ScreenState();
}

class _AnnualSummaryGstr9ScreenState extends State<AnnualSummaryGstr9Screen> {
  static const List<String> _gstinOptions = <String>[
    '32AACCZ4912F1Z5',
    '32AACCZ4912F1Z6',
    '32AACCZ4912F1Z7',
  ];

  String _selectedGstin = _gstinOptions.first;
  bool _hasPendingFilterChanges = false;

  void _handleGstinChanged(String value) {
    if (_selectedGstin == value) return;
    setState(() {
      _selectedGstin = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _refreshReport() {
    setState(() => _hasPendingFilterChanges = false);
  }

  void _closeReport() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: 'Annual Summary (GSTR-9)',
      dateLabel: '',
      companyName: '',
      reportHeading: const SizedBox.shrink(),
      filters: [
        ReportSearchableFilterDropdown(
          label: 'GSTIN',
          value: _selectedGstin,
          options: _gstinOptions,
          width: 216,
          onChanged: _handleGstinChanged,
        ),
      ],
      showInlineRunReportButton: false,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showExport: false,
      showSettings: false,
      showSchedule: false,
      showReload: false,
      showRefresh: true,
      onRefresh: _refreshReport,
      onClose: _closeReport,
      currentNavigationCategory: 'Taxes',
      currentNavigationReport: 'Annual Summary (GSTR-9)',
      onReportSelected: (reportName, category) {
        if (reportName == 'Annual Summary (GSTR-9)') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: const Gstr9AnnualSummaryContent(),
    );
  }
}
