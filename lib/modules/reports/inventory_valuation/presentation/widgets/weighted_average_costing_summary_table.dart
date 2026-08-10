import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class WeightedAverageCostingSummaryRow {
  final String itemName;
  final double openingStock;
  final double openingStockAmount;
  final double openingWac;
  final double closingStock;
  final double closingStockAmount;
  final double closingWac;

  const WeightedAverageCostingSummaryRow({
    required this.itemName,
    required this.openingStock,
    required this.openingStockAmount,
    required this.openingWac,
    required this.closingStock,
    required this.closingStockAmount,
    required this.closingWac,
  });

  factory WeightedAverageCostingSummaryRow.totalFromRows(
    List<WeightedAverageCostingSummaryRow> rows,
  ) {
    return WeightedAverageCostingSummaryRow(
      itemName: 'Total',
      openingStock: rows.fold<double>(0, (sum, row) => sum + row.openingStock),
      openingStockAmount: rows.fold<double>(
        0,
        (sum, row) => sum + row.openingStockAmount,
      ),
      openingWac: 0,
      closingStock: rows.fold<double>(0, (sum, row) => sum + row.closingStock),
      closingStockAmount: rows.fold<double>(
        0,
        (sum, row) => sum + row.closingStockAmount,
      ),
      closingWac: 0,
    );
  }
}

const double _wacHorizontalPadding = AppTheme.space20 * 2;
const double _wacColumnGap = AppTheme.space14;
const double _wacItemNameWidth = 330;
const double _wacOpeningStockWidth = 150;
const double _wacOpeningStockAmountWidth = 200;
const double _wacOpeningWacWidth = 160;
const double _wacClosingStockWidth = 150;
const double _wacClosingStockAmountWidth = 210;
const double _wacClosingWacWidth = 160;
const double _wacContentWidth =
    _wacItemNameWidth +
    _wacOpeningStockWidth +
    _wacOpeningStockAmountWidth +
    _wacOpeningWacWidth +
    _wacClosingStockWidth +
    _wacClosingStockAmountWidth +
    _wacClosingWacWidth +
    (_wacColumnGap * 6);
const double _wacTableWidth = _wacContentWidth + _wacHorizontalPadding;

class WeightedAverageCostingSummaryTable extends StatefulWidget {
  final List<WeightedAverageCostingSummaryRow> rows;
  final WeightedAverageCostingSummaryRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const WeightedAverageCostingSummaryTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<WeightedAverageCostingSummaryTable> createState() =>
      _WeightedAverageCostingSummaryTableState();
}

class _WeightedAverageCostingSummaryTableState
    extends State<WeightedAverageCostingSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<WeightedAverageCostingSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <WeightedAverageCostingSummaryRow>[];
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
          width: _wacTableWidth,
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
                        return _WeightedAverageCostingDataRow(
                          row: _pageRows[index],
                          quantityFormatter: _quantityFormat,
                          currencyFormatter: _currencyFormat,
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
        openingStock: _headerText('OPENING STOCK'),
        openingStockAmount: _headerText('OPENING STOCK AMOUNT'),
        openingWac: _headerText('OPENING WAC'),
        closingStock: _headerText('CLOSING STOCK'),
        closingStockAmount: _headerText('CLOSING STOCK AMOUNT'),
        closingWac: _headerText('CLOSING WAC'),
      ),
    );
  }

  Widget _buildTotalRow(WeightedAverageCostingSummaryRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        itemName: Text('Total', style: _totalStyle),
        openingStock: _totalQuantity(row.openingStock),
        openingStockAmount: _totalCurrency(row.openingStockAmount),
        openingWac: _totalCurrency(row.openingWac),
        closingStock: _totalQuantity(row.closingStock),
        closingStockAmount: _totalCurrency(row.closingStockAmount),
        closingWac: _totalCurrency(row.closingWac),
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

  Widget _totalQuantity(double value) {
    return Text(
      _quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: _totalStyle,
    );
  }

  Widget _totalCurrency(double value) {
    return Text(
      _currencyFormat.format(value),
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

class _WeightedAverageCostingDataRow extends StatefulWidget {
  final WeightedAverageCostingSummaryRow row;
  final NumberFormat quantityFormatter;
  final NumberFormat currencyFormatter;

  const _WeightedAverageCostingDataRow({
    required this.row,
    required this.quantityFormatter,
    required this.currencyFormatter,
  });

  @override
  State<_WeightedAverageCostingDataRow> createState() =>
      _WeightedAverageCostingDataRowState();
}

class _WeightedAverageCostingDataRowState
    extends State<_WeightedAverageCostingDataRow> {
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
          openingStock: _quantityCell(widget.row.openingStock),
          openingStockAmount: _currencyCell(widget.row.openingStockAmount),
          openingWac: _currencyCell(widget.row.openingWac),
          closingStock: _quantityCell(widget.row.closingStock),
          closingStockAmount: _currencyCell(widget.row.closingStockAmount),
          closingWac: _currencyCell(widget.row.closingWac),
        ),
      ),
    );
  }

  Widget _quantityCell(double value) {
    return Text(
      widget.quantityFormatter.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell,
    );
  }

  Widget _currencyCell(double value) {
    return Text(
      widget.currencyFormatter.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell,
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget openingStock,
  required Widget openingStockAmount,
  required Widget openingWac,
  required Widget closingStock,
  required Widget closingStockAmount,
  required Widget closingWac,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _wacCell(itemName, _wacItemNameWidth),
      _wacGap(),
      _wacCell(openingStock, _wacOpeningStockWidth),
      _wacGap(),
      _wacCell(openingStockAmount, _wacOpeningStockAmountWidth),
      _wacGap(),
      _wacCell(openingWac, _wacOpeningWacWidth),
      _wacGap(),
      _wacCell(closingStock, _wacClosingStockWidth),
      _wacGap(),
      _wacCell(closingStockAmount, _wacClosingStockAmountWidth),
      _wacGap(),
      _wacCell(closingWac, _wacClosingWacWidth),
    ],
  );
}

Widget _wacCell(Widget child, double width) {
  return SizedBox(width: width, child: child);
}

Widget _wacGap() {
  return const SizedBox(width: _wacColumnGap);
}
