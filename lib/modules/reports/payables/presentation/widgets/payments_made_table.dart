import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class PaymentsMadeRow {
  final String paymentMadeId;
  final String paymentDate;
  final String referenceNumber;
  final String billNumber;
  final String vendorName;
  final String paymentMode;
  final String notes;
  final String paidThrough;
  final String status;
  final double amount;
  final double amountFcy;
  final double unusedAmountBcy;
  final double unusedAmountFcy;

  const PaymentsMadeRow({
    required this.paymentMadeId,
    required this.paymentDate,
    required this.referenceNumber,
    required this.billNumber,
    required this.vendorName,
    required this.paymentMode,
    required this.notes,
    required this.paidThrough,
    required this.status,
    required this.amount,
    required this.amountFcy,
    required this.unusedAmountBcy,
    required this.unusedAmountFcy,
  });

  static List<PaymentsMadeRow> fromResponse(
    Map<String, dynamic>? response,
    DateFormat dateFormat,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <PaymentsMadeRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => PaymentsMadeRow.fromJson(
            Map<String, dynamic>.from(raw),
            dateFormat,
          ),
        )
        .toList(growable: false);
  }

  factory PaymentsMadeRow.fromJson(
    Map<String, dynamic> json,
    DateFormat dateFormat,
  ) {
    return PaymentsMadeRow(
      paymentMadeId: _stringValue(json['paymentMadeId']),
      paymentDate: _formatDate(json['paymentDate'], dateFormat),
      referenceNumber: _stringValue(json['referenceNumber']),
      billNumber: _stringValue(json['billNumber']),
      vendorName: _stringValue(json['vendorName'], fallback: '-'),
      paymentMode: _stringValue(json['paymentMode'], fallback: '-'),
      notes: _stringValue(json['notes']),
      paidThrough: _stringValue(json['paidThrough'], fallback: '-'),
      status: _titleCase(_stringValue(json['status'], fallback: 'Paid')),
      amount: _doubleValue(json['paymentAmount']),
      amountFcy: _doubleValue(json['amountFcy']),
      unusedAmountBcy: _doubleValue(json['excessAmount']),
      unusedAmountFcy: _doubleValue(json['excessAmountFcy']),
    );
  }
}

class PaymentsMadeTotals {
  final double amount;
  final double amountFcy;
  final double unusedAmountBcy;
  final double unusedAmountFcy;
  final double totalAllocated;
  final double totalRefunded;

  const PaymentsMadeTotals({
    required this.amount,
    required this.amountFcy,
    required this.unusedAmountBcy,
    required this.unusedAmountFcy,
    required this.totalAllocated,
    required this.totalRefunded,
  });

  factory PaymentsMadeTotals.fromResponse(Map<String, dynamic>? response) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return PaymentsMadeTotals(
      amount: _doubleValue(totals['paymentAmount']),
      amountFcy: _doubleValue(totals['amountFcy']),
      unusedAmountBcy: _doubleValue(totals['excessAmount']),
      unusedAmountFcy: _doubleValue(totals['excessAmountFcy']),
      totalAllocated: _doubleValue(totals['totalAllocated']),
      totalRefunded: _doubleValue(totals['totalRefunded']),
    );
  }
}

class PaymentsMadeTable extends StatefulWidget {
  final List<PaymentsMadeRow> rows;
  final PaymentsMadeTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const PaymentsMadeTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.currencyFormat,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
  });

  @override
  State<PaymentsMadeTable> createState() => _PaymentsMadeTableState();
}

