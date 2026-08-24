import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/recurring_invoices/presentation/widgets/recurring_invoice_details_table.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

typedef RecurringInvoiceReportRequest = ({
  int refreshKey,
  DateTime startDate,
  DateTime endDate,
  String reportBy,
  String? recurringInvoiceId,
});

final recurringInvoiceReportRowsProvider = FutureProvider.autoDispose
    .family<List<RecurringInvoiceDetailsRow>, RecurringInvoiceReportRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final startDate = ReportFormatterCache.date('yyyy-MM-dd').format(request.startDate);
      final endDate = ReportFormatterCache.date('yyyy-MM-dd').format(request.endDate);
      final rows = request.recurringInvoiceId?.trim().isNotEmpty == true
          ? await repository.getRecurringInvoiceDetailRows(
              request.recurringInvoiceId!.trim(),
              startDate,
              endDate,
              reportBy: request.reportBy,
            )
          : await repository.getRecurringInvoiceRows(
              startDate,
              endDate,
              reportBy: request.reportBy,
              limit: 500,
            );
      return rows
          .map(RecurringInvoiceDetailsRow.fromJson)
          .toList(growable: false);
    });

class RecurringInvoiceDetailsPage extends ConsumerStatefulWidget {
  final String? recurringInvoiceId;
  final String? recurringInvoiceName;
  final ReportDateRangeSelection? initialDateRangeSelection;
  final String? initialReportBy;

  const RecurringInvoiceDetailsPage({
    super.key,
    this.recurringInvoiceId,
    this.recurringInvoiceName,
    this.initialDateRangeSelection,
    this.initialReportBy,
  });

  @override
  ConsumerState<RecurringInvoiceDetailsPage> createState() =>
      _RecurringInvoiceDetailsPageState();
}

class _RecurringInvoiceDetailsPageState
    extends ConsumerState<RecurringInvoiceDetailsPage> {
  static const String _summaryTitle = 'Recurring Invoice Details';
  static const String _detailsTitle = 'Recurring Invoice Details';
  static const int _pageSize = 10;
  static final DateFormat _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');
  static const List<String> _reportByOptions = <String>[
    'Next Invoice Date',
    'Last Invoice Date',
    'Expiry Date',
  ];

  late ReportDateRangeSelection _dateRangeSelection;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  String _groupBy = 'None';
  late String _reportBy;
  int _page = 1;
  int _refreshKey = 0;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;

  bool get _isDetailMode =>
      widget.recurringInvoiceId?.trim().isNotEmpty == true;

  String get _reportTitle => _isDetailMode
      ? '$_detailsTitle${widget.recurringInvoiceName?.trim().isNotEmpty == true ? ' - ${widget.recurringInvoiceName!.trim()}' : ''}'
      : _summaryTitle;

  String get _dateLabel =>
      'From ${_displayDateFormat.format(_appliedStartDate)} To ${_displayDateFormat.format(_appliedEndDate)}';

  @override
  void initState() {
    super.initState();
    _dateRangeSelection =
        widget.initialDateRangeSelection ??
        ReportDateRangeSelection(
          startDate: DateTime(2026, 7),
          endDate: DateTime(2026, 7, 31, 23, 59, 59),
          label: ReportDateRangePresets.thisMonth,
        );
    _appliedStartDate = _dateRangeSelection.startDate;
    _appliedEndDate = _dateRangeSelection.endDate;
    _reportBy = _reportByOptions.contains(widget.initialReportBy)
        ? widget.initialReportBy!
        : _reportByOptions.first;
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

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() {
      _groupBy = value;
      _hasPendingFilterChanges = true;
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
    AsyncValue<List<RecurringInvoiceDetailsRow>> rowsAsync,
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

  void _openRecurringInvoiceDetails(RecurringInvoiceDetailsRow row) {
    if (row.recurringInvoiceId.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecurringInvoiceDetailsPage(
          recurringInvoiceId: row.recurringInvoiceId,
          recurringInvoiceName: row.profileName,
          initialDateRangeSelection: _dateRangeSelection,
          initialReportBy: _reportBy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(
      recurringInvoiceReportRowsProvider((
        refreshKey: _refreshKey,
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
        reportBy: _reportBy,
        recurringInvoiceId: widget.recurringInvoiceId,
      )),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <RecurringInvoiceDetailsRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Recurring Invoices',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _dateRangeSelection.startDate,
          initialEndDate: _dateRangeSelection.endDate,
          onChanged: (selection) {
            setState(() {
              _dateRangeSelection = selection;
              _markFiltersDirty();
            });
          },
        ),
        ReportSearchableFilterDropdown(
          label: 'Report By',
          value: _reportBy,
          options: _reportByOptions,
          width: 244,
          menuWidth: 156,
          menuMaxHeight: 220,
          onChanged: (value) {
            setState(() {
              _reportBy = value;
              _markFiltersDirty();
            });
          },
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
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: _reportTitle),
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
      settingsTooltip: 'Customize the Recurring Invoice Details report.',
      scheduleTooltip: 'Schedule the Recurring Invoice Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
              'Customer Name',
              'Salesperson',
              'Currency',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 8),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No recurring invoices found',
      emptyMessage:
          'There are no recurring invoices recorded for the selected date range.',
      currentNavigationCategory: 'Recurring Invoices',
      currentNavigationReport: _summaryTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _summaryTitle && category == 'Recurring Invoices') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: RecurringInvoiceDetailsTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        onRowSelected: _isDetailMode ? null : _openRecurringInvoiceDetails,
        groupBy: _groupBy,
      ),
    );
  }
}
