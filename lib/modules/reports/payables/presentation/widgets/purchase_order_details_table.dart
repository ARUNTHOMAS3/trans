import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class PurchaseOrderDetailsTable extends StatefulWidget {
  final List<PurchaseOrderDetailsRow> rows;
  final PurchaseOrderDetailsTotals totals;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const PurchaseOrderDetailsTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.currencyFormat,
    required this.dateFormat,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
  });

  @override
  State<PurchaseOrderDetailsTable> createState() =>
      _PurchaseOrderDetailsTableState();
}

class _PurchaseOrderDetailsTableState extends State<PurchaseOrderDetailsTable> {
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
        final tableWidth = constraints.maxWidth < 1360
            ? 1360.0
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
                      _PurchaseOrderDetailsDataRow(
                        row: row,
                        dateFormat: widget.dateFormat,
                        currencyFormat: widget.currencyFormat,
                      ),
                    _PurchaseOrderDetailsTotalRow(
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
        status: _headerText('STATUS'),
        date: _headerText('DATE'),
        deliveryDate: _headerText('DELIVERY DATE'),
        purchaseOrderNumber: _headerText('P.O#'),
        vendorName: _headerText('VENDOR NAME'),
        amount: _headerText('AMOUNT', alignRight: true),
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
      case 'Delivery Date':
        return '03-08-2026';
      case 'Vendor Name':
        return 'Vendor Name - Not mentioned';
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
        status: Text(_groupDisplayValue(), style: _groupStyle),
        date: const SizedBox.shrink(),
        deliveryDate: const SizedBox.shrink(),
        purchaseOrderNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        amount: _totalAmountText(widget.totals.grandTotal, widget.currencyFormat),
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
        status: Text('Current', style: _groupStyle),
        date: const SizedBox.shrink(),
        deliveryDate: const SizedBox.shrink(),
        purchaseOrderNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        amount: _totalAmountText(widget.totals.grandTotal, widget.currencyFormat),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      );
}

class _PurchaseOrderDetailsDataRow extends StatelessWidget {
  final PurchaseOrderDetailsRow row;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  const _PurchaseOrderDetailsDataRow({
    required this.row,
    required this.dateFormat,
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
        status: _bodyText(row.status),
        date: _bodyText(_formatDate(row.orderDate, dateFormat)),
        deliveryDate: _bodyText(
          _formatDate(row.expectedDeliveryDate, dateFormat),
        ),
        purchaseOrderNumber: _bodyText(row.purchaseOrderNumber),
        vendorName: _bodyText(row.vendorName),
        amount: _amountText(row.grandTotal, currencyFormat),
      ),
    );
  }
}

class _PurchaseOrderDetailsTotalRow extends StatelessWidget {
  final PurchaseOrderDetailsTotals totals;
  final NumberFormat currencyFormat;

  const _PurchaseOrderDetailsTotalRow({
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
        status: _totalLabel('Total'),
        date: const SizedBox.shrink(),
        deliveryDate: const SizedBox.shrink(),
        purchaseOrderNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        amount: _totalAmountText(totals.grandTotal, currencyFormat),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget date,
  required Widget deliveryDate,
  required Widget purchaseOrderNumber,
  required Widget vendorName,
  required Widget amount,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: status),
      Expanded(flex: 3, child: date),
      Expanded(flex: 3, child: deliveryDate),
      Expanded(flex: 3, child: purchaseOrderNumber),
      Expanded(flex: 5, child: vendorName),
      Expanded(
        flex: 3,
        child: Align(alignment: Alignment.centerRight, child: amount),
      ),
    ],
  );
}

Widget _bodyText(String value) {
  return Text(
    value.trim().isEmpty ? '-' : value,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    ),
  );
}

Widget _amountText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
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

String _formatDate(DateTime? value, DateFormat dateFormat) {
  if (value == null) return '-';
  return dateFormat.format(value);
}

class PurchaseOrderDetailsRow {
  final String status;
  final DateTime? orderDate;
  final DateTime? expectedDeliveryDate;
  final String purchaseOrderNumber;
  final String vendorName;
  final double grandTotal;

  const PurchaseOrderDetailsRow({
    required this.status,
    required this.orderDate,
    required this.expectedDeliveryDate,
    required this.purchaseOrderNumber,
    required this.vendorName,
    required this.grandTotal,
  });

  static List<PurchaseOrderDetailsRow> fromResponse(
    Map<String, dynamic>? response,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <PurchaseOrderDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) =>
              PurchaseOrderDetailsRow.fromJson(Map<String, dynamic>.from(raw)),
        )
        .toList(growable: false);
  }

  factory PurchaseOrderDetailsRow.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetailsRow(
      status: _stringValue(json['status'], fallback: 'Draft'),
      orderDate: _dateValue(json['orderDate']),
      expectedDeliveryDate: _dateValue(json['expectedDeliveryDate']),
      purchaseOrderNumber: _stringValue(json['purchaseOrderNumber']),
      vendorName: _stringValue(json['vendorName'], fallback: '-'),
      grandTotal: _doubleValue(json['grandTotal']),
    );
  }
}

class PurchaseOrderDetailsTotals {
  final double grandTotal;

  const PurchaseOrderDetailsTotals({required this.grandTotal});

  factory PurchaseOrderDetailsTotals.fromResponse(
    Map<String, dynamic>? response,
  ) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return PurchaseOrderDetailsTotals(
      grandTotal: _doubleValue(totals['grandTotal']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
