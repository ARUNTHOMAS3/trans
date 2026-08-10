import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';

const String _tdsSummaryTitle = 'TDS Summary';

class TdsSummaryScreen extends ConsumerStatefulWidget {
  const TdsSummaryScreen({super.key});

  @override
  ConsumerState<TdsSummaryScreen> createState() => _TdsSummaryScreenState();
}

class _TdsSummaryScreenState extends ConsumerState<TdsSummaryScreen> {
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  int _page = 1;
  final int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';
  String _groupBy = 'TDS Section';

  void _initializeFromRoute(Map<String, Object?> parsedParams) {
    if (_isInitialized) return;
    _startDate = parsedParams['startDate'] as DateTime;
    _endDate = parsedParams['endDate'] as DateTime;
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
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

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
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
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedReportBasis = _reportBasis;
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() {
      _groupBy = value;
    });
  }

  void _handlePageChanged(int page) {
    if (_page == page) return;
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);
    _initializeFromRoute(parsedParams);

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
    const rows = <_TdsSummaryRow>[];
    const totals = _TdsSummaryTotals(
      total: 0,
      totalAfterDeduction: 0,
      tdsAmount: 0,
    );
    const totalCount = 0;
    final currentPage = _page;
    final effectivePageSize = _pageSize;
    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: _tdsSummaryTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _TdsSummaryHeading(
        basis: _appliedReportBasis,
        dateLabel: dateLabel,
      ),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
          onChanged: _handleDateRangeChanged,
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
        reportName: _tdsSummaryTitle,
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
      settingsTooltip: 'Customize the TDS Summary report.',
      scheduleTooltip: 'Schedule the TDS Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'Vendor',
              'TDS Section',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space12),
          Container(
            width: 1,
            height: 16,
            color: AppTheme.borderColor,
          ),
          const SizedBox(width: AppTheme.space12),
          const ReportCustomizeColumnsButton(count: 4),
        ],
      ),
      isLoading: false,
      errorMessage: null,
      onRetry: _runReport,
      isEmpty: false,
      emptyTitle: 'There are no transactions during the selected date range.',
      emptyMessage: 'There are no transactions during the selected date range.',
      currentNavigationCategory: 'Taxes',
      currentNavigationReport: _tdsSummaryTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _tdsSummaryTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _TdsSummaryTable(
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



class _TdsSummaryHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _TdsSummaryHeading({required this.basis, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _tdsSummaryTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle,
        ),
        const SizedBox(height: AppTheme.space10),
        Text(
          dateLabel,
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.space18),
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
      ],
    );
  }
}

class _TdsSummaryTable extends StatelessWidget {
  final List<_TdsSummaryRow> rows;
  final _TdsSummaryTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _TdsSummaryTable({
    required this.rows,
    required this.totals,
    required this.currencyFormat,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1120 ? 1120.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                if (rows.isEmpty)
                  const _TdsSummaryEmptyBody()
                else ...[
                  for (final row in rows)
                    _TdsSummaryDataRow(
                      row: row,
                      currencyFormat: currencyFormat,
                    ),
                  _TdsSummaryTotalRow(
                    totals: totals,
                    currencyFormat: currencyFormat,
                  ),
                  ReportPaginationFooter(
                    totalCount: totalCount,
                    page: page,
                    pageSize: pageSize,
                    onPageChanged: onPageChanged,
                  ),
                ],
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
      child: _buildTdsSummaryRow(
        section: _headerText('TDS SECTION'),
        total: _headerText('TOTAL', alignRight: true),
        afterDeduction: _headerText('TOTAL AFTER TDS DEDUCTION', alignRight: true),
        deducted: _headerText('TAX DEDUCTED AT SOURCE', alignRight: true),
      ),
    );
  }
}

class _TdsSummaryDataRow extends StatelessWidget {
  final _TdsSummaryRow row;
  final NumberFormat currencyFormat;

  const _TdsSummaryDataRow({required this.row, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTdsSummaryRow(
        section: _bodyText(row.tdsSection),
        total: _amountText(row.total, currencyFormat),
        afterDeduction: _amountText(row.totalAfterDeduction, currencyFormat),
        deducted: _amountText(row.tdsAmount, currencyFormat),
      ),
    );
  }
}

class _TdsSummaryTotalRow extends StatelessWidget {
  final _TdsSummaryTotals totals;
  final NumberFormat currencyFormat;

  const _TdsSummaryTotalRow({required this.totals, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTdsSummaryRow(
        section: Text(
          'Total',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        total: _totalText(totals.total, currencyFormat),
        afterDeduction: _totalText(totals.totalAfterDeduction, currencyFormat),
        deducted: _totalText(totals.tdsAmount, currencyFormat),
      ),
    );
  }
}

class _TdsSummaryEmptyBody extends StatelessWidget {
  const _TdsSummaryEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
      alignment: Alignment.center,
      color: AppTheme.backgroundColor,
      child: Text(
        'There are no transactions during the selected date range.',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

Widget _buildTdsSummaryRow({
  required Widget section,
  required Widget total,
  required Widget afterDeduction,
  required Widget deducted,
}) {
  return Row(
    children: [
      Expanded(flex: 3, child: section),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: total),
      ),
      Expanded(
        flex: 3,
        child: Align(alignment: Alignment.centerRight, child: afterDeduction),
      ),
      Expanded(
        flex: 3,
        child: Align(alignment: Alignment.centerRight, child: deducted),
      ),
    ],
  );
}

Widget _headerText(String label, {bool alignRight = false}) {
  return Align(
    alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(label, style: ReportTableTypography.header),
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

Widget _amountText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
    ),
  );
}

Widget _totalText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _TdsSummaryRow {
  final String tdsSection;
  final double total;
  final double totalAfterDeduction;
  final double tdsAmount;

  const _TdsSummaryRow({
    required this.tdsSection,
    required this.total,
    required this.totalAfterDeduction,
    required this.tdsAmount,
  });

}

class _TdsSummaryTotals {
  final double total;
  final double totalAfterDeduction;
  final double tdsAmount;

  const _TdsSummaryTotals({
    required this.total,
    required this.totalAfterDeduction,
    required this.tdsAmount,
  });

}
