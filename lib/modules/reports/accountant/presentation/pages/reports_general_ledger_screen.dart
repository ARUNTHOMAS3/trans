import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';

class GeneralLedgerComparisonPeriod {
  final String label;
  final bool isCurrent;
  final DateTime startDate;
  final DateTime endDate;

  const GeneralLedgerComparisonPeriod({
    required this.label,
    required this.isCurrent,
    required this.startDate,
    required this.endDate,
  });
}

const String _generalLedgerTitle = 'General Ledger';

typedef GlParams = ({
  String startDate,
  String endDate,
  String basis,
  int page,
  int pageSize,
});

final glProvider = FutureProvider.family<Map<String, dynamic>, GlParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getGeneralLedger(
    params.startDate,
    params.endDate,
    basis: params.basis,
    page: params.page,
    pageSize: params.pageSize,
  );
});

class GeneralLedgerScreen extends ConsumerStatefulWidget {
  const GeneralLedgerScreen({super.key});

  @override
  ConsumerState<GeneralLedgerScreen> createState() =>
      _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends ConsumerState<GeneralLedgerScreen> {
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _collapseSubAccounts = true;
  String _compareWith = 'None';
  ReportCompareSelection _compareSelection =
      const ReportCompareSelection.none();
  int _page = 1;
  int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';

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

  void _handlePageChanged(int page) {
    if (_page == page) return;
    setState(() => _page = page);
  }

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareWith = selection.displayValue;
      _compareSelection = selection;
    });
  }

  List<GeneralLedgerComparisonPeriod> _buildComparisonPeriods() {
    if (_compareSelection.compareType == null ||
        _compareSelection.compareType == 'None' ||
        _appliedStartDate == null ||
        _appliedEndDate == null) {
      return const [];
    }

    final count = _compareSelection.count;
    final periods = <GeneralLedgerComparisonPeriod>[
      GeneralLedgerComparisonPeriod(
        label: _formatComparisonPeriod(_appliedStartDate!, _appliedEndDate!),
        isCurrent: true,
        startDate: _appliedStartDate!,
        endDate: _appliedEndDate!,
      ),
    ];

    if (_compareSelection.compareType == 'Previous Year(s)') {
      for (var offset = count; offset >= 1; offset -= 1) {
        final previousStart = DateTime(
          _appliedStartDate!.year - offset,
          _appliedStartDate!.month,
          _appliedStartDate!.day,
        );
        final previousEnd = DateTime(
          _appliedEndDate!.year - offset,
          _appliedEndDate!.month,
          _appliedEndDate!.day,
        );
        periods.add(
          GeneralLedgerComparisonPeriod(
            label: _formatComparisonPeriod(previousStart, previousEnd),
            isCurrent: false,
            startDate: previousStart,
            endDate: previousEnd,
          ),
        );
      }
    } else {
      final periodDays =
          _appliedEndDate!.difference(_appliedStartDate!).inDays + 1;
      for (var offset = count; offset >= 1; offset -= 1) {
        final previousEnd = _appliedStartDate!.subtract(
          Duration(days: periodDays * (offset - 1) + 1),
        );
        final previousStart = previousEnd.subtract(
          Duration(days: periodDays - 1),
        );
        periods.add(
          GeneralLedgerComparisonPeriod(
            label: _formatComparisonPeriod(previousStart, previousEnd),
            isCurrent: false,
            startDate: previousStart,
            endDate: previousEnd,
          ),
        );
      }
    }

    if (_compareSelection.arrangeLatestFirst) {
      return periods.reversed.toList(growable: false);
    }
    return periods;
  }

  String _formatComparisonPeriod(DateTime startDate, DateTime endDate) {
    final dateFormat = ReportFormatterCache.date('dd-MM-yyyy');
    return '${dateFormat.format(startDate)}-${dateFormat.format(endDate)}';
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
    final currencyCode = currencyAsync.valueOrNull?.code ?? 'INR';
    final queryParams = (
      startDate: ReportUtils.formatApiDate(appliedStartDate),
      endDate: ReportUtils.formatApiDate(appliedEndDate),
      basis: _appliedReportBasis,
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(glProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final rows = _GeneralLedgerRow.fromResponse(reportData);
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
    final comparisonPeriods = _buildComparisonPeriods();

    return ReportViewScaffold(
      categoryLabel: 'Accountant',
      reportTitle: _generalLedgerTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _GeneralLedgerHeading(
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
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: _generalLedgerTitle),
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
      settingsTooltip: 'Customize the General Ledger report.',
      scheduleTooltip: 'Schedule the General Ledger report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CollapseSubAccountsAction(
            value: _collapseSubAccounts,
            onChanged: (value) => setState(() => _collapseSubAccounts = value),
          ),
          const SizedBox(width: AppTheme.space10),
          ReportCompareSection(
            selectedValue: _compareWith,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 4),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(glProvider(queryParams)),
      isEmpty: rows.isEmpty,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Accountant',
      currentNavigationReport: _generalLedgerTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _generalLedgerTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _GeneralLedgerTable(
        rows: rows,
        startDate: appliedStartDate,
        endDate: appliedEndDate,
        basis: _appliedReportBasis,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
        currencyCode: currencyCode,
        comparisonPeriods: comparisonPeriods,
      ),
    );
  }
}

