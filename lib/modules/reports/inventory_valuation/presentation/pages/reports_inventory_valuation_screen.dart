import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory/presentation/widgets/inventory_valuation_summary_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

class InventoryValuationSummaryReportQuery {
  final int refreshKey;
  final int page;
  final int pageSize;
  final DateTime asOfDate;
  final String stockAvailability;
  final String status;

  const InventoryValuationSummaryReportQuery({
    required this.refreshKey,
    required this.page,
    required this.pageSize,
    required this.asOfDate,
    required this.stockAvailability,
    required this.status,
  });

  @override
  bool operator ==(Object other) {
    return other is InventoryValuationSummaryReportQuery &&
        other.refreshKey == refreshKey &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.asOfDate == asOfDate &&
        other.stockAvailability == stockAvailability &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        refreshKey,
        page,
        pageSize,
        asOfDate,
        stockAvailability,
        status,
      );
}

class InventoryValuationSummaryReportData {
  final List<InventoryValuationSummaryRow> rows;
  final InventoryValuationSummaryRow totals;
  final int totalCount;

  const InventoryValuationSummaryReportData({
    required this.rows,
    required this.totals,
    required this.totalCount,
  });
}

final inventoryValuationProvider = FutureProvider.autoDispose.family<
    InventoryValuationSummaryReportData,
    InventoryValuationSummaryReportQuery>((ref, query) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final dateFormatter = ReportFormatterCache.date('yyyy-MM-dd');
  final response = await repo.getInventoryValuation(
    page: query.page,
    limit: query.pageSize,
    endDate: dateFormatter.format(query.asOfDate),
    stockAvailability: query.stockAvailability,
    status: query.status,
  );
  final rows = List<Map<String, dynamic>>.from(response['data'] ?? const [])
      .map(InventoryValuationSummaryRow.fromJson)
      .where((row) => row.itemName.trim().isNotEmpty)
      .toList(growable: false);
  final meta = Map<String, dynamic>.from(response['meta'] ?? const {});
  final totalsMap = meta['totals'] is Map
      ? Map<String, dynamic>.from(meta['totals'] as Map)
      : null;
  return InventoryValuationSummaryReportData(
    rows: rows,
    totals: InventoryValuationSummaryRow.fromTotalsJson(totalsMap),
    totalCount: _intValue(meta['total']) ?? rows.length,
  );
});

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

class InventoryValuationScreen extends ConsumerStatefulWidget {
  const InventoryValuationScreen({super.key});

  @override
  ConsumerState<InventoryValuationScreen> createState() =>
      _InventoryValuationScreenState();
}

class _InventoryValuationScreenState
    extends ConsumerState<InventoryValuationScreen> {
  static const int _pageSize = 20;

  DateTime _asOfDate = DateTime.now();

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedGroupBy = 'None';
  static const List<String> _stockAvailabilityOptions = <String>[
    'No criteria',
    'Greater than zero',
    'Less than or equal to zero',
    'Less than zero',
    'Equal to zero',
    'Not equal to zero',
  ];

  String _selectedStockAvailability = 'No criteria';
  static const List<String> _statusOptions = <String>[
    'All',
    'Active',
    'Inactive',
  ];

  String _selectedStatus = 'All';

  String get _asOfLabel =>
      'As of ${ReportFormatterCache.date('dd-MM-yyyy').format(_asOfDate)}';

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

  void _handleAsOfChanged(ReportDateRangeSelection selection) {
    setState(() {
      _asOfDate = selection.endDate;
      _markFiltersDirty();
    });
  }

  void _handleGroupByChanged(String value) {
    if (_selectedGroupBy == value) return;
    setState(() {
      _selectedGroupBy = value;
      _markFiltersDirty();
    });
  }

  void _handleStockAvailabilityChanged(String value) {
    if (_selectedStockAvailability == value) return;
    setState(() {
      _selectedStockAvailability = value;
      _markFiltersDirty();
    });
  }

  void _handleStatusChanged(String value) {
    if (_selectedStatus == value) return;
    setState(() {
      _selectedStatus = value;
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
    AsyncValue<InventoryValuationSummaryReportData> rowsAsync,
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
    final query = InventoryValuationSummaryReportQuery(
      refreshKey: _refreshKey,
      page: _page,
      pageSize: _pageSize,
      asOfDate: _asOfDate,
      stockAvailability: _selectedStockAvailability,
      status: _selectedStatus,
    );
    final rowsAsync = ref.watch(inventoryValuationProvider(query));
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final reportData = rowsAsync.valueOrNull;
    final rows = reportData?.rows ?? const <InventoryValuationSummaryRow>[];
    final totals =
        reportData?.totals ?? InventoryValuationSummaryRow.emptyTotal();
    final totalCount = reportData?.totalCount ?? rows.length;

    return ReportViewScaffold(
      categoryLabel: 'Inventory Valuation',
      reportTitle: 'Inventory Valuation Summary',
      dateLabel: _asOfLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'As of',
          initialStartDate: _asOfDate,
          initialEndDate: _asOfDate,
          onChanged: _handleAsOfChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Stock Availability',
          value: _selectedStockAvailability,
          options: _stockAvailabilityOptions,
          onChanged: _handleStockAvailabilityChanged,
          width: 280,
          menuWidth: 156,
          menuMaxHeight: 244,
        ),
        ReportSearchableFilterDropdown(
          label: 'Status',
          value: _selectedStatus,
          options: _statusOptions,
          onChanged: _handleStatusChanged,
          width: 220,
          menuWidth: 156,
          menuMaxHeight: 196,
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
        reportName: 'Inventory Valuation Summary',
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
      settingsTooltip: 'Customize the Inventory Valuation Summary report.',
      scheduleTooltip: 'Schedule the Inventory Valuation Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _selectedGroupBy,
            options: const <String>['None'],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 3),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No inventory valuation rows found',
      emptyMessage:
          'There are no inventory valuation rows for the selected criteria.',
      currentNavigationCategory: 'Inventory Valuation',
      currentNavigationReport: 'Inventory Valuation Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'Inventory Valuation Summary') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: InventoryValuationSummaryTable(
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
