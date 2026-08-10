import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class QuoteDetailsRow {
  final String status;
  final String quoteDate;
  final String expiryDate;
  final String quoteNumber;
  final String referenceNumber;
  final String customerName;
  final String invoiceNumber;
  final String projectName;
  final double quoteAmount;

  const QuoteDetailsRow({
    required this.status,
    required this.quoteDate,
    required this.expiryDate,
    required this.quoteNumber,
    required this.referenceNumber,
    required this.customerName,
    required this.invoiceNumber,
    required this.projectName,
    required this.quoteAmount,
  });

  static List<QuoteDetailsRow> fromResponse(
    Map<String, dynamic>? response,
    DateFormat dateFormat,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <QuoteDetailsRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) => QuoteDetailsRow.fromJson(
            Map<String, dynamic>.from(raw),
            dateFormat,
          ),
        )
        .toList(growable: false);
  }

  factory QuoteDetailsRow.fromJson(
    Map<String, dynamic> json,
    DateFormat dateFormat,
  ) {
    return QuoteDetailsRow(
      status: _titleCase(_stringValue(json['status'], fallback: 'Draft')),
      quoteDate: _formatDate(json['quoteDate'], dateFormat),
      expiryDate: _formatDate(json['expiryDate'], dateFormat),
      quoteNumber: _stringValue(json['quoteNumber']),
      referenceNumber: _stringValue(json['referenceNumber']),
      customerName: _stringValue(json['customerName'], fallback: '-'),
      invoiceNumber: _stringValue(json['invoiceNumber']),
      projectName: _stringValue(json['projectName']),
      quoteAmount: _doubleValue(json['quoteAmount']),
    );
  }
}

class QuoteDetailsTotals {
  final double quoteAmount;

  const QuoteDetailsTotals({required this.quoteAmount});

  factory QuoteDetailsTotals.fromResponse(Map<String, dynamic>? response) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return QuoteDetailsTotals(quoteAmount: _doubleValue(totals['quoteAmount']));
  }
}

class QuoteDetailsTable extends StatefulWidget {
  final List<QuoteDetailsRow> rows;
  final QuoteDetailsTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const QuoteDetailsTable({
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
  State<QuoteDetailsTable> createState() => _QuoteDetailsTableState();
}

class _QuoteDetailsTableState extends State<QuoteDetailsTable> {
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
                      message: 'No data to display',
                    )
                  else ...[
                    for (final row in widget.rows)
                      _QuoteDetailsDataRow(
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
        quoteDate: Row(
          children: [
            Text('QUOTE DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        expiryDate: _headerText('EXPIRY DATE'),
        quoteNumber: _headerText('QUOTE#'),
        referenceNumber: _headerText('REFERENCE#'),
        customerName: _headerText('CUSTOMER NAME'),
        invoiceNumber: _headerText('INVOICE#'),
        projectName: _headerText('PROJECT NAME'),
        quoteAmount: _headerText('QUOTE AMOUNT', alignRight: true),
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

class _QuoteDetailsDataRow extends StatefulWidget {
  final QuoteDetailsRow row;
  final NumberFormat currencyFormat;

  const _QuoteDetailsDataRow({required this.row, required this.currencyFormat});

  @override
  State<_QuoteDetailsDataRow> createState() => _QuoteDetailsDataRowState();
}

class _QuoteDetailsDataRowState extends State<_QuoteDetailsDataRow> {
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
          quoteDate: _bodyText(row.quoteDate),
          expiryDate: _bodyText(row.expiryDate),
          quoteNumber: _linkText(row.quoteNumber, isUnderlined: _isHovered),
          referenceNumber: _bodyText(row.referenceNumber),
          customerName: _linkText(row.customerName, isUnderlined: _isHovered),
          invoiceNumber: row.invoiceNumber.isEmpty
              ? const SizedBox.shrink()
              : _linkText(row.invoiceNumber, isUnderlined: _isHovered),
          projectName: _bodyText(row.projectName),
          quoteAmount: _linkText(
            widget.currencyFormat.format(row.quoteAmount),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final QuoteDetailsTotals totals;
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
        quoteDate: const SizedBox.shrink(),
        expiryDate: const SizedBox.shrink(),
        quoteNumber: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        invoiceNumber: const SizedBox.shrink(),
        projectName: const SizedBox.shrink(),
        quoteAmount: _totalText(
          currencyFormat.format(totals.quoteAmount),
          align: TextAlign.right,
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget quoteDate,
  required Widget expiryDate,
  required Widget quoteNumber,
  required Widget referenceNumber,
  required Widget customerName,
  required Widget invoiceNumber,
  required Widget projectName,
  required Widget quoteAmount,
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
          quoteDate,
          flex: 3,
          padding: const EdgeInsets.only(
            top: AppTheme.space10,
            left: AppTheme.space10,
            bottom: AppTheme.space10,
          ),
        ),
        _tableCell(expiryDate, flex: 3),
        _tableCell(quoteNumber, flex: 3),
        _tableCell(referenceNumber, flex: 3),
        _tableCell(customerName, flex: 4),
        _tableCell(invoiceNumber, flex: 3),
        _tableCell(projectName, flex: 4),
        _tableCell(quoteAmount, flex: 3),
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
  if (status == 'accepted' || status == 'approved' || status == 'confirmed') {
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