class _GeneralLedgerHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _GeneralLedgerHeading({required this.basis, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _generalLedgerTitle,
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
        const SizedBox(height: AppTheme.space20),
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

class _CollapseSubAccountsAction extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CollapseSubAccountsAction({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.72,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.backgroundColor,
            activeTrackColor: AppTheme.primaryBlue,
            inactiveThumbColor: AppTheme.backgroundColor,
            inactiveTrackColor: AppTheme.borderColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppTheme.space4),
        Text(
          'Collapse Sub-Accounts',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GeneralLedgerTable extends StatelessWidget {
  static final NumberFormat _numberFormat = ReportFormatterCache.number(
    '#,##0.00',
  );

  final List<_GeneralLedgerRow> rows;
  final DateTime startDate;
  final DateTime endDate;
  final String basis;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String currencyCode;
  final List<GeneralLedgerComparisonPeriod> comparisonPeriods;

  const _GeneralLedgerTable({
    required this.rows,
    required this.startDate,
    required this.endDate,
    required this.basis,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.currencyCode,
    required this.comparisonPeriods,
  });

  bool get _isComparisonMode => comparisonPeriods.length > 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 826
            ? constraints.maxWidth
            : 826.0;

        final tableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 520.0;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: tableWidth,
            height: tableHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: rows.isEmpty
                      ? const _GeneralLedgerEmptyBody()
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final row in rows)
                                _GeneralLedgerDataRow(
                                  row: row,
                                  startDate: startDate,
                                  endDate: endDate,
                                  basis: basis,
                                  numberFormat: _numberFormat,
                                  comparisonPeriods: comparisonPeriods,
                                ),
                              const SizedBox(height: AppTheme.space6),
                              _BaseCurrencyNote(currencyCode: currencyCode),
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
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: _isComparisonMode
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Text('ACCOUNT', style: ReportTableTypography.header),
                      const SizedBox(width: AppTheme.space4),
                      const Icon(
                        Icons.unfold_more,
                        size: AppTheme.space14,
                        color: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
                ...comparisonPeriods.map(
                  (period) => Expanded(
                    flex: 6,
                    child: _comparisonPeriodHeader(period.label),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Text('ACCOUNT', style: ReportTableTypography.header),
                      const SizedBox(width: AppTheme.space4),
                      const Icon(
                        Icons.unfold_more,
                        size: AppTheme.space14,
                        color: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DEBIT',
                    textAlign: TextAlign.right,
                    style: ReportTableTypography.header,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CREDIT',
                    textAlign: TextAlign.right,
                    style: ReportTableTypography.header,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'BALANCE',
                    textAlign: TextAlign.right,
                    style: ReportTableTypography.header,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _comparisonPeriodHeader(String periodLabel) {
    return Column(
      children: [
        Container(
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Text(periodLabel, style: ReportTableTypography.header),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space10),
                child: Text(
                  'DEBIT',
                  textAlign: TextAlign.right,
                  style: ReportTableTypography.header,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space10),
                child: Text(
                  'CREDIT',
                  textAlign: TextAlign.right,
                  style: ReportTableTypography.header,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space10),
                child: Text(
                  'BALANCE',
                  textAlign: TextAlign.right,
                  style: ReportTableTypography.header,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GeneralLedgerEmptyBody extends StatelessWidget {
  const _GeneralLedgerEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No data to display',
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _GeneralLedgerDataRow extends StatefulWidget {
  final _GeneralLedgerRow row;
  final DateTime startDate;
  final DateTime endDate;
  final String basis;
  final NumberFormat numberFormat;
  final List<GeneralLedgerComparisonPeriod> comparisonPeriods;

  const _GeneralLedgerDataRow({
    required this.row,
    required this.startDate,
    required this.endDate,
    required this.basis,
    required this.numberFormat,
    required this.comparisonPeriods,
  });

  @override
  State<_GeneralLedgerDataRow> createState() => _GeneralLedgerDataRowState();
}

class _GeneralLedgerDataRowState extends State<_GeneralLedgerDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _openAccountTransactions() {
    final uri = Uri.parse(AppRoutes.accountantTransactionsReport).replace(
      queryParameters: {
        'accountId': widget.row.accountId,
        'accountName': widget.row.accountName,
        'startDate': ReportUtils.formatApiDate(widget.startDate),
        'endDate': ReportUtils.formatApiDate(widget.endDate),
        'basis': widget.basis,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isComparisonMode = widget.comparisonPeriods.length > 1;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openAccountTransactions,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: isComparisonMode
              ? Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          SizedBox(
                            width: AppTheme.space16,
                            child: widget.row.hasChildren
                                ? const Icon(
                                    Icons.add_box_outlined,
                                    size: AppTheme.space12,
                                    color: AppTheme.textPrimary,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Expanded(
                            child: Text(
                              widget.row.accountName,
                              style: AppTheme.bodyText.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...widget.comparisonPeriods.map((period) {
                      final deb = period.isCurrent ? widget.row.debit : 0.0;
                      final cred = period.isCurrent ? widget.row.credit : 0.0;
                      final bal = period.isCurrent ? widget.row.balance : 0.0;
                      return Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: _amountText(deb)),
                            Expanded(flex: 2, child: _amountText(cred)),
                            Expanded(flex: 2, child: _amountText(bal)),
                          ],
                        ),
                      );
                    }),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          SizedBox(
                            width: AppTheme.space16,
                            child: widget.row.hasChildren
                                ? const Icon(
                                    Icons.add_box_outlined,
                                    size: AppTheme.space12,
                                    color: AppTheme.textPrimary,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Expanded(
                            child: Text(
                              widget.row.accountName,
                              style: AppTheme.bodyText.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: _amountText(widget.row.debit)),
                    Expanded(flex: 2, child: _amountText(widget.row.credit)),
                    Expanded(flex: 2, child: _amountText(widget.row.balance)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _amountText(double value) {
    return Text(
      widget.numberFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        decoration: _isHovered ? TextDecoration.underline : null,
        decorationColor: AppTheme.primaryBlue,
      ),
    );
  }
}

class _BaseCurrencyNote extends StatelessWidget {
  final String currencyCode;

  const _BaseCurrencyNote({required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space2,
        AppTheme.space16,
        AppTheme.space12,
      ),
      child: Row(
        children: [
          Text(
            '**Amount is displayed in your base currency ',
            style: AppTheme.captionText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              currencyCode,
              style: AppTheme.captionText.copyWith(
                color: AppTheme.backgroundColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralLedgerRow {
  final String accountId;
  final String accountName;
  final double debit;
  final double credit;
  final double balance;
  final bool hasChildren;

  const _GeneralLedgerRow({
    required this.accountId,
    required this.accountName,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.hasChildren,
  });

  factory _GeneralLedgerRow.fromJson(Map<String, dynamic> json) {
    final debit = _numberValue(json['debit'] ?? json['totalDebit']);
    final credit = _numberValue(json['credit'] ?? json['totalCredit']);
    return _GeneralLedgerRow(
      accountId: json['accountId']?.toString() ?? '',
      accountName: _textValue(json['accountName']),
      debit: debit,
      credit: credit,
      balance: _numberValue(json['balance'] ?? json['netBalance']) == 0
          ? debit - credit
          : _numberValue(json['balance'] ?? json['netBalance']),
      hasChildren:
          json['hasChildren'] == true ||
          json['hasChildren']?.toString().toLowerCase() == 'true',
    );
  }

  static List<_GeneralLedgerRow> fromResponse(Map<String, dynamic>? data) {
    final rawRows = List<Map<String, dynamic>>.from(
      data?['accounts'] ??
          data?['Accountant'] ??
          const <Map<String, dynamic>>[],
    );
    return rawRows.map(_GeneralLedgerRow.fromJson).toList(growable: false);
  }

  static String _textValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Unknown' : text;
  }

  static double _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
