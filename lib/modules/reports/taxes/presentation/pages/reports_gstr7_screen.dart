import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';

const String _gstr7Title = 'GSTR-7 (Return for Tax Deducted at Source)';

class Gstr7Screen extends ConsumerStatefulWidget {
  const Gstr7Screen({super.key});

  @override
  ConsumerState<Gstr7Screen> createState() => _Gstr7ScreenState();
}

class _Gstr7ScreenState extends ConsumerState<Gstr7Screen> {
  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  int _page = 1;
  final int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;

  void _initializeFromRoute(Map<String, Object?> parsedParams) {
    if (_isInitialized) return;
    _startDate = parsedParams['startDate'] as DateTime;
    _endDate = parsedParams['endDate'] as DateTime;
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
      _page = 1;
      _hasPendingFilterChanges = false;
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
    const rows = <_Gstr7Row>[];
    const totals = _Gstr7Totals(
      amountPaid: 0,
      integratedTax: 0,
      centralTax: 0,
      stateTax: 0,
      totalTds: 0,
    );

    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: _gstr7Title,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _Gstr7Heading(dateLabel: dateLabel),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
          onChanged: _handleDateRangeChanged,
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
      showReload: false,
      showRefresh: true,
      onRefresh: _runReport,
      onReload: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      isLoading: false,
      errorMessage: null,
      onRetry: _runReport,
      isEmpty: false,
      emptyTitle: 'There are no transactions during the selected date range.',
      emptyMessage: 'There are no transactions during the selected date range.',
      currentNavigationCategory: 'Taxes',
      currentNavigationReport: _gstr7Title,
      onReportSelected: (reportName, category) {
        if (reportName == _gstr7Title) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _Gstr7Table(
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

class _Gstr7Heading extends StatelessWidget {
  final String dateLabel;

  const _Gstr7Heading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _gstr7Title,
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
      ],
    );
  }
}

class _Gstr7Table extends StatelessWidget {
  final List<_Gstr7Row> rows;
  final _Gstr7Totals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _Gstr7Table({
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
        final tableWidth = constraints.maxWidth < 1240
            ? 1240.0
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
                      ? const Expanded(child: _Gstr7EmptyBody())
                      : const _Gstr7EmptyBody()
                else ...[
                  for (final row in rows)
                    _Gstr7DataRow(row: row, currencyFormat: currencyFormat),
                  _Gstr7TotalRow(totals: totals, currencyFormat: currencyFormat),
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
      child: _buildGstr7Row(
        gstin: _headerText('GSTIN OF DEDUCTEE'),
        vendor: _headerText('VENDOR NAME'),
        amountPaid: _headerText(
          'AMOUNT PAID TO DEDUCTEE ON WHICH TAX IS DEDUCTED',
          alignRight: true,
        ),
        integratedTax: _headerText('INTEGRATED TAX', alignRight: true),
        centralTax: _headerText('CENTRAL TAX', alignRight: true),
        stateTax: _headerText('STATE/UT TAX', alignRight: true),
        totalTds: _headerText(
          'TOTAL TAX DEDUCTED AT SOURCE',
          alignRight: true,
        ),
      ),
    );
  }
}

class _Gstr7DataRow extends StatelessWidget {
  final _Gstr7Row row;
  final NumberFormat currencyFormat;

  const _Gstr7DataRow({required this.row, required this.currencyFormat});

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
      child: _buildGstr7Row(
        gstin: _bodyText(row.gstin),
        vendor: _bodyText(row.vendorName),
        amountPaid: _amountText(row.amountPaid, currencyFormat),
        integratedTax: _amountText(row.integratedTax, currencyFormat),
        centralTax: _amountText(row.centralTax, currencyFormat),
        stateTax: _amountText(row.stateTax, currencyFormat),
        totalTds: _amountText(row.totalTds, currencyFormat),
      ),
    );
  }
}

class _Gstr7TotalRow extends StatelessWidget {
  final _Gstr7Totals totals;
  final NumberFormat currencyFormat;

  const _Gstr7TotalRow({required this.totals, required this.currencyFormat});

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
      child: _buildGstr7Row(
        gstin: Text(
          'Total',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        vendor: const SizedBox.shrink(),
        amountPaid: _totalText(totals.amountPaid, currencyFormat),
        integratedTax: _totalText(totals.integratedTax, currencyFormat),
        centralTax: _totalText(totals.centralTax, currencyFormat),
        stateTax: _totalText(totals.stateTax, currencyFormat),
        totalTds: _totalText(totals.totalTds, currencyFormat),
      ),
    );
  }
}

class _Gstr7EmptyBody extends StatelessWidget {
  const _Gstr7EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      alignment: Alignment.center,
      color: AppTheme.backgroundColor,
      child: Text(
        'There are no transactions during the selected date range.',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

Widget _buildGstr7Row({
  required Widget gstin,
  required Widget vendor,
  required Widget amountPaid,
  required Widget integratedTax,
  required Widget centralTax,
  required Widget stateTax,
  required Widget totalTds,
}) {
  return Row(
    children: [
      Expanded(flex: 2, child: gstin),
      Expanded(flex: 2, child: vendor),
      Expanded(
        flex: 4,
        child: Align(alignment: Alignment.centerRight, child: amountPaid),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: integratedTax),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: centralTax),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: stateTax),
      ),
      Expanded(
        flex: 3,
        child: Align(alignment: Alignment.centerRight, child: totalTds),
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

class _Gstr7Row {
  final String gstin;
  final String vendorName;
  final double amountPaid;
  final double integratedTax;
  final double centralTax;
  final double stateTax;
  final double totalTds;

  const _Gstr7Row({
    required this.gstin,
    required this.vendorName,
    required this.amountPaid,
    required this.integratedTax,
    required this.centralTax,
    required this.stateTax,
    required this.totalTds,
  });
}

class _Gstr7Totals {
  final double amountPaid;
  final double integratedTax;
  final double centralTax;
  final double stateTax;
  final double totalTds;

  const _Gstr7Totals({
    required this.amountPaid,
    required this.integratedTax,
    required this.centralTax,
    required this.stateTax,
    required this.totalTds,
  });
}
