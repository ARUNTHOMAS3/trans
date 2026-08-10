import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class DeliveryChallanDetailsRow {
  final String deliveryChallanNumber;
  final String date;
  final String status;
  final String invoiceStatus;
  final String customerName;
  final double amount;

  const DeliveryChallanDetailsRow({
    required this.deliveryChallanNumber,
    required this.date,
    required this.status,
    required this.invoiceStatus,
    required this.customerName,
    required this.amount,
  });

  static List<DeliveryChallanDetailsRow> fromResponse(
    Map<String, dynamic>? response,
    DateFormat dateFormat,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <DeliveryChallanDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => DeliveryChallanDetailsRow.fromJson(
            Map<String, dynamic>.from(raw),
            dateFormat,
          ),
        )
        .toList(growable: false);
  }

  factory DeliveryChallanDetailsRow.fromJson(
    Map<String, dynamic> json,
    DateFormat dateFormat,
  ) {
    return DeliveryChallanDetailsRow(
      deliveryChallanNumber: _stringValue(json['deliveryChallanNumber']),
      date: _formatDate(json['date'], dateFormat),
      status: _titleCase(_stringValue(json['status'], fallback: 'Draft')),
      invoiceStatus: _titleCase(
        _stringValue(json['invoiceStatus'], fallback: 'Not Invoiced'),
      ),
      customerName: _stringValue(json['customerName'], fallback: '-'),
      amount: _doubleValue(json['grandTotal']),
    );
  }
}

class DeliveryChallanDetailsTotals {
  final double amount;

  const DeliveryChallanDetailsTotals({required this.amount});

  factory DeliveryChallanDetailsTotals.fromResponse(
    Map<String, dynamic>? response,
  ) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return DeliveryChallanDetailsTotals(
      amount: _doubleValue(totals['grandTotal']),
    );
  }
}

class DeliveryChallanDetailsTable extends StatefulWidget {
  final List<DeliveryChallanDetailsRow> rows;
  final DeliveryChallanDetailsTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const DeliveryChallanDetailsTable({
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
  State<DeliveryChallanDetailsTable> createState() =>
      _DeliveryChallanDetailsTableState();
}

class _DeliveryChallanDetailsTableState
    extends State<DeliveryChallanDetailsTable> {
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
                    for (final row in widget.rows)
                      _DeliveryChallanDetailsDataRow(
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
        deliveryChallanNumber: _headerText('DELIVERY CHALLAN#'),
        date: _headerText('DATE'),
        status: _headerText('STATUS'),
        invoiceStatus: _headerText('INVOICE STATUS'),
        customerName: _headerText('CUSTOMER NAME'),
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
}

class _DeliveryChallanDetailsDataRow extends StatefulWidget {
  final DeliveryChallanDetailsRow row;
  final NumberFormat currencyFormat;

  const _DeliveryChallanDetailsDataRow({
    required this.row,
    required this.currencyFormat,
  });

  @override
  State<_DeliveryChallanDetailsDataRow> createState() =>
      _DeliveryChallanDetailsDataRowState();
}

class _DeliveryChallanDetailsDataRowState
    extends State<_DeliveryChallanDetailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  bool get _isStatusLink => widget.row.status.toLowerCase() == 'open';

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
          deliveryChallanNumber: _linkText(
            row.deliveryChallanNumber,
            isUnderlined: _isHovered,
          ),
          date: _bodyText(row.date),
          status: _statusText(
            row.status,
            isUnderlined: _isHovered && _isStatusLink,
          ),
          invoiceStatus: _bodyText(
            row.invoiceStatus,
            color: AppTheme.textSecondary,
          ),
          customerName: _linkText(row.customerName, isUnderlined: _isHovered),
          amount: _linkText(
            widget.currencyFormat.format(row.amount),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final DeliveryChallanDetailsTotals totals;
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
        deliveryChallanNumber: _totalText('Total'),
        date: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        invoiceStatus: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        amount: _totalText(
          currencyFormat.format(totals.amount),
          align: TextAlign.right,
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget deliveryChallanNumber,
  required Widget date,
  required Widget status,
  required Widget invoiceStatus,
  required Widget customerName,
  required Widget amount,
}) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tableCell(
          deliveryChallanNumber,
          flex: 3,
          padding: const EdgeInsets.only(
            top: AppTheme.space10,
            right: AppTheme.space10,
            bottom: AppTheme.space10,
          ),
          rightBorder: true,
        ),
        _tableCell(
          date,
          flex: 3,
          padding: const EdgeInsets.only(
            top: AppTheme.space10,
            left: AppTheme.space10,
            bottom: AppTheme.space10,
          ),
        ),
        _tableCell(status, flex: 3),
        _tableCell(invoiceStatus, flex: 3),
        _tableCell(customerName, flex: 5),
        _tableCell(amount, flex: 2),
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
  final normalized = value.toLowerCase();
  final color = normalized == 'delivered'
      ? AppTheme.successGreen
      : normalized == 'open'
      ? AppTheme.primaryBlue
      : AppTheme.textSecondary;
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

Widget _bodyText(
  String value, {
  TextAlign align = TextAlign.left,
  Color color = AppTheme.textPrimary,
}) {
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: AppTheme.tableCell.copyWith(color: color),
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
