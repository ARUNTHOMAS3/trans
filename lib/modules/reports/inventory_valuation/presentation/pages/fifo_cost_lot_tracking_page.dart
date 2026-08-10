import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory_valuation/presentation/widgets/fifo_cost_lot_tracking_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';

typedef FifoCostLotTrackingQuery = ({
  int refreshKey,
  int page,
  int pageSize,
  String startDate,
  String endDate,
  String? search,
});

final fifoCostLotTrackingRowsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, FifoCostLotTrackingQuery>((ref, query) async {
      final repository = ref.watch(reportsRepositoryProvider);
      return repository.getFifoCostLotTracking(
        page: query.page,
        limit: query.pageSize,
        startDate: query.startDate,
        endDate: query.endDate,
        search: query.search,
      );
    });

class FifoCostLotTrackingPage extends ConsumerStatefulWidget {
  const FifoCostLotTrackingPage({super.key});

  @override
  ConsumerState<FifoCostLotTrackingPage> createState() =>
      _FifoCostLotTrackingPageState();
}

class _FifoCostLotTrackingPageState
    extends ConsumerState<FifoCostLotTrackingPage> {
  static const int _pageSize = 200;
  static const String _allItemsOption = 'All Items';

  final _apiDateFormat = ReportFormatterCache.date('yyyy-MM-dd');
  final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');
  late DateTime _draftStartDate;
  late DateTime _draftEndDate;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedItemName = _allItemsOption;
  String _appliedItemName = _allItemsOption;

  @override
  void initState() {
    super.initState();
    final initialRange = ReportDateRangePresets.resolveRange(
      ReportDateRangePresets.thisMonth,
    );
    _draftStartDate = initialRange.startDate;
    _draftEndDate = initialRange.endDate;
    _appliedStartDate = initialRange.startDate;
    _appliedEndDate = initialRange.endDate;
  }

  String get _dateLabel =>
      'From ${_displayDateFormat.format(_appliedStartDate)} '
      'To ${_displayDateFormat.format(_appliedEndDate)}';

  String get _appliedSearch => _appliedItemName == _allItemsOption
      ? ''
      : _normalizeItemName(_appliedItemName);

  FifoCostLotTrackingQuery get _query => (
    refreshKey: _refreshKey,
    page: _page,
    pageSize: _pageSize,
    startDate: _apiDateFormat.format(_appliedStartDate),
    endDate: _apiDateFormat.format(_appliedEndDate),
    search: _appliedSearch.isEmpty ? null : _appliedSearch,
  );

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

  List<String> _itemNameOptions(List<FifoCostLotTrackingRow> rows) {
    final itemNames = LinkedHashSet<String>()..add(_allItemsOption);
    if (_selectedItemName != _allItemsOption) itemNames.add(_selectedItemName);
    for (final row in rows) {
      final itemName = _normalizeItemName(row.itemName);
      if (itemName.isNotEmpty) itemNames.add(itemName);
    }
    return itemNames.toList(growable: false);
  }

  String _normalizeItemName(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _draftStartDate = selection.startDate;
      _draftEndDate = selection.endDate;
      _markFiltersDirty();
    });
  }

  void _handleItemNameChanged(String value) {
    if (_selectedItemName == value) return;
    setState(() {
      _selectedItemName = value;
      _markFiltersDirty();
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _appliedStartDate = _draftStartDate;
      _appliedEndDate = _draftEndDate;
      _appliedItemName = _selectedItemName;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(AsyncValue<Map<String, dynamic>> data) {
    if (!_isApplyingFilters || data.isLoading || !data.hasValue) return;
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

  List<FifoCostLotTrackingRow> _rowsFromResponse(Map<String, dynamic>? data) {
    final rows = data?['data'];
    if (rows is! List) return const <FifoCostLotTrackingRow>[];
    return rows
        .whereType<Map>()
        .map((row) => FifoCostLotTrackingRow.fromJson(
              Map<String, dynamic>.from(row),
            ))
        .toList(growable: false);
  }

  int _totalCountFromResponse(Map<String, dynamic>? data, int fallback) {
    final meta = data?['meta'];
    if (meta is Map && meta['total'] is num) return (meta['total'] as num).toInt();
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(fifoCostLotTrackingRowsProvider(_query));
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final response = rowsAsync.valueOrNull;
    final rows = _rowsFromResponse(response);
    final totalCount = _totalCountFromResponse(response, rows.length);
    final itemNameOptions = _itemNameOptions(rows);

    return ReportViewScaffold(
      categoryLabel: 'Inventory Valuation',
      reportTitle: 'FIFO Cost Lot Tracking',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _draftStartDate,
          initialEndDate: _draftEndDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Item Name',
          value: _selectedItemName,
          options: itemNameOptions,
          onChanged: _handleItemNameChanged,
          width: 250,
          menuWidth: 156,
          menuMaxHeight: 300,
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
        reportName: 'FIFO Cost Lot Tracking',
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
      settingsTooltip: 'Customize the FIFO Cost Lot Tracking report.',
      scheduleTooltip: 'Schedule the FIFO Cost Lot Tracking report.',
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No FIFO cost lot tracking rows found',
      emptyMessage:
          'There are no FIFO cost lot tracking rows for the selected criteria.',
      currentNavigationCategory: 'Inventory Valuation',
      currentNavigationReport: 'FIFO Cost Lot Tracking',
      onReportSelected: (reportName, category) {
        if (reportName == 'FIFO Cost Lot Tracking') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FifoReportMetadata(),
          const SizedBox(height: AppTheme.space24),
          Expanded(
            child: FifoCostLotTrackingTable(
              rows: rows,
              totalCount: totalCount,
              page: _page,
              pageSize: _pageSize,
              onPageChanged: _handlePageChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FifoReportMetadata extends StatelessWidget {
  const _FifoReportMetadata();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              LucideIcons.fileText,
              size: AppTheme.space14,
              color: AppTheme.textPrimary,
            ),
            SizedBox(width: AppTheme.space4),
            ReportCompanyHeader(companyName: ''),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Report Generation Basis:Product In',
          style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
