import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/reports/inventory_valuation/presentation/widgets/landed_cost_summary_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';

class LandedCostSummaryReportQuery {
  final int refreshKey;
  final int page;
  final int pageSize;
  final DateTime startDate;
  final DateTime endDate;

  const LandedCostSummaryReportQuery({
    required this.refreshKey,
    required this.page,
    required this.pageSize,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    return other is LandedCostSummaryReportQuery &&
        other.refreshKey == refreshKey &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
        refreshKey,
        page,
        pageSize,
        startDate,
        endDate,
      );
}

class LandedCostSummaryReportData {
  final List<LandedCostSummaryRow> rows;
  final LandedCostSummaryRow totals;
  final int totalCount;

  const LandedCostSummaryReportData({
    required this.rows,
    required this.totals,
    required this.totalCount,
  });
}

final landedCostSummaryRowsProvider = FutureProvider.autoDispose.family<
    LandedCostSummaryReportData,
    LandedCostSummaryReportQuery>((ref, query) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final dateFormatter = ReportFormatterCache.date('yyyy-MM-dd');
  final response = await repository.getLandedCostSummary(
    page: query.page,
    limit: query.pageSize,
    startDate: dateFormatter.format(query.startDate),
    endDate: dateFormatter.format(query.endDate),
  );
  final rows = List<Map<String, dynamic>>.from(response['data'] ?? const [])
      .map(LandedCostSummaryRow.fromJson)
      .toList(growable: false);
  final meta = Map<String, dynamic>.from(response['meta'] ?? const {});
  final totalsMap = meta['totals'] is Map
      ? Map<String, dynamic>.from(meta['totals'] as Map)
      : null;
  return LandedCostSummaryReportData(
    rows: rows,
    totals: LandedCostSummaryRow.fromTotalsJson(totalsMap),
    totalCount: _intValue(meta['total']) ?? rows.length,
  );
});

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

class LandedCostSummaryPage extends ConsumerStatefulWidget {
  const LandedCostSummaryPage({super.key});

  @override
  ConsumerState<LandedCostSummaryPage> createState() =>
      _LandedCostSummaryPageState();
}

class _LandedCostSummaryPageState extends ConsumerState<LandedCostSummaryPage> {
  static const int _pageSize = 20;
  DateTime _startDate = DateTime(2026, 4, 1);
  DateTime _endDate = DateTime(2027, 3, 31, 23, 59, 59);
  DateTime _appliedStartDate = DateTime(2026, 4, 1);
  DateTime _appliedEndDate = DateTime(2027, 3, 31, 23, 59, 59);

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;

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
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _markFiltersDirty();
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<LandedCostSummaryReportData> rowsAsync,
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
    final query = LandedCostSummaryReportQuery(
      refreshKey: _refreshKey,
      page: _page,
      pageSize: _pageSize,
      startDate: _appliedStartDate,
      endDate: _appliedEndDate,
    );
    final rowsAsync = ref.watch(landedCostSummaryRowsProvider(query));
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final reportData = rowsAsync.valueOrNull;
    final rows = reportData?.rows ?? const <LandedCostSummaryRow>[];
    final totals = reportData?.totals ?? LandedCostSummaryRow.emptyTotal();
    final totalCount = reportData?.totalCount ?? rows.length;
    final dateLabel =
        'From ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate)} To ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate)}';

    return ReportViewScaffold(
      categoryLabel: 'Inventory Valuation',
      reportTitle: 'Landed Cost Summary',
      dateLabel: dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _startDate,
          initialEndDate: _endDate,
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
      settingsTooltip: 'Customize the Landed Cost Summary report.',
      tableHeaderActions: const ReportCustomizeColumnsButton(count: 7),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No landed cost rows found',
      emptyMessage: 'There are no landed cost rows for the selected criteria.',
      currentNavigationCategory: 'Inventory Valuation',
      currentNavigationReport: 'Landed Cost Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'Landed Cost Summary') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: LandedCostSummaryTable(
        rows: rows,
        totals: totals,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        totalCount: totalCount,
        serverPaginated: true,
      ),
    );
  }
}
