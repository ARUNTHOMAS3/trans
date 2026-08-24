import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_tooltip.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';

const String _dayBookTitle = 'Day Book';

typedef DayBookParams = ({
  String startDate,
  String endDate,
  String basis,
  int page,
  int pageSize,
});

final dayBookProvider = FutureProvider.family<Map<String, dynamic>, DayBookParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getDayBook(
    params.startDate,
    params.endDate,
    basis: params.basis,
    page: params.page,
    pageSize: params.pageSize,
  );
});

class DayBookScreen extends ConsumerStatefulWidget {
  const DayBookScreen({super.key});

  @override
  ConsumerState<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends ConsumerState<DayBookScreen> {
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  int _page = 1;
  final int _pageSize = 25;
  DateTime? _reportDate;
  DateTime? _appliedReportDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';

  void _initializeFromRoute(Map<String, Object?> parsedParams) {
    if (_isInitialized) return;
    _reportDate = parsedParams['startDate'] as DateTime;
    _appliedReportDate = _reportDate;
    _reportBasis = (parsedParams['basis'] as String?) ?? 'Accrual';
    _appliedReportBasis = _reportBasis;
    _isInitialized = true;
  }

  void _markFiltersDirty() {
    setState(() {
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleDateChanged(ReportDateRangeSelection selection) {
    setState(() {
      _reportDate = selection.startDate;
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleReportBasisChanged(String value) {
    if (_reportBasis == value) return;
    setState(() {
      _reportBasis = value;
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

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedReportDate = _reportDate;
      _appliedReportBasis = _reportBasis;
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

  String _formatTransactionType(String? rawType) {
    final value = (rawType ?? '').trim();
    if (value.isEmpty) return '--';
    return value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);
    _initializeFromRoute(parsedParams);

    final reportDate = _reportDate!;
    final appliedReportDate = _appliedReportDate!;
    final orgDatePattern = ref.watch(orgDateFormatProvider);
    final dateFormat = ReportFormatterCache.date(orgDatePattern);
    final reportDateLabel = 'Report Date ${dateFormat.format(appliedReportDate)}';
    final queryParams = (
      startDate: ReportUtils.formatApiDate(appliedReportDate),
      endDate: ReportUtils.formatApiDate(appliedReportDate),
      basis: _appliedReportBasis,
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(dayBookProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final rows = _DayBookRow.fromResponse(reportData);
    final pagination = Map<String, dynamic>.from(
      reportData?['pagination'] as Map? ?? const <String, dynamic>{},
    );
    final totalCount = _intValue(
      pagination['totalRecords'] ?? pagination['total'] ?? reportData?['total'],
      rows.length,
    );
    final currentPage = _intValue(pagination['page'] ?? reportData?['page'], _page);
    final effectivePageSize = _intValue(
      pagination['pageSize'] ?? reportData?['pageSize'],
      _pageSize,
    );

    return ReportViewScaffold(
      categoryLabel: 'Accountant',
      reportTitle: _dayBookTitle,
      dateLabel: reportDateLabel,
      companyName: '',
      reportHeading: _DayBookHeading(
        basis: _appliedReportBasis,
        reportDateLabel: 'Report Date: ${dateFormat.format(appliedReportDate)}',
      ),
      filters: [
        ReportDateRangeFilter(
          label: 'Report Date',
          initialStartDate: reportDate,
          initialEndDate: reportDate,
          onChanged: _handleDateChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Report Basis',
          value: _reportBasis,
          options: _reportBasisOptions,
          onChanged: _handleReportBasisChanged,
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
      showRefresh: false,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: _dayBookTitle,
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
      settingsTooltip: 'Customize the Day Book report.',
      scheduleTooltip: 'Schedule the Day Book report.',
      tableHeaderActions: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [ReportCustomizeColumnsButton(count: 9)],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(dayBookProvider(queryParams)),
      isEmpty: false,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Accountant',
      currentNavigationReport: _dayBookTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _dayBookTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _DayBookTable(
        rows: rows,
        dateFormat: dateFormat,
        transactionTypeFormatter: _formatTransactionType,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _DayBookHeading extends StatelessWidget {
  final String basis;
  final String reportDateLabel;

  const _DayBookHeading({required this.basis, required this.reportDateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(_dayBookTitle, textAlign: TextAlign.center, style: AppTheme.pageTitle),
        const SizedBox(height: AppTheme.space10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'Basis : ',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(text: basis),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        Text(
          reportDateLabel,
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DayBookTable extends StatelessWidget {
  static final NumberFormat _numberFormat = ReportFormatterCache.number('#,##0.00');

  final List<_DayBookRow> rows;
  final DateFormat dateFormat;
  final String Function(String?) transactionTypeFormatter;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _DayBookTable({
    required this.rows,
    required this.dateFormat,
    required this.transactionTypeFormatter,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1370
            ? 1370.0
            : constraints.maxWidth;
        final tableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 520.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            height: tableHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: rows.isEmpty
                      ? const _DayBookEmptyBody()
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final row in rows)
                                _DayBookDataRow(
                                  row: row,
                                  dateFormat: dateFormat,
                                  transactionTypeFormatter:
                                      transactionTypeFormatter,
                                ),
                              ReportPaginationFooter(
                                totalCount: totalCount,
                                page: page,
                                pageSize: pageSize,
                                onPageChanged: onPageChanged,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: _buildDayBookRow(
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        account: _headerText('ACCOUNT'),
        details: _headerText('TRANSACTION DETAILS'),
        type: _headerText('TRANSACTION TYPE'),
        transactionNumber: _headerText('TRANSACTION#'),
        reference: _headerText('REFERENCE#'),
        debit: _headerText(
          'DEBIT',
          alignRight: true,
          helpMessage: 'The positive difference between the debit and credit value in an account.',
        ),
        credit: _headerText(
          'CREDIT',
          alignRight: true,
          helpMessage: 'The negative difference between the debit and credit value in an account.',
        ),
        amount: _headerText(
          'AMOUNT',
          alignRight: true,
          helpMessage: 'Total value of the account.',
        ),
      ),
    );
  }
}

class _DayBookDataRow extends StatelessWidget {
  final _DayBookRow row;
  final DateFormat dateFormat;
  final String Function(String?) transactionTypeFormatter;

  const _DayBookDataRow({
    required this.row,
    required this.dateFormat,
    required this.transactionTypeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),

      child: _buildDayBookRow(
        date: _bodyText(dateFormat.format(row.date)),
        account: _bodyText(row.accountName),
        details: _bodyText(row.details),
        type: _bodyText(transactionTypeFormatter(row.transactionType)),
        transactionNumber: _bodyText(row.transactionNumber),
        reference: _bodyText(row.reference),
        debit: _amountText(row.debit),
        credit: _amountText(row.credit),
        amount: Text(
          '${_DayBookTable._numberFormat.format(row.amount)} ${row.amountType}',
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DayBookEmptyBody extends StatelessWidget {
  const _DayBookEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        'No data to display',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

Widget _buildDayBookRow({
  required Widget date,
  required Widget account,
  required Widget details,
  required Widget type,
  required Widget transactionNumber,
  required Widget reference,
  required Widget debit,
  required Widget credit,
  required Widget amount,
}) {
  return Row(
    children: [
      Expanded(flex: 2, child: date),
      Expanded(flex: 2, child: account),
      Expanded(flex: 2, child: details),
      Expanded(flex: 2, child: type),
      Expanded(flex: 2, child: transactionNumber),
      Expanded(flex: 2, child: reference),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: debit)),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: credit)),
      Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: amount)),
    ],
  );
}

Widget _headerText(String label, {bool alignRight = false, String? helpMessage}) {
  final text = Text(label, style: ReportTableTypography.header);
  final content = helpMessage == null
      ? text
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            text,
            const SizedBox(width: AppTheme.space4),
            ReportTooltip(
              message: helpMessage,
              child: const Icon(
                Icons.help_outline,
                size: AppTheme.space14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
  return Align(
    alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
    child: content,
  );
}

Widget _bodyText(String value) {
  return Text(
    value.isEmpty ? '--' : value,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    ),
  );
}

Widget _amountText(double value) {
  return Text(
    _DayBookTable._numberFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _DayBookRow {
  final DateTime date;
  final String accountName;
  final String details;
  final String transactionType;
  final String transactionNumber;
  final String reference;
  final double debit;
  final double credit;
  final double amount;
  final String amountType;

  const _DayBookRow({
    required this.date,
    required this.accountName,
    required this.details,
    required this.transactionType,
    required this.transactionNumber,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.amount,
    required this.amountType,
  });

  static List<_DayBookRow> fromResponse(Map<String, dynamic>? response) {
    final rawRows = response?['transactions'];
    if (rawRows is! List) return const <_DayBookRow>[];
    return rawRows
        .whereType<Map>()
        .map((raw) => _DayBookRow.fromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false);
  }

  factory _DayBookRow.fromJson(Map<String, dynamic> json) {
    return _DayBookRow(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      accountName: json['accountName']?.toString() ?? '--',
      details: json['details']?.toString() ?? '--',
      transactionType: json['transactionType']?.toString() ?? '--',
      transactionNumber: json['transactionNumber']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      debit: _doubleValue(json['debit']),
      credit: _doubleValue(json['credit']),
      amount: _doubleValue(json['amount']),
      amountType: json['amountType']?.toString() ?? 'Dr',
    );
  }
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
