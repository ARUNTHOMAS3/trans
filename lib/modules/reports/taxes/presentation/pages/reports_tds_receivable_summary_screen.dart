import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';

const String _tdsReceivableSummaryTitle = 'TDS Receivables Summary';
const String _tdsReceivableSummaryNavigationTitle = 'TDS Receivable Summary';

class TdsReceivableSummaryScreen extends ConsumerStatefulWidget {
  const TdsReceivableSummaryScreen({super.key});

  @override
  ConsumerState<TdsReceivableSummaryScreen> createState() =>
      _TdsReceivableSummaryScreenState();
}

class _TdsReceivableSummaryScreenState
    extends ConsumerState<TdsReceivableSummaryScreen> {
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
    const rows = <_TdsReceivableSummaryRow>[];
    const totals = _TdsReceivableSummaryTotals(
      total: 0,
      totalAfterDeduction: 0,
      tdsAmount: 0,
    );

    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: _tdsReceivableSummaryTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _TdsReceivableSummaryHeading(
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
      showSettings: false,
      showSchedule: false,
      showReload: true,
      showRefresh: false,
      leadingToolbarActions: [
        ReportIconActionButton(
          icon: LucideIcons.slidersHorizontal,
          onPressed: _runReport,
          tooltip: 'Customize report filters',
        ),
        ReportIconActionButton(
          icon: LucideIcons.share2,
          onPressed: () {},
          tooltip: 'Share report',
        ),
      ],
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
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'Customer',
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
      currentNavigationReport: _tdsReceivableSummaryNavigationTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _tdsReceivableSummaryNavigationTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _TdsReceivableSummaryTable(
        rows: rows,
        totals: totals,
        currencyFormat: currencyFormat,
        totalCount: 0,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}


class _TdsReceivableSummaryHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _TdsReceivableSummaryHeading({
    required this.basis,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _tdsReceivableSummaryTitle,
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

class _TdsReceivableSummaryTable extends StatelessWidget {
  final List<_TdsReceivableSummaryRow> rows;
  final _TdsReceivableSummaryTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _TdsReceivableSummaryTable({
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
        final tableWidth = constraints.maxWidth < 1120
            ? 1120.0
            : constraints.maxWidth;
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            height: hasBoundedHeight ? constraints.maxHeight : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                if (rows.isEmpty)
                  hasBoundedHeight
                      ? const Expanded(child: _TdsReceivableSummaryEmptyBody())
                      : const _TdsReceivableSummaryEmptyBody()
                else ...[
                  for (final row in rows)
                    _TdsReceivableSummaryDataRow(
                      row: row,
                      currencyFormat: currencyFormat,
                    ),
                  _TdsReceivableSummaryTotalRow(
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
      child: _buildTdsReceivableSummaryRow(
        section: _headerText('TDS SECTION'),
        total: _headerText('TOTAL', alignRight: true),
        afterDeduction: _headerText(
          'TOTAL AFTER TDS DEDUCTION',
          alignRight: true,
        ),
        deducted: _headerText('TAX DEDUCTED AT SOURCE', alignRight: true),
      ),
    );
  }
}

class _TdsReceivableSummaryDataRow extends StatelessWidget {
  final _TdsReceivableSummaryRow row;
  final NumberFormat currencyFormat;

  const _TdsReceivableSummaryDataRow({
    required this.row,
    required this.currencyFormat,
  });

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
      child: _buildTdsReceivableSummaryRow(
        section: _bodyText(row.tdsSection),
        total: _amountText(row.total, currencyFormat),
        afterDeduction: _amountText(row.totalAfterDeduction, currencyFormat),
        deducted: _amountText(row.tdsAmount, currencyFormat),
      ),
    );
  }
}

class _TdsReceivableSummaryTotalRow extends StatelessWidget {
  final _TdsReceivableSummaryTotals totals;
  final NumberFormat currencyFormat;

  const _TdsReceivableSummaryTotalRow({
    required this.totals,
    required this.currencyFormat,
  });

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
      child: _buildTdsReceivableSummaryRow(
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

class _TdsReceivableSummaryEmptyBody extends StatelessWidget {
  const _TdsReceivableSummaryEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      alignment: Alignment.center,
      color: AppTheme.backgroundColor,
      child: Text(
        'There are no transactions during the selected date range.',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

Widget _buildTdsReceivableSummaryRow({
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

class _TdsReceivableSummaryRow {
  final String tdsSection;
  final double total;
  final double totalAfterDeduction;
  final double tdsAmount;

  const _TdsReceivableSummaryRow({
    required this.tdsSection,
    required this.total,
    required this.totalAfterDeduction,
    required this.tdsAmount,
  });
}

class _TdsReceivableSummaryTotals {
  final double total;
  final double totalAfterDeduction;
  final double tdsAmount;

  const _TdsReceivableSummaryTotals({
    required this.total,
    required this.totalAfterDeduction,
    required this.tdsAmount,
  });
}
