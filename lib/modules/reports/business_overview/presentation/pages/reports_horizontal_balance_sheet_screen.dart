import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class HorizontalBalanceSheetScreen extends StatefulWidget {
  const HorizontalBalanceSheetScreen({super.key});

  @override
  State<HorizontalBalanceSheetScreen> createState() =>
      _HorizontalBalanceSheetScreenState();
}

class _HorizontalBalanceSheetScreenState
    extends State<HorizontalBalanceSheetScreen> {
  static const String _dateLabel = 'As of 14-07-2026';

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _reportBasis = 'Accrual';

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

  void _cycleReportBasis() {
    setState(() {
      _reportBasis = _reportBasis == 'Accrual' ? 'Cash' : 'Accrual';
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Horizontal Balance Sheet',
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
      settingsTooltip: 'Customize the Horizontal Balance Sheet report.',
      tableHeaderActions: ReportIconActionButton(
        icon: Icons.settings_outlined,
        onPressed: () {},
        tooltip: 'Customize report settings',
        chromeless: true,
      ),
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Horizontal Balance Sheet',
      onReportSelected: (reportName, category) {
        if (reportName == 'Horizontal Balance Sheet') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: _HorizontalBalanceSheetStatement(
        reportBasis: _reportBasis,
      ),
    );
  }
}

class _HorizontalBalanceSheetItem {
  final String label;
  final String amount;
  final int indentLevel;
  final bool isSection;
  final bool isTotal;
  final bool isLink;
  final bool isItalic;
  final bool showCollapseIcon;
  final bool highlighted;

  const _HorizontalBalanceSheetItem({
    required this.label,
    required this.amount,
    this.indentLevel = 0,
    this.isSection = false,
    this.isTotal = false,
    this.isLink = false,
    this.isItalic = false,
    this.showCollapseIcon = false,
    this.highlighted = false,
  });
}

class _HorizontalBalanceSheetStatement extends StatelessWidget {
  final String reportBasis;

  const _HorizontalBalanceSheetStatement({required this.reportBasis});

  static const List<_HorizontalBalanceSheetItem> _liabilitiesRows = [
    _HorizontalBalanceSheetItem(
      label: 'LIABILITIES',
      amount: '',
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Current Liabilities',
      amount: '',
      indentLevel: 1,
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Accounts Payable',
      amount: '74,831.05',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'GST PAYABLE',
      amount: '-4,680.00',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Opening Balance Adjustments',
      amount: '37,500.00',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Output Payable',
      amount: '0.00',
      indentLevel: 1,
      isLink: true,
      showCollapseIcon: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Output CGST',
      amount: '54,053.53',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Output SGST',
      amount: '54,053.53',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total for Output Payable',
      amount: '1,08,107.06',
      indentLevel: 1,
      isTotal: true,
      isLink: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Staff Salary Payable',
      amount: '0.00',
      indentLevel: 1,
      isLink: true,
      showCollapseIcon: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Althaf -Salary',
      amount: '2,07,131.62',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Bijisha -Salary',
      amount: '29,404.92',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Deepthi -Salary',
      amount: '2,19,788.00',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Nandana -Salary',
      amount: '87,049.54',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'RAHUL MURALEEDARAN - SALARY',
      amount: '74,538.00',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total for Staff Salary Payable',
      amount: '6,17,912.08',
      indentLevel: 1,
      isTotal: true,
      isLink: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Unearned Revenue',
      amount: '21,73,340.00',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total',
      amount: '30,07,010.19',
      isTotal: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'TOTAL LIABILITIES',
      amount: '30,07,010.19',
      isTotal: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'EQUITIES',
      amount: '',
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Current Year Earnings',
      amount: '2,23,122.34',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Retained Earnings',
      amount: '12,042.38',
      indentLevel: 1,
    ),
    _HorizontalBalanceSheetItem(
      label: 'TOTAL EQUITIES',
      amount: '2,35,164.72',
      isTotal: true,
    ),
  ];

  static const List<_HorizontalBalanceSheetItem> _assetRows = [
    _HorizontalBalanceSheetItem(
      label: 'CURRENT ASSETS',
      amount: '',
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Cash',
      amount: '',
      indentLevel: 1,
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Petty Cash',
      amount: '210.55',
      indentLevel: 1,
      isLink: true,
      showCollapseIcon: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'TESTINGS CASH',
      amount: '-169.00',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total for Petty Cash',
      amount: '41.55',
      indentLevel: 1,
      isTotal: true,
      isLink: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Undeposited Funds',
      amount: '210.00',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total',
      amount: '251.55',
      isTotal: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Bank',
      amount: '',
      indentLevel: 1,
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Bandhan Bank',
      amount: '8,79,240.48',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total',
      amount: '8,79,240.48',
      isTotal: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Accounts Receivable',
      amount: '',
      indentLevel: 1,
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Accounts Receivable',
      amount: '7,10,737.00',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total',
      amount: '7,10,737.00',
      isTotal: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Other Current Assets',
      amount: '',
      indentLevel: 1,
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Finished Goods',
      amount: '15,004.50',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Goods In Transit',
      amount: '2,710.90',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Input Tax Credits',
      amount: '0.00',
      indentLevel: 1,
      isLink: true,
      showCollapseIcon: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Input CGST',
      amount: '52.59',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Input IGST',
      amount: '1,029.33',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Input SGST',
      amount: '52.59',
      indentLevel: 2,
      isLink: true,
      isItalic: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total for Input Tax Credits',
      amount: '1,134.51',
      indentLevel: 1,
      isTotal: true,
      isLink: true,
      highlighted: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Inventory Asset',
      amount: '3,14,988.70',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Prepaid Expenses',
      amount: '13,17,984.10',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'TCS Receivable',
      amount: '23.17',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'Total',
      amount: '16,51,845.88',
      isTotal: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'TOTAL CURRENT ASSETS',
      amount: '32,42,074.91',
      isTotal: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'OTHER ASSETS',
      amount: '',
      isSection: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'd',
      amount: '100.00',
      indentLevel: 1,
      isLink: true,
    ),
    _HorizontalBalanceSheetItem(
      label: 'TOTAL OTHER ASSETS',
      amount: '100.00',
      isTotal: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const statementWidth = 1100.0;
        final statementHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 480.0;
        final statement = SizedBox(
          width: statementWidth,
          height: statementHeight,
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
                Text(
                  'As of 14-07-2026',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.space28),
              ],
            ),
            emptyBody: const SizedBox.shrink(),
            children: const [
              _HorizontalBalanceSheetGrid(),
              SizedBox(height: AppTheme.space48),
              _BaseCurrencyNote(),
              SizedBox(height: AppTheme.space10),
            ],
          ),
        );

        if (constraints.maxWidth < statementWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: statement,
          );
        }

        return Center(child: statement);
      },
    );
  }
}

