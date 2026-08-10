import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class InventoryTurnoverByQuantityRow {
  final String itemName;
  final double openingStock;
  final double closingStock;
  final double quantitySold;
  final double averageQuantity;
  final double turnOverRatio;
  final double averageTurnoverDays;

  const InventoryTurnoverByQuantityRow({
    required this.itemName,
    required this.openingStock,
    required this.closingStock,
    required this.quantitySold,
    required this.averageQuantity,
    required this.turnOverRatio,
    required this.averageTurnoverDays,
  });

  factory InventoryTurnoverByQuantityRow.fromJson(Map<String, dynamic> item) {
    return InventoryTurnoverByQuantityRow(
      itemName: item['itemName']?.toString() ?? '-',
      openingStock: _numberValue(item, 'openingStock'),
      closingStock: _numberValue(item, 'closingStock'),
      quantitySold: _numberValue(item, 'quantitySold'),
      averageQuantity: _numberValue(item, 'averageQuantity'),
      turnOverRatio: _numberValue(item, 'turnOverRatio'),
      averageTurnoverDays: _numberValue(item, 'averageTurnoverDays'),
    );
  }

  factory InventoryTurnoverByQuantityRow.fromTotals(Map<String, dynamic> item) {
    return InventoryTurnoverByQuantityRow(
      itemName: 'Total',
      openingStock: _numberValue(item, 'openingStock'),
      closingStock: _numberValue(item, 'closingStock'),
      quantitySold: _numberValue(item, 'quantitySold'),
      averageQuantity: _numberValue(item, 'averageQuantity'),
      turnOverRatio: _numberValue(item, 'turnOverRatio'),
      averageTurnoverDays: _numberValue(item, 'averageTurnoverDays'),
    );
  }

  factory InventoryTurnoverByQuantityRow.totalFromRows(
    List<InventoryTurnoverByQuantityRow> rows,
  ) {
    final openingStock = rows.fold<double>(
      0,
      (sum, row) => sum + row.openingStock,
    );
    final closingStock = rows.fold<double>(
      0,
      (sum, row) => sum + row.closingStock,
    );
    final quantitySold = rows.fold<double>(
      0,
      (sum, row) => sum + row.quantitySold,
    );
    final averageQuantity = rows.fold<double>(
      0,
      (sum, row) => sum + row.averageQuantity,
    );
    final turnOverRatio = averageQuantity == 0
        ? 0.0
        : quantitySold / averageQuantity;
    return InventoryTurnoverByQuantityRow(
      itemName: 'Total',
      openingStock: openingStock,
      closingStock: closingStock,
      quantitySold: quantitySold,
      averageQuantity: averageQuantity,
      turnOverRatio: turnOverRatio,
      averageTurnoverDays: 0,
    );
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

const double _turnoverHorizontalPadding = AppTheme.space20 * 2;
const double _turnoverColumnGap = AppTheme.space14;
const double _turnoverItemNameWidth = 270;
const double _turnoverOpeningStockWidth = 160;
const double _turnoverClosingStockWidth = 160;
const double _turnoverQuantitySoldWidth = 170;
const double _turnoverAverageQuantityWidth = 180;
const double _turnoverRatioWidth = 170;
const double _turnoverDaysWidth = 210;
const double _turnoverContentWidth =
    _turnoverItemNameWidth +
    _turnoverOpeningStockWidth +
    _turnoverClosingStockWidth +
    _turnoverQuantitySoldWidth +
    _turnoverAverageQuantityWidth +
    _turnoverRatioWidth +
    _turnoverDaysWidth +
    (_turnoverColumnGap * 6);
const double _turnoverTableWidth =
    _turnoverContentWidth + _turnoverHorizontalPadding;

class InventoryTurnoverByQuantityTable extends StatefulWidget {
  final List<InventoryTurnoverByQuantityRow> rows;
  final InventoryTurnoverByQuantityRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const InventoryTurnoverByQuantityTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<InventoryTurnoverByQuantityTable> createState() =>
      _InventoryTurnoverByQuantityTableState();
}

class _InventoryTurnoverByQuantityTableState
    extends State<InventoryTurnoverByQuantityTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _stockFormat = ReportFormatterCache.number('0.00');
  final NumberFormat _compactFormat = ReportFormatterCache.number('0.##');

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<InventoryTurnoverByQuantityRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <InventoryTurnoverByQuantityRow>[];
    }
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
          width: _turnoverTableWidth,
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
                        return _InventoryTurnoverDataRow(
                          row: _pageRows[index],
                          stockFormatter: _stockFormat,
                          compactFormatter: _compactFormat,
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
        itemName: Text('ITEM NAME', style: ReportTableTypography.header),
        openingStock: _headerText('OPENING STOCK'),
        closingStock: _headerText('CLOSING STOCK'),
        quantitySold: _headerText('QUANTITY SOLD'),
        averageQuantity: _headerWithInfo(
          'AVERAGE QUANTITY',
          '((Opening Stock + Closing Stock) / 2)',
        ),
        turnOverRatio: _headerWithInfo(
          'TURN OVER RATIO',
          'Quantity Sold / ((Opening Stock + Closing Stock) / 2)',
        ),
        averageTurnoverDays: _headerWithInfo(
          'AVERAGE TURNOVER DAYS',
          'No Of Days / Turn Over Ratio',
        ),
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

  Widget _headerWithInfo(String value, String tooltipMessage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _headerText(value)),
        const SizedBox(width: AppTheme.space4),
        ZTooltip(
          message: tooltipMessage,
          direction: ZTooltipDirection.bottom,
          child: const Icon(
            Icons.help_outline,
            size: AppTheme.space14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(InventoryTurnoverByQuantityRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: _buildTableRow(
        itemName: Text('Total', style: _totalStyle),
        openingStock: _totalStock(row.openingStock),
        closingStock: _totalStock(row.closingStock),
        quantitySold: _totalStock(row.quantitySold),
        averageQuantity: _totalCompact(row.averageQuantity),
        turnOverRatio: _totalCompact(row.turnOverRatio),
        averageTurnoverDays: _totalCompact(row.averageTurnoverDays),
      ),
    );
  }

  Widget _totalStock(double value) {
    return Text(
      _stockFormat.format(value),
      textAlign: TextAlign.right,
      style: _totalStyle,
    );
  }

  Widget _totalCompact(double value) {
    return Text(
      _compactFormat.format(value),
      textAlign: TextAlign.right,
      style: _totalStyle,
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );
}

class _InventoryTurnoverDataRow extends StatefulWidget {
  final InventoryTurnoverByQuantityRow row;
  final NumberFormat stockFormatter;
  final NumberFormat compactFormatter;

  const _InventoryTurnoverDataRow({
    required this.row,
    required this.stockFormatter,
    required this.compactFormatter,
  });

  @override
  State<_InventoryTurnoverDataRow> createState() =>
      _InventoryTurnoverDataRowState();
}

class _InventoryTurnoverDataRowState extends State<_InventoryTurnoverDataRow> {
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
          openingStock: _stockCell(widget.row.openingStock),
          closingStock: _stockCell(widget.row.closingStock),
          quantitySold: _stockCell(widget.row.quantitySold),
          averageQuantity: _compactCell(widget.row.averageQuantity),
          turnOverRatio: _compactCell(widget.row.turnOverRatio),
          averageTurnoverDays: _compactCell(widget.row.averageTurnoverDays),
        ),
      ),
    );
  }

  Widget _stockCell(double value) {
    return Text(
      widget.stockFormatter.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell,
    );
  }

  Widget _compactCell(double value) {
    return Text(
      widget.compactFormatter.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell,
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget openingStock,
  required Widget closingStock,
  required Widget quantitySold,
  required Widget averageQuantity,
  required Widget turnOverRatio,
  required Widget averageTurnoverDays,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _turnoverCell(itemName, _turnoverItemNameWidth),
      _turnoverGap(),
      _turnoverCell(openingStock, _turnoverOpeningStockWidth),
      _turnoverGap(),
      _turnoverCell(closingStock, _turnoverClosingStockWidth),
      _turnoverGap(),
      _turnoverCell(quantitySold, _turnoverQuantitySoldWidth),
      _turnoverGap(),
      _turnoverCell(averageQuantity, _turnoverAverageQuantityWidth),
      _turnoverGap(),
      _turnoverCell(turnOverRatio, _turnoverRatioWidth),
      _turnoverGap(),
      _turnoverCell(averageTurnoverDays, _turnoverDaysWidth),
    ],
  );
}

Widget _turnoverCell(Widget child, double width) {
  return SizedBox(width: width, child: child);
}

Widget _turnoverGap() {
  return const SizedBox(width: _turnoverColumnGap);
}
