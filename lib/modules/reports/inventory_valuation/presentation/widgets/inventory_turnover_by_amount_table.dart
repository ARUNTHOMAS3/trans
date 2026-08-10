import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class InventoryTurnoverByAmountRow {
  final String itemName;
  final double openingBalance;
  final double closingBalance;
  final double costOfGoodsSold;
  final double averagePrice;
  final double turnOverRatio;
  final double averageTurnoverDays;

  const InventoryTurnoverByAmountRow({
    required this.itemName,
    required this.openingBalance,
    required this.closingBalance,
    required this.costOfGoodsSold,
    required this.averagePrice,
    required this.turnOverRatio,
    required this.averageTurnoverDays,
  });

  factory InventoryTurnoverByAmountRow.totalFromRows(
    List<InventoryTurnoverByAmountRow> rows,
  ) {
    final openingBalance = rows.fold<double>(
      0,
      (sum, row) => sum + row.openingBalance,
    );
    final closingBalance = rows.fold<double>(
      0,
      (sum, row) => sum + row.closingBalance,
    );
    final costOfGoodsSold = rows.fold<double>(
      0,
      (sum, row) => sum + row.costOfGoodsSold,
    );
    final averagePrice = rows.fold<double>(
      0,
      (sum, row) => sum + row.averagePrice,
    );
    final turnOverRatio = averagePrice == 0
        ? 0.0
        : costOfGoodsSold / averagePrice;

    return InventoryTurnoverByAmountRow(
      itemName: 'Total',
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      costOfGoodsSold: costOfGoodsSold,
      averagePrice: averagePrice,
      turnOverRatio: turnOverRatio,
      averageTurnoverDays: 0,
    );
  }
}

const double _amountHorizontalPadding = AppTheme.space20 * 2;
const double _amountColumnGap = AppTheme.space14;
const double _amountItemNameWidth = 300;
const double _amountOpeningBalanceWidth = 160;
const double _amountClosingBalanceWidth = 160;
const double _amountCostOfGoodsSoldWidth = 190;
const double _amountAveragePriceWidth = 180;
const double _amountRatioWidth = 170;
const double _amountDaysWidth = 210;
const double _amountContentWidth =
    _amountItemNameWidth +
    _amountOpeningBalanceWidth +
    _amountClosingBalanceWidth +
    _amountCostOfGoodsSoldWidth +
    _amountAveragePriceWidth +
    _amountRatioWidth +
    _amountDaysWidth +
    (_amountColumnGap * 6);
const double _amountTableWidth = _amountContentWidth + _amountHorizontalPadding;

class InventoryTurnoverByAmountTable extends StatefulWidget {
  final List<InventoryTurnoverByAmountRow> rows;
  final InventoryTurnoverByAmountRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const InventoryTurnoverByAmountTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<InventoryTurnoverByAmountTable> createState() =>
      _InventoryTurnoverByAmountTableState();
}

class _InventoryTurnoverByAmountTableState
    extends State<InventoryTurnoverByAmountTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\u20B9',
    decimalDigits: 2,
  );
  final NumberFormat _compactFormat = ReportFormatterCache.number('0.##');

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<InventoryTurnoverByAmountRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <InventoryTurnoverByAmountRow>[];
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
          width: _amountTableWidth,
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
                        return _InventoryTurnoverByAmountDataRow(
                          row: _pageRows[index],
                          currencyFormatter: _currencyFormat,
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
        openingBalance: _headerText('OPENING BALANCE'),
        closingBalance: _headerText('CLOSING BALANCE'),
        costOfGoodsSold: _headerText('COST OF GOODS SOLD'),
        averagePrice: _headerWithInfo(
          'AVERAGE PRICE',
          '(Opening Balance + Closing Balance) / 2',
        ),
        turnOverRatio: _headerWithInfo(
          'TURN OVER RATIO',
          'Cost of Goods Sold / ((Opening Balance + Closing Balance) / 2)',
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

  Widget _buildTotalRow(InventoryTurnoverByAmountRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        itemName: Text('Total', style: _totalStyle),
        openingBalance: _totalCurrency(row.openingBalance),
        closingBalance: _totalCurrency(row.closingBalance),
        costOfGoodsSold: _totalCurrency(row.costOfGoodsSold),
        averagePrice: _totalCurrency(row.averagePrice),
        turnOverRatio: _totalCompact(row.turnOverRatio),
        averageTurnoverDays: _totalCompact(row.averageTurnoverDays),
      ),
    );
  }

  Widget _totalCurrency(double value) {
    return Text(
      _currencyFormat.format(value),
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

class _InventoryTurnoverByAmountDataRow extends StatefulWidget {
  final InventoryTurnoverByAmountRow row;
  final NumberFormat currencyFormatter;
  final NumberFormat compactFormatter;

  const _InventoryTurnoverByAmountDataRow({
    required this.row,
    required this.currencyFormatter,
    required this.compactFormatter,
  });

  @override
  State<_InventoryTurnoverByAmountDataRow> createState() =>
      _InventoryTurnoverByAmountDataRowState();
}

class _InventoryTurnoverByAmountDataRowState
    extends State<_InventoryTurnoverByAmountDataRow> {
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
          openingBalance: _currencyCell(widget.row.openingBalance),
          closingBalance: _currencyCell(widget.row.closingBalance),
          costOfGoodsSold: _currencyCell(widget.row.costOfGoodsSold),
          averagePrice: _currencyCell(widget.row.averagePrice),
          turnOverRatio: _compactCell(widget.row.turnOverRatio),
          averageTurnoverDays: _compactCell(widget.row.averageTurnoverDays),
        ),
      ),
    );
  }

  Widget _currencyCell(double value) {
    return Text(
      widget.currencyFormatter.format(value),
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
  required Widget openingBalance,
  required Widget closingBalance,
  required Widget costOfGoodsSold,
  required Widget averagePrice,
  required Widget turnOverRatio,
  required Widget averageTurnoverDays,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _amountCell(itemName, _amountItemNameWidth),
      _amountGap(),
      _amountCell(openingBalance, _amountOpeningBalanceWidth),
      _amountGap(),
      _amountCell(closingBalance, _amountClosingBalanceWidth),
      _amountGap(),
      _amountCell(costOfGoodsSold, _amountCostOfGoodsSoldWidth),
      _amountGap(),
      _amountCell(averagePrice, _amountAveragePriceWidth),
      _amountGap(),
      _amountCell(turnOverRatio, _amountRatioWidth),
      _amountGap(),
      _amountCell(averageTurnoverDays, _amountDaysWidth),
    ],
  );
}

Widget _amountCell(Widget child, double width) {
  return SizedBox(width: width, child: child);
}

Widget _amountGap() {
  return const SizedBox(width: _amountColumnGap);
}
