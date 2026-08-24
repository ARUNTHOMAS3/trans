import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/business_overview/data/providers/horizontal_profit_and_loss_provider.dart';

class HorizontalProfitAndLossScreen extends ConsumerStatefulWidget {
  const HorizontalProfitAndLossScreen({super.key});

  @override
  ConsumerState<HorizontalProfitAndLossScreen> createState() =>
      _HorizontalProfitAndLossScreenState();
}

class _HorizontalProfitAndLossScreenState
    extends ConsumerState<HorizontalProfitAndLossScreen> {
  static final DateTime _defaultDate = DateTime.now();
  DateTime _startDate = _defaultDate;
  DateTime _endDate = _defaultDate;
  DateTime _appliedStartDate = _defaultDate;
  DateTime _appliedEndDate = _defaultDate;

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;

  String get _dateLabel {
    final f = ReportFormatterCache.date('dd-MM-yyyy');
    return 'From ${f.format(_appliedStartDate)} To ${f.format(_appliedEndDate)}';
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
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

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _hasPendingFilterChanges = false;
    });
  }


  List<_HorizontalLineItem> _buildRows(List<dynamic> items, dynamic f, bool isExpense, num netPL) {
    List<_HorizontalLineItem> rows = [];
    
    // Group by accountType
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      final type = item['accountType'] ?? 'Uncategorized';
      grouped.putIfAbsent(type, () => []).add(item);
    }
    
    for (var entry in grouped.entries) {
      final type = entry.key;
      final groupItems = entry.value;
      
      rows.add(_HorizontalLineItem(
        label: type.toUpperCase(),
        amount: '',
        isSection: true,
      ));
      
      num sectionTotal = 0;
      for (var item in groupItems) {
        final amount = item['amount'] ?? 0;
        sectionTotal += amount;
        rows.add(_HorizontalLineItem(
          label: item['accountName'] ?? 'Unknown',
          amount: f.format(amount),
          isIndented: true,
          isLink: true,
        ));
      }
      
      rows.add(_HorizontalLineItem(
        label: 'TOTAL ${type.toUpperCase()}',
        amount: f.format(sectionTotal),
        isTotal: true,
      ));
    }
    
    // Add Net Profit/Loss if applicable
    if (isExpense && netPL > 0) {
      rows.add(_HorizontalLineItem(
        label: 'NET PROFIT',
        amount: f.format(netPL),
        hasBox: true,
      ));
    } else if (!isExpense && netPL < 0) {
      rows.add(_HorizontalLineItem(
        label: 'NET LOSS',
        amount: f.format(netPL.abs()),
        hasBox: true,
      ));
    }
    
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final request = HorizontalProfitAndLossRequest(
      startDate: _appliedStartDate,
      endDate: _appliedEndDate,
      basis: 'Accrual',
    );
    final reportState = ref.watch(horizontalProfitAndLossProvider(request));
    final isLoading = reportState.isLoading;
    final hasError = reportState.hasError;
    
    List<_HorizontalLineItem> expenseRows = [];
    List<_HorizontalLineItem> incomeRows = [];
    String expenseTotal = '0.00';
    String incomeTotal = '0.00';
    
    if (reportState.hasValue && reportState.value != null) {
      final data = reportState.value!;
      final f = ReportFormatterCache.number('#,##,##0.00');
      
      final rawExpenseSide = data['expenseSide'] as List<dynamic>? ?? [];
      final rawIncomeSide = data['incomeSide'] as List<dynamic>? ?? [];
      final num totalE = data['totalExpense'] ?? 0;
      final num totalI = data['totalIncome'] ?? 0;
      final num netPL = data['netProfitLoss'] ?? 0;
      
      expenseRows = _buildRows(rawExpenseSide, f, true, netPL);
      incomeRows = _buildRows(rawIncomeSide, f, false, netPL);
      
      num balancingTotalE = totalE;
      num balancingTotalI = totalI;
      if (netPL > 0) {
        balancingTotalE += netPL;
      } else if (netPL < 0) {
        balancingTotalI += netPL.abs();
      }
      
      expenseTotal = f.format(balancingTotalE);
      incomeTotal = f.format(balancingTotalI);
    }

    return ReportViewScaffold(

      categoryLabel: 'Business Overview',
      reportTitle: 'Horizontal Profit and Loss',
      dateLabel: _dateLabel,
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
      settingsTooltip: 'Customize the Horizontal Profit and Loss report.',
      isLoading: isLoading,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Horizontal Profit and Loss',
      onReportSelected: (reportName, category) {
        if (reportName == 'Horizontal Profit and Loss') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: hasError ? const Center(child: Text('Failed to load data.')) : _HorizontalProfitAndLossStatement(expenseRows: expenseRows, incomeRows: incomeRows, expenseTotal: expenseTotal, incomeTotal: incomeTotal),
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
  final List<_HorizontalLineItem> expenseRows;
  final List<_HorizontalLineItem> incomeRows;
  final String expenseTotal;
  final String incomeTotal;

  const _HorizontalProfitAndLossStatement({
    required this.expenseRows,
    required this.incomeRows,
    required this.expenseTotal,
    required this.incomeTotal,
  });

  

  

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
              children: [
                const Text(
                  'Basis : Accrual',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                _HorizontalStatementGrid(expenseRows: expenseRows, incomeRows: incomeRows, expenseTotal: expenseTotal, incomeTotal: incomeTotal),
                const SizedBox(height: AppTheme.space48),
                const _BaseCurrencyNote(),
                const SizedBox(height: AppTheme.space10),
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
  final List<_HorizontalLineItem> expenseRows;
  final List<_HorizontalLineItem> incomeRows;
  final String expenseTotal;
  final String incomeTotal;

  const _HorizontalStatementGrid({
    required this.expenseRows,
    required this.incomeRows,
    required this.expenseTotal,
    required this.incomeTotal,
  });

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
              children: [
                Expanded(
                  child: _StatementSide(
                    title: 'Expense',
                    rows: expenseRows,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.borderLight,
                ),
                Expanded(
                  child: _StatementSide(
                    title: 'Income',
                    rows: incomeRows,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          _StatementTotalsRow(expenseTotal: expenseTotal, incomeTotal: incomeTotal),
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
  final String expenseTotal;
  final String incomeTotal;

  const _StatementTotalsRow({
    required this.expenseTotal,
    required this.incomeTotal,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _TotalCell(label: 'Total', amount: expenseTotal),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderLight),
          Expanded(
            child: _TotalCell(label: 'Total', amount: incomeTotal),
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
