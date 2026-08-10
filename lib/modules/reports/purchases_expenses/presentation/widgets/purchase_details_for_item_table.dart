import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');
final NumberFormat _currencyFormat = NumberFormat.currency(
  symbol: '\u20B9',
  decimalDigits: 2,
);

class PurchaseDetailsForItemRow {
  final String vendorName;
  final double quantity;
  final double amount;
  final double averagePrice;

  const PurchaseDetailsForItemRow({
    required this.vendorName,
    required this.quantity,
    required this.amount,
    required this.averagePrice,
  });

  factory PurchaseDetailsForItemRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final quantity = numberValue('quantity');
    final amount = numberValue('lineTotal');

    return PurchaseDetailsForItemRow(
      vendorName: item['vendorName']?.toString().trim().isNotEmpty == true
          ? item['vendorName'].toString()
          : 'Others',
      quantity: quantity,
      amount: amount,
      averagePrice: quantity == 0 ? 0 : amount / quantity,
    );
  }
}

class PurchaseDetailsForItemTable extends StatefulWidget {
  final List<PurchaseDetailsForItemRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const PurchaseDetailsForItemTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<PurchaseDetailsForItemTable> createState() =>
      _PurchaseDetailsForItemTableState();
}

class _PurchaseDetailsForItemTableState
    extends State<PurchaseDetailsForItemTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<PurchaseDetailsForItemRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <PurchaseDetailsForItemRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _totalQuantity =>
      widget.rows.fold<double>(0, (total, row) => total + row.quantity);

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
                      message: 'No data to display',
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
                            return _PurchaseDetailsForItemDataRow(
                              row: _pageRows[index],
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
        vendorName: _headerText('VENDOR NAME'),
        quantity: _headerText('QUANTITY', alignRight: true),
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
      overflow: TextOverflow.ellipsis,
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
        vendorName: Text('Total', style: _totalStyle),
        quantity: Text(
          _quantityFormat.format(_totalQuantity),
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

class _PurchaseDetailsForItemDataRow extends StatefulWidget {
  final PurchaseDetailsForItemRow row;

  const _PurchaseDetailsForItemDataRow({required this.row});

  @override
  State<_PurchaseDetailsForItemDataRow> createState() =>
      _PurchaseDetailsForItemDataRowState();
}

class _PurchaseDetailsForItemDataRowState
    extends State<_PurchaseDetailsForItemDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
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
          vendorName: _linkText(row.vendorName),
          quantity: Text(
            _quantityFormat.format(row.quantity),
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
            overflow: TextOverflow.ellipsis,
          ),
          amount: _amountText(row.amount),
          averagePrice: Text(
            _currencyFormat.format(row.averagePrice),
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _amountText(double value) {
    return Text(
      _currencyFormat.format(value),
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
  required Widget vendorName,
  required Widget quantity,
  required Widget amount,
  required Widget averagePrice,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 5, child: vendorName),
      Expanded(flex: 4, child: quantity),
      Expanded(flex: 4, child: amount),
      Expanded(flex: 4, child: averagePrice),
    ],
  );
}
