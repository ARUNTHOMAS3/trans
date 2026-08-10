import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  symbol: '\u20B9',
  decimalDigits: 2,
);

class ExpenseDetailsRow {
  final String status;
  final String date;
  final String transactionType;
  final String transactionNumber;
  final String distance;
  final String vendorName;
  final String category;
  final String customerName;
  final String notes;
  final double amountValue;
  final double amountWithTaxValue;

  const ExpenseDetailsRow({
    required this.status,
    required this.date,
    required this.transactionType,
    required this.transactionNumber,
    required this.distance,
    required this.vendorName,
    required this.category,
    required this.customerName,
    required this.notes,
    required this.amountValue,
    required this.amountWithTaxValue,
  });

  factory ExpenseDetailsRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String textValue(String key, [String fallback = '-']) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return ExpenseDetailsRow(
      status: textValue('status'),
      date: textValue('date'),
      transactionType: textValue('transactionType', 'Expense'),
      transactionNumber: textValue('transactionNumber', ''),
      distance: textValue('distance', '0 Kilometer(s)'),
      vendorName: textValue('vendorName'),
      category: textValue('category'),
      customerName: textValue('customerName'),
      notes: textValue('notes', ''),
      amountValue: numberValue('amountValue'),
      amountWithTaxValue: numberValue('amountWithTaxValue'),
    );
  }
}

class ExpenseDetailsTable extends StatefulWidget {
  final List<ExpenseDetailsRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final bool categoryDetailMode;
  final bool customerDetailMode;

  const ExpenseDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.categoryDetailMode = false,
    this.customerDetailMode = false,
  });

  @override
  State<ExpenseDetailsTable> createState() => _ExpenseDetailsTableState();
}

