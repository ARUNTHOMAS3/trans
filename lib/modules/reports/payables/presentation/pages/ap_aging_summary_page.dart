import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/payables/presentation/widgets/ap_aging_summary_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_aging_interval_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class ApAgingSummaryPage extends StatefulWidget {
  const ApAgingSummaryPage({super.key});

  @override
  State<ApAgingSummaryPage> createState() => _ApAgingSummaryPageState();
}

class _ApAgingSummaryPageState extends State<ApAgingSummaryPage> {
  static const String _reportTitle = 'AP Aging Summary By Bill Due Date';
  static const String _dateLabel = 'As of 15-07-2026';
  static const int _pageSize = 10;

  static const List<ApAgingSummaryRow> _rows = [
    ApAgingSummaryRow(
      vendorName: 'FIRST LOGIC META LAB\nPRIVATE LIMITED',
      current: '\u20B90.00',
      oneToFifteen: '\u20B90.00',
      sixteenToThirty: '\u20B92,100.00',
      thirtyOneToFortyFive: '\u20B90.00',
      overFortyFive: '\u20B90.00',
      total: '\u20B92,100.00',
      totalFcy: '\u20B92,100.00',
    ),
    ApAgingSummaryRow(
      vendorName: 'm, althaf',
      current: '\u20B963,935.00',
      oneToFifteen: '\u20B90.00',
      sixteenToThirty: '\u20B90.00',
      thirtyOneToFortyFive: '\u20B90.00',
      overFortyFive: '\u20B90.00',
      total: '\u20B963,935.00',
      totalFcy: '\u20B963,935.00',
    ),
    ApAgingSummaryRow(
      vendorName: 'ZERPAI TESTING',
      current: '\u20B98,711.05',
      oneToFifteen: '\u20B90.00',
      sixteenToThirty: '\u20B90.00',
      thirtyOneToFortyFive: '\u20B90.00',
      overFortyFive: '\u20B9185.00',
      total: '\u20B98,896.05',
      totalFcy: '\u20B98,896.05',
    ),
  ];

  ReportDateRangeSelection _asOfSelection = ReportDateRangeSelection(
    startDate: DateTime(2026, 7, 17),
    endDate: DateTime(2026, 7, 17, 23, 59, 59),
    label: ReportDateRangePresets.today,
  );

  static const List<String> _agingByOptions = <String>[
    'Bill Due Date',
    'Bill Date',
  ];
  static const List<String> _entityOptions = <String>[
    'Bill',
    'Vendor Credit',
    'Journal',
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _agingBy = 'Bill Due Date';
  List<String> _selectedEntities = const <String>['Bill'];
  String _groupBy = 'None';
  String _showBy = 'Outstanding Bill Amount';
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

  void _handleShowByChanged(String value) {
    if (_showBy == value) return;
    setState(() {
      _showBy = value;
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
      settingsTooltip: 'Customize the AP Aging Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
              'Currency',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const _HeaderActionDivider(),
          ReportGroupBySection(
            label: 'Show By',
            leadingIcon: LucideIcons.eye,
            selectedValue: _showBy,
            options: const <String>[
              'Outstanding Bill Amount',
              'Bill Count',
            ],
            showClearAction: false,
            onChanged: _handleShowByChanged,
          ),
          const _HeaderActionDivider(),
          ReportAgingIntervalSection(
            selectedValue: _agingIntervals,
            onChanged: _handleAgingIntervalsChanged,
          ),
          const _HeaderActionDivider(),
          const ReportCustomizeColumnsButton(count: 5),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Payables',
      currentNavigationReport: 'AP Aging Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'AP Aging Summary') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: ApAgingSummaryTable(
        rows: _rows,
        page: _page,
        pageSize: _pageSize,
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
