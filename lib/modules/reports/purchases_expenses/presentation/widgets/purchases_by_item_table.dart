import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_item_table.dart';

class PurchasesByItemRow {
  final String itemName;
  final double quantityPurchased;
  final double amount;
  final double averagePrice;
  final List<PurchaseDetailsForItemRow> details;

  const PurchasesByItemRow({
    required this.itemName,
    required this.quantityPurchased,
    required this.amount,
    required this.averagePrice,
    this.details = const <PurchaseDetailsForItemRow>[],
  });

  factory PurchasesByItemRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final purchaseValues = item['purchases'];
    final detailRows = purchaseValues is List
        ? purchaseValues
              .whereType<Map>()
              .map(
                (purchase) => PurchaseDetailsForItemRow.fromJson(
                  Map<String, dynamic>.from(purchase),
                ),
              )
              .toList(growable: false)
        : const <PurchaseDetailsForItemRow>[];

    return PurchasesByItemRow(
      itemName: item['itemName']?.toString() ?? '-',
      quantityPurchased: numberValue('quantityPurchased'),
      amount: numberValue('amount'),
      averagePrice: numberValue('averagePrice'),
      details: detailRows,
    );
  }
}

class PurchasesByItemTable extends StatefulWidget {
  final List<PurchasesByItemRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PurchasesByItemRow>? onItemSelected;

  const PurchasesByItemTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.onItemSelected,
  });

  @override
  State<PurchasesByItemTable> createState() => _PurchasesByItemTableState();
}

class _PurchasesByItemTableState extends State<PurchasesByItemTable> {
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

  List<PurchasesByItemRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <PurchasesByItemRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _totalQuantityPurchased => widget.rows.fold<double>(
    0,
    (total, row) => total + row.quantityPurchased,
  );

  double get _totalAmount =>
      widget.rows.fold<double>(0, (total, row) => total + row.amount);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1180
            ? 1180.0
            : constraints.maxWidth;

        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: tableWidth > constraints.maxWidth,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: ReportStickyHeaderScrollTable(
                header: _buildHeader(),
                emptyBody: const SizedBox.shrink(),
                children: [
                  if (widget.rows.isEmpty)
                    const ReportTableEmptyBody(
                      minHeight: 260,
                      message:
                          'There are no purchases recorded for the selected date range.',
                    )
                  else
                    SizedBox(
                      height: 260,
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: _pageRows.length > 6,
                        child: ListView.separated(
                          controller: _verticalController,
                          itemCount: _pageRows.length + 1,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.borderLight,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _pageRows.length) {
                              return _buildTotalRow();
                            }
                            return _PurchasesByItemDataRow(
                              row: _pageRows[index],
                              quantityFormat: _quantityFormat,
                              currencyFormat: _currencyFormat,
                              onItemSelected: widget.onItemSelected,
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
      },
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
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        quantityPurchased: _headerText('QUANTITY PURCHASED', alignRight: true),
        amount: _headerText('AMOUNT', alignRight: true),
        averagePrice: _headerText('AVERAGE PRICE', alignRight: true),
      ),
    );
  }

  Widget _headerText(String value, {bool alignRight = false}) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: ReportTableTypography.header,
    );
  }

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        itemName: Text('Total', style: _totalStyle),
        quantityPurchased: Text(
          _quantityFormat.format(_totalQuantityPurchased),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amount: Text(
          _currencyFormat.format(_totalAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        averagePrice: const SizedBox.shrink(),
      ),
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );
}

class _PurchasesByItemDataRow extends StatefulWidget {
  final PurchasesByItemRow row;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;
  final ValueChanged<PurchasesByItemRow>? onItemSelected;

  const _PurchasesByItemDataRow({
    required this.row,
    required this.quantityFormat,
    required this.currencyFormat,
    required this.onItemSelected,
  });

  @override
  State<_PurchasesByItemDataRow> createState() =>
      _PurchasesByItemDataRowState();
}

class _PurchasesByItemDataRowState extends State<_PurchasesByItemDataRow> {
  bool _isHovered = false;

  bool get _isClickable => widget.onItemSelected != null;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _handlePressed() {
    widget.onItemSelected?.call(widget.row);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
      child: _buildTableRow(
        itemName: Text(row.itemName, style: AppTheme.tableCell),
        quantityPurchased: Text(
          widget.quantityFormat.format(row.quantityPurchased),
          textAlign: TextAlign.right,
          style: AppTheme.tableCell,
        ),
        amount: _amountText(row.amount),
        averagePrice: Text(
          widget.currencyFormat.format(row.averagePrice),
          textAlign: TextAlign.right,
          style: AppTheme.tableCell,
        ),
      ),
    );

    if (!_isClickable) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handlePressed,
        child: content,
      ),
    );
  }

  Widget _amountText(double value) {
    return Text(
      widget.currencyFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget quantityPurchased,
  required Widget amount,
  required Widget averagePrice,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 5, child: itemName),
      Expanded(flex: 4, child: quantityPurchased),
      Expanded(flex: 4, child: amount),
      Expanded(flex: 4, child: averagePrice),
    ],
  );
}
