import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class SalesByCustomerTransactionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const SalesByCustomerTransactionsTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
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
          date: Text('DATE', style: ReportTableTypography.header),
          type: Text('TYPE', style: ReportTableTypography.header),
          status: Text('STATUS', style: ReportTableTypography.header),
          number: Text('NUMBER', style: ReportTableTypography.header),
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
            (item) => _SalesTransactionRow(
              item: item,
              currencyFormat: currencyFormat,
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
              number: const SizedBox.shrink(),
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
    required Widget number,
    required Widget sales,
    required Widget salesWithTax,
    required Widget balanceDue,
  }) {
    return Row(
      children: [
        Expanded(flex: 2, child: date),
        Expanded(flex: 2, child: type),
        Expanded(flex: 2, child: status),
        Expanded(flex: 3, child: number),
        Expanded(flex: 2, child: sales),
        Expanded(flex: 2, child: salesWithTax),
        Expanded(flex: 2, child: balanceDue),
      ],
    );
  }
}

class _SalesTransactionRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final NumberFormat currencyFormat;

  const _SalesTransactionRow({
    required this.item,
    required this.currencyFormat,
  });

  @override
  State<_SalesTransactionRow> createState() => _SalesTransactionRowState();
}

class _SalesTransactionRowState extends State<_SalesTransactionRow> {
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
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                widget.item['date']?.toString() ?? '-',
                style: AppTheme.tableCell,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SalesTransactionLinkText(
                  text: widget.item['type']?.toString() ?? '-',
                  onTap: () {},
                  textAlign: TextAlign.left,
                  isUnderlined: _isHovered,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.item['status']?.toString() ?? '-',
                style: AppTheme.linkText.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.item['number']?.toString() ?? '-',
                style: AppTheme.tableCell,
              ),
            ),
            Expanded(
              flex: 2,
              child: _SalesTransactionLinkText(
                text: widget.currencyFormat.format(
                  (widget.item['sales'] as num?)?.toDouble() ?? 0,
                ),
                onTap: () {},
                textAlign: TextAlign.right,
                isUnderlined: _isHovered,
              ),
            ),
            Expanded(
              flex: 2,
              child: _SalesTransactionLinkText(
                text: widget.currencyFormat.format(
                  (widget.item['salesWithTax'] as num?)?.toDouble() ?? 0,
                ),
                onTap: () {},
                textAlign: TextAlign.right,
                isUnderlined: _isHovered,
              ),
            ),
            Expanded(
              flex: 2,
              child: _SalesTransactionLinkText(
                text: widget.currencyFormat.format(
                  (widget.item['balanceDue'] as num?)?.toDouble() ?? 0,
                ),
                onTap: () {},
                textAlign: TextAlign.right,
                isUnderlined: _isHovered,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesTransactionLinkText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final bool isUnderlined;

  const _SalesTransactionLinkText({
    required this.text,
    required this.onTap,
    required this.textAlign,
    required this.isUnderlined,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      textAlign: textAlign,
      style: AppTheme.linkText.copyWith(
        fontWeight: FontWeight.w500,
        decoration: isUnderlined
            ? TextDecoration.underline
            : TextDecoration.none,
      ),
    );

    if (onTap == null) {
      return textWidget;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppTheme.transparent,
        splashColor: AppTheme.transparent,
        highlightColor: AppTheme.transparent,
        child: textWidget,
      ),
    );
  }
}
