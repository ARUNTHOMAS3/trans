import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class PaymentsReceivedRow {
  final String paymentNumber;
  final String date;
  final String status;
  final String referenceNumber;
  final String customerName;
  final String paymentMode;
  final String notes;
  final String invoiceNumber;
  final String depositTo;
  final String amountFcy;
  final String unusedAmountFcy;
  final String amountBcy;
  final String unusedAmountBcy;
  final String placeOfSupply;

  const PaymentsReceivedRow({
    required this.paymentNumber,
    required this.date,
    required this.status,
    required this.referenceNumber,
    required this.customerName,
    required this.paymentMode,
    required this.notes,
    required this.invoiceNumber,
    required this.depositTo,
    required this.amountFcy,
    required this.unusedAmountFcy,
    required this.amountBcy,
    required this.unusedAmountBcy,
    required this.placeOfSupply,
  });
  factory PaymentsReceivedRow.fromJson(Map<String, dynamic> json) {
    final amountReceived = _parseNumber(json['amountReceived']);
    final excessAmount = _parseNumber(json['excessAmount']);
    return PaymentsReceivedRow(
      paymentNumber: _text(json['paymentNumber']),
      date: _text(json['date']),
      status: _formatStatus(_text(json['status'])),
      referenceNumber: _text(json['referenceNumber']),
      customerName: _text(json['customerName']),
      paymentMode: _text(json['paymentMode']),
      notes: _text(json['notes'], fallback: ''),
      invoiceNumber: _text(json['invoiceNumber']),
      depositTo: _text(json['depositTo']),
      amountFcy: _formatCurrency(amountReceived),
      unusedAmountFcy: _formatCurrency(excessAmount),
      amountBcy: _formatCurrency(amountReceived),
      unusedAmountBcy: _formatCurrency(excessAmount),
      placeOfSupply: _text(json['placeOfSupply'], fallback: ''),
    );
  }

  static double _parseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String _text(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _formatStatus(String value) {
    if (value == '-') return value;
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _formatCurrency(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 2,
  ).format(value);
}

class PaymentsReceivedTable extends StatefulWidget {
  final List<PaymentsReceivedRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;
  final String amountBcyTotal;
  final String unusedAmountBcyTotal;

  const PaymentsReceivedTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
    required this.amountBcyTotal,
    required this.unusedAmountBcyTotal,
  });

  @override
  State<PaymentsReceivedTable> createState() => _PaymentsReceivedTableState();
}

