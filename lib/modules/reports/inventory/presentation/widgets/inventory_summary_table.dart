import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class InventorySummaryRow {
  final String itemName;
  final double reorderLevel;
  final double quantityOrdered;
  final double quantityIn;
  final double quantityOut;
  final double stockOnHand;
  final double committedStock;
  final double availableForSale;

  const InventorySummaryRow({
    required this.itemName,
    required this.reorderLevel,
    required this.quantityOrdered,
    required this.quantityIn,
    required this.quantityOut,
    required this.stockOnHand,
    required this.committedStock,
    required this.availableForSale,
  });

  factory InventorySummaryRow.fromInventoryValuation(
    Map<String, dynamic> item,
  ) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return InventorySummaryRow(
      itemName: item['itemName']?.toString() ?? '-',
      reorderLevel: numberValue('reorderLevel'),
      quantityOrdered: numberValue('quantityOrdered'),
      quantityIn: numberValue('quantityIn'),
      quantityOut: numberValue('quantityOut'),
      stockOnHand: numberValue('stockOnHand'),
      committedStock: numberValue('committedStock'),
      availableForSale: numberValue('availableForSale'),
    );
  }
}

class InventorySummaryTable extends StatefulWidget {
  final List<InventorySummaryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const InventorySummaryTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<InventorySummaryTable> createState() => _InventorySummaryTableState();
}

class _InventorySummaryTableState extends State<InventorySummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _twoDecimalFormat = ReportFormatterCache.number('0.00');
  final NumberFormat _sixDecimalFormat = ReportFormatterCache.number('0.000000');

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<InventorySummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <InventorySummaryRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  InventorySummaryRow get _totalRow {
    return InventorySummaryRow(
      itemName: 'Total',
      reorderLevel: widget.rows.fold<double>(
        0,
        (sum, row) => sum + row.reorderLevel,
      ),
      quantityOrdered: widget.rows.fold<double>(
        0,
        (sum, row) => sum + row.quantityOrdered,
      ),
      quantityIn: widget.rows.fold<double>(
        0,
        (sum, row) => sum + row.quantityIn,
      ),
      quantityOut: widget.rows.fold<double>(
        0,
        (sum, row) => sum + row.quantityOut,
      ),
      stockOnHand: widget.rows.fold<double>(
        0,
        (sum, row) => sum + row.stockOnHand,
      ),
      committedStock: widget.rows.fold<double>(
        0,
        (sum, row) => sum + row.committedStock,
      ),
      availableForSale: widget.rows.fold<double>(
        0,
        (sum, row) => sum + row.availableForSale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1320,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              if (widget.rows.isEmpty)
                const ReportTableEmptyBody(minHeight: 345)
              else
                SizedBox(
                  height: 345,
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _verticalController,
                      itemCount: _pageRows.length + 1,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, index) {
                        if (index == _pageRows.length) {
                          return _buildTotalRow(_totalRow);
                        }
                        return _InventorySummaryDataRow(
                          row: _pageRows[index],
                          formatter: _formatQuantity,
                        );
                      },
                    ),
                  ),
                ),
              ReportPaginationFooter(
                totalCount: widget.rows.length,
                page: widget.page,
                pageSize: widget.pageSize,
                onPageChanged: widget.onPageChanged,
              ),
              const SizedBox(height: AppTheme.space28),
            ],
          ),
        ),
      ),
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
        reorderLevel: Text(
          'REORDER LEVEL',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        quantityOrdered: Text(
          'QUANTITY ORDERED',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        quantityIn: Text(
          'QUANTITY IN',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        quantityOut: Text(
          'QUANTITY OUT',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        stockOnHand: Text(
          'STOCK ON HAND',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        committedStock: Text(
          'COMMITTED STOCK',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        availableForSale: Text(
          'AVAILABLE FOR SALE',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
      ),
    );
  }

  Widget _buildTotalRow(InventorySummaryRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        itemName: Text(
          row.itemName,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        reorderLevel: _totalText(_twoDecimalFormat.format(row.reorderLevel)),
        quantityOrdered: _totalText(
          _twoDecimalFormat.format(row.quantityOrdered),
        ),
        quantityIn: _totalText(_twoDecimalFormat.format(row.quantityIn)),
        quantityOut: _totalText(_twoDecimalFormat.format(row.quantityOut)),
        stockOnHand: _totalText(_twoDecimalFormat.format(row.stockOnHand)),
        committedStock: _totalText(
          _twoDecimalFormat.format(row.committedStock),
        ),
        availableForSale: _totalText(
          _twoDecimalFormat.format(row.availableForSale),
        ),
      ),
    );
  }

  Widget _totalText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    );
  }

  String _formatQuantity(double value) {
    final requiresPrecision =
        value != 0 && value.abs() < 10 && value != value.truncateToDouble();
    return requiresPrecision
        ? _sixDecimalFormat.format(value)
        : _twoDecimalFormat.format(value);
  }
}

class _InventorySummaryDataRow extends StatefulWidget {
  final InventorySummaryRow row;
  final String Function(double value) formatter;

  const _InventorySummaryDataRow({required this.row, required this.formatter});

  @override
  State<_InventorySummaryDataRow> createState() =>
      _InventorySummaryDataRowState();
}

class _InventorySummaryDataRowState extends State<_InventorySummaryDataRow> {
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
          vertical: AppTheme.space12,
        ),
        color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
        child: _buildTableRow(
          itemName: Text(widget.row.itemName, style: AppTheme.tableCell),
          reorderLevel: _cell(widget.row.reorderLevel),
          quantityOrdered: _cell(widget.row.quantityOrdered),
          quantityIn: _cell(widget.row.quantityIn),
          quantityOut: _cell(widget.row.quantityOut),
          stockOnHand: _cell(widget.row.stockOnHand),
          committedStock: _cell(widget.row.committedStock),
          availableForSale: _cell(widget.row.availableForSale),
        ),
      ),
    );
  }

  Widget _cell(double value) {
    return Text(
      widget.formatter(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell,
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget reorderLevel,
  required Widget quantityOrdered,
  required Widget quantityIn,
  required Widget quantityOut,
  required Widget stockOnHand,
  required Widget committedStock,
  required Widget availableForSale,
}) {
  return Row(
    children: [
      Expanded(flex: 4, child: itemName),
      Expanded(flex: 2, child: reorderLevel),
      Expanded(flex: 3, child: quantityOrdered),
      Expanded(flex: 3, child: quantityIn),
      Expanded(flex: 3, child: quantityOut),
      Expanded(flex: 3, child: stockOnHand),
      Expanded(flex: 3, child: committedStock),
      Expanded(flex: 3, child: availableForSale),
    ],
  );
}