class _HorizontalBalanceSheetGrid extends StatelessWidget {
  const _HorizontalBalanceSheetGrid();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.space4),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Expanded(
              child: _StatementSide(
                title: 'Liabilities & Equities',
                rows: _HorizontalBalanceSheetStatement._liabilitiesRows,
                totalLabel: 'TOTAL LIABILITIES & EQUITIES',
                totalAmount: '32,42,174.91',
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppTheme.borderLight,
            ),
            Expanded(
              child: _StatementSide(
                title: 'Assets',
                rows: _HorizontalBalanceSheetStatement._assetRows,
                totalLabel: 'TOTAL ASSETS',
                totalAmount: '32,42,174.91',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementSide extends StatelessWidget {
  final String title;
  final List<_HorizontalBalanceSheetItem> rows;
  final String totalLabel;
  final String totalAmount;

  const _StatementSide({
    required this.title,
    required this.rows,
    required this.totalLabel,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space14,
            AppTheme.space20,
            AppTheme.space12,
          ),
          child: Text(
            title,
            style: AppTheme.pageTitle.copyWith(
              fontStyle: FontStyle.italic,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space8,
            AppTheme.space20,
            AppTheme.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in rows) _StatementRow(row: row),
            ],
          ),
        ),
        const Spacer(),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        _StatementTotalRow(label: totalLabel, amount: totalAmount),
      ],
    );
  }
}

class _StatementRow extends StatelessWidget {
  final _HorizontalBalanceSheetItem row;

  const _StatementRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final textColor = row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary;
    final textStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: textColor,
      fontStyle: row.isItalic ? FontStyle.italic : FontStyle.normal,
      fontWeight: row.isSection || row.isTotal ? FontWeight.w700 : FontWeight.w400,
    );

    final content = Padding(
      padding: EdgeInsets.only(
        left: row.indentLevel * AppTheme.space14,
        top: row.isSection ? AppTheme.space16 : AppTheme.space8,
        bottom: AppTheme.space8,
      ),
      child: Row(
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
                ] else if (!row.isSection && !row.isTotal) ...[
                  Text('- ', style: textStyle.copyWith(color: AppTheme.textPrimary)),
                ],
                Flexible(
                  child: Text(row.label, style: textStyle),
                ),
              ],
            ),
          ),
          if (row.amount.isNotEmpty)
            Text(
              row.amount,
              textAlign: TextAlign.right,
              style: textStyle.copyWith(
                color: row.isTotal && !row.isLink
                    ? AppTheme.textPrimary
                    : textStyle.color,
              ),
            ),
        ],
      ),
    );

    final decorated = row.isTotal
        ? DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: content,
          )
        : content;

    if (!row.highlighted) return decorated;

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.bgLight),
      child: decorated,
    );
  }
}

class _StatementTotalRow extends StatelessWidget {
  final String label;
  final String amount;

  const _StatementTotalRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space14,
        AppTheme.space32,
        AppTheme.space14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.tableCell.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            amount,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell.copyWith(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
