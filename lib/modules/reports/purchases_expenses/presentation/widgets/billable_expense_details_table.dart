import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  symbol: '\u20B9',
  decimalDigits: 2,
);

class BillableExpenseDetailsRow {
  final String date;
  final String transactionNumber;
  final String vendorName;
  final String itemName;
  final double itemAmountValue;
  final double markupValue;
  final double invoiceItemAmountValue;
  final double markedUpAmountValue;
  final double grossProfitValue;

  const BillableExpenseDetailsRow({
    required this.date,
    required this.transactionNumber,
    required this.vendorName,
    required this.itemName,
    required this.itemAmountValue,
    required this.markupValue,
    required this.invoiceItemAmountValue,
    required this.markedUpAmountValue,
    required this.grossProfitValue,
  });

  factory BillableExpenseDetailsRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String textValue(String key, [String fallback = '-']) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return BillableExpenseDetailsRow(
      date: textValue('date'),
      transactionNumber: textValue('transactionNumber', ''),
      vendorName: textValue('vendorName'),
      itemName: textValue('itemName'),
      itemAmountValue: numberValue('itemAmount'),
      markupValue: numberValue('markup'),
      invoiceItemAmountValue: numberValue('invoiceItemAmount'),
      markedUpAmountValue: numberValue('markedUpAmount'),
      grossProfitValue: numberValue('grossProfit'),
    );
  }

  String get itemAmount => _currencyFormat.format(itemAmountValue);
  String get markup => markupValue.toStringAsFixed(2);
  String get invoiceItemAmount =>
      _currencyFormat.format(invoiceItemAmountValue);
  String get markedUpAmount => _currencyFormat.format(markedUpAmountValue);
  String get grossProfit => _currencyFormat.format(grossProfitValue);
}

class BillableExpenseDetailsTable extends StatefulWidget {
  final List<BillableExpenseDetailsRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const BillableExpenseDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<BillableExpenseDetailsTable> createState() =>
      _BillableExpenseDetailsTableState();
}

class _BillableExpenseDetailsTableState
    extends State<BillableExpenseDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<BillableExpenseDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <BillableExpenseDetailsRow>[];
    }
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _totalItemAmount =>
      widget.rows.fold<double>(0, (total, row) => total + row.itemAmountValue);

  double get _totalInvoiceItemAmount => widget.rows.fold<double>(
    0,
    (total, row) => total + row.invoiceItemAmountValue,
  );

  double get _totalMarkedUpAmount => widget.rows.fold<double>(
    0,
    (total, row) => total + row.markedUpAmountValue,
  );

  double get _totalGrossProfit =>
      widget.rows.fold<double>(0, (total, row) => total + row.grossProfitValue);

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
          width: 1500,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 300,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: _pageRows.length > 7,
                  child: _pageRows.isEmpty
                      ? SingleChildScrollView(
                          controller: _verticalController,
                          child: const ReportTableEmptyBody(
                            minHeight: 300,
                            message: 'No data to display',
                          ),
                        )
                      : ListView.separated(
                          controller: _verticalController,
                          itemCount: _pageRows.length + 1,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.borderLight,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _pageRows.length) {
                              return _buildGrandTotalRow();
                            }
                            return _BillableExpenseDetailsDataRow(
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
        date: _headerText('DATE'),
        transactionNumber: _headerText('TRANSACTION#'),
        vendorName: _headerText('VENDOR NAME'),
        itemName: _headerText('ITEM NAME'),
        itemAmount: _headerText('ITEM AMOUNT (BCY)', alignRight: true),
        markup: _headerText('MARKUP (%)', alignRight: true),
        invoiceItemAmount: _headerText(
          'INVOICE ITEM AMOUNT...',
          alignRight: true,
        ),
        markedUpAmount: _headerText('MARKED UP AMOUNT', alignRight: true),
        grossProfit: _headerText('GROSS PROFIT', alignRight: true),
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

  Widget _buildGrandTotalRow() {
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
        date: Text('Total', style: _totalStyle),
        transactionNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        itemName: const SizedBox.shrink(),
        itemAmount: Text(
          _currencyFormat.format(_totalItemAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
          overflow: TextOverflow.ellipsis,
        ),
        markup: const SizedBox.shrink(),
        invoiceItemAmount: Text(
          _currencyFormat.format(_totalInvoiceItemAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
          overflow: TextOverflow.ellipsis,
        ),
        markedUpAmount: Text(
          _currencyFormat.format(_totalMarkedUpAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
          overflow: TextOverflow.ellipsis,
        ),
        grossProfit: Text(
          _currencyFormat.format(_totalGrossProfit),
          textAlign: TextAlign.right,
          style: _totalStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );
}

class _BillableExpenseDetailsDataRow extends StatefulWidget {
  final BillableExpenseDetailsRow row;

  const _BillableExpenseDetailsDataRow({required this.row});

  @override
  State<_BillableExpenseDetailsDataRow> createState() =>
      _BillableExpenseDetailsDataRowState();
}

class _BillableExpenseDetailsDataRowState
    extends State<_BillableExpenseDetailsDataRow> {
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
          date: _plainText(row.date),
          transactionNumber: _linkText(row.transactionNumber),
          vendorName: _plainText(row.vendorName),
          itemName: _plainText(row.itemName),
          itemAmount: _amountText(row.itemAmount),
          markup: _plainText(row.markup, alignRight: true),
          invoiceItemAmount: _amountText(row.invoiceItemAmount),
          markedUpAmount: _amountText(row.markedUpAmount),
          grossProfit: _amountText(row.grossProfit),
        ),
      ),
    );
  }

  Widget _plainText(String value, {bool alignRight = false}) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _amountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

Widget _buildTableRow({
  required Widget date,
  required Widget transactionNumber,
  required Widget vendorName,
  required Widget itemName,
  required Widget itemAmount,
  required Widget markup,
  required Widget invoiceItemAmount,
  required Widget markedUpAmount,
  required Widget grossProfit,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: date),
      Expanded(flex: 4, child: transactionNumber),
      Expanded(flex: 4, child: vendorName),
      Expanded(flex: 4, child: itemName),
      Expanded(flex: 4, child: itemAmount),
      Expanded(flex: 3, child: markup),
      Expanded(flex: 4, child: invoiceItemAmount),
      Expanded(flex: 4, child: markedUpAmount),
      Expanded(flex: 4, child: grossProfit),
    ],
  );
}
