import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
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

const String _tcsSummaryTitle = 'TCS Summary (Form No. 27EQ)';
const String _tcsSummaryNavigationTitle = 'TCS Payable Summary (Form No. 27EQ)';

class TcsPayableSummaryScreen extends ConsumerStatefulWidget {
  const TcsPayableSummaryScreen({super.key});

  @override
  ConsumerState<TcsPayableSummaryScreen> createState() =>
      _TcsPayableSummaryScreenState();
}

class _TcsPayableSummaryScreenState
    extends ConsumerState<TcsPayableSummaryScreen> {
  static const List<String> _reportBasisOptions = <String>['Cash', 'Accrual'];
  static const List<String> _reportByOptions = <String>['None', 'Party', 'Location'];

  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  int _page = 1;
  final int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String _reportBasis = 'Cash';
  String _appliedReportBasis = 'Cash';
  String _reportBy = 'None';

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

  void _handleReportBasisChanged(String value) {
    if (_reportBasis == value) return;
    setState(() {
      _reportBasis = value;
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
    const rows = <_TcsSummaryRow>[];
    const totals = _TcsSummaryTotals(
      totalValue: 0,
      taxCollected: 0,
      amountReceived: 0,
    );

    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: _tcsSummaryTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _TcsSummaryHeading(
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
          width: 254,
          onChanged: _handleReportBasisChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Report By',
          value: _reportBy,
          options: _reportByOptions,
          width: 238,
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
      showSettings: false,
      showSchedule: false,
      showReload: false,
      showRefresh: true,
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
      tableHeaderActions: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [ReportCustomizeColumnsButton(count: 13)],
      ),
      isLoading: false,
      errorMessage: null,
      onRetry: _runReport,
      isEmpty: false,
      emptyTitle: 'There are no transactions during the selected date range.',
      emptyMessage: 'There are no transactions during the selected date range.',
      currentNavigationCategory: 'Taxes',
      currentNavigationReport: _tcsSummaryNavigationTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _tcsSummaryNavigationTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _TcsSummaryTable(
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

class _TcsSummaryHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _TcsSummaryHeading({required this.basis, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _tcsSummaryTitle,
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

class _TcsSummaryTable extends StatelessWidget {
  final List<_TcsSummaryRow> rows;
  final _TcsSummaryTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _TcsSummaryTable({
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
        final tableWidth = constraints.maxWidth < 1560
            ? 1560.0
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
                      ? const Expanded(child: _TcsSummaryEmptyBody())
                      : const _TcsSummaryEmptyBody()
                else ...[
                  for (final row in rows)
                    _TcsSummaryDataRow(row: row, currencyFormat: currencyFormat),
                  _TcsSummaryTotalRow(totals: totals, currencyFormat: currencyFormat),
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
      child: _buildTcsSummaryRow(
        partyName: _headerText('NAME OF THE PARTY'),
        pan: _headerText('PAN OF THE PARTY'),
        tcsRate: _headerText('TCS RATE (%)', alignRight: true),
        collectionCode: _headerText('COLLECTION CODE'),
        collectReason: _headerText('REASON FOR COLLECT...'),
        collectionDate: _headerText('COLLECTION DATE'),
        paymentNumber: _headerText('PAYMENT NUMBER'),
        invoiceNumber: _headerText('INVOICE NUMBER', alignRight: false),
        location: _headerText('LOCATION'),
        totalValue: _headerText('TOTAL VALUE', alignRight: true),
        taxCollected: _headerText('TAX COLLECTED', alignRight: true),
        amountReceived: _headerText('AMOUNT RECEIVED', alignRight: true),
      ),
    );
  }
}

class _TcsSummaryDataRow extends StatelessWidget {
  final _TcsSummaryRow row;
  final NumberFormat currencyFormat;

  const _TcsSummaryDataRow({required this.row, required this.currencyFormat});

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
      child: _buildTcsSummaryRow(
        partyName: _bodyText(row.partyName),
        pan: _bodyText(row.pan),
        tcsRate: _bodyText(row.tcsRate),
        collectionCode: _bodyText(row.collectionCode),
        collectReason: _bodyText(row.collectReason),
        collectionDate: _bodyText(row.collectionDate),
        paymentNumber: _bodyText(row.paymentNumber),
        invoiceNumber: _bodyText(row.invoiceNumber),
        location: _bodyText(row.location),
        totalValue: _amountText(row.totalValue, currencyFormat),
        taxCollected: _amountText(row.taxCollected, currencyFormat),
        amountReceived: _amountText(row.amountReceived, currencyFormat),
      ),
    );
  }
}

class _TcsSummaryTotalRow extends StatelessWidget {
  final _TcsSummaryTotals totals;
  final NumberFormat currencyFormat;

  const _TcsSummaryTotalRow({required this.totals, required this.currencyFormat});

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
      child: _buildTcsSummaryRow(
        partyName: Text(
          'Total',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        pan: const SizedBox.shrink(),
        tcsRate: const SizedBox.shrink(),
        collectionCode: const SizedBox.shrink(),
        collectReason: const SizedBox.shrink(),
        collectionDate: const SizedBox.shrink(),
        paymentNumber: const SizedBox.shrink(),
        invoiceNumber: const SizedBox.shrink(),
        location: const SizedBox.shrink(),
        totalValue: _totalText(totals.totalValue, currencyFormat),
        taxCollected: _totalText(totals.taxCollected, currencyFormat),
        amountReceived: _totalText(totals.amountReceived, currencyFormat),
      ),
    );
  }
}

class _TcsSummaryEmptyBody extends StatelessWidget {
  const _TcsSummaryEmptyBody();

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

Widget _buildTcsSummaryRow({
  required Widget partyName,
  required Widget pan,
  required Widget tcsRate,
  required Widget collectionCode,
  required Widget collectReason,
  required Widget collectionDate,
  required Widget paymentNumber,
  required Widget invoiceNumber,
  required Widget location,
  required Widget totalValue,
  required Widget taxCollected,
  required Widget amountReceived,
}) {
  return Row(
    children: [
      Expanded(flex: 2, child: partyName),
      Expanded(flex: 2, child: pan),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: tcsRate),
      ),
      Expanded(flex: 2, child: collectionCode),
      Expanded(flex: 2, child: collectReason),
      Expanded(flex: 2, child: collectionDate),
      Expanded(flex: 2, child: paymentNumber),
      Expanded(flex: 2, child: invoiceNumber),
      Expanded(flex: 2, child: location),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: totalValue),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: taxCollected),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: amountReceived),
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

class _TcsSummaryRow {
  final String partyName;
  final String pan;
  final String tcsRate;
  final String collectionCode;
  final String collectReason;
  final String collectionDate;
  final String paymentNumber;
  final String invoiceNumber;
  final String location;
  final double totalValue;
  final double taxCollected;
  final double amountReceived;

  const _TcsSummaryRow({
    required this.partyName,
    required this.pan,
    required this.tcsRate,
    required this.collectionCode,
    required this.collectReason,
    required this.collectionDate,
    required this.paymentNumber,
    required this.invoiceNumber,
    required this.location,
    required this.totalValue,
    required this.taxCollected,
    required this.amountReceived,
  });
}

class _TcsSummaryTotals {
  final double totalValue;
  final double taxCollected;
  final double amountReceived;

  const _TcsSummaryTotals({
    required this.totalValue,
    required this.taxCollected,
    required this.amountReceived,
  });
}
