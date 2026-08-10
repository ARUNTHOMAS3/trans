import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/payables/presentation/widgets/ap_aging_details_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_aging_interval_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class ApAgingDetailsPage extends StatefulWidget {
  const ApAgingDetailsPage({super.key});

  @override
  State<ApAgingDetailsPage> createState() => _ApAgingDetailsPageState();
}

class _ApAgingDetailsPageState extends State<ApAgingDetailsPage> {
  static const String _reportTitle = 'AP Aging Details By Bill Due Date';
  static const String _dateLabel = 'As of 15-07-2026';
  static const int _pageSize = 18;

  static const List<ApAgingDetailsRow> _rows = [
    ApAgingDetailsRow.group(
      label: '> 45 Days',
      billAmount: '\u20B9185.00',
      balanceDue: '\u20B9185.00',
    ),
    ApAgingDetailsRow.bill(
      date: '05-05-2026',
      dueDate: '05-05-2026',
      transactionNumber: '11111',
      type: 'Bill',
      status: 'Overdue',
      vendorName: 'ZERPAI TESTING',
      age: '71 Days',
      billAmount: '\u20B9185.00',
      balanceDue: '\u20B9185.00',
    ),
    ApAgingDetailsRow.group(
      label: '16 - 30 Days',
      billAmount: '\u20B92,100.00',
      balanceDue: '\u20B92,100.00',
    ),
    ApAgingDetailsRow.bill(
      date: '15-06-2026',
      dueDate: '15-06-2026',
      transactionNumber: '32',
      type: 'Bill',
      status: 'Overdue',
      vendorName: 'FIRST LOGIC META\nLAB PRIVATE LIMITED',
      age: '30 Days',
      billAmount: '\u20B92,100.00',
      balanceDue: '\u20B92,100.00',
    ),
    ApAgingDetailsRow.group(
      label: 'Current',
      billAmount: '\u20B972,646.05',
      balanceDue: '\u20B972,646.05',
    ),
    ApAgingDetailsRow.bill(
      date: '24-04-2026',
      dueDate: '19-04-2027',
      transactionNumber: 'ftgyjnmk',
      type: 'Bill',
      status: 'Open',
      vendorName: 'ZERPAI TESTING',
      age: '',
      billAmount: '\u20B9500.00',
      balanceDue: '\u20B9500.00',
    ),
    ApAgingDetailsRow.bill(
      date: '05-05-2026',
      dueDate: '30-04-2027',
      transactionNumber: '12345',
      type: 'Bill',
      status: 'Open',
      vendorName: 'ZERPAI TESTING',
      age: '',
      billAmount: '\u20B92,103.73',
      balanceDue: '\u20B92,103.73',
    ),
    ApAgingDetailsRow.bill(
      date: '12-05-2026',
      dueDate: '07-05-2027',
      transactionNumber: '33333',
      type: 'Bill',
      status: 'Open',
      vendorName: 'ZERPAI TESTING',
      age: '',
      billAmount: '\u20B9123.92',
      balanceDue: '\u20B9123.92',
    ),
    ApAgingDetailsRow.bill(
      date: '30-05-2026',
      dueDate: '25-05-2027',
      transactionNumber: '2222',
      type: 'Bill',
      status: 'Open',
      vendorName: 'ZERPAI TESTING',
      age: '',
      billAmount: '\u20B93,163.50',
      balanceDue: '\u20B93,163.50',
    ),
    ApAgingDetailsRow.bill(
      date: '15-06-2026',
      dueDate: '10-06-2027',
      transactionNumber: '2312',
      type: 'Bill',
      status: 'Open',
      vendorName: 'ZERPAI TESTING',
      age: '',
      billAmount: '\u20B92,319.90',
      balanceDue: '\u20B92,319.90',
    ),
    ApAgingDetailsRow.bill(
      date: '24-06-2026',
      dueDate: '19-06-2027',
      transactionNumber: 'qwfgmk',
      type: 'Bill',
      status: 'Open',
      vendorName: 'ZERPAI TESTING',
      age: '',
      billAmount: '\u20B9500.00',
      balanceDue: '\u20B9500.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: 'ddfhhklouyy',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B92,375.00',
      balanceDue: '\u20B92,375.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: '7895632',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B92,850.00',
      balanceDue: '\u20B92,850.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: 'oouiugcc',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B9760.00',
      balanceDue: '\u20B9760.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: '12344',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B928,500.00',
      balanceDue: '\u20B928,500.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: '1qwdfgbnm',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B91,900.00',
      balanceDue: '\u20B91,900.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: 'wedfghnm',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B94,750.00',
      balanceDue: '\u20B94,750.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: 'qdfgjm,',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B92,850.00',
      balanceDue: '\u20B92,850.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: 'qaszax',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B96,650.00',
      balanceDue: '\u20B96,650.00',
    ),
    ApAgingDetailsRow.bill(
      date: '26-06-2026',
      dueDate: '21-06-2027',
      transactionNumber: 'EZSXCVBJNK',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B99,500.00',
      balanceDue: '\u20B99,500.00',
    ),
    ApAgingDetailsRow.bill(
      date: '30-06-2026',
      dueDate: '25-06-2027',
      transactionNumber: '23123',
      type: 'Bill',
      status: 'Open',
      vendorName: 'm, althaf',
      age: '',
      billAmount: '\u20B93,800.00',
      balanceDue: '\u20B93,800.00',
    ),
  ];

  ReportDateRangeSelection _asOfSelection = ReportDateRangeSelection(
    startDate: DateTime(2026, 7, 17),
    endDate: DateTime(2026, 7, 17, 23, 59, 59),
    label: ReportDateRangePresets.today,
  );

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  static const List<String> _agingByOptions = <String>[
    'Bill Due Date',
    'Bill Date',
  ];

  String _agingBy = 'Bill Due Date';
  static const List<String> _entityOptions = <String>[
    'Bill',
    'Vendor Credits',
    'Journal',
  ];

  List<String> _selectedEntities = const <String>['Bill'];
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
      categoryLabel: 'Payables',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'As of',
          initialStartDate: _asOfSelection.startDate,
          initialEndDate: _asOfSelection.endDate,
          onChanged: (selection) {
            setState(() {
              _asOfSelection = selection;
              _hasPendingFilterChanges = true;
            });
          },
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
      settingsTooltip: 'Customize the AP Aging Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
              'Vendor Name',
              'Currency',
            ],
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
      currentNavigationCategory: 'Payables',
      currentNavigationReport: 'AP Aging Details',
      onReportSelected: (reportName, category) {
        if (reportName == 'AP Aging Details') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: ApAgingDetailsTable(
        rows: _rows,
        page: _page,
        pageSize: _pageSize,
        totalCount: 18,
        onPageChanged: _handlePageChanged,
        groupBy: _groupBy,
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