class _PaymentsMadeTableState extends State<PaymentsMadeTable> {
  final ScrollController _horizontalController = ScrollController();

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1760
            ? 1760.0
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
                      minHeight: 300,
                      message: 'No data to display',
                    )
                  else ...[
                    if (_isGrouped) ...[
                      _buildAppliedGroupRow(),
                      _buildCurrentGroupRow(),
                    ],
                    for (final row in widget.rows)
                      _PaymentsMadeDataRow(
                        row: row,
                        currencyFormat: widget.currencyFormat,
                      ),
                    _PaymentsMadeTotalRow(
                      totals: widget.totals,
                      currencyFormat: widget.currencyFormat,
                    ),
                  ],
                  ReportPaginationFooter(
                    totalCount: widget.totalCount,
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
        billNumber: _headerText('BILL#'),
        vendorName: _headerText('VENDOR NAME'),
        paymentMode: _headerText('PAYMENT MODE'),
        notes: _headerText('NOTES'),
        paidThrough: _headerText('PAID THROUGH'),
        status: _headerText('STATUS'),
        amount: _headerText('AMOUNT', alignRight: true),
        amountFcy: _headerText('AMOUNT (FCY)', alignRight: true),
        unusedAmountBcy: _headerText('UNUSED AMOUNT (BCY)', alignRight: true),
        unusedAmountFcy: _headerText('UNUSED AMOUNT (FCY)', alignRight: true),
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

  String _groupDisplayValue() {
    switch (widget.groupBy) {
      case 'Date':
        return '03-08-2026';
      case 'Vendor Name':
        return 'Vendor Name - Not mentioned';
      case 'Payment Type':
        return 'Bill Payment';
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
        date: Text(_groupDisplayValue(), style: _groupStyle),
        referenceNumber: const SizedBox.shrink(),
        billNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        paymentMode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        paidThrough: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        amount: _totalAmountText(widget.totals.amount, widget.currencyFormat),
        amountFcy: _totalAmountText(widget.totals.amountFcy, widget.currencyFormat),
        unusedAmountBcy: _totalAmountText(widget.totals.unusedAmountBcy, widget.currencyFormat),
        unusedAmountFcy: _totalAmountText(widget.totals.unusedAmountFcy, widget.currencyFormat),
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
        date: Text('Current', style: _groupStyle),
        referenceNumber: const SizedBox.shrink(),
        billNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        paymentMode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        paidThrough: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        amount: _totalAmountText(widget.totals.amount, widget.currencyFormat),
        amountFcy: _totalAmountText(widget.totals.amountFcy, widget.currencyFormat),
        unusedAmountBcy: _totalAmountText(widget.totals.unusedAmountBcy, widget.currencyFormat),
        unusedAmountFcy: _totalAmountText(widget.totals.unusedAmountFcy, widget.currencyFormat),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      );
}

class _PaymentsMadeDataRow extends StatefulWidget {
  final PaymentsMadeRow row;
  final NumberFormat currencyFormat;

  const _PaymentsMadeDataRow({required this.row, required this.currencyFormat});

  @override
  State<_PaymentsMadeDataRow> createState() => _PaymentsMadeDataRowState();
}

class _PaymentsMadeDataRowState extends State<_PaymentsMadeDataRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: _buildTableRow(
          date: _bodyText(row.paymentDate),
          referenceNumber: _bodyText(row.referenceNumber),
          billNumber: _bodyText(row.billNumber, maxLines: 4),
          vendorName: _linkText(row.vendorName, hovered: _isHovered),
          paymentMode: _bodyText(row.paymentMode),
          notes: _bodyText(row.notes),
          paidThrough: _bodyText(row.paidThrough, maxLines: 2),
          status: _bodyText(row.status),
          amount: _linkText(
            widget.currencyFormat.format(row.amount),
            hovered: _isHovered,
            alignRight: true,
          ),
          amountFcy: _linkText(
            widget.currencyFormat.format(row.amountFcy),
            hovered: _isHovered,
            alignRight: true,
          ),
          unusedAmountBcy: _linkText(
            widget.currencyFormat.format(row.unusedAmountBcy),
            hovered: _isHovered,
            alignRight: true,
          ),
          unusedAmountFcy: _linkText(
            widget.currencyFormat.format(row.unusedAmountFcy),
            hovered: _isHovered,
            alignRight: true,
          ),
        ),
      ),
    );
  }
}

class _PaymentsMadeTotalRow extends StatelessWidget {
  final PaymentsMadeTotals totals;
  final NumberFormat currencyFormat;

  const _PaymentsMadeTotalRow({
    required this.totals,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        date: _totalLabel('Total'),
        referenceNumber: const SizedBox.shrink(),
        billNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        paymentMode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        paidThrough: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        amount: _totalAmountText(totals.amount, currencyFormat),
        amountFcy: _totalAmountText(totals.amountFcy, currencyFormat),
        unusedAmountBcy: _totalAmountText(
          totals.unusedAmountBcy,
          currencyFormat,
        ),
        unusedAmountFcy: _totalAmountText(
          totals.unusedAmountFcy,
          currencyFormat,
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget date,
  required Widget referenceNumber,
  required Widget billNumber,
  required Widget vendorName,
  required Widget paymentMode,
  required Widget notes,
  required Widget paidThrough,
  required Widget status,
  required Widget amount,
  required Widget amountFcy,
  required Widget unusedAmountBcy,
  required Widget unusedAmountFcy,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _tableCell(date, flex: 2),
      _tableCell(referenceNumber, flex: 3),
      _tableCell(billNumber, flex: 3),
      _tableCell(vendorName, flex: 4),
      _tableCell(paymentMode, flex: 3),
      _tableCell(notes, flex: 2),
      _tableCell(paidThrough, flex: 3),
      _tableCell(status, flex: 3),
      _tableCell(amount, flex: 3, alignRight: true),
      _tableCell(amountFcy, flex: 3, alignRight: true),
      _tableCell(unusedAmountBcy, flex: 4, alignRight: true),
      _tableCell(unusedAmountFcy, flex: 4, alignRight: true),
    ],
  );
}

Widget _tableCell(Widget child, {required int flex, bool alignRight = false}) {
  return Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.only(right: AppTheme.space20),
      child: alignRight
          ? Align(alignment: Alignment.centerRight, child: child)
          : child,
    ),
  );
}

Widget _bodyText(String value, {int maxLines = 1}) {
  final display = value.trim().isEmpty ? '' : value;
  return Text(
    display,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    ),
  );
}

Widget _linkText(
  String value, {
  required bool hovered,
  bool alignRight = false,
}) {
  return Text(
    value.trim().isEmpty ? '' : value,
    textAlign: alignRight ? TextAlign.right : TextAlign.left,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
      decoration: hovered ? TextDecoration.underline : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
      decorationThickness: 1,
    ),
  );
}

Widget _totalLabel(String value) {
  return Text(
    value,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
    ),
  );
}

Widget _totalAmountText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
    ),
  );
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatDate(Object? value, DateFormat dateFormat) {
  if (value is DateTime) return dateFormat.format(value);
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';
  final parsed = DateTime.tryParse(text);
  return parsed == null ? text : dateFormat.format(parsed);
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
