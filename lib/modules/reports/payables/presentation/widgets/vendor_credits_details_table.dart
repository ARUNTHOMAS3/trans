import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class VendorCreditsDetailsTable extends StatefulWidget {
  final List<VendorCreditsDetailsRow> rows;
  final VendorCreditsDetailsTotals totals;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const VendorCreditsDetailsTable({
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
  State<VendorCreditsDetailsTable> createState() =>
      _VendorCreditsDetailsTableState();
}

class _VendorCreditsDetailsTableState extends State<VendorCreditsDetailsTable> {
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
                      _VendorCreditsDetailsDataRow(
                        row: row,
                        dateFormat: widget.dateFormat,
                        currencyFormat: widget.currencyFormat,
                      ),
                    _VendorCreditsDetailsTotalRow(
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
        vendorCreditDate: Row(
          children: [
            Text('VENDOR CREDIT DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        creditNoteNumber: _headerText('CREDIT NOTE#'),
        vendorName: _headerText('VENDOR NAME'),
        amount: _headerText('AMOUNT', alignRight: true),
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
      case 'Vendor Credit Date':
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
        vendorCreditDate: const SizedBox.shrink(),
        creditNoteNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        amount: _totalAmountText(widget.totals.amount, widget.currencyFormat),
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
        vendorCreditDate: const SizedBox.shrink(),
        creditNoteNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        amount: _totalAmountText(widget.totals.amount, widget.currencyFormat),
        balanceAmount: _totalAmountText(widget.totals.balanceAmount, widget.currencyFormat),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      );
}

class _VendorCreditsDetailsDataRow extends StatefulWidget {
  final VendorCreditsDetailsRow row;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  const _VendorCreditsDetailsDataRow({
    required this.row,
    required this.dateFormat,
    required this.currencyFormat,
  });

  @override
  State<_VendorCreditsDetailsDataRow> createState() =>
      _VendorCreditsDetailsDataRowState();
}

class _VendorCreditsDetailsDataRowState
    extends State<_VendorCreditsDetailsDataRow> {
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
          vendorCreditDate: _bodyText(
            _formatDate(row.vendorCreditDate, widget.dateFormat),
          ),
          creditNoteNumber: _linkText(row.vendorCreditNumber),
          vendorName: _linkText(row.vendorName),
          amount: _amountText(row.amount, widget.currencyFormat),
          balanceAmount: _amountText(row.balanceAmount, widget.currencyFormat),
        ),
      ),
    );
  }
}

class _VendorCreditsDetailsTotalRow extends StatelessWidget {
  final VendorCreditsDetailsTotals totals;
  final NumberFormat currencyFormat;

  const _VendorCreditsDetailsTotalRow({
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
        vendorCreditDate: const SizedBox.shrink(),
        creditNoteNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        amount: _totalAmountText(totals.amount, currencyFormat),
        balanceAmount: _totalAmountText(totals.balanceAmount, currencyFormat),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget vendorCreditDate,
  required Widget creditNoteNumber,
  required Widget vendorName,
  required Widget amount,
  required Widget balanceAmount,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: status),
      Expanded(flex: 3, child: vendorCreditDate),
      Expanded(flex: 3, child: creditNoteNumber),
      Expanded(flex: 6, child: vendorName),
      Expanded(
        flex: 3,
        child: Align(alignment: Alignment.centerRight, child: amount),
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
    style: AppTheme.tableCell,
  );
}

Widget _linkText(String value) {
  return Text(
    value.trim().isEmpty ? '-' : value,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
  );
}

Widget _statusText(String value) {
  final normalized = value.trim();
  final color = <String>{'closed', 'applied', 'used'}
          .contains(normalized.toLowerCase())
      ? AppTheme.successDark
      : AppTheme.primaryBlue;
  return Text(
    normalized.isEmpty ? '-' : normalized,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.tableCell.copyWith(color: color, fontWeight: FontWeight.w500),
  );
}

Widget _amountText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.tableCell.copyWith(
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
      fontSize: 15,
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
      fontSize: 15,
    ),
  );
}

String _formatDate(DateTime? value, DateFormat dateFormat) {
  if (value == null) return '-';
  return dateFormat.format(value);
}

class VendorCreditsDetailsRow {
  final String status;
  final DateTime? vendorCreditDate;
  final String vendorCreditNumber;
  final String vendorName;
  final double amount;
  final double balanceAmount;

  const VendorCreditsDetailsRow({
    required this.status,
    required this.vendorCreditDate,
    required this.vendorCreditNumber,
    required this.vendorName,
    required this.amount,
    required this.balanceAmount,
  });

  static List<VendorCreditsDetailsRow> fromResponse(
    Map<String, dynamic>? response,
  ) {
    final rawRows = response?['data'] ?? response?['rows'];
    if (rawRows is! List) return const <VendorCreditsDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => VendorCreditsDetailsRow.fromJson(
            Map<String, dynamic>.from(raw),
          ),
        )
        .toList(growable: false);
  }

  factory VendorCreditsDetailsRow.fromJson(Map<String, dynamic> json) {
    return VendorCreditsDetailsRow(
      status: _stringValue(json['status'], fallback: 'Open'),
      vendorCreditDate: _dateValue(
        json['vendorCreditDateRaw'] ?? json['vendorCreditDate'],
      ),
      vendorCreditNumber: _stringValue(json['vendorCreditNumber']),
      vendorName: _stringValue(json['vendorName'], fallback: '-'),
      amount: _doubleValue(json['amount']),
      balanceAmount: _doubleValue(json['balanceAmount']),
    );
  }
}

class VendorCreditsDetailsTotals {
  final double amount;
  final double balanceAmount;

  const VendorCreditsDetailsTotals({
    required this.amount,
    required this.balanceAmount,
  });

  factory VendorCreditsDetailsTotals.fromResponse(
    Map<String, dynamic>? response,
  ) {
    final meta = Map<String, dynamic>.from(
      response?['meta'] as Map? ?? const <String, dynamic>{},
    );
    final totals = Map<String, dynamic>.from(
      meta['totals'] as Map? ??
          response?['totals'] as Map? ??
          const <String, dynamic>{},
    );
    return VendorCreditsDetailsTotals(
      amount: _doubleValue(totals['amount']),
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
