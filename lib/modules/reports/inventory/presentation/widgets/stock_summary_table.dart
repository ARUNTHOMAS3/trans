import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class StockSummaryRow {
  final String itemName;
  final String sku;
  final double openingStock;
  final double quantityIn;
  final double quantityOut;
  final double closingStock;

  const StockSummaryRow({
    required this.itemName,
    required this.sku,
    required this.openingStock,
    required this.quantityIn,
    required this.quantityOut,
    required this.closingStock,
  });

  factory StockSummaryRow.fromJson(Map<String, dynamic> item) {
    return StockSummaryRow(
      itemName: item['itemName']?.toString() ?? '-',
      sku: item['sku']?.toString() ?? '',
      openingStock: _numberValue(item, 'openingStock'),
      quantityIn: _numberValue(item, 'quantityIn'),
      quantityOut: _numberValue(item, 'quantityOut'),
      closingStock: _numberValue(item, 'closingStock'),
    );
  }

  factory StockSummaryRow.fromTotals(Map<String, dynamic> item) {
    return StockSummaryRow(
      itemName: 'Total',
      sku: '',
      openingStock: _numberValue(item, 'openingStock'),
      quantityIn: _numberValue(item, 'quantityIn'),
      quantityOut: _numberValue(item, 'quantityOut'),
      closingStock: _numberValue(item, 'closingStock'),
    );
  }

  factory StockSummaryRow.totalFromRows(List<StockSummaryRow> rows) {
    return StockSummaryRow(
      itemName: 'Total',
      sku: '',
      openingStock: rows.fold<double>(0, (sum, row) => sum + row.openingStock),
      quantityIn: rows.fold<double>(0, (sum, row) => sum + row.quantityIn),
      quantityOut: rows.fold<double>(0, (sum, row) => sum + row.quantityOut),
      closingStock: rows.fold<double>(0, (sum, row) => sum + row.closingStock),
    );
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class StockSummaryTable extends StatefulWidget {
  final List<StockSummaryRow> rows;
  final StockSummaryRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const StockSummaryTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<StockSummaryTable> createState() => _StockSummaryTableState();
}

class _StockSummaryTableState extends State<StockSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<StockSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <StockSummaryRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
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
                          return _buildTotalRow(widget.totals);
                        }
                        return _StockSummaryDataRow(
                          row: _pageRows[index],
                          formatter: _quantityFormat,
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

  Widget _buildTotalRow(StockSummaryRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        itemName: Text('Total', style: _totalStyle),
        sku: const SizedBox.shrink(),
        openingStock: _totalText(row.openingStock),
        quantityIn: _totalText(row.quantityIn),
        quantityOut: _totalText(row.quantityOut),
        closingStock: _totalText(row.closingStock),
      ),
    );
  }

  Widget _totalText(double value) {
    return Text(
      _quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: _totalStyle,
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );

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
        sku: Text('SKU', style: ReportTableTypography.header),
        openingStock: _headerText('OPENING STOCK'),
        quantityIn: _headerText('QUANTITY IN'),
        quantityOut: _headerText('QUANTITY OUT'),
        closingStock: _headerText('CLOSING STOCK'),
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: ReportTableTypography.header,
    );
  }
}

class _StockSummaryDataRow extends StatefulWidget {
  final StockSummaryRow row;
  final NumberFormat formatter;

  const _StockSummaryDataRow({required this.row, required this.formatter});

  @override
  State<_StockSummaryDataRow> createState() => _StockSummaryDataRowState();
}

class _StockSummaryDataRowState extends State<_StockSummaryDataRow> {
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
          itemName: Text(
            widget.row.itemName,
            style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
          ),
          sku: Text(widget.row.sku, style: AppTheme.tableCell),
          openingStock: _quantityCell(widget.row.openingStock),
          quantityIn: _quantityCell(widget.row.quantityIn, linkStyle: true),
          quantityOut: _quantityCell(widget.row.quantityOut, linkStyle: true),
          closingStock: _quantityCell(widget.row.closingStock, linkStyle: true),
        ),
      ),
    );
  }

  Widget _quantityCell(double value, {bool linkStyle = false}) {
    return Text(
      widget.formatter.format(value),
      textAlign: TextAlign.right,
      style: linkStyle
          ? AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue)
          : AppTheme.tableCell,
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget sku,
  required Widget openingStock,
  required Widget quantityIn,
  required Widget quantityOut,
  required Widget closingStock,
}) {
  return Row(
    children: [
      Expanded(flex: 4, child: itemName),
      Expanded(flex: 2, child: sku),
      Expanded(flex: 3, child: openingStock),
      Expanded(flex: 3, child: quantityIn),
      Expanded(flex: 3, child: quantityOut),
      Expanded(flex: 3, child: closingStock),
    ],
  );
}