class _PaymentsReceivedTableState extends State<PaymentsReceivedTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<PaymentsReceivedRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <PaymentsReceivedRow>[];
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
          width: 2100,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 250,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _verticalController,
                    itemCount: _pageRows.length + (_isGrouped ? 3 : 1),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) {
                      if (_isGrouped && index == 0) {
                        return _buildAppliedGroupRow();
                      }
                      final currentIndex = _isGrouped ? 1 : 0;
                      if (_isGrouped && index == currentIndex) {
                        return _buildCurrentGroupRow();
                      }
                      final totalIndex = _pageRows.length + (_isGrouped ? 2 : 0);
                      if (index == totalIndex) return _buildTotalRow();
                      final rowIndex = index - (_isGrouped ? 2 : 0);
                      return _PaymentsReceivedDataRow(row: _pageRows[rowIndex]);
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

  String _groupDisplayValue() {
    switch (widget.groupBy) {
      case 'Customer Name':
        return 'Customer Name - Not mentioned';
      case 'Payment Mode':
        return 'Cash';
      case 'Created By':
        return 'Created By - Not mentioned';
      case 'Payment Type':
        return 'Invoice Payment';
      case 'Currency':
        return 'INR';
      default:
        return widget.groupBy;
    }
  }

  Widget _buildAppliedGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        paymentNumber: Text(_groupDisplayValue(), style: _groupStyle),
        date: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        paymentMode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        invoiceNumber: const SizedBox.shrink(),
        depositTo: const SizedBox.shrink(),
        amountFcy: const SizedBox.shrink(),
        unusedAmountFcy: const SizedBox.shrink(),
        amountBcy: Text(
          widget.amountBcyTotal,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        unusedAmountBcy: Text(
          widget.unusedAmountBcyTotal,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        placeOfSupply: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCurrentGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        paymentNumber: Text('Current', style: _groupStyle),
        date: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        paymentMode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        invoiceNumber: const SizedBox.shrink(),
        depositTo: const SizedBox.shrink(),
        amountFcy: const SizedBox.shrink(),
        unusedAmountFcy: const SizedBox.shrink(),
        amountBcy: Text(
          widget.amountBcyTotal,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        unusedAmountBcy: Text(
          widget.unusedAmountBcyTotal,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        placeOfSupply: const SizedBox.shrink(),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
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
        paymentNumber: _headerText('PAYMENT NUMBER'),
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
        status: _headerText('STATUS'),
        referenceNumber: _headerText('REFERENCE NUMBER'),
        customerName: _headerText('CUSTOMER NAME'),
        paymentMode: _headerText('PAYMENT MODE'),
        notes: _headerText('NOTES'),
        invoiceNumber: _headerText('INVOICE#'),
        depositTo: _headerText('DEPOSIT TO'),
        amountFcy: _headerText('AMOUNT (FCY)', alignRight: true),
        unusedAmountFcy: _headerText('UNUSED AMOUNT (FCY)', alignRight: true),
        amountBcy: _headerText('AMOUNT (BCY)', alignRight: true),
        unusedAmountBcy: _headerText('UNUSED AMOUNT (BCY)', alignRight: true),
        placeOfSupply: _headerText('PLACE OF SUPPLY'),
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
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: _buildTableRow(
        paymentNumber: Text('Total', style: _totalStyle),
        date: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        paymentMode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        invoiceNumber: const SizedBox.shrink(),
        depositTo: const SizedBox.shrink(),
        amountFcy: const SizedBox.shrink(),
        unusedAmountFcy: const SizedBox.shrink(),
        amountBcy: Text(
          widget.amountBcyTotal,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        unusedAmountBcy: Text(
          widget.unusedAmountBcyTotal,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        placeOfSupply: const SizedBox.shrink(),
      ),
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );
}

class _PaymentsReceivedDataRow extends StatefulWidget {
  final PaymentsReceivedRow row;

  const _PaymentsReceivedDataRow({required this.row});

  @override
  State<_PaymentsReceivedDataRow> createState() =>
      _PaymentsReceivedDataRowState();
}

class _PaymentsReceivedDataRowState extends State<_PaymentsReceivedDataRow> {
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
          paymentNumber: Text(row.paymentNumber, style: AppTheme.tableCell),
          date: Text(row.date, style: AppTheme.tableCell),
          status: Text(row.status, style: AppTheme.tableCell),
          referenceNumber: Text(row.referenceNumber, style: AppTheme.tableCell),
          customerName: _linkText(row.customerName),
          paymentMode: Text(row.paymentMode, style: AppTheme.tableCell),
          notes: Text(row.notes, style: AppTheme.tableCell),
          invoiceNumber: Text(row.invoiceNumber, style: AppTheme.tableCell),
          depositTo: Text(row.depositTo, style: AppTheme.tableCell),
          amountFcy: _blueAmountText(row.amountFcy),
          unusedAmountFcy: _blueAmountText(row.unusedAmountFcy),
          amountBcy: _blueAmountText(row.amountBcy),
          unusedAmountBcy: _blueAmountText(row.unusedAmountBcy),
          placeOfSupply: Text(row.placeOfSupply, style: AppTheme.tableCell),
        ),
      ),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }

  Widget _blueAmountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget paymentNumber,
  required Widget date,
  required Widget status,
  required Widget referenceNumber,
  required Widget customerName,
  required Widget paymentMode,
  required Widget notes,
  required Widget invoiceNumber,
  required Widget depositTo,
  required Widget amountFcy,
  required Widget unusedAmountFcy,
  required Widget amountBcy,
  required Widget unusedAmountBcy,
  required Widget placeOfSupply,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: paymentNumber),
      Expanded(flex: 3, child: date),
      Expanded(flex: 3, child: status),
      Expanded(flex: 4, child: referenceNumber),
      Expanded(flex: 4, child: customerName),
      Expanded(flex: 3, child: paymentMode),
      Expanded(flex: 3, child: notes),
      Expanded(flex: 3, child: invoiceNumber),
      Expanded(flex: 4, child: depositTo),
      Expanded(flex: 4, child: amountFcy),
      Expanded(flex: 5, child: unusedAmountFcy),
      Expanded(flex: 4, child: amountBcy),
      Expanded(flex: 5, child: unusedAmountBcy),
      Expanded(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.only(left: AppTheme.space16),
          child: placeOfSupply,
        ),
      ),
    ],
  );
}
