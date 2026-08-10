import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class RetainerInvoiceDetailsRow {
  final String status;
  final String retainerInvoiceDate;
  final String retainerInvoiceNumber;
  final String customerName;
  final String projectEstimate;
  final double amount;
  final double unusedRetainers;

  const RetainerInvoiceDetailsRow({
    required this.status,
    required this.retainerInvoiceDate,
    required this.retainerInvoiceNumber,
    required this.customerName,
    required this.projectEstimate,
    required this.amount,
    required this.unusedRetainers,
  });

  static List<RetainerInvoiceDetailsRow> fromResponse(
    Map<String, dynamic>? response,
    DateFormat dateFormat,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <RetainerInvoiceDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => RetainerInvoiceDetailsRow.fromJson(
            Map<String, dynamic>.from(raw),
            dateFormat,
          ),
        )
        .toList(growable: false);
  }

  factory RetainerInvoiceDetailsRow.fromJson(
    Map<String, dynamic> json,
    DateFormat dateFormat,
  ) {
    return RetainerInvoiceDetailsRow(
      status: _titleCase(_stringValue(json['status'], fallback: 'Draft')),
      retainerInvoiceDate: _formatDate(json['retainerInvoiceDate'], dateFormat),
      retainerInvoiceNumber: _stringValue(json['retainerInvoiceNumber']),
      customerName: _stringValue(json['customerName'], fallback: '-'),
      projectEstimate: _stringValue(json['projectEstimate']),
      amount: _doubleValue(json['totalAmount']),
      unusedRetainers: _doubleValue(json['balanceAmount']),
    );
  }
}

class RetainerInvoiceDetailsTotals {
  final double totalAmount;
  final double amountReceived;
  final double amountApplied;
  final double balanceAmount;

  const RetainerInvoiceDetailsTotals({
    required this.totalAmount,
    required this.amountReceived,
    required this.amountApplied,
    required this.balanceAmount,
  });

  factory RetainerInvoiceDetailsTotals.fromResponse(
    Map<String, dynamic>? response,
  ) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return RetainerInvoiceDetailsTotals(
      totalAmount: _doubleValue(totals['totalAmount']),
      amountReceived: _doubleValue(totals['amountReceived']),
      amountApplied: _doubleValue(totals['amountApplied']),
      balanceAmount: _doubleValue(totals['balanceAmount']),
    );
  }
}

class RetainerInvoiceDetailsTable extends StatefulWidget {
  final List<RetainerInvoiceDetailsRow> rows;
  final RetainerInvoiceDetailsTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const RetainerInvoiceDetailsTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.currencyFormat,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<RetainerInvoiceDetailsTable> createState() =>
      _RetainerInvoiceDetailsTableState();
}

class _RetainerInvoiceDetailsTableState
    extends State<RetainerInvoiceDetailsTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1500
            ? 1500.0
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
                      message:
                          'There are no transactions during the selected date range.',
                    )
                  else ...[
                    for (final row in widget.rows)
                      _RetainerInvoiceDetailsDataRow(
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
        retainerInvoiceDateSort: Row(
          children: [
            Text('RETAINER INVOICE DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        retainerInvoiceDate: _headerText('RETAINER INVOICE DATE'),
        retainerInvoiceNumber: _headerText('RETAINER INVOICE#'),
        customerName: _headerText('CUSTOMER NAME'),
        projectEstimate: _headerText('PROJECT/ESTIMATE'),
        amount: _headerText('AMOUNT', alignRight: true),
        unusedRetainers: _headerText('UNUSED RETAINERS', alignRight: true),
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
}

class _RetainerInvoiceDetailsDataRow extends StatefulWidget {
  final RetainerInvoiceDetailsRow row;
  final NumberFormat currencyFormat;

  const _RetainerInvoiceDetailsDataRow({
    required this.row,
    required this.currencyFormat,
  });

  @override
  State<_RetainerInvoiceDetailsDataRow> createState() =>
      _RetainerInvoiceDetailsDataRowState();
}

class _RetainerInvoiceDetailsDataRowState
    extends State<_RetainerInvoiceDetailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  bool get _isStatusLink {
    final status = widget.row.status.toLowerCase();
    return status == 'sent' || status == 'open';
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
          retainerInvoiceDateSort: _bodyText(row.retainerInvoiceDate),
          retainerInvoiceDate: _bodyText(row.retainerInvoiceDate),
          retainerInvoiceNumber: _linkText(
            row.retainerInvoiceNumber,
            isUnderlined: _isHovered,
          ),
          customerName: _linkText(row.customerName, isUnderlined: _isHovered),
          projectEstimate: _bodyText(row.projectEstimate),
          amount: _linkText(
            widget.currencyFormat.format(row.amount),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
          unusedRetainers: _linkText(
            widget.currencyFormat.format(row.unusedRetainers),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final RetainerInvoiceDetailsTotals totals;
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
        retainerInvoiceDateSort: const SizedBox.shrink(),
        retainerInvoiceDate: const SizedBox.shrink(),
        retainerInvoiceNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        projectEstimate: const SizedBox.shrink(),
        amount: _totalText(
          currencyFormat.format(totals.totalAmount),
          align: TextAlign.right,
        ),
        unusedRetainers: _totalText(
          currencyFormat.format(totals.balanceAmount),
          align: TextAlign.right,
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget retainerInvoiceDateSort,
  required Widget retainerInvoiceDate,
  required Widget retainerInvoiceNumber,
  required Widget customerName,
  required Widget projectEstimate,
  required Widget amount,
  required Widget unusedRetainers,
}) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tableCell(
          status,
          flex: 2,
          padding: const EdgeInsets.only(
            top: AppTheme.space10,
            right: AppTheme.space10,
            bottom: AppTheme.space10,
          ),
          rightBorder: true,
        ),
        _tableCell(
          retainerInvoiceDateSort,
          flex: 3,
          padding: const EdgeInsets.only(
            top: AppTheme.space10,
            left: AppTheme.space10,
            bottom: AppTheme.space10,
          ),
        ),
        _tableCell(retainerInvoiceDate, flex: 3),
        _tableCell(retainerInvoiceNumber, flex: 3),
        _tableCell(customerName, flex: 3),
        _tableCell(projectEstimate, flex: 3),
        _tableCell(amount, flex: 2),
        _tableCell(unusedRetainers, flex: 3),
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
  bool rightBorder = false,
}) {
  return Expanded(
    flex: flex,
    child: Container(
      padding: padding,
      decoration: rightBorder
          ? const BoxDecoration(
              border: Border(right: BorderSide(color: AppTheme.borderLight)),
            )
          : null,
      child: child,
    ),
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
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
    ),
  );
}

Widget _statusText(String value, {required bool isUnderlined}) {
  final status = value.toLowerCase();
  Color color = AppTheme.textMuted;
  if (status == 'accepted' ||
      status == 'paid' ||
      status == 'confirmed' ||
      status == 'closed') {
    color = AppTheme.successDark;
  } else if (status == 'sent' || status == 'open') {
    color = AppTheme.primaryBlue;
  }
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.tableCell.copyWith(
      color: color,
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
