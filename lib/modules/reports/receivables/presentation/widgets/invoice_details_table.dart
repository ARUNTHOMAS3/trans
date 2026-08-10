import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class InvoiceDetailsRow {
  final String status;
  final String invoiceDate;
  final String dueDate;
  final String invoiceNumber;
  final String orderNumber;
  final String customerName;
  final double total;
  final double balance;

  const InvoiceDetailsRow({
    required this.status,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceNumber,
    required this.orderNumber,
    required this.customerName,
    required this.total,
    required this.balance,
  });

  static List<InvoiceDetailsRow> fromResponse(
    Map<String, dynamic>? response,
    DateFormat dateFormat,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <InvoiceDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => InvoiceDetailsRow.fromJson(
            Map<String, dynamic>.from(raw),
            dateFormat,
          ),
        )
        .toList(growable: false);
  }

  factory InvoiceDetailsRow.fromJson(
    Map<String, dynamic> json,
    DateFormat dateFormat,
  ) {
    return InvoiceDetailsRow(
      status: _titleCase(_stringValue(json['status'], fallback: 'Draft')),
      invoiceDate: _formatDate(json['invoiceDate'], dateFormat),
      dueDate: _formatDate(json['dueDate'], dateFormat),
      invoiceNumber: _stringValue(json['invoiceNumber']),
      orderNumber: _stringValue(json['orderNumber']),
      customerName: _stringValue(json['customerName'], fallback: '-'),
      total: _doubleValue(json['grandTotal']),
      balance: _doubleValue(json['balance']),
    );
  }
}

class InvoiceDetailsTotals {
  final double total;
  final double balance;

  const InvoiceDetailsTotals({required this.total, required this.balance});

  factory InvoiceDetailsTotals.fromResponse(Map<String, dynamic>? response) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return InvoiceDetailsTotals(
      total: _doubleValue(totals['grandTotal']),
      balance: _doubleValue(totals['balance']),
    );
  }
}

class InvoiceDetailsTable extends StatefulWidget {
  final List<InvoiceDetailsRow> rows;
  final InvoiceDetailsTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const InvoiceDetailsTable({
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
  State<InvoiceDetailsTable> createState() => _InvoiceDetailsTableState();
}

class _InvoiceDetailsTableState extends State<InvoiceDetailsTable> {
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
        final tableWidth = constraints.maxWidth < 1460
            ? 1460.0
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
                    for (final row in widget.rows)
                      _InvoiceDetailsDataRow(
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
        invoiceDate: Row(
          children: [
            Text('INVOICE DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        dueDate: _headerText('DUE DATE'),
        invoiceNumber: _headerText('INVOICE#'),
        orderNumber: _headerText('ORDER NUMBER'),
        customerName: _headerText('CUSTOMER NAME'),
        total: _headerText('TOTAL', alignRight: true),
        balance: _headerText('BALANCE', alignRight: true),
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

class _InvoiceDetailsDataRow extends StatefulWidget {
  final InvoiceDetailsRow row;
  final NumberFormat currencyFormat;

  const _InvoiceDetailsDataRow({
    required this.row,
    required this.currencyFormat,
  });

  @override
  State<_InvoiceDetailsDataRow> createState() => _InvoiceDetailsDataRowState();
}

class _InvoiceDetailsDataRowState extends State<_InvoiceDetailsDataRow> {
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
          invoiceDate: _bodyText(row.invoiceDate),
          dueDate: _bodyText(row.dueDate),
          invoiceNumber: _linkText(row.invoiceNumber, isUnderlined: _isHovered),
          orderNumber: row.orderNumber.isEmpty
              ? const SizedBox.shrink()
              : _linkText(row.orderNumber, isUnderlined: _isHovered),
          customerName: _linkText(row.customerName, isUnderlined: _isHovered),
          total: _linkText(
            widget.currencyFormat.format(row.total),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
          balance: _linkText(
            widget.currencyFormat.format(row.balance),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final InvoiceDetailsTotals totals;
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
        invoiceDate: const SizedBox.shrink(),
        dueDate: const SizedBox.shrink(),
        invoiceNumber: const SizedBox.shrink(),
        orderNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        total: _totalText(
          currencyFormat.format(totals.total),
          align: TextAlign.right,
        ),
        balance: _totalText(
          currencyFormat.format(totals.balance),
          align: TextAlign.right,
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget invoiceDate,
  required Widget dueDate,
  required Widget invoiceNumber,
  required Widget orderNumber,
  required Widget customerName,
  required Widget total,
  required Widget balance,
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
          invoiceDate,
          flex: 2,
          padding: const EdgeInsets.only(
            top: AppTheme.space10,
            left: AppTheme.space10,
            bottom: AppTheme.space10,
          ),
        ),
        _tableCell(dueDate, flex: 2),
        _tableCell(invoiceNumber, flex: 2),
        _tableCell(orderNumber, flex: 2),
        _tableCell(customerName, flex: 4),
        _tableCell(total, flex: 2),
        _tableCell(balance, flex: 2),
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
  if (status == 'paid' || status == 'delivered') {
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
