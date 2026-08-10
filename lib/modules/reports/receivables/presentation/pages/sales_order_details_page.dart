import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/receivables/presentation/widgets/sales_order_details_table.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';

const String _salesOrderDetailsTitle = 'Sales Order Details';
const String _salesOrderDetailsBasis = 'Accrual';
const List<String> _statusOptions = <String>[
  'All',
  'Draft',
  'Pending',
  'Confirmed',
  'Void',
  'Closed',
  'Partially Invoiced',
  'Invoiced',
  'Not Invoiced',
];
const List<String> _salesOrderGroupByOptions = <String>[
  'Date',
  'Customer Name',
  'Salesperson',
  'Currency',
  'Location',
];

typedef SalesOrderDetailsParams = ({
  String startDate,
  String endDate,
  String basis,
  String status,
  int page,
  int pageSize,
});

final salesOrderDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, SalesOrderDetailsParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getSalesOrderDetails(
    params.startDate,
    params.endDate,
    basis: params.basis,
    status: params.status,
    page: params.page,
    pageSize: params.pageSize,
  );
});

class SalesOrderDetailsPage extends ConsumerStatefulWidget {
  const SalesOrderDetailsPage({super.key});

  @override
  ConsumerState<SalesOrderDetailsPage> createState() =>
      _SalesOrderDetailsPageState();
}

class _SalesOrderDetailsPageState extends ConsumerState<SalesOrderDetailsPage> {
  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  List<String> _selectedStatuses = List<String>.from(_statusOptions);
  List<String> _appliedStatuses = List<String>.from(_statusOptions);
  String _groupBy = 'None';
  int _page = 1;
  final int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;

  void _initializeFromRoute(
    Map<String, Object?> parsedParams,
    GoRouterState routerState,
  ) {
    if (_isInitialized) return;
    final query = routerState.uri.queryParameters;
    if (query['startDate'] == null && query['endDate'] == null) {
      final thisMonth = ReportDateRangePresets.resolveRange(
        ReportDateRangePresets.thisMonth,
      );
      _startDate = thisMonth.startDate;
      _endDate = thisMonth.endDate;
    } else {
      _startDate = parsedParams['startDate'] as DateTime;
      _endDate = parsedParams['endDate'] as DateTime;
    }
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
    _isInitialized = true;
  }

  void _markFiltersDirty() {
    setState(() {
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleStatusChanged(List<String> values) {
    setState(() {
      _selectedStatuses = values.isEmpty
          ? List<String>.from(_statusOptions)
          : List<String>.from(values);
      _page = 1;
      _hasPendingFilterChanges = true;
    });
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
    setState(() => _groupBy = value);
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedStatuses = List<String>.from(_selectedStatuses);
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    if (_page == page) return;
    setState(() => _page = page);
  }

  int _intValue(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _statusQuery(List<String> statuses) {
    if (statuses.isEmpty || statuses.length == _statusOptions.length) return '';
    return statuses.where((status) => status != 'All').join(',');
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);
    _initializeFromRoute(parsedParams, routerState);

    final startDate = _startDate!;
    final endDate = _endDate!;
    final appliedStartDate = _appliedStartDate!;
    final appliedEndDate = _appliedEndDate!;
    final orgDatePattern = ref.watch(orgDateFormatProvider);
    final dateFormat = ReportFormatterCache.date(orgDatePattern);
    final dateLabel =
        'From ${dateFormat.format(appliedStartDate)} To ${dateFormat.format(appliedEndDate)}';
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: currencyAsync.valueOrNull?.symbol ?? '\u20B9',
      decimalDigits: 2,
    );
    final queryParams = (
      startDate: ReportUtils.formatApiDate(appliedStartDate),
      endDate: ReportUtils.formatApiDate(appliedEndDate),
      basis: _salesOrderDetailsBasis,
      status: _statusQuery(_appliedStatuses),
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(salesOrderDetailsProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final rows = SalesOrderDetailsRow.fromResponse(reportData, dateFormat);
    final totals = SalesOrderDetailsTotals.fromResponse(reportData);
    final pagination = Map<String, dynamic>.from(
      reportData?['pagination'] as Map? ?? const <String, dynamic>{},
    );
    final totalCount = _intValue(
      pagination['totalRecords'] ?? pagination['total'] ?? reportData?['total'],
      rows.length,
    );
    final currentPage = _intValue(
      pagination['page'] ?? reportData?['page'],
      _page,
    );
    final effectivePageSize = _intValue(
      pagination['pageSize'] ?? reportData?['pageSize'],
      _pageSize,
    );

    return ReportViewScaffold(
      categoryLabel: 'Receivables',
      reportTitle: _salesOrderDetailsTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _SalesOrderDetailsHeading(dateLabel: dateLabel),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportEntitiesFilter(
          label: 'Status',
          options: _statusOptions,
          initialSelection: _selectedStatuses,
          onChanged: _handleStatusChanged,
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
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: _salesOrderDetailsTitle,
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
      settingsTooltip: 'Customize the Sales Order Details report.',
      scheduleTooltip: 'Schedule the Sales Order Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: _salesOrderGroupByOptions,
            onChanged: _handleGroupByChanged,
          ),
          const _HeaderActionDivider(),
          const ReportCustomizeColumnsButton(count: 6),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(salesOrderDetailsProvider(queryParams)),
      isEmpty: false,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Receivables',
      currentNavigationReport: _salesOrderDetailsTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _salesOrderDetailsTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: SalesOrderDetailsTable(
        rows: rows,
        totals: totals,
        currencyFormat: currencyFormat,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _HeaderActionDivider extends StatelessWidget {
  const _HeaderActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppTheme.space20,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      color: AppTheme.borderLight,
    );
  }
}

class _SalesOrderDetailsHeading extends StatelessWidget {
  final String dateLabel;

  const _SalesOrderDetailsHeading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _salesOrderDetailsTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppTheme.space10),
        Text(
          dateLabel,
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
