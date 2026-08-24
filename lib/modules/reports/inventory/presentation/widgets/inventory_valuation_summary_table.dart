import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class InventoryValuationSummaryRow {
  final String itemName;
  final String unit;
  final double stockOnHand;
  final double inventoryAssetValue;

  const InventoryValuationSummaryRow({
    required this.itemName,
    required this.unit,
    required this.stockOnHand,
    required this.inventoryAssetValue,
  });

  factory InventoryValuationSummaryRow.fromJson(Map<String, dynamic> item) {
    return InventoryValuationSummaryRow(
      itemName: item['itemName']?.toString() ?? '-',
      unit: _unitValue(item),
      stockOnHand: _numberValue(item, 'stockOnHand'),
      inventoryAssetValue: _numberValue(item, 'assetValue'),
    );
  }

  factory InventoryValuationSummaryRow.fromTotalsJson(
    Map<String, dynamic>? totals,
  ) {
    return InventoryValuationSummaryRow(
      itemName: 'Total',
      unit: '',
      stockOnHand: _numberValue(totals ?? const <String, dynamic>{}, 'stockOnHand'),
      inventoryAssetValue: _numberValue(
        totals ?? const <String, dynamic>{},
        'assetValue',
      ),
    );
  }

  factory InventoryValuationSummaryRow.emptyTotal() {
    return const InventoryValuationSummaryRow(
      itemName: 'Total',
      unit: '',
      stockOnHand: 0,
      inventoryAssetValue: 0,
    );
  }

  static String _unitValue(Map<String, dynamic> item) {
    for (final key in <String>['unit', 'unitName', 'uom', 'stockUnit']) {
      final value = item[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != '-') return value;
    }
    return '';
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class InventoryValuationSummaryTable extends StatefulWidget {
  final List<InventoryValuationSummaryRow> rows;
  final InventoryValuationSummaryRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final int? totalCount;
  final bool serverPaginated;

  const InventoryValuationSummaryTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.totalCount,
    this.serverPaginated = false,
  });

  @override
  State<InventoryValuationSummaryTable> createState() =>
      _InventoryValuationSummaryTableState();
}

class _InventoryValuationSummaryTableState
    extends State<InventoryValuationSummaryTable> {
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

  int get _totalCount => widget.totalCount ?? widget.rows.length;

  List<InventoryValuationSummaryRow> get _pageRows {
    if (widget.serverPaginated) return widget.rows;
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <InventoryValuationSummaryRow>[];
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
                        return _InventoryValuationSummaryDataRow(
                          row: _pageRows[index],
                          quantityFormat: _quantityFormat,
                          currencyFormat: _currencyFormat,
                        );
                      },
                    ),
                  ),
                ),
              ReportPaginationFooter(
                totalCount: _totalCount,
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
        stockOnHand: _headerText('STOCK ON HAND'),
        inventoryAssetValue: _headerText('INVENTORY ASSET VALUE'),
      ),
    );
  }

  Widget _buildTotalRow(InventoryValuationSummaryRow row) {
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
        stockOnHand: _totalText(_quantityFormat.format(row.stockOnHand)),
        inventoryAssetValue: _totalText(
          _currencyFormat.format(row.inventoryAssetValue),
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

  Widget _totalText(String value) {
    return Text(value, textAlign: TextAlign.right, style: _totalStyle);
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );
}

class _InventoryValuationSummaryDataRow extends StatefulWidget {
  final InventoryValuationSummaryRow row;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;

  const _InventoryValuationSummaryDataRow({
    required this.row,
    required this.quantityFormat,
    required this.currencyFormat,
  });

  @override
  State<_InventoryValuationSummaryDataRow> createState() =>
      _InventoryValuationSummaryDataRowState();
}

class _InventoryValuationSummaryDataRowState
    extends State<_InventoryValuationSummaryDataRow> {
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
          itemName: _itemName(),
          stockOnHand: _quantityCell(widget.row.stockOnHand),
          inventoryAssetValue: _currencyCell(widget.row.inventoryAssetValue),
        ),
      ),
    );
  }

  Widget _itemName() {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        text: widget.row.itemName,
        style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
        children: [
          if (widget.row.unit.isNotEmpty)
            TextSpan(
              text: ' (${widget.row.unit})',
              style: AppTheme.tableCell.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _quantityCell(double value) {
    return Text(
      widget.quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell,
    );
  }

  Widget _currencyCell(double value) {
    return Text(
      widget.currencyFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget stockOnHand,
  required Widget inventoryAssetValue,
}) {
  return Row(
    children: [
      Expanded(flex: 6, child: itemName),
      Expanded(flex: 3, child: stockOnHand),
      Expanded(flex: 3, child: inventoryAssetValue),
    ],
  );
}
