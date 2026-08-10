import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class SalesOrderDetailsRow {
  final String status;
  final String date;
  final String expectedShipmentDate;
  final String salesOrderNumber;
  final String customerName;
  final double amount;

  const SalesOrderDetailsRow({
    required this.status,
    required this.date,
    required this.expectedShipmentDate,
    required this.salesOrderNumber,
    required this.customerName,
    required this.amount,
  });

  static List<SalesOrderDetailsRow> fromResponse(
    Map<String, dynamic>? response,
    DateFormat dateFormat,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <SalesOrderDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => SalesOrderDetailsRow.fromJson(
            Map<String, dynamic>.from(raw),
            dateFormat,
          ),
        )
        .toList(growable: false);
  }

  factory SalesOrderDetailsRow.fromJson(
    Map<String, dynamic> json,
    DateFormat dateFormat,
  ) {
    return SalesOrderDetailsRow(
      status: _titleCase(_stringValue(json['status'], fallback: 'Draft')),
      date: _formatDate(json['date'], dateFormat),
      expectedShipmentDate: _formatDate(
        json['expectedShipmentDate'],
        dateFormat,
      ),
      salesOrderNumber: _stringValue(json['salesOrderNumber']),
      customerName: _stringValue(json['customerName'], fallback: '-'),
      amount: _doubleValue(json['grandTotal']),
    );
  }
}

class SalesOrderDetailsTotals {
  final double amount;

  const SalesOrderDetailsTotals({required this.amount});

  factory SalesOrderDetailsTotals.fromResponse(Map<String, dynamic>? response) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return SalesOrderDetailsTotals(amount: _doubleValue(totals['grandTotal']));
  }
}

class SalesOrderDetailsTable extends StatefulWidget {
  final List<SalesOrderDetailsRow> rows;
  final SalesOrderDetailsTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const SalesOrderDetailsTable({
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
  State<SalesOrderDetailsTable> createState() => _SalesOrderDetailsTableState();
}

class _SalesOrderDetailsTableState extends State<SalesOrderDetailsTable> {
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
                      _SalesOrderDetailsDataRow(
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
        date: _headerText('DATE'),
        expectedShipmentDate: _headerText('EXPECTED SHIPMENT DATE'),
        salesOrderNumber: _headerText('SALES ORDER#'),
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

class _SalesOrderDetailsDataRow extends StatefulWidget {
  final SalesOrderDetailsRow row;
  final NumberFormat currencyFormat;

  const _SalesOrderDetailsDataRow({
    required this.row,
    required this.currencyFormat,
  });

  @override
  State<_SalesOrderDetailsDataRow> createState() =>
      _SalesOrderDetailsDataRowState();
}

class _SalesOrderDetailsDataRowState extends State<_SalesOrderDetailsDataRow> {
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
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: _buildTableRow(
          status: _linkText(row.status, isUnderlined: _isHovered),
          date: _bodyText(row.date),
          expectedShipmentDate: _bodyText(row.expectedShipmentDate),
          salesOrderNumber: _linkText(
            row.salesOrderNumber,
            isUnderlined: _isHovered,
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
  final SalesOrderDetailsTotals totals;
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
        date: const SizedBox.shrink(),
        expectedShipmentDate: const SizedBox.shrink(),
        salesOrderNumber: const SizedBox.shrink(),
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
  required Widget status,
  required Widget date,
  required Widget expectedShipmentDate,
  required Widget salesOrderNumber,
  required Widget customerName,
  required Widget amount,
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
          date,
          flex: 2,
          padding: const EdgeInsets.only(
            top: AppTheme.space10,
            left: AppTheme.space10,
            bottom: AppTheme.space10,
          ),
        ),
        _tableCell(expectedShipmentDate, flex: 4),
        _tableCell(salesOrderNumber, flex: 3),
        _tableCell(customerName, flex: 4),
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
