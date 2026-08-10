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
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/receivables/presentation/widgets/invoice_details_table.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';

const String _invoiceDetailsTitle = 'Invoice Details';
const String _invoiceDetailsBasis = 'Accrual';
const List<String> _reportByOptions = <String>[
  'Invoice Date',
  'Invoice Due Date',
];
const List<String> _groupByOptions = <String>[
  'Invoice Date',
  'Due Date',
  'Customer Name',
  'Salesperson',
  'Currency',
  'Location',
];

typedef InvoiceDetailsParams = ({
  String startDate,
  String endDate,
  String basis,
  String reportBy,
  int page,
  int pageSize,
});

final invoiceDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, InvoiceDetailsParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getInvoiceDetails(
    params.startDate,
    params.endDate,
    basis: params.basis,
    reportBy: params.reportBy,
    page: params.page,
    pageSize: params.pageSize,
  );
});

class InvoiceDetailsPage extends ConsumerStatefulWidget {
  const InvoiceDetailsPage({super.key});

  @override
  ConsumerState<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends ConsumerState<InvoiceDetailsPage> {
  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _reportBy = 'Invoice Date';
  String _appliedReportBy = 'Invoice Date';
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
    final reportByParam = query['reportBy'];
    if (reportByParam != null && _reportByOptions.contains(reportByParam)) {
      _reportBy = reportByParam;
      _appliedReportBy = reportByParam;
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

  void _handleReportByChanged(String value) {
    if (_reportBy == value) return;
    setState(() {
      _reportBy = value;
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
    if (_groupBy == value) return;
    setState(() => _groupBy = value);
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedReportBy = _reportBy;
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
      basis: _invoiceDetailsBasis,
      reportBy: _appliedReportBy,
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(invoiceDetailsProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final rows = InvoiceDetailsRow.fromResponse(reportData, dateFormat);
    final totals = InvoiceDetailsTotals.fromResponse(reportData);
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
      reportTitle: _invoiceDetailsTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _InvoiceDetailsHeading(dateLabel: dateLabel),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Report By',
          value: _reportBy,
          options: _reportByOptions,
          onChanged: _handleReportByChanged,
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
        reportName: _invoiceDetailsTitle,
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
      settingsTooltip: 'Customize the Invoice Details report.',
      scheduleTooltip: 'Schedule the Invoice Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: _groupByOptions,
            onChanged: _handleGroupByChanged,
          ),
          const _HeaderActionDivider(),
          const ReportCustomizeColumnsButton(count: 8),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(invoiceDetailsProvider(queryParams)),
      isEmpty: false,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Receivables',
      currentNavigationReport: _invoiceDetailsTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _invoiceDetailsTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: InvoiceDetailsTable(
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.space10),
      child: SizedBox(
        height: AppTheme.space20,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderLight,
        ),
      ),
    );
  }
}

class _InvoiceDetailsHeading extends StatelessWidget {
  final String dateLabel;

  const _InvoiceDetailsHeading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _invoiceDetailsTitle,
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
