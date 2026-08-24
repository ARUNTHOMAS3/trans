import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/payments_received/presentation/widgets/payments_received_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

typedef PaymentsReceivedReportRequest = ({
  int refreshKey,
  DateTime startDate,
  DateTime endDate,
  String transactionType,
});

final paymentsReceivedReportRowsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, PaymentsReceivedReportRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final startDate = ReportFormatterCache.date('yyyy-MM-dd').format(request.startDate);
      final endDate = ReportFormatterCache.date('yyyy-MM-dd').format(request.endDate);
      return repository.getPaymentsReceivedRows(
        startDate,
        endDate,
        transactionType: request.transactionType,
        limit: 500,
      );
    });

class PaymentsReceivedPage extends ConsumerStatefulWidget {
  const PaymentsReceivedPage({super.key});

  @override
  ConsumerState<PaymentsReceivedPage> createState() =>
      _PaymentsReceivedPageState();
}

class _PaymentsReceivedPageState extends ConsumerState<PaymentsReceivedPage> {
  static const String _reportTitle = 'Payments Received';
  static const int _pageSize = 10;
  static final DateFormat _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 2,
  );
  static const List<String> _transactionTypeOptions = <String>[
    'All',
    'Invoice Payment',
    'Retainer Payment',
  ];

  ReportDateRangeSelection? _dateRangeSelection;

  ReportDateRangeSelection get _effectiveDateRangeSelection =>
      _dateRangeSelection ??
      ReportDateRangeSelection(
        startDate: DateTime(2026, 7),
        endDate: DateTime(2026, 7, 31, 23, 59, 59),
        label: ReportDateRangePresets.thisMonth,
      );

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  String _transactionType = 'All';
  String _groupBy = 'None';
  int _page = 1;
  int _refreshKey = 0;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;

  String get _dateLabel =>
      'From ${_displayDateFormat.format(_appliedStartDate)} To ${_displayDateFormat.format(_appliedEndDate)}';

  @override
  void initState() {
    super.initState();
    final selection = _effectiveDateRangeSelection;
    _appliedStartDate = selection.startDate;
    _appliedEndDate = selection.endDate;
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

  void _handleTransactionTypeChanged(String value) {
    if (_transactionType == value) return;
    setState(() {
      _transactionType = value;
      _hasPendingFilterChanges = true;
    });
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
    final selection = _effectiveDateRangeSelection;
    setState(() {
      _page = 1;
      _appliedStartDate = selection.startDate;
      _appliedEndDate = selection.endDate;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<Map<String, dynamic>>> rowsAsync,
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

  double _parseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatCurrency(double value) => _currencyFormat.format(value);

  @override
  Widget build(BuildContext context) {
    final dateRangeSelection = _effectiveDateRangeSelection;
    final rowsAsync = ref.watch(
      paymentsReceivedReportRowsProvider((
        refreshKey: _refreshKey,
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
        transactionType: _transactionType,
      )),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rawRows = rowsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final rows = rawRows
        .map(PaymentsReceivedRow.fromJson)
        .toList(growable: false);
    final amountTotal = rawRows.isEmpty
        ? 0.0
        : _parseNumber(rawRows.first['amountReceivedTotal']);
    final unusedTotal = rawRows.isEmpty
        ? 0.0
        : _parseNumber(rawRows.first['excessAmountTotal']);

    return ReportViewScaffold(
      categoryLabel: 'Payments Received',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: dateRangeSelection.startDate,
          initialEndDate: dateRangeSelection.endDate,
          onChanged: (selection) {
            setState(() {
              _dateRangeSelection = selection;
              _markFiltersDirty();
            });
          },
        ),
        ReportSearchableFilterDropdown(
          label: 'Transaction Type',
          value: _transactionType,
          options: _transactionTypeOptions,
          onChanged: _handleTransactionTypeChanged,
          width: 282,
          menuWidth: 156,
          menuMaxHeight: 204,
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
      settingsTooltip: 'Customize the Payments Received report.',
      scheduleTooltip: 'Schedule the Payments Received report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
              'Date',
              'Customer Name',
              'Payment Mode',
              'Created By',
              'Payment Type',
              'Currency',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 14),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No payments received found',
      emptyMessage:
          'There are no payments received recorded for the selected date range.',
      currentNavigationCategory: 'Payments Received',
      currentNavigationReport: 'Payments Received',
      onReportSelected: (reportName, category) {
        if (reportName == 'Payments Received') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: PaymentsReceivedTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        groupBy: _groupBy,
        amountBcyTotal: _formatCurrency(amountTotal),
        unusedAmountBcyTotal: _formatCurrency(unusedTotal),
      ),
    );
  }
}
