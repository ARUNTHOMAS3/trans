import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/banking/presentation/widgets/reconciliation_status_content.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class ReconciliationStatusReportScreen extends StatefulWidget {
  const ReconciliationStatusReportScreen({super.key});

  @override
  State<ReconciliationStatusReportScreen> createState() =>
      _ReconciliationStatusReportScreenState();
}

class _ReconciliationStatusReportScreenState
    extends State<ReconciliationStatusReportScreen> {
  static final DateTime _defaultStartDate = DateTime(2026, 7, 1);
  static final DateTime _defaultEndDate = DateTime(2026, 7, 31);
  static const List<String> _accountOptions = <String>[
    'Zoho Payroll - Bank Account',
    'Main Bank Account',
    'Petty Cash',
  ];

  DateTime _startDate = _defaultStartDate;
  DateTime _endDate = _defaultEndDate;
  DateTime _appliedStartDate = _defaultStartDate;
  DateTime _appliedEndDate = _defaultEndDate;
  String _selectedAccount = _accountOptions.first;
  bool _hasPendingFilterChanges = false;

  String get _dateLabel =>
      'From ${_formatDate(_appliedStartDate)} To ${_formatDate(_appliedEndDate)}';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleAccountChanged(String value) {
    if (_selectedAccount == value) return;
    setState(() {
      _selectedAccount = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _hasPendingFilterChanges = false;
    });
  }

  void _closeReport() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Banking',
      reportTitle: 'Reconciliation Status',
      dateLabel: _dateLabel,
      companyName: '',
      reportHeading: const ReconciliationStatusHeading(),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Account',
          value: _selectedAccount,
          options: _accountOptions,
          width: 228,
          onChanged: _handleAccountChanged,
        ),
      ],
      onRunReport: _runReport,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showSettings: false,
      showSchedule: false,
      showReload: false,
      showRefresh: true,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: _closeReport,
      currentNavigationCategory: 'Banking',
      currentNavigationReport: 'Reconciliation Status',
      onReportSelected: (reportName, category) {
        if (reportName == 'Reconciliation Status') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: const ReconciliationStatusContent(),
    );
  }
}