class _ExpenseDetailsTableState extends State<ExpenseDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<ExpenseDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <ExpenseDetailsRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _totalAmount =>
      widget.rows.fold<double>(0, (total, row) => total + row.amountValue);

  double get _totalAmountWithTax => widget.rows.fold<double>(
    0,
    (total, row) => total + row.amountWithTaxValue,
  );

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
          width: widget.categoryDetailMode || widget.customerDetailMode
              ? 1380
              : 1600,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 260,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: _pageRows.length > 6,
                  child: ListView.separated(
                    controller: _verticalController,
                    itemCount: _pageRows.length + 1,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) {
                      if (index == _pageRows.length) return _buildTotalRow();
                      return _ExpenseDetailsDataRow(
                        row: _pageRows[index],
                        categoryDetailMode: widget.categoryDetailMode,
                        customerDetailMode: widget.customerDetailMode,
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
    if (widget.categoryDetailMode) {
      return _buildCategoryDetailHeader();
    }
    if (widget.customerDetailMode) {
      return _buildCustomerDetailHeader();
    }

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
        status: _headerText('STATUS'),
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        transactionType: _headerText('TRANSACTION TYPE'),
        transactionNumber: _headerText('TRANSACTION#'),
        distance: _headerText('DISTANCE', alignRight: true),
        vendorName: _headerText('VENDOR NAME'),
        category: _headerText('CATEGORY'),
        customerName: _headerText('CUSTOMER NAME'),
        amount: _headerText('AMOUNT', alignRight: true),
        amountWithTax: _headerText('AMOUNT WITH TAX', alignRight: true),
      ),
    );
  }

  Widget _buildCategoryDetailHeader() {
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
      child: _buildCategoryDetailTableRow(
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        transactionType: _headerText('TYPE'),
        customerName: _headerText('CUSTOMER NAME'),
        vendorName: _headerText('VENDOR NAME'),
        amount: _headerText('AMOUNT', alignRight: true),
        amountWithTax: _headerText('AMOUNT WITH TAX', alignRight: true),
      ),
    );
  }

  Widget _buildCustomerDetailHeader() {
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
      child: _buildCustomerDetailTableRow(
        status: _headerText('STATUS'),
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        referenceNumber: _headerText('REFERENCE#'),
        category: _headerText('CATEGORY'),
        notes: _headerText('NOTES'),
        amount: _headerText('AMOUNT', alignRight: true),
        amountWithTax: _headerText('AMOUNT WITH TAX', alignRight: true),
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
    if (widget.categoryDetailMode) {
      return _buildCategoryDetailTotalRow();
    }
    if (widget.customerDetailMode) {
      return _buildCustomerDetailTotalRow();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      color: AppTheme.tableHeaderBg,
      child: _buildTableRow(
        status: Text('Total', style: _totalStyle),
        date: const SizedBox.shrink(),
        transactionType: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        distance: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        category: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        amount: Text(
          _currencyFormat.format(_totalAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amountWithTax: Text(
          _currencyFormat.format(_totalAmountWithTax),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
      ),
    );
  }

  Widget _buildCategoryDetailTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      color: AppTheme.backgroundColor,
      child: _buildCategoryDetailTableRow(
        date: Text('Total', style: _totalStyle),
        transactionType: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        amount: Text(
          _currencyFormat.format(_totalAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amountWithTax: Text(
          _currencyFormat.format(_totalAmountWithTax),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
      ),
    );
  }

  Widget _buildCustomerDetailTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      color: AppTheme.backgroundColor,
      child: _buildCustomerDetailTableRow(
        status: Text('Total', style: _totalStyle),
        date: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        category: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        amount: Text(
          _currencyFormat.format(_totalAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amountWithTax: Text(
          _currencyFormat.format(_totalAmountWithTax),
          textAlign: TextAlign.right,
          style: _totalStyle,
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

class _ExpenseDetailsDataRow extends StatefulWidget {
  final ExpenseDetailsRow row;
  final bool categoryDetailMode;
  final bool customerDetailMode;

  const _ExpenseDetailsDataRow({
    required this.row,
    required this.categoryDetailMode,
    required this.customerDetailMode,
  });

  @override
  State<_ExpenseDetailsDataRow> createState() => _ExpenseDetailsDataRowState();
}

class _ExpenseDetailsDataRowState extends State<_ExpenseDetailsDataRow> {
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
        child: widget.categoryDetailMode
            ? _buildCategoryDetailTableRow(
                date: _plainText(row.date),
                transactionType: _plainText(row.transactionType),
                customerName: _plainText(row.customerName),
                vendorName: _plainText(row.vendorName),
                amount: _blueAmountText(
                  _currencyFormat.format(row.amountValue),
                ),
                amountWithTax: _blueAmountText(
                  _currencyFormat.format(row.amountWithTaxValue),
                ),
              )
            : widget.customerDetailMode
            ? _buildCustomerDetailTableRow(
                status: _plainText(row.status),
                date: _plainText(row.date),
                referenceNumber: _plainText(row.transactionNumber),
                category: _plainText(row.category),
                notes: _plainText(row.notes),
                amount: _blueAmountText(
                  _currencyFormat.format(row.amountValue),
                ),
                amountWithTax: _blueAmountText(
                  _currencyFormat.format(row.amountWithTaxValue),
                ),
              )
            : _buildTableRow(
                status: _plainText(row.status),
                date: _plainText(row.date),
                transactionType: _plainText(row.transactionType),
                transactionNumber: _plainText(row.transactionNumber),
                distance: _plainText(row.distance, alignRight: true),
                vendorName: _plainText(row.vendorName),
                category: _plainText(row.category),
                customerName: _plainText(row.customerName),
                amount: _blueAmountText(
                  _currencyFormat.format(row.amountValue),
                ),
                amountWithTax: _blueAmountText(
                  _currencyFormat.format(row.amountWithTaxValue),
                ),
              ),
      ),
    );
  }

  Widget _plainText(String value, {bool alignRight = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
    );
  }

  Widget _blueAmountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget date,
  required Widget transactionType,
  required Widget transactionNumber,
  required Widget distance,
  required Widget vendorName,
  required Widget category,
  required Widget customerName,
  required Widget amount,
  required Widget amountWithTax,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: status),
      Expanded(flex: 3, child: date),
      Expanded(flex: 4, child: transactionType),
      Expanded(flex: 4, child: transactionNumber),
      Expanded(flex: 3, child: distance),
      Expanded(flex: 3, child: vendorName),
      Expanded(flex: 4, child: category),
      Expanded(flex: 4, child: customerName),
      Expanded(flex: 3, child: amount),
      Expanded(flex: 3, child: amountWithTax),
    ],
  );
}

Widget _buildCategoryDetailTableRow({
  required Widget date,
  required Widget transactionType,
  required Widget customerName,
  required Widget vendorName,
  required Widget amount,
  required Widget amountWithTax,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 4, child: date),
      Expanded(flex: 4, child: transactionType),
      Expanded(flex: 5, child: customerName),
      Expanded(flex: 5, child: vendorName),
      Expanded(flex: 4, child: amount),
      Expanded(flex: 4, child: amountWithTax),
    ],
  );
}

Widget _buildCustomerDetailTableRow({
  required Widget status,
  required Widget date,
  required Widget referenceNumber,
  required Widget category,
  required Widget notes,
  required Widget amount,
  required Widget amountWithTax,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: status),
      Expanded(flex: 3, child: date),
      Expanded(flex: 4, child: referenceNumber),
      Expanded(flex: 4, child: category),
      Expanded(flex: 5, child: notes),
      Expanded(flex: 4, child: amount),
      Expanded(flex: 4, child: amountWithTax),
    ],
  );
}
