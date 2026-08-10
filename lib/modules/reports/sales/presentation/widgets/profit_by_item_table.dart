import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_tooltip.dart';

class ProfitByItemTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat currencyFormat;

  const ProfitByItemTable({
    super.key,
    required this.items,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuantity = items.fold<double>(
      0,
      (sum, item) => sum + ((item['quantitySold'] as num?)?.toDouble() ?? 0),
    );
    final totalSales = items.fold<double>(
      0,
      (sum, item) => sum + ((item['totalSales'] as num?)?.toDouble() ?? 0),
    );
    final totalSalesWithTax = items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['totalSalesWithTax'] as num?)?.toDouble() ?? 0),
    );
    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + ((item['totalCost'] as num?)?.toDouble() ?? 0),
    );
    final totalProfit = items.fold<double>(
      0,
      (sum, item) => sum + ((item['profit'] as num?)?.toDouble() ?? 0),
    );

    return ReportStickyHeaderScrollTable(
      header: _buildHeader(),
      emptyBody: const ReportTableEmptyBody(),
      isEmpty: items.isEmpty,
      children: [
        ...items.map((item) {
          final itemName = item['itemName']?.toString() ?? '-';
          final margin = item['margin']?.toString() ?? '-';
          final quantitySold = (item['quantitySold'] as num?)?.toDouble() ?? 0;
          final totalSales = (item['totalSales'] as num?)?.toDouble() ?? 0;
          final totalSalesWithTax =
              (item['totalSalesWithTax'] as num?)?.toDouble() ?? 0;
          final totalCost = (item['totalCost'] as num?)?.toDouble() ?? 0;
          final profit = (item['profit'] as num?)?.toDouble() ?? 0;

          return _ProfitByItemDataRow(
            itemName: itemName,
            margin: margin,
            quantitySoldText: quantitySold.toStringAsFixed(2),
            totalSalesText: currencyFormat.format(totalSales),
            totalSalesWithTaxText: currencyFormat.format(totalSalesWithTax),
            totalCostText: currencyFormat.format(totalCost),
            profitText: currencyFormat.format(profit),
            rowBuilder: _buildTableRow,
          );
        }),
        if (items.isNotEmpty)
          _buildTotalRow(
            totalQuantity: totalQuantity,
            totalSales: totalSales,
            totalSalesWithTax: totalSalesWithTax,
            totalCost: totalCost,
            totalProfit: totalProfit,
          ),
        const SizedBox(height: AppTheme.space64),
        const SizedBox(height: AppTheme.space24),
      ],
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
      child: _buildTableRow(
        itemName: Row(
          children: [
            Text('ITEM NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        margin: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('MARGIN', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            _headerHelpTooltip(
              '((Total Sales - Total Cost) / Total Sales) * 100',
            ),
          ],
        ),
        quantitySold: Text(
          'QTY SOLD',
          textAlign: TextAlign.center,
          style: ReportTableTypography.header,
        ),
        totalSales: Text(
          'TOTAL SALES',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        totalSalesWithTax: Text(
          'TOTAL SALES WITH TAX',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        totalCost: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('TOTAL COST', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            _headerHelpTooltip(
              'This is calculated based on the valuation method selected at the time of item creation.',
            ),
          ],
        ),
        profit: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('PROFIT', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            _headerHelpTooltip(
              'This is the difference between Total Sales and Total Cost.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow({
    required double totalQuantity,
    required double totalSales,
    required double totalSalesWithTax,
    required double totalCost,
    required double totalProfit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: _buildTableRow(
        itemName: Text(
          'Total',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        margin: const SizedBox.shrink(),
        quantitySold: Text(
          totalQuantity.toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        totalSales: Text(
          currencyFormat.format(totalSales),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        totalSalesWithTax: Text(
          currencyFormat.format(totalSalesWithTax),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        totalCost: Text(
          currencyFormat.format(totalCost),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        profit: Text(
          currencyFormat.format(totalProfit),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required Widget itemName,
    required Widget margin,
    required Widget quantitySold,
    required Widget totalSales,
    required Widget totalSalesWithTax,
    required Widget totalCost,
    required Widget profit,
  }) {
    return Row(
      children: [
        Expanded(flex: 25, child: itemName),
        Expanded(flex: 13, child: margin),
        Expanded(flex: 12, child: quantitySold),
        Expanded(flex: 15, child: totalSales),
        Expanded(flex: 20, child: totalSalesWithTax),
        Expanded(flex: 15, child: totalCost),
        Expanded(flex: 12, child: profit),
      ],
    );
  }
}

Widget _headerHelpTooltip(String message) {
  return ReportTooltip(
    message: message,
    child: const SizedBox(
      width: AppTheme.space20,
      height: AppTheme.space20,
      child: Icon(
        Icons.info_outline,
        size: AppTheme.space14,
        color: AppTheme.textSecondary,
      ),
    ),
  );
}

class _ProfitByItemDataRow extends StatefulWidget {
  final String itemName;
  final String margin;
  final String quantitySoldText;
  final String totalSalesText;
  final String totalSalesWithTaxText;
  final String totalCostText;
  final String profitText;
  final Widget Function({
    required Widget itemName,
    required Widget margin,
    required Widget quantitySold,
    required Widget totalSales,
    required Widget totalSalesWithTax,
    required Widget totalCost,
    required Widget profit,
  })
  rowBuilder;

  const _ProfitByItemDataRow({
    required this.itemName,
    required this.margin,
    required this.quantitySoldText,
    required this.totalSalesText,
    required this.totalSalesWithTaxText,
    required this.totalCostText,
    required this.profitText,
    required this.rowBuilder,
  });

  @override
  State<_ProfitByItemDataRow> createState() => _ProfitByItemDataRowState();
}

class _ProfitByItemDataRowState extends State<_ProfitByItemDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space16,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: widget.rowBuilder(
          itemName: Text(
            widget.itemName,
            style: AppTheme.linkText.copyWith(
              fontWeight: FontWeight.w500,
              decoration: _isHovered
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
          margin: Text(
            widget.margin,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
          quantitySold: Text(
            widget.quantitySoldText,
            textAlign: TextAlign.center,
            style: AppTheme.tableCell,
          ),
          totalSales: Text(
            widget.totalSalesText,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
          totalSalesWithTax: Text(
            widget.totalSalesWithTaxText,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
          totalCost: Text(
            widget.totalCostText,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
          profit: Text(
            widget.profitText,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
        ),
      ),
    );
  }
}
