import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_aging_interval_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/receivables/presentation/widgets/ar_aging_details_table.dart';

class ArAgingDetailsPage extends StatefulWidget {
  const ArAgingDetailsPage({super.key});

  @override
  State<ArAgingDetailsPage> createState() => _ArAgingDetailsPageState();
}

class _ArAgingDetailsPageState extends State<ArAgingDetailsPage> {
  static const String _reportTitle = 'AR Aging Details By Invoice Due Date';
  static const String _dateLabel = 'As of 15-07-2026';
  static final DateTime _asOfStartDate = DateTime(2026, 7, 15);
  static final DateTime _asOfEndDate = DateTime(2026, 7, 15, 23, 59, 59);
  static const int _pageSize = 11;

  static const List<ArAgingDetailsRow> _rows = [
    ArAgingDetailsRow(
      date: '28-03-2026',
      dueDate: '23-03-2027',
      transactionNumber: 'INV-000071',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'SAHAKAR MEDICALS AND\nSURGICALS THRISSUR LLP',
      age: '',
      amount: '\u20B91,18,000.00',
      balanceDue: '\u20B91,18,000.00',
    ),
    ArAgingDetailsRow(
      date: '28-03-2026',
      dueDate: '23-03-2027',
      transactionNumber: 'INV-000072',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'SAHAKAR MEDICALS AND\nSURGICALS\nMAKKARAPARAMBA LLP',
      age: '',
      amount: '\u20B91,18,000.00',
      balanceDue: '\u20B91,18,000.00',
    ),
    ArAgingDetailsRow(
      date: '31-03-2026',
      dueDate: '26-03-2027',
      transactionNumber: 'INV-000073',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'SAHAKAR MEDICALS AND\nSURGICALS TIRUR LLP',
      age: '',
      amount: '\u20B91,18,000.00',
      balanceDue: '\u20B91,18,000.00',
    ),
    ArAgingDetailsRow(
      date: '31-03-2026',
      dueDate: '26-03-2027',
      transactionNumber: 'INV-000074',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'SAHAKAR MEDICALS AND\nSURGICALS KKL LLP',
      age: '',
      amount: '\u20B91,18,000.00',
      balanceDue: '\u20B91,18,000.00',
    ),
    ArAgingDetailsRow(
      date: '31-03-2026',
      dueDate: '26-03-2027',
      transactionNumber: 'INV-000075',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'SAHAKAR MEDICALS AND\nSURGICALS HYPER STORE\nLLP',
      age: '',
      amount: '\u20B91,18,000.00',
      balanceDue: '\u20B91,18,000.00',
    ),
    ArAgingDetailsRow(
      date: '31-03-2026',
      dueDate: '26-03-2027',
      transactionNumber: 'INV-000076',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'SAHAKAR MEDICALS AND\nSURGICALS ALANALLUR LLP',
      age: '',
      amount: '\u20B91,18,000.00',
      balanceDue: '\u20B91,18,000.00',
    ),
    ArAgingDetailsRow(
      date: '20-04-2026',
      dueDate: '15-04-2027',
      transactionNumber: 'INV-000081',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'CUS-1',
      age: '',
      amount: '\u20B91,649.00',
      balanceDue: '\u20B91,649.00',
    ),
    ArAgingDetailsRow(
      date: '10-06-2026',
      dueDate: '05-06-2027',
      transactionNumber: 'INV-000087',
      type: 'Invoice',
      status: 'Partially Paid',
      customerName: 'althaf m',
      age: '',
      amount: '\u20B9885.00',
      balanceDue: '\u20B9785.00',
    ),
    ArAgingDetailsRow(
      date: '30-06-2026',
      dueDate: '25-06-2027',
      transactionNumber: 'BOS-000001',
      type: 'Bill Of Supply',
      status: 'Sent',
      customerName: 'althaf m',
      age: '',
      amount: '\u20B9199.00',
      balanceDue: '\u20B9199.00',
    ),
    ArAgingDetailsRow(
      date: '12-07-2026',
      dueDate: '07-07-2027',
      transactionNumber: 'INV-000098',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'althaf m',
      age: '',
      amount: '\u20B9238.00',
      balanceDue: '\u20B9238.00',
    ),
    ArAgingDetailsRow(
      date: '13-07-2026',
      dueDate: '08-07-2027',
      transactionNumber: 'INV-000099',
      type: 'Invoice',
      status: 'Sent',
      customerName: 'althaf m',
      age: '',
      amount: '\u20B9209.00',
      balanceDue: '\u20B9209.00',
    ),
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  static const List<String> _agingByOptions = <String>[
    'Invoice Due Date',
    'Invoice Date',
  ];

  String _agingBy = 'Invoice Due Date';
  static const List<String> _entityOptions = <String>[
    'Invoice',
    'Credit Note',
    'Journal',
  ];

  List<String> _selectedEntities = const <String>['Invoice'];
  static const List<String> _groupByOptions = <String>[
    'None',
    'Customer Name',
    'Salesperson',
    'Currency',
  ];

  String _groupBy = 'None';
  String _agingIntervals = '4 X 15 Days';
  int _page = 1;

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

  void _handleAgingByChanged(String value) {
    if (_agingBy == value) return;
    setState(() {
      _agingBy = value;
      _hasPendingFilterChanges = true;
    });
  }


  void _handleEntitiesChanged(List<String> entities) {
    if (_sameStringList(_selectedEntities, entities)) return;
    setState(() {
      _selectedEntities = List<String>.from(entities);
      _hasPendingFilterChanges = true;
    });
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() {
      _groupBy = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleAgingIntervalsChanged(String value) {
    if (_agingIntervals == value) return;
    setState(() {
      _agingIntervals = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Receivables',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'As of',
          initialStartDate: _asOfStartDate,
          initialEndDate: _asOfEndDate,
          onChanged: (_) => _markFiltersDirty(),
        ),
        ReportSearchableFilterDropdown(
          label: 'Aging By',
          value: _agingBy,
          options: _agingByOptions,
          onChanged: _handleAgingByChanged,
          width: 230,
          menuWidth: 156,
          menuMaxHeight: 156,
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
      showSchedule: false,
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
      settingsTooltip: 'Customize the AR Aging Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: _groupByOptions,
            onChanged: _handleGroupByChanged,
          ),
          const _HeaderActionDivider(),
          ReportAgingIntervalSection(
            selectedValue: _agingIntervals,
            onChanged: _handleAgingIntervalsChanged,
          ),
          const _HeaderActionDivider(),
          const ReportCustomizeColumnsButton(count: 9),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Receivables',
      currentNavigationReport: 'AR Aging Details',
      onReportSelected: (reportName, category) {
        if (reportName == 'AR Aging Details') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: ArAgingDetailsTable(
        rows: _rows,
        groupBy: _groupBy,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}
class _HeaderActionDivider extends StatelessWidget {
  const _HeaderActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.space10),
      child: SizedBox(
        height: AppTheme.space20,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderLight,
        ),
      ),
    );
  }
}
