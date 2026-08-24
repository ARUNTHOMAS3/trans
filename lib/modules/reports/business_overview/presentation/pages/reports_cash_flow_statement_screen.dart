import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';

import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/business_overview/data/providers/cash_flow_statement_provider.dart';

class CashFlowStatementScreen extends ConsumerStatefulWidget {
  const CashFlowStatementScreen({super.key});

  @override
  ConsumerState<CashFlowStatementScreen> createState() =>
      _CashFlowStatementScreenState();
}

class _CashFlowStatementScreenState extends ConsumerState<CashFlowStatementScreen> {


  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _collapseSubAccounts = false;
  
  static final DateTime _defaultDate = DateTime.now();
  late DateTime _startDate = DateTime(_defaultDate.year, _defaultDate.month, 1);
  late DateTime _endDate = _defaultDate;
  late DateTime _appliedStartDate = DateTime(_defaultDate.year, _defaultDate.month, 1);
  late DateTime _appliedEndDate = _defaultDate;
  static final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
  ReportCompareSelection _appliedCompareSelection = const ReportCompareSelection.none();

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    DateTime start = selection.startDate;
    DateTime end = selection.endDate;
    setState(() {
      _startDate = start;
      _endDate = end;
      _hasPendingFilterChanges = true;
    });
  }

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _toggleCollapseSubAccounts() {
    setState(() {
      _collapseSubAccounts = !_collapseSubAccounts;
    });
  }

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareSelection = selection;
      _appliedCompareSelection = selection;
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
        periods.add('Period - $i');
      } else {
        periods.add('Compare $i');
      }
    }
    periods.add(_displayDateFormat.format(_appliedEndDate));
    return periods;
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedCompareSelection = _compareSelection;
      _hasPendingFilterChanges = false;
    });
    ref.invalidate(cashFlowStatementProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Cash Flow Statement',
      dateLabel: 'From ${_displayDateFormat.format(_appliedStartDate)} To ${_displayDateFormat.format(_appliedEndDate)}',
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _startDate,
          initialEndDate: _endDate,
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
      settingsTooltip: 'Customize the Cash Flow Statement report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CollapseSubAccountsAction(
            value: _collapseSubAccounts,
            onChanged: _toggleCollapseSubAccounts,
          ),
          const SizedBox(width: AppTheme.space10),
          ReportCompareSection(
            selectedValue: _compareSelection.displayValue,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 2),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Cash Flow Statement',
      onReportSelected: (reportName, category) {
        if (reportName == 'Cash Flow Statement') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: _CashFlowStatementBody(
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
        comparisonPeriods: _buildComparisonPeriods(),
        collapseSubAccounts: _collapseSubAccounts,
      ),
    );
  }
}

class _CollapseSubAccountsAction extends StatelessWidget {
  final bool value;
  final VoidCallback onChanged;

  const _CollapseSubAccountsAction({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(AppTheme.space4),
      hoverColor: AppTheme.bgHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: value,
              onChanged: (_) => onChanged(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: AppTheme.space4),
            Text(
              'Collapse Sub-Accounts',
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowRowData {
  final String account;
  final String total;
  final int indentLevel;
  final bool isSection;
  final bool isTotal;
  final bool isLink = false;
  final bool showCollapseIcon = false;

  const _CashFlowRowData({
    required this.account,
    required this.total,
    this.indentLevel = 0,
    this.isSection = false,
    this.isTotal = false,
    });
}

class _CashFlowStatementBody extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<String> comparisonPeriods;
  final bool collapseSubAccounts;

  const _CashFlowStatementBody({
    required this.startDate,
    required this.endDate,
    required this.comparisonPeriods,
    required this.collapseSubAccounts,
  });

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = CashFlowStatementRequest(
      startDate: startDate,
      endDate: endDate,
      basis: 'Accrual',
    );

    final asyncData = ref.watch(cashFlowStatementProvider(request));

    return asyncData.when(
      loading: () => const Padding(padding: EdgeInsets.all(AppTheme.space16), child: SingleChildScrollView(physics: NeverScrollableScrollPhysics(), child: ZTableSkeleton(rows: 5, columns: 3))),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final operating = (data['operatingActivities'] as List<dynamic>?) ?? [];
        final investing = (data['investingActivities'] as List<dynamic>?) ?? [];
        final financing = (data['financingActivities'] as List<dynamic>?) ?? [];

        final List<_CashFlowRowData> dynamicRows = [];

        // Operating Activities
        dynamicRows.add(const _CashFlowRowData(account: 'Cash Flow from Operating Activities', total: '', isSection: true));
        double totalOperating = 0;
        for (final item in operating) {
          final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
          totalOperating += amount;
          if (!collapseSubAccounts) {
            dynamicRows.add(_CashFlowRowData(
              account: item['accountName'] as String,
              total: amount.toStringAsFixed(2),
              indentLevel: 1,
            ));
          }
        }
        dynamicRows.add(_CashFlowRowData(account: 'Net Cash from Operating Activities', total: totalOperating.toStringAsFixed(2), isTotal: true));

        // Investing Activities
        dynamicRows.add(const _CashFlowRowData(account: 'Cash Flow from Investing Activities', total: '', isSection: true));
        double totalInvesting = 0;
        for (final item in investing) {
          final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
          totalInvesting += amount;
          if (!collapseSubAccounts) {
            dynamicRows.add(_CashFlowRowData(
              account: item['accountName'] as String,
              total: amount.toStringAsFixed(2),
              indentLevel: 1,
            ));
          }
        }
        dynamicRows.add(_CashFlowRowData(account: 'Net Cash from Investing Activities', total: totalInvesting.toStringAsFixed(2), isTotal: true));

        // Financing Activities
        dynamicRows.add(const _CashFlowRowData(account: 'Cash Flow from Financing Activities', total: '', isSection: true));
        double totalFinancing = 0;
        for (final item in financing) {
          final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
          totalFinancing += amount;
          if (!collapseSubAccounts) {
            dynamicRows.add(_CashFlowRowData(
              account: item['accountName'] as String,
              total: amount.toStringAsFixed(2),
              indentLevel: 1,
            ));
          }
        }
        dynamicRows.add(_CashFlowRowData(account: 'Net Cash from Financing Activities', total: totalFinancing.toStringAsFixed(2), isTotal: true));

        final totalChange = totalOperating + totalInvesting + totalFinancing;
        dynamicRows.add(_CashFlowRowData(account: 'Net Change in Cash', total: totalChange.toStringAsFixed(2), isTotal: true, indentLevel: 0, isSection: true));

        return LayoutBuilder(
          builder: (context, constraints) {
            final int extraCols = comparisonPeriods.isEmpty ? 0 : comparisonPeriods.length - 1;
            final double minWidth = 825.0 + (extraCols * 170.0);
            final tableWidth = constraints.maxWidth < minWidth ? constraints.maxWidth : minWidth;
            
            final tableHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : 360.0;
            final table = SizedBox(
              width: tableWidth,
              height: tableHeight,
              child: ReportStickyHeaderScrollTable(
                header: _CashFlowTableHeader(comparisonPeriods: comparisonPeriods),
                emptyBody: const SizedBox.shrink(),
                children: [
                  for (final row in dynamicRows) 
                    _CashFlowTableRow(
                      row: row,
                      comparisonPeriods: comparisonPeriods,
                    ),
                  const SizedBox(height: AppTheme.space24),
                  const _BaseCurrencyNote(),
                  const SizedBox(height: AppTheme.space10),
                ],
              ),
            );

            if (constraints.maxWidth < tableWidth) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              );
            }

            return Center(child: table);
          },
        );
      },
    );
  }
}

