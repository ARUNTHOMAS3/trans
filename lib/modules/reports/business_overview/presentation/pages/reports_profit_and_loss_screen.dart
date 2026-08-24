import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/business_overview/data/providers/profit_and_loss_provider.dart';

const String _profitAndLossTitle = 'Profit and Loss';

class ProfitAndLossScreen extends ConsumerStatefulWidget {
  const ProfitAndLossScreen({super.key});

  @override
  ConsumerState<ProfitAndLossScreen> createState() => _ProfitAndLossScreenState();
}

class _ProfitAndLossScreenState extends ConsumerState<ProfitAndLossScreen> {
  static final DateTime _defaultDate = DateTime.now();
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];
  static final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  DateTime _startDate = _defaultDate;
  DateTime _endDate = _defaultDate;
  DateTime _appliedStartDate = _defaultDate;
  DateTime _appliedEndDate = _defaultDate;
  String _reportBasis = 'Cash';
  String _appliedReportBasis = 'Cash';
  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
  ReportCompareSelection _appliedCompareSelection = const ReportCompareSelection.none();

  String get _dateLabel =>
      'From ${_displayDateFormat.format(_appliedStartDate)} To ${_displayDateFormat.format(_appliedEndDate)}';

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleReportBasisChanged(String value) {
    if (_reportBasis == value) return;
    setState(() {
      _reportBasis = value;
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

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareSelection = selection;
      _appliedCompareSelection = selection;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedReportBasis = _reportBasis;
      _appliedCompareSelection = _compareSelection;
      _hasPendingFilterChanges = false;
    });
  }

  List<String> _buildComparisonPeriods() {
    if (!_appliedCompareSelection.isActive) {
      return const <String>[];
    }
    final periods = <String>[];
    final count = _appliedCompareSelection.count;
    final type = _appliedCompareSelection.compareType;

    for (int i = count; i >= 1; i--) {
      if (type == 'Previous Year(s)') {
        final dt = DateTime(
          _appliedEndDate.year - i,
          _appliedEndDate.month,
          _appliedEndDate.day,
        );
        periods.add(_displayDateFormat.format(dt));
      } else if (type == 'Previous Period(s)') {
        // Just mock period labels for now
        periods.add('Period - $i');
      } else {
        periods.add('Compare $i');
      }
    }
    periods.add(_displayDateFormat.format(_appliedEndDate));
    return periods;
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(profitAndLossProvider(
      ProfitAndLossRequest(
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
        basis: _appliedReportBasis,
      ),
    ));

    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: _profitAndLossTitle,
      dateLabel: _dateLabel,
      companyName: '',
      reportHeading: _ProfitAndLossHeading(
        basis: _appliedReportBasis,
        dateLabel: _dateLabel,
      ),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _startDate,
          initialEndDate: _endDate,
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
      settingsTooltip: 'Customize the Profit and Loss report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportCompareSection(
            selectedValue: _compareSelection.displayValue,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 2),
          const SizedBox(width: AppTheme.space10),
          ReportIconActionButton(
            icon: Icons.settings_outlined,
            onPressed: () {},
            tooltip: 'Customize report settings',
            chromeless: true,
          ),
        ],
      ),
      isLoading: reportAsync.isLoading,
      isEmpty: reportAsync.hasValue && reportAsync.value?['report'] == null,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: _profitAndLossTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _profitAndLossTitle) return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: reportAsync.when(
        data: (data) => _ProfitAndLossStatement(
          comparisonPeriods: _buildComparisonPeriods(),
          data: data,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
        ),
        loading: () => const Padding(padding: EdgeInsets.all(AppTheme.space16), child: SingleChildScrollView(physics: NeverScrollableScrollPhysics(), child: ZTableSkeleton(rows: 5, columns: 3))),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProfitAndLossHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _ProfitAndLossHeading({required this.basis, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _profitAndLossTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle,
        ),
        const SizedBox(height: AppTheme.space8),
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

class _ProfitAndLossStatement extends StatelessWidget {
  final List<String> comparisonPeriods;
  final Map<String, dynamic> data;
  final DateTime startDate;
  final DateTime endDate;

  const _ProfitAndLossStatement({
    required this.comparisonPeriods,
    required this.data,
    required this.startDate,
    required this.endDate,
  });

  List<_ProfitAndLossLine> _buildLines() {
    final report = data['report'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};

    final opIncome = (report['operatingIncome'] as List?) ?? [];
    final cogs = (report['costOfGoodsSold'] as List?) ?? [];
    final opExpenses = (report['operatingExpenses'] as List?) ?? [];
    final nonOpIncome = (report['nonOperatingIncome'] as List?) ?? [];
    final nonOpExpenses = (report['nonOperatingExpenses'] as List?) ?? [];

    String f(num? val) => (val ?? 0).toStringAsFixed(2);

    final lines = <_ProfitAndLossLine>[];
    
    // Operating Income
    lines.add(const _ProfitAndLossLine('Operating Income', isSection: true));
    for (final item in opIncome) {
      lines.add(_ProfitAndLossLine(item['accountName'] ?? '', amount: f(item['netAmount']), accountId: item['accountId'], isLink: true));
    }
    lines.add(_ProfitAndLossLine('Total for Operating Income', amount: f(summary['operatingIncome']), isTotal: true));

    // COGS
    lines.add(const _ProfitAndLossLine('Cost of Goods Sold', isSection: true));
    for (final item in cogs) {
      lines.add(_ProfitAndLossLine(item['accountName'] ?? '', amount: f(item['netAmount']), accountId: item['accountId'], isLink: true));
    }
    lines.add(_ProfitAndLossLine('Total for Cost of Goods Sold', amount: f(summary['costOfGoodsSold']), isTotal: true));

    lines.add(_ProfitAndLossLine('Gross Profit', amount: f(summary['grossProfit']), isTotal: true));

    // Operating Expenses
    lines.add(const _ProfitAndLossLine('Operating Expense', isSection: true));
    for (final item in opExpenses) {
      lines.add(_ProfitAndLossLine(item['accountName'] ?? '', amount: f(item['netAmount']), accountId: item['accountId'], isLink: true));
    }
    lines.add(_ProfitAndLossLine('Total for Operating Expense', amount: f(summary['operatingExpenses']), isTotal: true));

    lines.add(_ProfitAndLossLine('Operating Profit', amount: f(summary['operatingProfit']), isTotal: true));

    // Non Operating Income
    lines.add(const _ProfitAndLossLine('Non Operating Income', isSection: true));
    for (final item in nonOpIncome) {
      lines.add(_ProfitAndLossLine(item['accountName'] ?? '', amount: f(item['netAmount']), accountId: item['accountId'], isLink: true));
    }
    lines.add(_ProfitAndLossLine('Total for Non Operating Income', amount: f(summary['nonOperatingIncome']), isTotal: true));

    // Non Operating Expenses
    lines.add(const _ProfitAndLossLine('Non Operating Expense', isSection: true));
    for (final item in nonOpExpenses) {
      lines.add(_ProfitAndLossLine(item['accountName'] ?? '', amount: f(item['netAmount']), accountId: item['accountId'], isLink: true));
    }
    lines.add(_ProfitAndLossLine('Total for Non Operating Expense', amount: f(summary['nonOperatingExpenses']), isTotal: true));

    lines.add(_ProfitAndLossLine('Net Profit/Loss', amount: f(summary['netProfit']), isTotal: true));
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int extraCols = comparisonPeriods.isEmpty ? 0 : comparisonPeriods.length - 1;
        final double minWidth = 826.0 + (extraCols * 160.0);
        final tableWidth = constraints.maxWidth < minWidth ? constraints.maxWidth : minWidth;
        
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfitAndLossTableHeader(comparisonPeriods: comparisonPeriods),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final line in _buildLines())
                        _ProfitAndLossTableRow(
                          line: line,
                          comparisonPeriods: comparisonPeriods,
                          startDate: startDate,
                          endDate: endDate,
                        ),
                      const SizedBox(height: AppTheme.space24),
                      const _ProfitAndLossCurrencyNote(),
                      const SizedBox(height: AppTheme.space28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfitAndLossTableHeader extends StatelessWidget {
  final List<String> comparisonPeriods;
  const _ProfitAndLossTableHeader({required this.comparisonPeriods});

  @override
  Widget build(BuildContext context) {
    final bool hasComparison = comparisonPeriods.isNotEmpty;
    return Container(
      height: hasComparison ? 68 : 34,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: hasComparison
          ? Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      for (final period in comparisonPeriods)
                        SizedBox(
                          width: 160,
                          child: Center(
                            child: Text(
                              period,
                              style: ReportTableTypography.header,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Text('ACCOUNT', style: ReportTableTypography.header)),
                      for (final _ in comparisonPeriods)
                        SizedBox(
                          width: 160,
                          child: Text(
                            'TOTAL',
                            textAlign: TextAlign.right,
                            style: ReportTableTypography.header,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: Text('ACCOUNT', style: ReportTableTypography.header)),
                SizedBox(
                  width: 160,
                  child: Text(
                    'TOTAL',
                    textAlign: TextAlign.right,
                    style: ReportTableTypography.header,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfitAndLossTableRow extends StatelessWidget {
  final _ProfitAndLossLine line;
  final List<String> comparisonPeriods;
  final DateTime startDate;
  final DateTime endDate;

  const _ProfitAndLossTableRow({
    required this.line,
    required this.comparisonPeriods,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBold = line.isSection || line.isTotal;
    final textStyle = AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      height: 1.35,
    );
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: line.isTotal ? const Border(bottom: BorderSide(color: AppTheme.borderLight)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: (line.isLink && line.accountId != null)
                ? ZerpaiLinkText(
                    text: line.label,
                    style: textStyle,
                    onTap: () {
                      final apiDateFormat = ReportFormatterCache.date('yyyy-MM-dd');
                      context.push(Uri(
                        path: AppRoutes.accountantTransactionsReport,
                        queryParameters: {
                          'accountId': line.accountId,
                          'accountName': line.label,
                          'startDate': apiDateFormat.format(startDate),
                          'endDate': apiDateFormat.format(endDate),
                        },
                      ).toString());
                    },
                  )
                : Text(
                    line.label,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
          ),
          if (comparisonPeriods.isEmpty)
            SizedBox(
              width: 160,
              child: Text(
                line.amount,
                textAlign: TextAlign.right,
                style: textStyle.copyWith(
                  fontWeight: line.isTotal ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            )
          else
            for (final _ in comparisonPeriods)
              SizedBox(
                width: 160,
                child: Text(
                  line.amount,
                  textAlign: TextAlign.right,
                  style: textStyle.copyWith(
                    fontWeight: line.isTotal ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ProfitAndLossCurrencyNote extends StatelessWidget {
  const _ProfitAndLossCurrencyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '**Amount is displayed in your base currency',
          style: AppTheme.captionText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppTheme.space4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: 2,
          ),
          color: AppTheme.successTextDark,
          child: Text(
            'INR',
            style: AppTheme.captionText.copyWith(
              color: AppTheme.backgroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfitAndLossLine {
  final String label;
  final String amount;
  final bool isSection;
  final bool isTotal;
  final String? accountId;
  final bool isLink;

  const _ProfitAndLossLine(
    this.label, {
    this.amount = '',
    this.isSection = false,
    this.isTotal = false,
    this.accountId,
    this.isLink = false,
  });
}
