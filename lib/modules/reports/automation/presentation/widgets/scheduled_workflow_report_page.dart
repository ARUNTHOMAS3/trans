import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';

class ScheduledWorkflowColumnConfig {
  final String label;
  final int flex;
  final bool isSorted;

  const ScheduledWorkflowColumnConfig({
    required this.label,
    required this.flex,
    this.isSorted = false,
  });
}

class ScheduledWorkflowReportPage extends StatefulWidget {
  final String reportTitle;
  final List<ScheduledWorkflowColumnConfig> columns;
  final int customizeColumnCount;
  final String initialGroupBy;
  final bool showTopDateLabel;
  final bool showReloadAction;
  final bool showEntityClearIndicator;

  const ScheduledWorkflowReportPage({
    super.key,
    required this.reportTitle,
    required this.columns,
    required this.customizeColumnCount,
    this.initialGroupBy = 'None',
    this.showTopDateLabel = true,
    this.showReloadAction = true,
    this.showEntityClearIndicator = false,
  });

  @override
  State<ScheduledWorkflowReportPage> createState() =>
      _ScheduledWorkflowReportPageState();
}

class _ScheduledWorkflowReportPageState
    extends State<ScheduledWorkflowReportPage> {
  static final DateTime _defaultStartDate = DateTime(2026, 7, 1);
  static final DateTime _defaultEndDate = DateTime(2026, 7, 31);
  static final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');
  static const List<String> _entityOptions = <String>[
    'Retainer Invoice',
    'Invoice',
    'Customer',
    'Bill',
  ];
  static const List<String> _workflowRuleOptions = <String>[
    'Select a rule',
    'Payment reminder',
    'Invoice follow up',
    'Renewal reminder',
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  DateTime _startDate = _defaultStartDate;
  DateTime _endDate = _defaultEndDate;
  DateTime _appliedStartDate = _defaultStartDate;
  DateTime _appliedEndDate = _defaultEndDate;
  String _selectedEntity = 'Retainer Invoice';
  String _selectedWorkflowRule = 'Select a rule';
  late String _groupBy = widget.initialGroupBy;

  String get _dateLabel =>
      'From ${_displayDateFormat.format(_appliedStartDate)} To ${_displayDateFormat.format(_appliedEndDate)}';

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleEntityChanged(String value) {
    if (_selectedEntity == value) return;
    setState(() {
      _selectedEntity = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleWorkflowRuleChanged(String value) {
    if (_selectedWorkflowRule == value) return;
    setState(() {
      _selectedWorkflowRule = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() => _groupBy = value);
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
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _hasPendingFilterChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Automation',
      reportTitle: widget.reportTitle,
      dateLabel: widget.showTopDateLabel ? _dateLabel : '',
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Entity',
          value: _selectedEntity,
          options: _entityOptions,
          width: 212,
          labelSuffix: widget.showEntityClearIndicator
              ? const Icon(
                  Icons.close,
                  size: AppTheme.space14,
                  color: AppTheme.errorRed,
                )
              : null,
          onChanged: _handleEntityChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Workflow Rule',
          value: _selectedWorkflowRule,
          options: _workflowRuleOptions,
          width: 266,
          onChanged: _handleWorkflowRuleChanged,
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
      showExport: false,
      showReload: widget.showReloadAction,
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
      settingsTooltip: 'Customize the ${widget.reportTitle} report.',
      scheduleTooltip: 'Schedule the ${widget.reportTitle} report.',
      tableHeaderActions: _ScheduledWorkflowHeaderActions(
        groupBy: _groupBy,
        customizeColumnCount: widget.customizeColumnCount,
        onGroupByChanged: _handleGroupByChanged,
      ),
      currentNavigationCategory: 'Automation',
      currentNavigationReport: widget.reportTitle,
      onReportSelected: (selectedReport, category) {
        if (selectedReport == widget.reportTitle) return;
        openReportFromReportsModule(
          context,
          selectedReport,
          category: category,
        );
      },
      isEmpty: true,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      reportContent: ScheduledWorkflowEmptyTable(columns: widget.columns),
    );
  }
}

class _ScheduledWorkflowHeaderActions extends StatelessWidget {
  final String groupBy;
  final int customizeColumnCount;
  final ValueChanged<String> onGroupByChanged;

  const _ScheduledWorkflowHeaderActions({
    required this.groupBy,
    required this.customizeColumnCount,
    required this.onGroupByChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReportGroupBySection(
          selectedValue: groupBy,
          options: const <String>[
            'Execution Date',
          ],
          showClearAction: true,
          onChanged: onGroupByChanged,
        ),
        Container(
          width: 1,
          height: AppTheme.space24,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
          color: AppTheme.borderColor,
        ),
        ReportCustomizeColumnsButton(
          count: customizeColumnCount,
          onPressed: () {},
        ),
      ],
    );
  }
}

class ScheduledWorkflowEmptyTable extends StatelessWidget {
  final List<ScheduledWorkflowColumnConfig> columns;

  const ScheduledWorkflowEmptyTable({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScheduledWorkflowTableHeader(columns: columns),
        Expanded(
          child: Center(
            child: Text(
              'No data to display',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ScheduledWorkflowTableHeader extends StatelessWidget {
  final List<ScheduledWorkflowColumnConfig> columns;

  const ScheduledWorkflowTableHeader({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          for (final column in columns)
            _ScheduledWorkflowHeaderCell(column: column),
        ],
      ),
    );
  }
}

class _ScheduledWorkflowHeaderCell extends StatelessWidget {
  final ScheduledWorkflowColumnConfig column;

  const _ScheduledWorkflowHeaderCell({required this.column});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: column.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                column.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.metaHelper.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            if (column.isSorted) ...[
              const SizedBox(width: AppTheme.space4),
              Icon(
                Icons.unfold_more,
                size: AppTheme.space12,
                color: AppTheme.primaryBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