class _CashFlowTableHeader extends StatelessWidget {
  final List<String> comparisonPeriods;
  const _CashFlowTableHeader({required this.comparisonPeriods});

  @override
  Widget build(BuildContext context) {
    final bool hasComparison = comparisonPeriods.isNotEmpty;
    return Container(
      height: hasComparison ? 68 : 34,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
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
                          width: 170,
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                          child: Row(
                            children: [
                              Text('ACCOUNT', style: ReportTableTypography.header),
                              const SizedBox(width: AppTheme.space4),
                              const Icon(
                                Icons.unfold_more,
                                size: AppTheme.space12,
                                color: AppTheme.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final _ in comparisonPeriods)
                        SizedBox(
                          width: 170,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                            child: Text(
                              'TOTAL',
                              textAlign: TextAlign.right,
                              style: ReportTableTypography.header,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                    child: Row(
                      children: [
                        Text('ACCOUNT', style: ReportTableTypography.header),
                        const SizedBox(width: AppTheme.space4),
                        const Icon(
                          Icons.unfold_more,
                          size: AppTheme.space12,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                    child: Text(
                      'TOTAL',
                      textAlign: TextAlign.right,
                      style: ReportTableTypography.header,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CashFlowTableRow extends StatelessWidget {
  final _CashFlowRowData row;
  final List<String> comparisonPeriods;

  const _CashFlowTableRow({
    required this.row,
    required this.comparisonPeriods,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary;
    final labelStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: textColor,
      fontWeight: row.isSection || row.isTotal
          ? FontWeight.w700
          : FontWeight.w400,
    );
    final amountStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection ? FontWeight.w700 : FontWeight.w400,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.space20 + (row.indentLevel * AppTheme.space16),
          right: AppTheme.space20,
          top: row.isSection ? AppTheme.space14 : AppTheme.space10,
          bottom: AppTheme.space10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (row.showCollapseIcon) ...[
                    const Icon(
                      Icons.remove_circle,
                      size: AppTheme.space12,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: AppTheme.space2),
                  ],
                  Flexible(child: Text(row.account, style: labelStyle)),
                ],
              ),
            ),
            if (comparisonPeriods.isEmpty)
              SizedBox(
                width: 170,
                child: Text(
                  row.total,
                  textAlign: TextAlign.right,
                  style: amountStyle,
                ),
              )
            else
              for (final _ in comparisonPeriods)
                SizedBox(
                  width: 170,
                  child: Text(
                    row.total,
                    textAlign: TextAlign.right,
                    style: amountStyle,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _BaseCurrencyNote extends StatelessWidget {
  const _BaseCurrencyNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '**Amount is displayed in your base currency',
            style: AppTheme.captionText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successTextDark,
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              'INR',
              style: AppTheme.captionText.copyWith(
                color: AppTheme.backgroundColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
