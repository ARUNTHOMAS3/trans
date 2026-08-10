import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class CreditNoteDetailsRow {
  final String status;
  final String creditDate;
  final String creditNoteNumber;
  final String creditNoteRecordId;
  final String customerName;
  final double creditNoteAmount;
  final double balanceAmount;

  const CreditNoteDetailsRow({
    required this.status,
    required this.creditDate,
    required this.creditNoteNumber,
    required this.creditNoteRecordId,
    required this.customerName,
    required this.creditNoteAmount,
    required this.balanceAmount,
  });

  static List<CreditNoteDetailsRow> fromResponse(
    Map<String, dynamic>? response,
    DateFormat dateFormat,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <CreditNoteDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => CreditNoteDetailsRow.fromJson(
            Map<String, dynamic>.from(raw),
            dateFormat,
          ),
        )
        .toList(growable: false);
  }

  factory CreditNoteDetailsRow.fromJson(
    Map<String, dynamic> json,
    DateFormat dateFormat,
  ) {
    return CreditNoteDetailsRow(
      status: _titleCase(_stringValue(json['status'], fallback: 'Draft')),
      creditDate: _formatDate(json['creditDate'], dateFormat),
      creditNoteNumber: _stringValue(json['creditNoteNumber']),
      creditNoteRecordId: _stringValue(json['creditNoteRecordId']),
      customerName: _stringValue(json['customerName'], fallback: '-'),
      creditNoteAmount: _doubleValue(json['grandTotal']),
      balanceAmount: _doubleValue(json['balanceAmount']),
    );
  }
}

class CreditNoteDetailsTotals {
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double shippingCharges;
  final double grandTotal;
  final double balanceAmount;

  const CreditNoteDetailsTotals({
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.shippingCharges,
    required this.grandTotal,
    required this.balanceAmount,
  });

  factory CreditNoteDetailsTotals.fromResponse(Map<String, dynamic>? response) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return CreditNoteDetailsTotals(
      subtotal: _doubleValue(totals['subtotal']),
      discountTotal: _doubleValue(totals['discountTotal']),
      taxTotal: _doubleValue(totals['taxTotal']),
      shippingCharges: _doubleValue(totals['shippingCharges']),
      grandTotal: _doubleValue(totals['grandTotal']),
      balanceAmount: _doubleValue(totals['balanceAmount']),
    );
  }
}

class CreditNoteDetailsTable extends StatefulWidget {
  final List<CreditNoteDetailsRow> rows;
  final CreditNoteDetailsTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const CreditNoteDetailsTable({
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
  State<CreditNoteDetailsTable> createState() => _CreditNoteDetailsTableState();
}

class _CreditNoteDetailsTableState extends State<CreditNoteDetailsTable> {
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
                      _CreditNoteDetailsDataRow(
                        row: row,
                        currencyFormat: widget.currencyFormat,
                      ),
                    _TotalRow(
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: _buildTableRow(
        status: _headerText('STATUS'),
        creditDate: Row(
          children: [
            Text('CREDIT DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        creditNoteNumber: _headerText('CREDIT NOTE#'),
        creditNoteId: _headerText('CREDITNOTE ID'),
        customerName: _headerText('CUSTOMER NAME'),
        creditNoteAmount: _headerText('CREDIT NOTE AMOUNT', alignRight: true),
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
      case 'Credit Date':
        return '03-08-2026';
      case 'Customer Name':
        return 'Customer Name - Not mentioned';
      case 'Salesperson':
        return 'Salesperson - Not mentioned';
      case 'Currency':
        return 'INR';
      default:
        return widget.groupBy;
    }
  }

  Widget _buildAppliedGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        status: _groupStyleText(_groupDisplayValue()),
        creditDate: const SizedBox.shrink(),
        creditNoteNumber: const SizedBox.shrink(),
        creditNoteId: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        creditNoteAmount: _groupStyleText(
          widget.currencyFormat.format(widget.totals.grandTotal),
          align: TextAlign.right,
        ),
        balanceAmount: _groupStyleText(
          widget.currencyFormat.format(widget.totals.balanceAmount),
          align: TextAlign.right,
        ),
      ),
    );
  }

  Widget _buildCurrentGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        status: _groupStyleText('Current'),
        creditDate: const SizedBox.shrink(),
        creditNoteNumber: const SizedBox.shrink(),
        creditNoteId: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        creditNoteAmount: _groupStyleText(
          widget.currencyFormat.format(widget.totals.grandTotal),
          align: TextAlign.right,
        ),
        balanceAmount: _groupStyleText(
          widget.currencyFormat.format(widget.totals.balanceAmount),
          align: TextAlign.right,
        ),
      ),
    );
  }

  Widget _groupStyleText(String value, {TextAlign align = TextAlign.left}) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CreditNoteDetailsDataRow extends StatefulWidget {
  final CreditNoteDetailsRow row;
  final NumberFormat currencyFormat;

  const _CreditNoteDetailsDataRow({
    required this.row,
    required this.currencyFormat,
  });

  @override
  State<_CreditNoteDetailsDataRow> createState() =>
      _CreditNoteDetailsDataRowState();
}

