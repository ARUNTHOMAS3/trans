import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class SalesBySalespersonTransactionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const SalesBySalespersonTransactionsTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\u20B9',
      decimalDigits: 2,
    );
    final totalSales = items.fold<double>(
      0,
      (sum, item) => sum + ((item['sales'] as num?)?.toDouble() ?? 0),
    );
    final totalSalesWithTax = items.fold<double>(
      0,
      (sum, item) => sum + ((item['salesWithTax'] as num?)?.toDouble() ?? 0),
    );
    final totalBalanceDue = items.fold<double>(
      0,
      (sum, item) => sum + ((item['balanceDue'] as num?)?.toDouble() ?? 0),
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
          date: Row(
            children: [
              Text('DATE', style: ReportTableTypography.header),
              const SizedBox(width: AppTheme.space4),
              const Icon(
                Icons.unfold_more,
                size: AppTheme.space14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          type: Text('TYPE', style: ReportTableTypography.header),
          status: Text('STATUS', style: ReportTableTypography.header),
          dueDate: Text('DUE DATE', style: ReportTableTypography.header),
          number: Text('NUMBER', style: ReportTableTypography.header),
          customerName: Text(
            'CUSTOMER NAME',
            style: ReportTableTypography.header,
          ),
          sales: Text(
            'SALES',
            textAlign: TextAlign.right,
            style: ReportTableTypography.header,
          ),
          salesWithTax: Text(
            'SALES WITH TAX',
            textAlign: TextAlign.right,
            style: ReportTableTypography.header,
          ),
          balanceDue: Text(
            'BALANCE DUE',
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
          ...items.map(
            (item) => _SalesBySalespersonTransactionRow(
              item: item,
              currencyFormat: currencyFormat,
              rowBuilder: _buildTableRow,
            ),
          ),
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
              date: Text(
                'Total',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              type: const SizedBox.shrink(),
              status: const SizedBox.shrink(),
              dueDate: const SizedBox.shrink(),
              number: const SizedBox.shrink(),
              customerName: const SizedBox.shrink(),
              sales: Text(
                currencyFormat.format(totalSales),
                textAlign: TextAlign.right,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              salesWithTax: Text(
                currencyFormat.format(totalSalesWithTax),
                textAlign: TextAlign.right,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              balanceDue: Text(
                currencyFormat.format(totalBalanceDue),
                textAlign: TextAlign.right,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppTheme.space64 * 3),
      ],
    );
  }

  Widget _buildTableRow({
    required Widget date,
    required Widget type,
    required Widget status,
    required Widget dueDate,
    required Widget number,
    required Widget customerName,
    required Widget sales,
    required Widget salesWithTax,
    required Widget balanceDue,
  }) {
    return Row(
      children: [
        Expanded(flex: 10, child: date),
        Expanded(flex: 11, child: type),
        Expanded(flex: 11, child: status),
        Expanded(flex: 11, child: dueDate),
        Expanded(flex: 11, child: number),
        Expanded(flex: 18, child: customerName),
        Expanded(flex: 10, child: sales),
        Expanded(flex: 12, child: salesWithTax),
        Expanded(flex: 12, child: balanceDue),
      ],
    );
  }
}

class _SalesBySalespersonTransactionRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final NumberFormat currencyFormat;
  final Widget Function({
    required Widget date,
    required Widget type,
    required Widget status,
    required Widget dueDate,
    required Widget number,
    required Widget customerName,
    required Widget sales,
    required Widget salesWithTax,
    required Widget balanceDue,
  })
  rowBuilder;

  const _SalesBySalespersonTransactionRow({
    required this.item,
    required this.currencyFormat,
    required this.rowBuilder,
  });

  @override
  State<_SalesBySalespersonTransactionRow> createState() =>
      _SalesBySalespersonTransactionRowState();
}

class _SalesBySalespersonTransactionRowState
    extends State<_SalesBySalespersonTransactionRow> {
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
          date: Text(
            widget.item['date']?.toString() ?? '-',
            style: AppTheme.tableCell,
          ),
          type: _OverviewLinkText(
            text: widget.item['type']?.toString() ?? '-',
            isUnderlined: _isHovered,
            textAlign: TextAlign.left,
          ),
          status: _OverviewLinkText(
            text: widget.item['status']?.toString() ?? '-',
            isUnderlined: false,
            textAlign: TextAlign.left,
          ),
          dueDate: Text(
            widget.item['dueDate']?.toString() ?? '-',
            style: AppTheme.tableCell,
          ),
          number: _OverviewLinkText(
            text: widget.item['number']?.toString() ?? '-',
            isUnderlined: _isHovered,
            textAlign: TextAlign.left,
          ),
          customerName: _OverviewLinkText(
            text: widget.item['customerName']?.toString() ?? '-',
            isUnderlined: _isHovered,
            textAlign: TextAlign.left,
          ),
          sales: Text(
            widget.currencyFormat.format(
              (widget.item['sales'] as num?)?.toDouble() ?? 0,
            ),
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
          salesWithTax: Text(
            widget.currencyFormat.format(
              (widget.item['salesWithTax'] as num?)?.toDouble() ?? 0,
            ),
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
          balanceDue: Text(
            widget.currencyFormat.format(
              (widget.item['balanceDue'] as num?)?.toDouble() ?? 0,
            ),
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
        ),
      ),
    );
  }
}

class _OverviewLinkText extends StatelessWidget {
  final String text;
  final bool isUnderlined;
  final TextAlign textAlign;

  const _OverviewLinkText({
    required this.text,
    required this.isUnderlined,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: AppTheme.linkText.copyWith(
        fontWeight: FontWeight.w500,
        decoration: isUnderlined
            ? TextDecoration.underline
            : TextDecoration.none,
      ),
    );
  }
}
