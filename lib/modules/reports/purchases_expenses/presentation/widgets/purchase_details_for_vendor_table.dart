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

class PurchaseDetailsForVendorRow {
  final String status;
  final String date;
  final String accountName;
  final String transactionNumber;
  final double amountValue;
  final double amountWithTaxValue;
  final double balanceAmountValue;

  const PurchaseDetailsForVendorRow({
    required this.status,
    required this.date,
    required this.accountName,
    required this.transactionNumber,
    required this.amountValue,
    required this.amountWithTaxValue,
    required this.balanceAmountValue,
  });

  factory PurchaseDetailsForVendorRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String textValue(String key, [String fallback = '-']) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return PurchaseDetailsForVendorRow(
      status: textValue('status'),
      date: textValue('date'),
      accountName: textValue('accountName'),
      transactionNumber: textValue('transactionNumber', '--'),
      amountValue: numberValue('amount'),
      amountWithTaxValue: numberValue('amountWithTax'),
      balanceAmountValue: numberValue('balanceAmount'),
    );
  }

  String get amount => _currencyFormat.format(amountValue);
  String get amountWithTax => _currencyFormat.format(amountWithTaxValue);
  String get balanceAmount => _currencyFormat.format(balanceAmountValue);
}

class PurchaseDetailsForVendorTable extends StatefulWidget {
  final List<PurchaseDetailsForVendorRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const PurchaseDetailsForVendorTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<PurchaseDetailsForVendorTable> createState() =>
      _PurchaseDetailsForVendorTableState();
}

class _PurchaseDetailsForVendorTableState
    extends State<PurchaseDetailsForVendorTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<PurchaseDetailsForVendorRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <PurchaseDetailsForVendorRow>[];
    }
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _totalAmount =>
      widget.rows.fold<double>(0, (total, row) => total + row.amountValue);

  double get _totalAmountWithTax => widget.rows.fold<double>(
    0,
    (total, row) => total + row.amountWithTaxValue,
  );

  double get _totalBalanceAmount => widget.rows.fold<double>(
    0,
    (total, row) => total + row.balanceAmountValue,
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
          width: 1380,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 300,
                child: widget.rows.isEmpty
                    ? const ReportTableEmptyBody(
                        minHeight: 300,
                        message: 'No data to display',
                      )
                    : Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: _pageRows.length > 7,
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
                            return _PurchaseDetailsForVendorDataRow(
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
        accountName: _headerText('ACCOUNT NAME'),
        transactionNumber: _headerText('TRANSACTION#'),
        amount: _headerText('AMOUNT', alignRight: true),
        amountWithTax: _headerText('AMOUNT WITH TAX', alignRight: true),
        balanceAmount: _headerText('BALANCE AMOUNT', alignRight: true),
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
        status: Text('Total', style: _totalStyle),
        date: const SizedBox.shrink(),
        accountName: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
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
        balanceAmount: Text(
          _currencyFormat.format(_totalBalanceAmount),
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

class _PurchaseDetailsForVendorDataRow extends StatefulWidget {
  final PurchaseDetailsForVendorRow row;

  const _PurchaseDetailsForVendorDataRow({required this.row});

  @override
  State<_PurchaseDetailsForVendorDataRow> createState() =>
      _PurchaseDetailsForVendorDataRowState();
}

class _PurchaseDetailsForVendorDataRowState
    extends State<_PurchaseDetailsForVendorDataRow> {
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
          status: _plainText(row.status),
          date: _plainText(row.date),
          accountName: _linkText(row.accountName),
          transactionNumber: _plainText(row.transactionNumber),
          amount: _amountText(row.amount),
          amountWithTax: _amountText(row.amountWithTax),
          balanceAmount: _amountText(row.balanceAmount),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppTheme.tableCell.copyWith(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w600,
          decoration: _isHovered
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
        overflow: TextOverflow.ellipsis,
      ),
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
  required Widget status,
  required Widget date,
  required Widget accountName,
  required Widget transactionNumber,
  required Widget amount,
  required Widget amountWithTax,
  required Widget balanceAmount,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: status),
      Expanded(flex: 3, child: date),
      Expanded(flex: 4, child: accountName),
      Expanded(flex: 4, child: transactionNumber),
      Expanded(flex: 4, child: amount),
      Expanded(flex: 4, child: amountWithTax),
      Expanded(flex: 4, child: balanceAmount),
    ],
  );
}
