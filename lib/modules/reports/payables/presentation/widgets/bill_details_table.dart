import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class BillDetailsTable extends StatefulWidget {
  final List<BillDetailsRow> rows;
  final BillDetailsTotals totals;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const BillDetailsTable({
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
  State<BillDetailsTable> createState() => _BillDetailsTableState();
}

class _BillDetailsTableState extends State<BillDetailsTable> {
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
        final tableWidth = constraints.maxWidth < 1280
            ? 1280.0
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
                      _BillDetailsDataRow(
                        row: row,
                        dateFormat: widget.dateFormat,
                        currencyFormat: widget.currencyFormat,
                      ),
                    _BillDetailsTotalRow(
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
        billDate: Row(
          children: [
            Text('BILL DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        dueDate: _headerText('DUE DATE'),
        billNumber: _headerText('BILL#'),
        vendorName: _headerText('VENDOR NAME'),
        billAmount: _headerText('BILL AMOUNT', alignRight: true),
        balanceAmount: _headerText('BALANCE AMOUNT', alignRight: true),
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
      case 'Bill Date':
      case 'Due Date':
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
        billDate: const SizedBox.shrink(),
        dueDate: const SizedBox.shrink(),
        billNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        billAmount: _totalAmountText(widget.totals.billAmount, widget.currencyFormat),
        balanceAmount: _totalAmountText(widget.totals.balanceAmount, widget.currencyFormat),
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
        billDate: const SizedBox.shrink(),
        dueDate: const SizedBox.shrink(),
        billNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        billAmount: _totalAmountText(widget.totals.billAmount, widget.currencyFormat),
        balanceAmount: _totalAmountText(widget.totals.balanceAmount, widget.currencyFormat),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      );
}

class _BillDetailsDataRow extends StatefulWidget {
  final BillDetailsRow row;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  const _BillDetailsDataRow({
    required this.row,
    required this.dateFormat,
    required this.currencyFormat,
  });

  @override
  State<_BillDetailsDataRow> createState() => _BillDetailsDataRowState();
}

class _BillDetailsDataRowState extends State<_BillDetailsDataRow> {
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
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: _buildTableRow(
          status: _statusText(row.status),
          billDate: _bodyText(_formatDate(row.billDate, widget.dateFormat)),
          dueDate: _bodyText(_formatDate(row.dueDate, widget.dateFormat)),
          billNumber: _linkText(row.billNumber),
          vendorName: _linkText(row.vendorName),
          billAmount: _amountText(row.billAmount, widget.currencyFormat),
          balanceAmount: _amountText(row.balanceAmount, widget.currencyFormat),
        ),
      ),
    );
  }
}

class _BillDetailsTotalRow extends StatelessWidget {
  final BillDetailsTotals totals;
  final NumberFormat currencyFormat;

  const _BillDetailsTotalRow({
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
        billDate: const SizedBox.shrink(),
        dueDate: const SizedBox.shrink(),
        billNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        billAmount: _totalAmountText(totals.billAmount, currencyFormat),
        balanceAmount: _totalAmountText(totals.balanceAmount, currencyFormat),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget billDate,
  required Widget dueDate,
  required Widget billNumber,
  required Widget vendorName,
  required Widget billAmount,
  required Widget balanceAmount,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: status),
      Expanded(flex: 3, child: billDate),
      Expanded(flex: 3, child: dueDate),
      Expanded(flex: 3, child: billNumber),
      Expanded(flex: 4, child: vendorName),
      Expanded(
        flex: 3,
        child: Align(alignment: Alignment.centerRight, child: billAmount),
      ),
      Expanded(
        flex: 3,
        child: Align(alignment: Alignment.centerRight, child: balanceAmount),
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

Widget _linkText(String value) {
  return Text(
    value.trim().isEmpty ? '-' : value,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w600,
    ),
  );
}

Widget _statusText(String value) {
  final normalized = value.trim();
  final color = normalized.toLowerCase().contains('paid')
      ? AppTheme.successGreen
      : AppTheme.primaryBlue;
  return Text(
    normalized.isEmpty ? '-' : normalized,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.bodyText.copyWith(color: color, fontWeight: FontWeight.w500),
  );
}

Widget _amountText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w600,
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

class BillDetailsRow {
  final String status;
  final DateTime? billDate;
  final DateTime? dueDate;
  final String billNumber;
  final String vendorName;
  final double billAmount;
  final double balanceAmount;

  const BillDetailsRow({
    required this.status,
    required this.billDate,
    required this.dueDate,
    required this.billNumber,
    required this.vendorName,
    required this.billAmount,
    required this.balanceAmount,
  });

  static List<BillDetailsRow> fromResponse(Map<String, dynamic>? response) {
    final rawRows = response?['data'] ?? response?['rows'];
    if (rawRows is! List) return const <BillDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map((raw) => BillDetailsRow.fromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false);
  }

  factory BillDetailsRow.fromJson(Map<String, dynamic> json) {
    return BillDetailsRow(
      status: _stringValue(json['status'], fallback: 'Draft'),
      billDate: _dateValue(json['billDateRaw'] ?? json['billDate']),
      dueDate: _dateValue(json['dueDateRaw'] ?? json['dueDate']),
      billNumber: _stringValue(json['billNumber']),
      vendorName: _stringValue(json['vendorName'], fallback: '-'),
      billAmount: _doubleValue(json['billAmount']),
      balanceAmount: _doubleValue(json['balanceAmount']),
    );
  }
}

class BillDetailsTotals {
  final double billAmount;
  final double balanceAmount;

  const BillDetailsTotals({required this.billAmount, required this.balanceAmount});

  factory BillDetailsTotals.fromResponse(Map<String, dynamic>? response) {
    final meta = Map<String, dynamic>.from(
      response?['meta'] as Map? ?? const <String, dynamic>{},
    );
    final totals = Map<String, dynamic>.from(
      meta['totals'] as Map? ?? response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return BillDetailsTotals(
      billAmount: _doubleValue(totals['billAmount']),
      balanceAmount: _doubleValue(totals['balanceAmount']),
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
