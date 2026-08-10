import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/pages/expense_details_page.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/widgets/expenses_by_customer_table.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

typedef ExpensesByCustomerRequest = ({
  int refreshKey,
  DateTime startDate,
  DateTime endDate,
});

final expensesByCustomerRowsProvider = FutureProvider.autoDispose
    .family<List<ExpensesByCustomerRow>, ExpensesByCustomerRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getExpensesByCustomer(
        startDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.startDate),
        endDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.endDate),
        limit: 500,
      );
      final rows = List<Map<String, dynamic>>.from(
        response['data'] ?? const [],
      );
      return rows.map(ExpensesByCustomerRow.fromJson).toList(growable: false);
    });

class ExpensesByCustomerPage extends ConsumerStatefulWidget {
  const ExpensesByCustomerPage({super.key});

  @override
  ConsumerState<ExpensesByCustomerPage> createState() =>
      _ExpensesByCustomerPageState();
}

class _ExpensesByCustomerPageState
    extends ConsumerState<ExpensesByCustomerPage> {
  static const String _reportTitle = 'Expenses by Customer';
  static const int _pageSize = 20;
  static final DateFormat _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

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
  int _page = 1;
  int _refreshKey = 0;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;

  @override
  void initState() {
    super.initState();
    final initialSelection = _effectiveDateRangeSelection;
    _appliedStartDate = initialSelection.startDate;
    _appliedEndDate = initialSelection.endDate;
  }

  String get _dateLabel =>
      'From ${_displayDateFormat.format(_appliedStartDate)} To ${_displayDateFormat.format(_appliedEndDate)}';

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

  void _runReport() {
    _closeMoreFilters();
    final dateRangeSelection = _effectiveDateRangeSelection;
    setState(() {
      _page = 1;
      _appliedStartDate = dateRangeSelection.startDate;
      _appliedEndDate = dateRangeSelection.endDate;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<ExpensesByCustomerRow>> rowsAsync,
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

  void _handleOthersSelected(ExpensesByCustomerRow row) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailsPage(
          customerName: row.customerName,
          initialStartDate: _appliedStartDate,
          initialEndDate: _appliedEndDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeSelection = _effectiveDateRangeSelection;
    final rowsAsync = ref.watch(
      expensesByCustomerRowsProvider((
        refreshKey: _refreshKey,
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
      )),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <ExpensesByCustomerRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Purchases and Expenses',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: dateRangeSelection.startDate,
          initialEndDate: dateRangeSelection.endDate,
          onChanged: (selection) {
            setState(() {
              _dateRangeSelection = selection;
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
      settingsTooltip: 'Customize the Expenses by Customer report.',
      tableHeaderActions: const ReportCustomizeColumnsButton(count: 4),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No customer expense rows found',
      emptyMessage: 'There are no expenses for the selected criteria.',
      currentNavigationCategory: 'Purchases and Expenses',
      currentNavigationReport: _reportTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _reportTitle &&
            category == 'Purchases and Expenses') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: ExpensesByCustomerTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        onOthersSelected: _handleOthersSelected,
      ),
    );
  }
}
