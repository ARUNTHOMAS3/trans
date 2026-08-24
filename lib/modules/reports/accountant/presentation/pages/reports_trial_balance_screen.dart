import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';

const String _trialBalanceTitle = 'Trial Balance';

typedef TrialBalanceParams = ({
  String startDate,
  String endDate,
  String basis,
  int page,
  int pageSize,
});

final trialBalanceProvider =
    FutureProvider.family<Map<String, dynamic>, TrialBalanceParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return repo.getTrialBalance(
        params.startDate,
        params.endDate,
        basis: params.basis,
        page: params.page,
        pageSize: params.pageSize,
      );
    });

class TrialBalanceScreen extends ConsumerStatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  ConsumerState<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends ConsumerState<TrialBalanceScreen> {
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _collapseSubAccounts = true;
  int _page = 1;
  final int _pageSize = 100000;
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
    final asOfLabel = 'As of ${dateFormat.format(appliedEndDate)}';
    final queryParams = (
      startDate: ReportUtils.formatApiDate(appliedStartDate),
      endDate: ReportUtils.formatApiDate(appliedEndDate),
      basis: _appliedReportBasis,
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(trialBalanceProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final sections = _TrialBalanceSection.fromResponse(reportData);
    final totals = _TrialBalanceTotals.fromResponse(reportData);
    final pagination = Map<String, dynamic>.from(
      reportData?['pagination'] as Map? ?? const <String, dynamic>{},
    );
    final totalCount = _intValue(
      pagination['totalRecords'] ?? pagination['total'] ?? reportData?['total'],
      sections.fold<int>(0, (sum, section) => sum + section.rows.length),
    );
    final currentPage = _intValue(
      pagination['page'] ?? reportData?['page'],
      _page,
    );
    final effectivePageSize = _intValue(
      pagination['pageSize'] ?? reportData?['pageSize'],
      _pageSize,
    );
    final currencyCode = ref.watch(defaultCurrencyProvider).valueOrNull?.code ?? 'INR';

    return ReportViewScaffold(
      categoryLabel: 'Accountant',
      reportTitle: _trialBalanceTitle,
      dateLabel: asOfLabel,
      companyName: '',
      reportHeading: _TrialBalanceHeading(
        basis: _appliedReportBasis,
        asOfLabel: asOfLabel,
      ),
      filters: [
        ReportDateRangeFilter(
          label: 'As of Date',
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
        reportName: _trialBalanceTitle,
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
      settingsTooltip: 'Customize the Trial Balance report.',
      scheduleTooltip: 'Schedule the Trial Balance report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CollapseSubAccountsAction(
            value: _collapseSubAccounts,
            onChanged: (value) => setState(() => _collapseSubAccounts = value),
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 4),
          const SizedBox(width: AppTheme.space10),
          ReportIconActionButton(
            icon: Icons.settings_outlined,
            tooltip: 'Customize the Trial Balance report.',
            onPressed: () {},
          ),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(trialBalanceProvider(queryParams)),
      isEmpty: sections.isEmpty,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Accountant',
      currentNavigationReport: _trialBalanceTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _trialBalanceTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _TrialBalanceTable(
        collapseSubAccounts: _collapseSubAccounts,
        sections: sections,
        totals: totals,
        currencyCode: currencyCode,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _TrialBalanceHeading extends StatelessWidget {
  final String basis;
  final String asOfLabel;

  const _TrialBalanceHeading({required this.basis, required this.asOfLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _trialBalanceTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle,
        ),
        const SizedBox(height: AppTheme.space6),
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
          asOfLabel,
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

class _CollapseSubAccountsAction extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CollapseSubAccountsAction({required this.value, required this.onChanged});

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

class _TrialBalanceTable extends StatelessWidget {
  static final NumberFormat _numberFormat = ReportFormatterCache.number('#,##0.00');

  final bool collapseSubAccounts;
  final List<_TrialBalanceSection> sections;
  final _TrialBalanceTotals totals;
  final String currencyCode;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _TrialBalanceTable({
    required this.collapseSubAccounts,
    required this.sections,
    required this.totals,
    required this.currencyCode,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 826 ? constraints.maxWidth : 826.0;
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
                  child: sections.isEmpty
                      ? const _TrialBalanceEmptyBody()
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final section in sections) ...[
                                _TrialBalanceSectionHeader(label: section.label),
                                for (final row in section.rows)
                                  _TrialBalanceDataRow(row: row, collapseSubAccounts: collapseSubAccounts),
                              ],
                              _TrialBalanceTotalRow(totals: totals),
                              _BaseCurrencyNote(currencyCode: currencyCode),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: _buildTrialBalanceRow(
        account: _headerText('ACCOUNT'),
        accountCode: _headerText('ACCOUNT CODE'),
        debit: _headerText('NET DEBIT', alignRight: true),
        credit: _headerText('NET CREDIT', alignRight: true),
      ),
    );
  }
}

class _TrialBalanceSectionHeader extends StatelessWidget {
  final String label;

  const _TrialBalanceSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTrialBalanceRow(
        account: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        accountCode: const SizedBox.shrink(),
        debit: const SizedBox.shrink(),
        credit: const SizedBox.shrink(),
      ),
    );
  }
}

class _TrialBalanceDataRow extends StatefulWidget {
  final _TrialBalanceRow row;
  final int level;
  final bool collapseSubAccounts;

  const _TrialBalanceDataRow({required this.row, this.level = 0, required this.collapseSubAccounts});

  @override
  State<_TrialBalanceDataRow> createState() => _TrialBalanceDataRowState();
}

class _TrialBalanceDataRowState extends State<_TrialBalanceDataRow> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.collapseSubAccounts;
  }

  @override
  void didUpdateWidget(_TrialBalanceDataRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapseSubAccounts != oldWidget.collapseSubAccounts) {
      _isExpanded = !widget.collapseSubAccounts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSub = widget.row.subAccounts.isNotEmpty;
    
    double totalDebit = widget.row.closingDebit;
    double totalCredit = widget.row.closingCredit;
    if (hasSub) {
      for (var sub in widget.row.subAccounts) {
         totalDebit += sub.closingDebit;
         totalCredit += sub.closingCredit;
      }
    }
    
    double displayDebit = widget.row.closingDebit;
    double displayCredit = widget.row.closingCredit;
    if (hasSub && !_isExpanded) {
      displayDebit = totalDebit;
      displayCredit = totalCredit;
    }

    FontWeight fontWeight = FontWeight.w500;
    if (hasSub && !_isExpanded) {
      fontWeight = FontWeight.w700;
    }

    final rowWidget = InkWell(
      onTap: () {
        if (hasSub) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        } else {
          context.push(Uri(
            path: AppRoutes.accountantTransactionsReport,
            queryParameters: {
              'accountId': widget.row.accountId,
              'accountName': widget.row.accountName,
            },
          ).toString());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: _buildTrialBalanceRow(
          account: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                SizedBox(width: widget.level * 20.0),
                SizedBox(
                  width: 24.0,
                  child: hasSub
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            _isExpanded ? LucideIcons.minusCircle : LucideIcons.plusCircle,
                            size: 16,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : null,
                ),
                Expanded(
                child: ZerpaiLinkText(
                  text: widget.row.accountName,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: fontWeight,
                  ),
                  onTap: () {
                    context.push(Uri(
                      path: AppRoutes.accountantTransactionsReport,
                      queryParameters: {
                        'accountId': widget.row.accountId,
                        'accountName': widget.row.accountName,
                      },
                    ).toString());
                  },
                ),
              ),
            ],
          ),
        ),
        accountCode: Text(
          widget.row.accountCode,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          debit: Text(
            _TrialBalanceTable._numberFormat.format(displayDebit),
            textAlign: TextAlign.right,
            style: _amountStyle(AppTheme.primaryBlue),
          ),
          credit: Text(
            _TrialBalanceTable._numberFormat.format(displayCredit),
            textAlign: TextAlign.right,
            style: _amountStyle(AppTheme.primaryBlue),
          ),
        ),
      ),
    );

    if (!hasSub || !_isExpanded) {
      return rowWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rowWidget,
        ...widget.row.subAccounts.map((sub) => _TrialBalanceDataRow(row: sub, level: widget.level + 1, collapseSubAccounts: widget.collapseSubAccounts)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: _buildTrialBalanceRow(
            account: Padding(
              padding: EdgeInsets.only(left: (widget.level + 1) * 20.0),
              child: Text(
                'Total for ${widget.row.accountName}',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            accountCode: const SizedBox(),
            debit: Text(
              _TrialBalanceTable._numberFormat.format(totalDebit),
              textAlign: TextAlign.right,
              style: _amountStyle(AppTheme.textPrimary).copyWith(fontWeight: FontWeight.w700),
            ),
            credit: Text(
              _TrialBalanceTable._numberFormat.format(totalCredit),
              textAlign: TextAlign.right,
              style: _amountStyle(AppTheme.textPrimary).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrialBalanceTotalRow extends StatelessWidget {
  final _TrialBalanceTotals totals;

  const _TrialBalanceTotalRow({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTrialBalanceRow(
        account: Text(
          'Total for Trial Balance',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        accountCode: const SizedBox.shrink(),
        debit: Text(
          _TrialBalanceTable._numberFormat.format(totals.closingDebit),
          textAlign: TextAlign.right,
          style: _amountStyle(AppTheme.textPrimary),
        ),
        credit: Text(
          _TrialBalanceTable._numberFormat.format(totals.closingCredit),
          textAlign: TextAlign.right,
          style: _amountStyle(AppTheme.textPrimary),
        ),
      ),
    );
  }
}

class _TrialBalanceEmptyBody extends StatelessWidget {
  const _TrialBalanceEmptyBody();

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

class _BaseCurrencyNote extends StatelessWidget {
  final String currencyCode;

  const _BaseCurrencyNote({required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space20,
        AppTheme.space20,
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: AppTheme.space2,
            ),
            color: Colors.green.shade700,
            child: Text(
              currencyCode,
              style: AppTheme.captionText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildTrialBalanceRow({
    required Widget account,
    required Widget accountCode,
    required Widget debit,
    required Widget credit,
    double paddingVertical = AppTheme.space10,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: Padding(padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: AppTheme.space12), child: account)),
          Container(width: 1, color: AppTheme.borderLight),
          Expanded(flex: 3, child: Padding(padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: AppTheme.space12), child: accountCode)),
          Expanded(
            flex: 2,
            child: Padding(padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: AppTheme.space12), child: Align(alignment: Alignment.centerRight, child: debit)),
          ),
          Expanded(
            flex: 2,
            child: Padding(padding: EdgeInsets.symmetric(vertical: paddingVertical, horizontal: AppTheme.space12), child: Align(alignment: Alignment.centerRight, child: credit)),
          ),
        ],
      ),
    );
  }

Widget _headerText(String label, {bool alignRight = false}) {
  return Align(
    alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(label, style: ReportTableTypography.header),
  );
}

TextStyle _amountStyle(Color color) {
  return AppTheme.bodyText.copyWith(color: color, fontWeight: FontWeight.w500);
}

class _TrialBalanceSection {
  final String label;
  final List<_TrialBalanceRow> rows;

  const _TrialBalanceSection({required this.label, required this.rows});

  static List<_TrialBalanceSection> fromResponse(Map<String, dynamic>? response) {
    final rawSections = response?['sections'];
    if (rawSections is! List) return const <_TrialBalanceSection>[];
    return rawSections
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map(
          (raw) {
            final String label = raw['accountGroupLabel']?.toString() ?? 'Uncategorized';
            List<_TrialBalanceRow> allRows = [];
            if (raw['rows'] is List) {
              allRows = (raw['rows'] as List)
                  .whereType<Map>()
                  .map((row) => _TrialBalanceRow.fromJson(Map<String, dynamic>.from(row)))
                  .toList();
                  
              final outputTaxNames = ['Output SGST', 'Output CGST', 'Output IGST'];
              final inputTaxNames = ['Input SGST', 'Input CGST', 'Input IGST'];
              bool hasOutputTaxes = false;
              bool hasInputTaxes = false;

              allRows = allRows.map((row) {
                if (outputTaxNames.contains(row.accountName)) {
                  hasOutputTaxes = true;
                  return _TrialBalanceRow(
                    accountId: row.accountId,
                    parentId: 'fake-output-payable',
                    accountName: row.accountName,
                    accountCode: row.accountCode,
                    openingDebit: row.openingDebit,
                    openingCredit: row.openingCredit,
                    periodDebit: row.periodDebit,
                    periodCredit: row.periodCredit,
                    closingDebit: row.closingDebit,
                    closingCredit: row.closingCredit,
                  );
                } else if (inputTaxNames.contains(row.accountName)) {
                  hasInputTaxes = true;
                  return _TrialBalanceRow(
                    accountId: row.accountId,
                    parentId: 'fake-input-tax-credits',
                    accountName: row.accountName,
                    accountCode: row.accountCode,
                    openingDebit: row.openingDebit,
                    openingCredit: row.openingCredit,
                    periodDebit: row.periodDebit,
                    periodCredit: row.periodCredit,
                    closingDebit: row.closingDebit,
                    closingCredit: row.closingCredit,
                  );
                }
                return row;
              }).toList();

              if (hasOutputTaxes) {
                allRows.add(const _TrialBalanceRow(
                  accountId: 'fake-output-payable',
                  parentId: null,
                  accountName: 'Output Payable',
                  accountCode: '',
                  openingDebit: 0,
                  openingCredit: 0,
                  periodDebit: 0,
                  periodCredit: 0,
                  closingDebit: 0,
                  closingCredit: 0,
                ));
              }

              if (hasInputTaxes) {
                allRows.add(const _TrialBalanceRow(
                  accountId: 'fake-input-tax-credits',
                  parentId: null,
                  accountName: 'Input Tax Credits',
                  accountCode: '',
                  openingDebit: 0,
                  openingCredit: 0,
                  periodDebit: 0,
                  periodCredit: 0,
                  closingDebit: 0,
                  closingCredit: 0,
                ));
              }
            }
            
            final Map<String, List<_TrialBalanceRow>> childrenMap = {};
            for (var row in allRows) {
              if (row.parentId != null && row.parentId!.isNotEmpty) {
                childrenMap.putIfAbsent(row.parentId!, () => []).add(row);
              }
            }
            
            final List<_TrialBalanceRow> rootRows = [];
            for (var row in allRows) {
              final bool hasParentInGroup = row.parentId != null && allRows.any((r) => r.accountId == row.parentId);
              if (!hasParentInGroup) {
                _TrialBalanceRow buildNode(_TrialBalanceRow node) {
                  final children = childrenMap[node.accountId] ?? [];
                  if (children.isEmpty) return node;
                  return _TrialBalanceRow(
                    accountId: node.accountId,
                    parentId: node.parentId,
                    accountName: node.accountName,
                    accountCode: node.accountCode,
                    openingDebit: node.openingDebit,
                    openingCredit: node.openingCredit,
                    periodDebit: node.periodDebit,
                    periodCredit: node.periodCredit,
                    closingDebit: node.closingDebit,
                    closingCredit: node.closingCredit,
                    subAccounts: children.map((c) => buildNode(c)).toList(growable: false),
                  );
                }
                rootRows.add(buildNode(row));
              }
            }

            return _TrialBalanceSection(
              label: label,
              rows: rootRows,
            );
          },
        )
        .where((section) => section.rows.isNotEmpty)
        .toList(growable: false);
  }
}

class _TrialBalanceRow {
  final String accountId;
  final String? parentId;
  final String accountName;
  final List<_TrialBalanceRow> subAccounts;
  final String accountCode;
  final double openingDebit;
  final double openingCredit;
  final double periodDebit;
  final double periodCredit;
  final double closingDebit;
  final double closingCredit;

  const _TrialBalanceRow({
    required this.accountId,
    this.parentId,
    this.subAccounts = const [],
    required this.accountName,
    required this.accountCode,
    required this.openingDebit,
    required this.openingCredit,
    required this.periodDebit,
    required this.periodCredit,
    required this.closingDebit,
    required this.closingCredit,
  });

  factory _TrialBalanceRow.fromJson(Map<String, dynamic> json) {
    return _TrialBalanceRow(
      accountId: json['accountId']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      accountName: json['accountName']?.toString() ?? '--',
      accountCode: json['accountCode']?.toString() ?? '',
      openingDebit: _doubleValue(json['openingDebit']),
      openingCredit: _doubleValue(json['openingCredit']),
      periodDebit: _doubleValue(json['periodDebit']),
      periodCredit: _doubleValue(json['periodCredit']),
      closingDebit: _doubleValue(json['closingDebit']),
      closingCredit: _doubleValue(json['closingCredit']),
    );
  }
}

class _TrialBalanceTotals {
  final double closingDebit;
  final double closingCredit;

  const _TrialBalanceTotals({required this.closingDebit, required this.closingCredit});

  factory _TrialBalanceTotals.fromResponse(Map<String, dynamic>? response) {
    final raw = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return _TrialBalanceTotals(
      closingDebit: _doubleValue(raw['closingDebit']),
      closingCredit: _doubleValue(raw['closingCredit']),
    );
  }
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
