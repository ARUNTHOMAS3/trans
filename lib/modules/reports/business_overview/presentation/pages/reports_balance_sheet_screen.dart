import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  static const String _dateLabel = 'As of 14-07-2026';

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _collapseSubAccounts = false;
  String _reportBasis = 'Accrual';
  
  static final DateTime _defaultDate = DateTime(2026, 7, 14); // Mock anchor date
  final DateTime _appliedEndDate = _defaultDate;
  static final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
  ReportCompareSelection _appliedCompareSelection = const ReportCompareSelection.none();

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
      _hasPendingFilterChanges = true;
    });
  }

  void _cycleReportBasis() {
    setState(() {
      _reportBasis = _reportBasis == 'Accrual' ? 'Cash' : 'Accrual';
      _hasPendingFilterChanges = true;
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
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Balance Sheet',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'As of',
          value: 'Today',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'Report Basis',
          value: _reportBasis,
          onPressed: _cycleReportBasis,
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
      settingsTooltip: 'Customize the Balance Sheet report.',
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
          const SizedBox(width: AppTheme.space10),
          ReportIconActionButton(
            icon: Icons.settings_outlined,
            onPressed: () {},
            tooltip: 'Customize report settings',
            chromeless: true,
          ),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Balance Sheet',
      onReportSelected: (reportName, category) {
        if (reportName == 'Balance Sheet') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: _BalanceSheetBody(
        reportBasis: _reportBasis,
        comparisonPeriods: _buildComparisonPeriods(),
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

class _BalanceSheetRowData {
  final String account;
  final String total;
  final int indentLevel;
  final bool isSection;
  final bool isTotal;
  final bool isLink;
  final bool showCollapseIcon;

  const _BalanceSheetRowData({
    required this.account,
    required this.total,
    this.indentLevel = 0,
    this.isSection = false,
    this.isTotal = false,
    this.isLink = false,
    this.showCollapseIcon = false,
  });
}

class _BalanceSheetBody extends StatelessWidget {
  final String reportBasis;
  final List<String> comparisonPeriods;

  const _BalanceSheetBody({
    required this.reportBasis,
    required this.comparisonPeriods,
  });

  static const List<_BalanceSheetRowData> _rows = [
    _BalanceSheetRowData(account: 'Assets', total: '', isSection: true),
    _BalanceSheetRowData(
      account: 'Current Assets',
      total: '',
      indentLevel: 1,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Cash and Cash Equivalents',
      total: '',
      indentLevel: 2,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Cash',
      total: '',
      indentLevel: 3,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Petty Cash',
      total: '210.55',
      indentLevel: 4,
      isLink: true,
      showCollapseIcon: true,
    ),
    _BalanceSheetRowData(
      account: 'TESTINGS CASH',
      total: '-169.00',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Petty Cash',
      total: '41.55',
      indentLevel: 4,
      isTotal: true,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Undeposited Funds',
      total: '210.00',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Cash',
      total: '251.55',
      indentLevel: 3,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Bank',
      total: '',
      indentLevel: 3,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Bandhan Bank',
      total: '8,79,240.48',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Bank',
      total: '8,79,240.48',
      indentLevel: 3,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Cash and Cash Equivalents',
      total: '8,79,492.03',
      indentLevel: 2,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Accounts Receivable',
      total: '',
      indentLevel: 2,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Accounts Receivable',
      total: '7,10,737.00',
      indentLevel: 3,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Accounts Receivable',
      total: '7,10,737.00',
      indentLevel: 2,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Other current assets',
      total: '',
      indentLevel: 2,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Finished Goods',
      total: '15,004.50',
      indentLevel: 3,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Goods In Transit',
      total: '2,710.90',
      indentLevel: 3,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Inventory Asset',
      total: '3,14,988.70',
      indentLevel: 3,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Prepaid Expenses',
      total: '13,17,984.10',
      indentLevel: 3,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'TCS Receivable',
      total: '23.17',
      indentLevel: 3,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Input Tax Credits',
      total: '0.00',
      indentLevel: 3,
      isLink: true,
      showCollapseIcon: true,
    ),
    _BalanceSheetRowData(
      account: 'Input CGST',
      total: '52.59',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Input IGST',
      total: '1,029.33',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Input SGST',
      total: '52.59',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Input Tax Credits',
      total: '1,134.51',
      indentLevel: 3,
      isTotal: true,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Other current assets',
      total: '16,51,845.88',
      indentLevel: 2,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Current Assets',
      total: '32,42,074.91',
      indentLevel: 1,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Non Current Assets',
      total: '',
      indentLevel: 1,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Non Current Assets',
      total: '0.00',
      indentLevel: 1,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Fixed Assets',
      total: '',
      indentLevel: 1,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Fixed Assets',
      total: '0.00',
      indentLevel: 1,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Other Assets',
      total: '',
      indentLevel: 1,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'd',
      total: '100.00',
      indentLevel: 2,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Other Assets',
      total: '100.00',
      indentLevel: 1,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Assets',
      total: '32,42,174.91',
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Liabilities & Equities',
      total: '',
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Liabilities',
      total: '',
      indentLevel: 1,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Current Liabilities',
      total: '',
      indentLevel: 2,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Accounts Payable',
      total: '',
      indentLevel: 3,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Accounts Payable',
      total: '74,831.05',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Accounts Payable',
      total: '74,831.05',
      indentLevel: 3,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Other Current Liabilities',
      total: '',
      indentLevel: 3,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'GST PAYABLE',
      total: '-4,680.00',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Opening Balance Adjustments',
      total: '37,500.00',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Unearned Revenue',
      total: '21,73,340.00',
      indentLevel: 4,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Staff Salary Payable',
      total: '0.00',
      indentLevel: 4,
      isLink: true,
      showCollapseIcon: true,
    ),
    _BalanceSheetRowData(
      account: 'Althaf -Salary',
      total: '2,07,131.62',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Bijisha -Salary',
      total: '29,404.92',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Deepthi -Salary',
      total: '2,19,788.00',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Nandana -Salary',
      total: '87,049.54',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'RAHUL MURALEEDARAN - SALARY',
      total: '74,538.00',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Staff Salary Payable',
      total: '6,17,912.08',
      indentLevel: 4,
      isTotal: true,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Output Payable',
      total: '0.00',
      indentLevel: 4,
      isLink: true,
      showCollapseIcon: true,
    ),
    _BalanceSheetRowData(
      account: 'Output CGST',
      total: '54,053.53',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Output SGST',
      total: '54,053.53',
      indentLevel: 5,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Output Payable',
      total: '1,08,107.06',
      indentLevel: 4,
      isTotal: true,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Other Current Liabilities',
      total: '29,32,179.14',
      indentLevel: 3,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Current Liabilities',
      total: '30,07,010.19',
      indentLevel: 2,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Non Current Liabilities',
      total: '',
      indentLevel: 2,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Non Current Liabilities',
      total: '0.00',
      indentLevel: 2,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Other Liabilities',
      total: '',
      indentLevel: 2,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Other Liabilities',
      total: '0.00',
      indentLevel: 2,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Liabilities',
      total: '30,07,010.19',
      indentLevel: 1,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Equities',
      total: '',
      indentLevel: 1,
      isSection: true,
    ),
    _BalanceSheetRowData(
      account: 'Current Year Earnings',
      total: '2,23,122.34',
      indentLevel: 2,
      isLink: true,
    ),
    _BalanceSheetRowData(
      account: 'Retained Earnings',
      total: '12,042.38',
      indentLevel: 2,
    ),
    _BalanceSheetRowData(
      account: 'Total for Equities',
      total: '2,35,164.72',
      indentLevel: 1,
      isTotal: true,
    ),
    _BalanceSheetRowData(
      account: 'Total for Liabilities & Equities',
      total: '32,42,174.91',
      isTotal: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int extraCols = comparisonPeriods.isEmpty ? 0 : comparisonPeriods.length - 1;
        final double minWidth = 825.0 + (extraCols * 170.0);
        final tableWidth = constraints.maxWidth < minWidth ? constraints.maxWidth : minWidth;
        
        final tableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 480.0;
        final table = SizedBox(
          width: tableWidth,
          height: tableHeight,
          child: ReportStickyHeaderScrollTable(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Basis : $reportBasis',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                _BalanceSheetTableHeader(comparisonPeriods: comparisonPeriods),
              ],
            ),
            emptyBody: const SizedBox.shrink(),
            children: [
              for (final row in _rows) 
                _BalanceSheetTableRow(
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
  }
}

class _BalanceSheetTableHeader extends StatelessWidget {
  final List<String> comparisonPeriods;
  const _BalanceSheetTableHeader({required this.comparisonPeriods});

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
                          child: Text('ACCOUNT', style: ReportTableTypography.header),
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
                    child: Text('ACCOUNT', style: ReportTableTypography.header),
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

class _BalanceSheetTableRow extends StatelessWidget {
  final _BalanceSheetRowData row;
  final List<String> comparisonPeriods;

  const _BalanceSheetTableRow({
    required this.row,
    required this.comparisonPeriods,
  });

  @override
  Widget build(BuildContext context) {
    final isLinkedTotal = row.isTotal && row.isLink;
    final labelStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection || row.isTotal
          ? FontWeight.w700
          : FontWeight.w400,
      decoration: isLinkedTotal
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
    );
    final amountStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection ? FontWeight.w700 : FontWeight.w400,
      decoration: isLinkedTotal
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
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
