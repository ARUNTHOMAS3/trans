import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/advanced_inventory/presentation/widgets/serial_number_details_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';

class SerialNumberDetailsReportQuery {
  final int refreshKey;
  final int page;
  final int pageSize;
  final DateTime startDate;
  final DateTime endDate;
  final String reportBy;

  const SerialNumberDetailsReportQuery({
    required this.refreshKey,
    required this.page,
    required this.pageSize,
    required this.startDate,
    required this.endDate,
    required this.reportBy,
  });

  @override
  bool operator ==(Object other) {
    return other is SerialNumberDetailsReportQuery &&
        other.refreshKey == refreshKey &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.reportBy == reportBy;
  }

  @override
  int get hashCode => Object.hash(
        refreshKey,
        page,
        pageSize,
        startDate,
        endDate,
        reportBy,
      );
}

class SerialNumberDetailsReportData {
  final List<SerialNumberDetailsRow> rows;
  final int totalCount;

  const SerialNumberDetailsReportData({
    required this.rows,
    required this.totalCount,
  });
}

final serialNumberDetailsRowsProvider = FutureProvider.autoDispose.family<
    SerialNumberDetailsReportData,
    SerialNumberDetailsReportQuery>((ref, query) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final dateFormatter = ReportFormatterCache.date('yyyy-MM-dd');
  final response = await repository.getSerialNumberDetails(
    page: query.page,
    limit: query.pageSize,
    startDate: dateFormatter.format(query.startDate),
    endDate: dateFormatter.format(query.endDate),
    reportBy: query.reportBy,
  );
  final rows = List<Map<String, dynamic>>.from(response['data'] ?? const [])
      .map(SerialNumberDetailsRow.fromJson)
      .toList(growable: false);
  final meta = Map<String, dynamic>.from(response['meta'] ?? const {});
  return SerialNumberDetailsReportData(
    rows: rows,
    totalCount: _intValue(meta['total']) ?? rows.length,
  );
});

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

class SerialNumberDetailsPage extends ConsumerStatefulWidget {
  const SerialNumberDetailsPage({super.key});

  @override
  ConsumerState<SerialNumberDetailsPage> createState() =>
      _SerialNumberDetailsPageState();
}

class _SerialNumberDetailsPageState
    extends ConsumerState<SerialNumberDetailsPage> {
  static const int _pageSize = 200;
  static const String _defaultReportBy = 'Inward Transaction Date';

  DateTime _startDate = DateTime(2026, 7, 1);
  DateTime _endDate = DateTime(2026, 7, 31, 23, 59, 59);
  DateTime _appliedStartDate = DateTime(2026, 7, 1);
  DateTime _appliedEndDate = DateTime(2026, 7, 31, 23, 59, 59);
  final String _reportBy = _defaultReportBy;
  String _appliedReportBy = _defaultReportBy;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;

  void _markFiltersDirty() {
    _hasPendingFilterChanges = true;
    _isApplyingFilters = false;
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _markFiltersDirty();
    });
  }

  void _handleReportByPressed() {
    setState(_markFiltersDirty);
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
      _page = 1;
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedReportBy = _reportBy;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<SerialNumberDetailsReportData> rowsAsync,
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
    final query = SerialNumberDetailsReportQuery(
      refreshKey: _refreshKey,
      page: _page,
      pageSize: _pageSize,
      startDate: _appliedStartDate,
      endDate: _appliedEndDate,
      reportBy: _appliedReportBy,
    );
    final rowsAsync = ref.watch(serialNumberDetailsRowsProvider(query));
    _clearPendingAfterSuccessfulLoad(rowsAsync);

    final reportData = rowsAsync.valueOrNull;
    final rows = reportData?.rows ?? const <SerialNumberDetailsRow>[];
    final totalCount = reportData?.totalCount ?? rows.length;
    final dateLabel =
        'From ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate)} To ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate)}';

    return ReportViewScaffold(
      categoryLabel: 'Advanced Inventory',
      reportTitle: 'Serial Number Details',
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
          label: 'Report By',
          value: 'Inward Transacti...',
          onPressed: _handleReportByPressed,
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
        onChanged: () => setState(_markFiltersDirty),
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: 'Serial Number Details',
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
      settingsTooltip: 'Customize the Serial Number Details report.',
      scheduleTooltip: 'Schedule the Serial Number Details report.',
      tableHeaderActions: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: 'Applied',
            options: <String>['Applied'],
          ),
          SizedBox(width: AppTheme.space16),
          ReportCustomizeColumnsButton(count: 10),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No serial numbers found',
      emptyMessage: 'There are no transactions during the selected date range.',
      currentNavigationCategory: 'Advanced Inventory',
      currentNavigationReport: 'Serial Number Details',
      onReportSelected: (reportName, category) {
        if (reportName == 'Serial Number Details') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: SerialNumberDetailsTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        totalCount: totalCount,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}