class _CreditNoteDetailsDataRowState extends State<_CreditNoteDetailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  bool get _isStatusLink {
    final status = widget.row.status.toLowerCase();
    return status == 'open' || status == 'sent';
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: _buildTableRow(
          status: _statusText(
            row.status,
            isUnderlined: _isHovered && _isStatusLink,
          ),
          creditDate: _bodyText(row.creditDate),
          creditNoteNumber: _linkText(
            row.creditNoteNumber,
            isUnderlined: _isHovered,
          ),
          creditNoteId: const SizedBox.shrink(),
          customerName: _linkText(row.customerName, isUnderlined: _isHovered),
          creditNoteAmount: _linkText(
            widget.currencyFormat.format(row.creditNoteAmount),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
          balanceAmount: _linkText(
            widget.currencyFormat.format(row.balanceAmount),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final CreditNoteDetailsTotals totals;
  final NumberFormat currencyFormat;

  const _TotalRow({required this.totals, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        status: _totalText('Total'),
        creditDate: const SizedBox.shrink(),
        creditNoteNumber: const SizedBox.shrink(),
        creditNoteId: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        creditNoteAmount: _totalText(
          currencyFormat.format(totals.grandTotal),
          align: TextAlign.right,
        ),
        balanceAmount: _totalText(
          currencyFormat.format(totals.balanceAmount),
          align: TextAlign.right,
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget creditDate,
  required Widget creditNoteNumber,
  required Widget creditNoteId,
  required Widget customerName,
  required Widget creditNoteAmount,
  required Widget balanceAmount,
}) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tableCell(status, flex: 3),
        _tableCell(creditDate, flex: 4),
        _tableCell(creditNoteNumber, flex: 4),
        _tableCell(creditNoteId, flex: 5),
        _tableCell(customerName, flex: 5),
        _tableCell(creditNoteAmount, flex: 5),
        _tableCell(balanceAmount, flex: 5),
      ],
    ),
  );
}

Widget _tableCell(
  Widget child, {
  required int flex,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    vertical: AppTheme.space10,
  ),
}) {
  return Expanded(
    flex: flex,
    child: Padding(padding: padding, child: child),
  );
}

Widget _linkText(
  String value, {
  TextAlign align = TextAlign.left,
  required bool isUnderlined,
}) {
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: AppTheme.tableCell.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: align == TextAlign.right ? FontWeight.w600 : null,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
    ),
  );
}

Widget _statusText(String value, {required bool isUnderlined}) {
  final status = value.toLowerCase();
  Color color = AppTheme.textMuted;
  if (status == 'closed' || status == 'applied') {
    color = AppTheme.successDark;
  } else if (status == 'open' || status == 'sent') {
    color = AppTheme.primaryBlue;
  }
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.tableCell.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
      decorationColor: color,
    ),
  );
}

Widget _bodyText(String value, {TextAlign align = TextAlign.left}) {
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
  );
}

Widget _totalText(String value, {TextAlign align = TextAlign.left}) {
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 15,
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
  final text = value?.toString() ?? '';
  if (text.trim().isEmpty) return '';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return dateFormat.format(parsed.toLocal());
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
