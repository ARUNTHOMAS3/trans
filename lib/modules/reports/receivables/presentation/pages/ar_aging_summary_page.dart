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
import 'package:zerpai_erp/modules/reports/receivables/presentation/widgets/ar_aging_summary_table.dart';

class ArAgingSummaryPage extends StatefulWidget {
  const ArAgingSummaryPage({super.key});

  @override
  State<ArAgingSummaryPage> createState() => _ArAgingSummaryPageState();
}

class _ArAgingSummaryPageState extends State<ArAgingSummaryPage> {
  static const String _reportTitle = 'AR Aging Summary By Invoice Due Date';
  static const String _dateLabel = 'As of 15-07-2026';
  static final DateTime _asOfStartDate = DateTime(2026, 7, 15);
  static final DateTime _asOfEndDate = DateTime(2026, 7, 15, 23, 59, 59);

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  static const List<String> _agingByOptions = <String>[
    'Invoice Due Date',
    'Invoice Date',
  ];
  static const List<String> _entityOptions = <String>[
    'Invoice',
    'Credit Note',
    'Journal',
  ];
  static const List<String> _groupByOptions = <String>[
    'None',
    'Salesperson',
    'Currency',
  ];
  static const List<String> _showByOptions = <String>[
    'Outstanding Invoice Amount',
    'Invoice Count',
  ];

  String _agingBy = 'Invoice Due Date';
  List<String> _selectedEntities = _entityOptions;
  String _groupBy = 'None';
  String _showBy = 'Outstanding Invoice Amount';
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
      settingsTooltip: 'Customize the AR Aging Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: _groupByOptions,
            onChanged: _handleGroupByChanged,
          ),
          const _HeaderActionDivider(),
          ReportGroupBySection(
            label: 'Show By',
            leadingIcon: LucideIcons.eye,
            selectedValue: _showBy,
            options: _showByOptions,
            showClearAction: false,
            onChanged: _handleShowByChanged,
          ),
          const _HeaderActionDivider(),
          ReportAgingIntervalSection(
            selectedValue: _agingIntervals,
            onChanged: _handleAgingIntervalsChanged,
          ),
          const _HeaderActionDivider(),
          const ReportCustomizeColumnsButton(count: 4),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Receivables',
      currentNavigationReport: 'AR Aging Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'AR Aging Summary') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: ArAgingSummaryTable(
        page: _page,
        pageSize: 10,
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
