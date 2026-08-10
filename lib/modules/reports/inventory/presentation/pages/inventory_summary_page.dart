import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory/presentation/widgets/inventory_summary_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

final inventorySummaryRowsProvider = FutureProvider.autoDispose
    .family<List<InventorySummaryRow>, int>((ref, refreshKey) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getInventorySummary(limit: 500);
      final rows = List<Map<String, dynamic>>.from(
        response['data'] ?? const [],
      );
      if (rows.isEmpty) return const <InventorySummaryRow>[];
      return rows
          .map(InventorySummaryRow.fromInventoryValuation)
          .where((row) => row.itemName.trim().isNotEmpty)
          .toList(growable: false);
    });

class InventorySummaryPage extends ConsumerStatefulWidget {
  const InventorySummaryPage({super.key});

  @override
  ConsumerState<InventorySummaryPage> createState() =>
      _InventorySummaryPageState();
}

class _InventorySummaryPageState extends ConsumerState<InventorySummaryPage> {
  static const int _pageSize = 20;
  static const String _asOfLabel = 'As of 31-07-2026';
  static final DateTime _asOfStartDate = DateTime(2026, 7, 1);
  static final DateTime _asOfEndDate = DateTime(2026, 7, 31, 23, 59, 59);
  static const List<String> _stockAvailabilityOptions = <String>[
    'No criteria',
    'Greater than zero',
    'Less than or equal to zero',
    'Less than zero',
    'Equal to zero',
    'Not equal to zero',
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedGroupBy = 'None';
  String _selectedStockAvailability = 'No criteria';

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

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<InventorySummaryRow>> rowsAsync,
  ) {
    if (!_isApplyingFilters || rowsAsync.isLoading || !rowsAsync.hasValue)
      return;
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
    final rowsAsync = ref.watch(inventorySummaryRowsProvider(_refreshKey));
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <InventorySummaryRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Inventory',
      reportTitle: 'Inventory Summary',
      dateLabel: _asOfLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'As of',
          initialStartDate: _asOfStartDate,
          initialEndDate: _asOfEndDate,
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
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: 'Inventory Summary'),
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
      settingsTooltip: 'Customize the Inventory Summary report.',
      scheduleTooltip: 'Schedule the Inventory Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _selectedGroupBy,
            onChanged: _handleGroupByChanged,
            options: const [],
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 10),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No inventory summary rows found',
      emptyMessage: 'There are no inventory rows for the selected criteria.',
      currentNavigationCategory: 'Inventory',
      currentNavigationReport: 'Inventory Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'Inventory Summary') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: InventorySummaryTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}
