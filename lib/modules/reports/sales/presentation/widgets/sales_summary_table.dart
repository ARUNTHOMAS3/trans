import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class SalesSummaryTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat currencyFormat;
  final String groupBy;

  const SalesSummaryTable({
    super.key,
    required this.items,
    required this.currencyFormat,
    this.groupBy = 'None',
  });

  @override
  Widget build(BuildContext context) {
    final totalInvoiceCount = items.fold<int>(
      0,
      (sum, item) => sum + ((item['invoiceCount'] as num?)?.toInt() ?? 0),
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
    final totalTaxAmount = items.fold<double>(
      0,
      (sum, item) => sum + ((item['totalTaxAmount'] as num?)?.toDouble() ?? 0),
    );

    final List<Widget> tableRows = [];

    if (groupBy == 'Location' && items.isNotEmpty) {
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final item in items) {
        final loc = item['locationName']?.toString() ?? 'Unassigned';
        groups.putIfAbsent(loc, () => []).add(item);
      }

      for (final entry in groups.entries) {
        final locName = entry.key;
        final groupItems = entry.value;

        final groupInvoiceCount = groupItems.fold<int>(
          0,
          (sum, item) => sum + ((item['invoiceCount'] as num?)?.toInt() ?? 0),
        );
        final groupTotalSales = groupItems.fold<double>(
          0,
          (sum, item) => sum + ((item['totalSales'] as num?)?.toDouble() ?? 0),
        );
        final groupTotalSalesWithTax = groupItems.fold<double>(
          0,
          (sum, item) =>
              sum + ((item['totalSalesWithTax'] as num?)?.toDouble() ?? 0),
        );
        final groupTotalTaxAmount = groupItems.fold<double>(
          0,
          (sum, item) =>
              sum + ((item['totalTaxAmount'] as num?)?.toDouble() ?? 0),
        );

        tableRows.add(
          _buildGroupHeaderRow(
            locationName: locName,
            groupInvoiceCount: groupInvoiceCount,
            groupTotalSales: groupTotalSales,
            groupTotalSalesWithTax: groupTotalSalesWithTax,
            groupTotalTaxAmount: groupTotalTaxAmount,
          ),
        );

        for (final item in groupItems) {
          final date = item['date']?.toString() ?? '-';
          final invoiceCount = (item['invoiceCount'] as num?)?.toInt() ?? 0;
          final totalSales = (item['totalSales'] as num?)?.toDouble() ?? 0;
          final totalSalesWithTax =
              (item['totalSalesWithTax'] as num?)?.toDouble() ?? 0;
          final totalTaxAmount =
              (item['totalTaxAmount'] as num?)?.toDouble() ?? 0;

          tableRows.add(
            _SalesSummaryDataRow(
              date: date,
              invoiceCount: invoiceCount,
              totalSalesText: currencyFormat.format(totalSales),
              totalSalesWithTaxText: currencyFormat.format(totalSalesWithTax),
              totalTaxAmountText: currencyFormat.format(totalTaxAmount),
              rowBuilder: _buildTableRow,
              isIndented: true,
            ),
          );
        }
      }
    } else {
      for (final item in items) {
        final date = item['date']?.toString() ?? '-';
        final invoiceCount = (item['invoiceCount'] as num?)?.toInt() ?? 0;
        final totalSales = (item['totalSales'] as num?)?.toDouble() ?? 0;
        final totalSalesWithTax =
            (item['totalSalesWithTax'] as num?)?.toDouble() ?? 0;
        final totalTaxAmount =
            (item['totalTaxAmount'] as num?)?.toDouble() ?? 0;

        tableRows.add(
          _SalesSummaryDataRow(
            date: date,
            invoiceCount: invoiceCount,
            totalSalesText: currencyFormat.format(totalSales),
            totalSalesWithTaxText: currencyFormat.format(totalSalesWithTax),
            totalTaxAmountText: currencyFormat.format(totalTaxAmount),
            rowBuilder: _buildTableRow,
            isIndented: false,
          ),
        );
      }
    }

    return ReportStickyHeaderScrollTable(
      header: _buildHeader(),
      emptyBody: const ReportTableEmptyBody(),
      isEmpty: items.isEmpty,
      children: [
        ...tableRows,
        if (items.isNotEmpty)
          _buildTotalRow(
            totalInvoiceCount: totalInvoiceCount,
            totalSales: totalSales,
            totalSalesWithTax: totalSalesWithTax,
            totalTaxAmount: totalTaxAmount,
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
        date: Row(
          children: [
            Text(
              groupBy == 'Location' ? 'LOCATION' : 'DATE',
              style: ReportTableTypography.header,
            ),
            if (groupBy != 'Location') ...[
              const SizedBox(width: AppTheme.space4),
              const Icon(
                Icons.unfold_more,
                size: AppTheme.space14,
                color: AppTheme.textSecondary,
              ),
            ],
          ],
        ),
        invoiceCount: Text(
          'INVOICE COUNT',
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
        totalTaxAmount: Text(
          'TOTAL TAX AMOUNT',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
      ),
    );
  }

  Widget _buildTotalRow({
    required int totalInvoiceCount,
    required double totalSales,
    required double totalSalesWithTax,
    required double totalTaxAmount,
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
        date: Text(
          'Total',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        invoiceCount: Text(
          '$totalInvoiceCount',
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
        totalTaxAmount: Text(
          currencyFormat.format(totalTaxAmount),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeaderRow({
    required String locationName,
    required int groupInvoiceCount,
    required double groupTotalSales,
    required double groupTotalSalesWithTax,
    required double groupTotalTaxAmount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: _buildTableRow(
        date: Text(
          locationName,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        invoiceCount: Text(
          '$groupInvoiceCount',
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        totalSales: Text(
          currencyFormat.format(groupTotalSales),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        totalSalesWithTax: Text(
          currencyFormat.format(groupTotalSalesWithTax),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        totalTaxAmount: Text(
          currencyFormat.format(groupTotalTaxAmount),
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
    required Widget date,
    required Widget invoiceCount,
    required Widget totalSales,
    required Widget totalSalesWithTax,
    required Widget totalTaxAmount,
  }) {
    return Row(
      children: [
        Expanded(flex: 3, child: date),
        Expanded(flex: 2, child: invoiceCount),
        Expanded(flex: 2, child: totalSales),
        Expanded(flex: 2, child: totalSalesWithTax),
        Expanded(flex: 2, child: totalTaxAmount),
      ],
    );
  }
}

class _SalesSummaryDataRow extends StatefulWidget {
  final String date;
  final int invoiceCount;
  final String totalSalesText;
  final String totalSalesWithTaxText;
  final String totalTaxAmountText;
  final Widget Function({
    required Widget date,
    required Widget invoiceCount,
    required Widget totalSales,
    required Widget totalSalesWithTax,
    required Widget totalTaxAmount,
  })
  rowBuilder;
  final bool isIndented;

  const _SalesSummaryDataRow({
    required this.date,
    required this.invoiceCount,
    required this.totalSalesText,
    required this.totalSalesWithTaxText,
    required this.totalTaxAmountText,
    required this.rowBuilder,
    this.isIndented = false,
  });

  @override
  State<_SalesSummaryDataRow> createState() => _SalesSummaryDataRowState();
}

class _SalesSummaryDataRowState extends State<_SalesSummaryDataRow> {
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
          date: Padding(
            padding: EdgeInsets.only(
              left: widget.isIndented ? AppTheme.space24 : 0,
            ),
            child: Text(widget.date, style: AppTheme.tableCell),
          ),
          invoiceCount: Text(
            '${widget.invoiceCount}',
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
          totalTaxAmount: Text(
            widget.totalTaxAmountText,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
        ),
      ),
    );
  }
}
