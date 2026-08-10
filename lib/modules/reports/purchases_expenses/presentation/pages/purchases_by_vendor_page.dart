import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/pages/purchase_details_for_vendor_page.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/widgets/purchases_by_vendor_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/sales/presentation/widgets/sales_by_customer_table.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

typedef PurchasesByVendorRequest = ({
  int refreshKey,
  DateTime startDate,
  DateTime endDate,
  String filterBy,
});

final purchasesByVendorRowsProvider = FutureProvider.autoDispose
    .family<List<PurchasesByVendorRow>, PurchasesByVendorRequest>((
      ref,
      request,
    ) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getPurchasesByVendor(
        startDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.startDate),
        endDate: ReportFormatterCache.date('yyyy-MM-dd').format(request.endDate),
        filterBy: request.filterBy,
        limit: 500,
      );
      final rows = List<Map<String, dynamic>>.from(
        response['data'] ?? const [],
      );
      return rows.map(PurchasesByVendorRow.fromJson).toList(growable: false);
    });

class PurchasesByVendorPage extends ConsumerStatefulWidget {
  const PurchasesByVendorPage({super.key});

  @override
  ConsumerState<PurchasesByVendorPage> createState() =>
      _PurchasesByVendorPageState();
}

class _PurchasesByVendorPageState extends ConsumerState<PurchasesByVendorPage> {
  static const String _reportTitle = 'Purchases by Vendor';
  static const int _pageSize = 20;
  static final DateFormat _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');
  static const List<String> _filterByOptions = <String>[
    'All',
    'Bills',
    'Expenses',
    'Manual Journals',
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
  String _filterBy = 'All';
  String _appliedFilterBy = 'All';
  String _compareWith = 'None';
  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
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

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareSelection = selection;
      _compareWith = selection.displayValue;
      _refreshKey += 1;
    });
  }

  List<SalesByCustomerComparisonPeriod> _buildComparisonPeriods() {
    if (!_compareSelection.isActive) {
      return const <SalesByCustomerComparisonPeriod>[];
    }

    final count = _compareSelection.count.clamp(1, 5);
    final currentPeriod = SalesByCustomerComparisonPeriod(
      label: _formatComparisonPeriod(_appliedStartDate, _appliedEndDate),
      isCurrent: true,
    );
    final previousPeriods = <SalesByCustomerComparisonPeriod>[];

    if (_compareSelection.compareType == 'Previous Year(s)') {
      for (var offset = count; offset >= 1; offset -= 1) {
        previousPeriods.add(
          SalesByCustomerComparisonPeriod(
            label: _formatComparisonPeriod(
              _shiftDateByYears(_appliedStartDate, -offset),
              _shiftDateByYears(_appliedEndDate, -offset),
            ),
            isCurrent: false,
          ),
        );
      }
    } else {
      final periodDays = _appliedEndDate.difference(_appliedStartDate).inDays + 1;
      for (var offset = count; offset >= 1; offset -= 1) {
        final previousEnd = _appliedStartDate.subtract(
          Duration(days: periodDays * (offset - 1) + 1),
        );
        final previousStart = previousEnd.subtract(Duration(days: periodDays - 1));
        previousPeriods.add(
          SalesByCustomerComparisonPeriod(
            label: _formatComparisonPeriod(previousStart, previousEnd),
            isCurrent: false,
          ),
        );
      }
    }

    final periods = <SalesByCustomerComparisonPeriod>[
      ...previousPeriods,
      currentPeriod,
    ];
    if (_compareSelection.arrangeLatestFirst) {
      return periods.reversed.toList(growable: false);
    }
    return periods;
  }

  DateTime _shiftDateByYears(DateTime date, int years) {
    final targetYear = date.year + years;
    final lastDayOfTargetMonth = DateTime(targetYear, date.month + 1, 0).day;
    return DateTime(
      targetYear,
      date.month,
      date.day.clamp(1, lastDayOfTargetMonth),
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  String _formatComparisonPeriod(DateTime startDate, DateTime endDate) {
    final formatter = ReportFormatterCache.date('MMM yyyy');
    return '${formatter.format(startDate).toUpperCase()} - ${formatter.format(endDate).toUpperCase()}';
  }

  void _runReport() {
    _closeMoreFilters();
    final dateRangeSelection = _effectiveDateRangeSelection;
    setState(() {
      _page = 1;
      _appliedStartDate = dateRangeSelection.startDate;
      _appliedEndDate = dateRangeSelection.endDate;
      _appliedFilterBy = _filterBy;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<PurchasesByVendorRow>> rowsAsync,
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

  void _openVendorDetails(PurchasesByVendorRow row) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseDetailsForVendorPage(
          vendorName: row.vendorName,
          dateLabel: _dateLabel,
          filterBy: _appliedFilterBy,
          rows: row.details,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeSelection = _effectiveDateRangeSelection;
    final rowsAsync = ref.watch(
      purchasesByVendorRowsProvider((
        refreshKey: _refreshKey,
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
        filterBy: _appliedFilterBy,
      )),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <PurchasesByVendorRow>[];

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
        ReportSearchableFilterDropdown(
          label: 'Filter By',
          value: _filterBy,
          options: _filterByOptions,
          width: 228,
          menuWidth: 152,
          menuMaxHeight: 184,
          onChanged: (selection) {
            setState(() {
              _filterBy = selection;
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
      settingsTooltip: 'Customize the Purchases by Vendor report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportCompareSection(
            selectedValue: _compareWith,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 7),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No purchases found',
      emptyMessage: 'There are no purchases for the selected report filters.',
      currentNavigationCategory: 'Purchases and Expenses',
      currentNavigationReport: _reportTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _reportTitle &&
            category == 'Purchases and Expenses') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: PurchasesByVendorTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        onVendorSelected: _openVendorDetails,
        comparisonPeriods: _buildComparisonPeriods(),
      ),
    );
  }
}
