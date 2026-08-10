import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/widgets/expense_details_table.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

typedef ExpenseDetailsRequest = ({
  int refreshKey,
  DateTime startDate,
  DateTime endDate,
  List<String> entities,
  String? filterBy,
  String? accountType,
  String? categoryName,
  String? customerName,
});

final expenseDetailsRowsProvider = FutureProvider.autoDispose
    .family<List<ExpenseDetailsRow>, ExpenseDetailsRequest>((
      ref,
      request,
    ) async {
      if (!request.entities.contains('Expense')) {
        return const <ExpenseDetailsRow>[];
      }
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getExpenseDetails(
        startDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.startDate),
        endDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.endDate),
        limit: 500,
        filterBy: request.filterBy,
        accountType: request.accountType,
        categoryName: request.categoryName,
        customerName: request.customerName,
      );
      final rows = List<Map<String, dynamic>>.from(
        response['data'] ?? const [],
      );
      return rows.map(ExpenseDetailsRow.fromJson).toList(growable: false);
    });

class ExpenseDetailsPage extends ConsumerStatefulWidget {
  final String? categoryName;
  final String? customerName;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? filterBy;
  final String? accountType;

  const ExpenseDetailsPage({
    super.key,
    this.categoryName,
    this.customerName,
    this.initialStartDate,
    this.initialEndDate,
    this.filterBy,
    this.accountType,
  });

  @override
  ConsumerState<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends ConsumerState<ExpenseDetailsPage> {
  static const String _reportTitle = 'Expense Details';
  static const int _pageSize = 20;
  static const List<String> _entityOptions = <String>[
    'Bill',
    'Vendor Credits',
    'Expense',
  ];
  static final DateFormat _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

  ReportDateRangeSelection? _dateRangeSelection;

  bool get _isCategoryDetail =>
      widget.categoryName != null && widget.categoryName!.trim().isNotEmpty;

  bool get _isCustomerDetail =>
      widget.customerName != null && widget.customerName!.trim().isNotEmpty;

  bool get _isSummaryDetail => _isCategoryDetail || _isCustomerDetail;

  String get _effectiveReportTitle {
    if (_isCategoryDetail) {
      return 'Expenses For ${widget.categoryName!.trim()}';
    }
    if (_isCustomerDetail) {
      return 'Expenses For ${widget.customerName!.trim()}';
    }
    return _reportTitle;
  }

  ReportDateRangeSelection get _effectiveDateRangeSelection =>
      _dateRangeSelection ??
      ReportDateRangeSelection(
        startDate: widget.initialStartDate ?? DateTime(2026, 7),
        endDate: widget.initialEndDate ?? DateTime(2026, 7, 31, 23, 59, 59),
        label: ReportDateRangePresets.thisMonth,
      );

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  List<String> _selectedEntities = <String>['Expense'];
  List<String> _appliedEntities = <String>['Expense'];
  String _groupBy = 'None';
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

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() {
      _groupBy = value;
      _refreshKey += 1;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    final dateRangeSelection = _effectiveDateRangeSelection;
    setState(() {
      _page = 1;
      _appliedStartDate = dateRangeSelection.startDate;
      _appliedEndDate = dateRangeSelection.endDate;
      _appliedEntities = List<String>.from(_selectedEntities);
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<ExpenseDetailsRow>> rowsAsync,
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
    final dateRangeSelection = _effectiveDateRangeSelection;
    final rowsAsync = ref.watch(
      expenseDetailsRowsProvider((
        refreshKey: _refreshKey,
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
        entities: _appliedEntities,
        filterBy: widget.filterBy,
        accountType: widget.accountType,
        categoryName: widget.categoryName,
        customerName: widget.customerName,
      )),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <ExpenseDetailsRow>[];

    return ReportViewScaffold(
      categoryLabel: _isCategoryDetail
          ? 'Purchases and Expenses > Expense Summary by Category'
          : _isCustomerDetail
          ? 'Purchases and Expenses > Expenses by Customer'
          : 'Purchases and Expenses',
      reportTitle: _effectiveReportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: _isSummaryDetail
          ? [
              ReportSearchableFilterDropdown(
                label: 'Project',
                value: 'Select a project',
                options: const <String>['Select a project'],
                onChanged: (_) {},
              ),
            ]
          : [
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
              ReportEntitiesFilter(
                options: _entityOptions,
                initialSelection: _selectedEntities,
                onChanged: (selection) {
                  setState(() {
                    _selectedEntities = selection;
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
      settingsTooltip: 'Customize the Expense Details report.',
      tableHeaderActions: _isSummaryDetail
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReportGroupBySection(
                  selectedValue: _groupBy,
                  options: const <String>[
                    'Date',
                    'Transaction Type',
                    'Vendor Name',
                    'Customer Name',
                  ],
                  onChanged: _handleGroupByChanged,
                ),
                const SizedBox(width: AppTheme.space10),
                const ReportCustomizeColumnsButton(count: 10),
              ],
            ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No expense rows found',
      emptyMessage: 'There are no expenses for the selected criteria.',
      currentNavigationCategory: 'Purchases and Expenses',
      currentNavigationReport: _effectiveReportTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _effectiveReportTitle &&
            category == 'Purchases and Expenses') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: ExpenseDetailsTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        categoryDetailMode: _isCategoryDetail,
        customerDetailMode: _isCustomerDetail,
      ),
    );
  }
}
