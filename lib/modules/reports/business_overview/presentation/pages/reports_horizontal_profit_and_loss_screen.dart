import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class HorizontalProfitAndLossScreen extends StatefulWidget {
  const HorizontalProfitAndLossScreen({super.key});

  @override
  State<HorizontalProfitAndLossScreen> createState() =>
      _HorizontalProfitAndLossScreenState();
}

class _HorizontalProfitAndLossScreenState
    extends State<HorizontalProfitAndLossScreen> {
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

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

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Horizontal Profit and Loss',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
          value: 'This Month',
          onPressed: _markFiltersDirty,
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
      settingsTooltip: 'Customize the Horizontal Profit and Loss report.',
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Horizontal Profit and Loss',
      onReportSelected: (reportName, category) {
        if (reportName == 'Horizontal Profit and Loss') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: const _HorizontalProfitAndLossStatement(),
    );
  }
}

class _HorizontalLineItem {
  final String label;
  final String amount;
  final bool isSection;
  final bool isTotal;
  final bool isIndented;
  final bool isLink;
  final bool hasBox;

  const _HorizontalLineItem({
    required this.label,
    required this.amount,
    this.isSection = false,
    this.isTotal = false,
    this.isIndented = false,
    this.isLink = false,
    this.hasBox = false,
  });
}

class _HorizontalProfitAndLossStatement extends StatelessWidget {
  const _HorizontalProfitAndLossStatement();

  static const List<_HorizontalLineItem> _expenseRows = [
    _HorizontalLineItem(
      label: 'OPENING STOCK',
      amount: '3,29,094.30',
      isLink: true,
    ),
    _HorizontalLineItem(label: 'PURCHASES', amount: '0.00', isLink: true),
    _HorizontalLineItem(label: 'VENDOR CREDITS', amount: '0.00', isLink: true),
    _HorizontalLineItem(
      label: 'INVENTORY ADJUSTMENT',
      amount: '-0.20',
      isLink: true,
    ),
    _HorizontalLineItem(
      label: 'COST OF GOODS SOLD',
      amount: '',
      isSection: true,
    ),
    _HorizontalLineItem(
      label: 'Cost of Goods Sold',
      amount: '0.20',
      isIndented: true,
      isLink: true,
    ),
    _HorizontalLineItem(
      label: 'TOTAL COST OF GOODS SOLD',
      amount: '0.20',
      isTotal: true,
    ),
    _HorizontalLineItem(
      label: 'OPERATING EXPENSE',
      amount: '',
      isSection: true,
    ),
    _HorizontalLineItem(
      label: 'Fuel/Mileage Expenses',
      amount: '250.00',
      isIndented: true,
      isLink: true,
    ),
    _HorizontalLineItem(
      label: 'TOTAL OPERATING EXPENSE',
      amount: '250.00',
      isTotal: true,
    ),
    _HorizontalLineItem(
      label: 'NON OPERATING EXPENSE',
      amount: '',
      isSection: true,
    ),
    _HorizontalLineItem(
      label: 'TOTAL NON OPERATING EXPENSE',
      amount: '0.00',
      isTotal: true,
    ),
    _HorizontalLineItem(
      label: 'NET PROFIT/LOSS',
      amount: '1,287.40',
      hasBox: true,
    ),
  ];

  static const List<_HorizontalLineItem> _incomeRows = [
    _HorizontalLineItem(label: 'OPERATING INCOME', amount: '', isSection: true),
    _HorizontalLineItem(
      label: 'Other Charges',
      amount: '28.60',
      isIndented: true,
      isLink: true,
    ),
    _HorizontalLineItem(
      label: 'Sales',
      amount: '399.00',
      isIndented: true,
      isLink: true,
    ),
    _HorizontalLineItem(
      label: 'TOTAL OPERATING INCOME',
      amount: '427.60',
      isTotal: true,
    ),
    _HorizontalLineItem(
      label: 'CLOSING STOCK',
      amount: '3,30,204.10',
      isLink: true,
    ),
    _HorizontalLineItem(
      label: 'NON OPERATING INCOME',
      amount: '',
      isSection: true,
    ),
    _HorizontalLineItem(
      label: 'TOTAL NON OPERATING INCOME',
      amount: '0.00',
      isTotal: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const statementWidth = 1100.0;
        final statement = SizedBox(
          width: statementWidth,
          child: SingleChildScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Text(
                  'Basis : Accrual',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppTheme.space24),
                _HorizontalStatementGrid(),
                SizedBox(height: AppTheme.space48),
                _BaseCurrencyNote(),
                SizedBox(height: AppTheme.space10),
              ],
            ),
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

class _HorizontalStatementGrid extends StatelessWidget {
  const _HorizontalStatementGrid();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.space4),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                  child: _StatementSide(
                    title: 'Expense',
                    rows: _HorizontalProfitAndLossStatement._expenseRows,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.borderLight,
                ),
                Expanded(
                  child: _StatementSide(
                    title: 'Income',
                    rows: _HorizontalProfitAndLossStatement._incomeRows,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          const _StatementTotalsRow(),
        ],
      ),
    );
  }
}

class _StatementSide extends StatelessWidget {
  final String title;
  final List<_HorizontalLineItem> rows;

  const _StatementSide({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space14,
        AppTheme.space20,
        AppTheme.space20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTheme.pageTitle.copyWith(
              fontStyle: FontStyle.italic,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.space14),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          const SizedBox(height: AppTheme.space8),
          for (final row in rows) _StatementRow(row: row),
        ],
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  final _HorizontalLineItem row;

  const _StatementRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTheme.tableCell.copyWith(
      fontSize: 13,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection || row.isTotal
          ? FontWeight.w700
          : FontWeight.w400,
    );

    final content = Padding(
      padding: EdgeInsets.only(
        left: row.isIndented ? AppTheme.space12 : 0,
        right: AppTheme.space12,
        top: row.isSection ? AppTheme.space18 : AppTheme.space8,
        bottom: row.isTotal || row.hasBox ? AppTheme.space10 : AppTheme.space8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.isIndented ? '\u2022 ${row.label}' : row.label,
              style: textStyle.copyWith(
                color: row.isSection || row.isTotal || row.hasBox
                    ? AppTheme.textPrimary
                    : textStyle.color,
              ),
            ),
          ),
          if (row.amount.isNotEmpty)
            Text(
              row.amount,
              textAlign: TextAlign.right,
              style: textStyle.copyWith(
                color: row.isTotal || row.hasBox
                    ? AppTheme.textPrimary
                    : textStyle.color,
              ),
            ),
        ],
      ),
    );

    if (row.isTotal) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: content,
      );
    }

    if (row.hasBox) {
      return Padding(
        padding: const EdgeInsets.only(top: AppTheme.space18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _StatementTotalsRow extends StatelessWidget {
  const _StatementTotalsRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: const [
          Expanded(
            child: _TotalCell(label: 'Total', amount: '3,30,631.70'),
          ),
          VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderLight),
          Expanded(
            child: _TotalCell(label: 'Total', amount: '3,30,631.70'),
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  final String label;
  final String amount;

  const _TotalCell({required this.label, required this.amount});

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
