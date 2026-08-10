import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory/presentation/widgets/inventory_aging_summary_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_aging_interval_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_tooltip.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

class InventoryAgingSummaryRequest {
  final int refreshKey;
  final String asOfDate;
  final int intervalCount;
  final int intervalDays;

  const InventoryAgingSummaryRequest({
    required this.refreshKey,
    required this.asOfDate,
    required this.intervalCount,
    required this.intervalDays,
  });

  @override
  bool operator ==(Object other) {
    return other is InventoryAgingSummaryRequest &&
        other.refreshKey == refreshKey &&
        other.asOfDate == asOfDate &&
        other.intervalCount == intervalCount &&
        other.intervalDays == intervalDays;
  }

  @override
  int get hashCode =>
      Object.hash(refreshKey, asOfDate, intervalCount, intervalDays);
}

final inventoryAgingSummaryRowsProvider = FutureProvider.autoDispose
    .family<List<InventoryAgingSummaryRow>, InventoryAgingSummaryRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getInventoryAgingSummary(
        endDate: request.asOfDate,
        intervalCount: request.intervalCount,
        intervalDays: request.intervalDays,
        limit: 500,
      );
      final rows = List<Map<String, dynamic>>.from(
        response['data'] ?? const [],
      );
      if (rows.isEmpty) return const <InventoryAgingSummaryRow>[];
      return rows
          .map(InventoryAgingSummaryRow.fromJson)
          .where((row) => row.itemName.trim().isNotEmpty)
          .toList(growable: false);
    });

class InventoryAgingSummaryPage extends ConsumerStatefulWidget {
  const InventoryAgingSummaryPage({super.key});

  @override
  ConsumerState<InventoryAgingSummaryPage> createState() =>
      _InventoryAgingSummaryPageState();
}

class _InventoryAgingSummaryPageState
    extends ConsumerState<InventoryAgingSummaryPage> {
  static const int _pageSize = 20;
  static const String _asOfDate = '2026-07-13';
  static final DateTime _asOfStartDate = DateTime(2026, 7, 13);
  static final DateTime _asOfEndDate = DateTime(2026, 7, 13, 23, 59, 59);
  static const List<String> _stockTypeOptions = <String>[
    'No criteria',
    'Moving',
    'Not moving',
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedStockType = 'No criteria';
  String _selectedInterval = '6 X 3 Days';
  String _appliedInterval = '6 X 3 Days';

  String get _dateLabel =>
      'As of ${ReportFormatterCache.date('dd-MM-yyyy').format(DateTime.parse(_asOfDate))}';

  List<String> get _bucketLabels {
    final interval = _parseInterval(_appliedInterval);
    return List<String>.generate(interval.count, (index) {
      if (index == interval.count - 1) return '> ${index * interval.days} Days';
      final start = index * interval.days + 1;
      final end = (index + 1) * interval.days;
      return '$start - $end Days';
    }, growable: false);
  }

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

  void _handleAsOfChanged(ReportDateRangeSelection _) {
    _handleFilterControlChanged();
  }

  void _handleStockTypeChanged(String value) {
    if (_selectedStockType == value) return;
    setState(() {
      _selectedStockType = value;
      _markFiltersDirty();
    });
  }

  void _handleIntervalChanged(String value) {
    if (_selectedInterval == value) return;
    setState(() {
      _selectedInterval = value;
      _appliedInterval = value;
      _page = 1;
      _refreshKey += 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _appliedInterval = _selectedInterval;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<InventoryAgingSummaryRow>> rowsAsync,
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
    final applied = _parseInterval(_appliedInterval);
    final rowsAsync = ref.watch(
      inventoryAgingSummaryRowsProvider(
        InventoryAgingSummaryRequest(
          refreshKey: _refreshKey,
          asOfDate: _asOfDate,
          intervalCount: applied.count,
          intervalDays: applied.days,
        ),
      ),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <InventoryAgingSummaryRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Inventory',
      reportTitle: 'Inventory Aging Summary',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'As of',
          initialStartDate: _asOfStartDate,
          initialEndDate: _asOfEndDate,
          onChanged: _handleAsOfChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Stock Type',
          value: _selectedStockType,
          options: _stockTypeOptions,
          onChanged: _handleStockTypeChanged,
          width: 260,
          menuWidth: 156,
          menuMaxHeight: 196,
          labelSuffix: ReportTooltip(
            message:
                'Use this option to filter the last interval based on the stock that is moving or not moving.',
            child: const Icon(
              Icons.info_outline,
              size: AppTheme.space14,
              color: AppTheme.textMuted,
            ),
          ),
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
        reportName: 'Inventory Aging Summary',
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
      settingsTooltip: 'Customize the Inventory Aging Summary report.',
      scheduleTooltip: 'Schedule the Inventory Aging Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportAgingIntervalSection(
            selectedValue: _selectedInterval,
            onChanged: _handleIntervalChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 2),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No inventory aging rows found',
      emptyMessage:
          'There are no inventory aging rows for the selected criteria.',
      currentNavigationCategory: 'Inventory',
      currentNavigationReport: 'Inventory Aging Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'Inventory Aging Summary') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: InventoryAgingSummaryTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        bucketLabels: _bucketLabels,
      ),
    );
  }
}

({int count, int days}) _parseInterval(String value) {
  final match = RegExp(
    r'(\d+)\s*x\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return (count: 6, days: 3);
  final count = int.tryParse(match.group(1) ?? '') ?? 6;
  final days = int.tryParse(match.group(2) ?? '') ?? 3;
  return (count: count.clamp(1, 12), days: days.clamp(1, 365));
}
