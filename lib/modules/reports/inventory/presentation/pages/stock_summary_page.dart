import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory/presentation/widgets/stock_summary_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

class StockSummaryReportData {
  final List<StockSummaryRow> rows;
  final StockSummaryRow totals;

  const StockSummaryReportData({required this.rows, required this.totals});
}

final stockSummaryRowsProvider = FutureProvider.autoDispose
    .family<StockSummaryReportData, int>((ref, refreshKey) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getStockSummary(
        startDate: '2026-07-01',
        endDate: '2026-07-31',
        limit: 500,
      );
      final rows = List<Map<String, dynamic>>.from(response['data'] ?? const [])
          .map(StockSummaryRow.fromJson)
          .where((row) => row.itemName.trim().isNotEmpty)
          .toList(growable: false);
      final meta = response['meta'] is Map
          ? Map<String, dynamic>.from(response['meta'] as Map)
          : const <String, dynamic>{};
      final totals = meta['totals'] is Map
          ? StockSummaryRow.fromTotals(
              Map<String, dynamic>.from(meta['totals'] as Map),
            )
          : StockSummaryRow.totalFromRows(rows);
      return StockSummaryReportData(rows: rows, totals: totals);
    });

class StockSummaryPage extends ConsumerStatefulWidget {
  const StockSummaryPage({super.key});

  @override
  ConsumerState<StockSummaryPage> createState() => _StockSummaryPageState();
}

class _StockSummaryPageState extends ConsumerState<StockSummaryPage> {
  static const int _pageSize = 20;
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedGroupBy = 'None';

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

  void _handleGroupByChanged(String value) {
    if (_selectedGroupBy == value) return;
    setState(() {
      _selectedGroupBy = value;
      _markFiltersDirty();
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<StockSummaryReportData> rowsAsync,
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
    final rowsAsync = ref.watch(stockSummaryRowsProvider(_refreshKey));
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final reportData = rowsAsync.valueOrNull;
    final rows = reportData?.rows ?? const <StockSummaryRow>[];
    final totals = reportData?.totals ?? StockSummaryRow.totalFromRows(rows);

    return ReportViewScaffold(
      categoryLabel: 'Inventory',
      reportTitle: 'Stock Summary Report',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _handleFilterControlChanged,
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
        reportName: 'Stock Summary Report',
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
      settingsTooltip: 'Customize the Stock Summary report.',
      scheduleTooltip: 'Schedule the Stock Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _selectedGroupBy,
            onChanged: _handleGroupByChanged,
            options: const [],
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 6),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No stock summary rows found',
      emptyMessage:
          'There are no stock summary rows for the selected criteria.',
      currentNavigationCategory: 'Inventory',
      currentNavigationReport: 'Stock Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'Stock Summary') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: StockSummaryTable(
        rows: rows,
        totals: totals,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}
