import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class SalesByItemTransactionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat currencyFormat;
  final NumberFormat quantityFormat;

  const SalesByItemTransactionsTable({
    super.key,
    required this.items,
    required this.currencyFormat,
    required this.quantityFormat,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuantity = items.fold<double>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toDouble() ?? 0),
    );
    final totalAmount = items.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
    );

    return ReportStickyHeaderScrollTable(
      header: Container(
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
          customerName: Row(
            children: [
              Text('CUSTOMER NAME', style: ReportTableTypography.header),
              const SizedBox(width: AppTheme.space4),
              const Icon(
                Icons.unfold_more,
                size: AppTheme.space14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          quantity: Text(
            'QUANTITY',
            textAlign: TextAlign.center,
            style: ReportTableTypography.header,
          ),
          amount: Text(
            'AMOUNT',
            textAlign: TextAlign.right,
            style: ReportTableTypography.header,
          ),
          averagePrice: Text(
            'AVERAGE PRICE',
            textAlign: TextAlign.right,
            style: ReportTableTypography.header,
          ),
        ),
      ),
      emptyBody: const SizedBox.shrink(),
      children: [
        if (items.isEmpty)
          const ReportTableEmptyBody()
        else
          ...items.map((item) {
            final customerName = item['customerName']?.toString() ?? '-';
            final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
            final amount = (item['amount'] as num?)?.toDouble() ?? 0;
            final averagePrice =
                (item['averagePrice'] as num?)?.toDouble() ?? 0;

            return _SalesByItemTransactionRow(
              customerName: customerName,
              quantityText: quantityFormat.format(quantity),
              amountText: currencyFormat.format(amount),
              averagePriceText: currencyFormat.format(averagePrice),
              rowBuilder: _buildTableRow,
            );
          }),
        if (items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space20,
              vertical: AppTheme.space16,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: _buildTableRow(
              customerName: Text(
                'Total',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              quantity: Text(
                quantityFormat.format(totalQuantity),
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              amount: Text(
                currencyFormat.format(totalAmount),
                textAlign: TextAlign.right,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              averagePrice: const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: AppTheme.space64 * 3),
      ],
    );
  }

  Widget _buildTableRow({
    required Widget customerName,
    required Widget quantity,
    required Widget amount,
    required Widget averagePrice,
  }) {
    return Row(
      children: [
        Expanded(flex: 4, child: customerName),
        Expanded(flex: 2, child: quantity),
        Expanded(flex: 2, child: amount),
        const SizedBox(width: AppTheme.space28),
        Expanded(flex: 2, child: averagePrice),
      ],
    );
  }
}

class _SalesByItemTransactionRow extends StatefulWidget {
  final String customerName;
  final String quantityText;
  final String amountText;
  final String averagePriceText;
  final Widget Function({
    required Widget customerName,
    required Widget quantity,
    required Widget amount,
    required Widget averagePrice,
  })
  rowBuilder;

  const _SalesByItemTransactionRow({
    required this.customerName,
    required this.quantityText,
    required this.amountText,
    required this.averagePriceText,
    required this.rowBuilder,
  });

  @override
  State<_SalesByItemTransactionRow> createState() =>
      _SalesByItemTransactionRowState();
}

class _SalesByItemTransactionRowState
    extends State<_SalesByItemTransactionRow> {
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
          customerName: Text(
            widget.customerName,
            style: AppTheme.linkText.copyWith(
              fontWeight: FontWeight.w500,
              decoration: _isHovered
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
          quantity: Text(
            widget.quantityText,
            textAlign: TextAlign.center,
            style: AppTheme.tableCell,
          ),
          amount: Text(
            widget.amountText,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
          averagePrice: Text(
            widget.averagePriceText,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
        ),
      ),
    );
  }
}
