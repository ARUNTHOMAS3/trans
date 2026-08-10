import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory/presentation/widgets/committed_stock_details_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

typedef CommittedStockDetailsRequest = ({
  int refreshKey,
  DateTime startDate,
  DateTime endDate,
});

final committedStockDetailsRowsProvider = FutureProvider.autoDispose
    .family<List<CommittedStockDetailsRow>, CommittedStockDetailsRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getCommittedStockDetails(
        startDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.startDate),
        endDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.endDate),
        limit: 500,
      );
      final rows = List<Map<String, dynamic>>.from(
        response['data'] ?? const [],
      );
      if (rows.isEmpty) return const <CommittedStockDetailsRow>[];
      return rows
          .map(CommittedStockDetailsRow.fromJson)
          .where(
            (row) =>
                row.transactionNumber.trim().isNotEmpty &&
                row.itemName.trim().isNotEmpty,
          )
          .toList(growable: false);
    });

class CommittedStockDetailsPage extends ConsumerStatefulWidget {
  const CommittedStockDetailsPage({super.key});

  @override
  ConsumerState<CommittedStockDetailsPage> createState() =>
      _CommittedStockDetailsPageState();
}

class _CommittedStockDetailsPageState
    extends ConsumerState<CommittedStockDetailsPage> {
  static const int _pageSize = 20;
  static final DateFormat _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');
  static final DateTime _initialStartDate = DateTime(2026, 7, 1);
  static final DateTime _initialEndDate = DateTime(2026, 7, 31, 23, 59, 59);

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedGroupBy = 'None';
  late ReportDateRangeSelection _dateRangeSelection;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;

  @override
  void initState() {
    super.initState();
    _dateRangeSelection = ReportDateRangeSelection(
      startDate: _initialStartDate,
      endDate: _initialEndDate,
      label: ReportDateRangePresets.thisMonth,
    );
    _appliedStartDate = _dateRangeSelection.startDate;
    _appliedEndDate = _dateRangeSelection.endDate;
  }

  String get _dateLabel =>
      'From ' +
      _displayDateFormat.format(_appliedStartDate) +
      ' To ' +
      _displayDateFormat.format(_appliedEndDate);

  void _markFiltersDirty() {
    _hasPendingFilterChanges = true;
    _isApplyingFilters = false;
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _handleFilterControlChanged() {
    setState(_markFiltersDirty);
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    if (_dateRangeSelection.startDate.isAtSameMomentAs(selection.startDate) &&
        _dateRangeSelection.endDate.isAtSameMomentAs(selection.endDate)) {
      return;
    }
    setState(() {
      _dateRangeSelection = selection;
      _markFiltersDirty();
    });
  }

  void _handleGroupByChanged(String value) {
    if (_selectedGroupBy == value) return;
    setState(() {
      _selectedGroupBy = value;
      _refreshKey += 1;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _appliedStartDate = _dateRangeSelection.startDate;
      _appliedEndDate = _dateRangeSelection.endDate;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<CommittedStockDetailsRow>> rowsAsync,
  ) {
    if (!_isApplyingFilters || rowsAsync.isLoading || !rowsAsync.hasValue) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isApplyingFilters) return;
      setState(() {
        _isApplyingFilters = false;
        _hasPendingFilterChanges = false;
      });
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(
      committedStockDetailsRowsProvider((
        refreshKey: _refreshKey,
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
      )),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <CommittedStockDetailsRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Inventory',
      reportTitle: 'Committed Stock Details',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _dateRangeSelection.startDate,
          initialEndDate: _dateRangeSelection.endDate,
          onChanged: _handleDateRangeChanged,
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
        onChanged: _handleFilterControlChanged,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: 'Committed Stock Details',
      ),
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
      settingsTooltip: 'Customize the Committed Stock Details report.',
      scheduleTooltip: 'Schedule the Committed Stock Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _selectedGroupBy,
            onChanged: _handleGroupByChanged,
            options: const [
              'None',
              'Transaction#',
              'Salesperson',
              'Order Type',
              'Date',
              'Customer Name',
              'Item Name',
            ],
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 3),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No committed stock rows found',
      emptyMessage:
          'There are no committed stock rows for the selected criteria.',
      currentNavigationCategory: 'Inventory',
      currentNavigationReport: 'Committed Stock Details',
      onReportSelected: (reportName, category) {
        if (reportName == 'Committed Stock Details') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: CommittedStockDetailsTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        groupBy: _selectedGroupBy,
      ),
    );
  }
}
