import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  symbol: '\u20B9',
  decimalDigits: 2,
);

class RecurringInvoiceDetailsRow {
  final String recurringInvoiceId;
  final String status;
  final String profileName;
  final String customerName;
  final String frequency;
  final String lastInvoiceDate;
  final String nextInvoiceDate;
  final String expiryDate;
  final double amount;

  const RecurringInvoiceDetailsRow({
    required this.recurringInvoiceId,
    required this.status,
    required this.profileName,
    required this.customerName,
    required this.frequency,
    required this.lastInvoiceDate,
    required this.nextInvoiceDate,
    required this.expiryDate,
    required this.amount,
  });

  factory RecurringInvoiceDetailsRow.fromJson(Map<String, dynamic> item) {
    String textValue(String key, {String fallback = '-'}) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final frequency = textValue('frequency');
    final repeatEvery = textValue('repeatEvery', fallback: '');
    final repeatType = textValue('repeatType', fallback: '');
    final fallbackFrequency = [
      repeatEvery,
      repeatType,
    ].where((part) => part.trim().isNotEmpty && part != '-').join(' ');

    return RecurringInvoiceDetailsRow(
      recurringInvoiceId: textValue('recurringInvoiceId', fallback: ''),
      status: textValue('status'),
      profileName: textValue('profileName'),
      customerName: textValue('customerName'),
      frequency: frequency == '-' && fallbackFrequency.isNotEmpty
          ? fallbackFrequency
          : frequency,
      lastInvoiceDate: textValue('lastInvoiceDate'),
      nextInvoiceDate: textValue('nextInvoiceDate'),
      expiryDate: textValue('expiryDate'),
      amount: numberValue('grandTotal') != 0
          ? numberValue('grandTotal')
          : numberValue('amount'),
    );
  }
}

class RecurringInvoiceDetailsTable extends StatefulWidget {
  final List<RecurringInvoiceDetailsRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<RecurringInvoiceDetailsRow>? onRowSelected;
  final String groupBy;

  const RecurringInvoiceDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
    this.onRowSelected,
  });

  @override
  State<RecurringInvoiceDetailsTable> createState() =>
      _RecurringInvoiceDetailsTableState();
}

class _RecurringInvoiceDetailsTableState
    extends State<RecurringInvoiceDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<RecurringInvoiceDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <RecurringInvoiceDetailsRow>[];
    }
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _amountTotal =>
      widget.rows.fold<double>(0, (total, row) => total + row.amount);

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
                      minHeight: 260,
                      message: 'No data to display',
                    )
                  else
                    SizedBox(
                      height: 260,
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: _pageRows.length > 6,
                        child: ListView.separated(
                          controller: _verticalController,
                          itemCount: _pageRows.length + (_isGrouped ? 3 : 1),
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.borderLight,
                          ),
                          itemBuilder: (context, index) {
                            if (_isGrouped && index == 0) {
                              return _buildAppliedGroupRow();
                            }
                            final currentIndex = _isGrouped ? 1 : 0;
                            if (_isGrouped && index == currentIndex) {
                              return _buildCurrentGroupRow();
                            }
                            final totalIndex = _pageRows.length + (_isGrouped ? 2 : 0);
                            if (index == totalIndex) {
                              return _buildTotalRow();
                            }
                            final rowIndex = index - (_isGrouped ? 2 : 0);
                            return _RecurringInvoiceDetailsDataRow(
                              row: _pageRows[rowIndex],
                              onRowSelected: widget.onRowSelected,
                            );
                          },
                        ),
                      ),
                    ),
                  ReportPaginationFooter(
                    totalCount: widget.rows.length,
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
        profileName: _headerText('PROFILE NAME'),
        customerName: _headerText('CUSTOMER NAME'),
        frequency: _headerText('FREQUENCY'),
        lastInvoiceDate: _headerText('LAST INVOICE DATE'),
        nextInvoiceDate: _headerText('NEXT INVOICE DATE'),
        expiryDate: _headerText('EXPIRY DATE'),
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

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        status: Text('Total', style: _totalStyle),
        profileName: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        frequency: const SizedBox.shrink(),
        lastInvoiceDate: const SizedBox.shrink(),
        nextInvoiceDate: const SizedBox.shrink(),
        expiryDate: const SizedBox.shrink(),
        amount: Text(
          _currencyFormat.format(_amountTotal),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
      ),
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );

  String _groupDisplayValue() {
    switch (widget.groupBy) {
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        status: Text(_groupDisplayValue(), style: _groupStyle),
        profileName: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        frequency: const SizedBox.shrink(),
        lastInvoiceDate: const SizedBox.shrink(),
        nextInvoiceDate: const SizedBox.shrink(),
        expiryDate: const SizedBox.shrink(),
        amount: Text(
          _currencyFormat.format(_amountTotal),
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
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
        profileName: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        frequency: const SizedBox.shrink(),
        lastInvoiceDate: const SizedBox.shrink(),
        nextInvoiceDate: const SizedBox.shrink(),
        expiryDate: const SizedBox.shrink(),
        amount: Text(
          _currencyFormat.format(_amountTotal),
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      );
}

class _RecurringInvoiceDetailsDataRow extends StatefulWidget {
  final RecurringInvoiceDetailsRow row;
  final ValueChanged<RecurringInvoiceDetailsRow>? onRowSelected;

  const _RecurringInvoiceDetailsDataRow({
    required this.row,
    required this.onRowSelected,
  });

  @override
  State<_RecurringInvoiceDetailsDataRow> createState() =>
      _RecurringInvoiceDetailsDataRowState();
}

class _RecurringInvoiceDetailsDataRowState
    extends State<_RecurringInvoiceDetailsDataRow> {
  bool _isHovered = false;

  bool get _isClickable => widget.onRowSelected != null;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _handlePressed() {
    widget.onRowSelected?.call(widget.row);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
      child: _buildTableRow(
        status: Text(row.status, style: _statusStyle(row.status)),
        profileName: _linkText(row.profileName),
        customerName: _linkText(row.customerName),
        frequency: Text(row.frequency, style: AppTheme.tableCell),
        lastInvoiceDate: Text(row.lastInvoiceDate, style: AppTheme.tableCell),
        nextInvoiceDate: Text(row.nextInvoiceDate, style: AppTheme.tableCell),
        expiryDate: Text(row.expiryDate, style: AppTheme.tableCell),
        amount: _amountText(row.amount),
      ),
    );

    return MouseRegion(
      cursor: _isClickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isClickable ? _handlePressed : null,
        child: content,
      ),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        decoration: _isHovered && _isClickable
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _amountText(double value) {
    return Text(
      _currencyFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w600),
    );
  }

  TextStyle _statusStyle(String status) {
    return AppTheme.tableCell.copyWith(
      color: status.toLowerCase() == 'active'
          ? AppTheme.successDark
          : AppTheme.textSecondary,
      fontWeight: FontWeight.w500,
    );
  }
}

Widget _buildTableRow({
  required Widget status,
  required Widget profileName,
  required Widget customerName,
  required Widget frequency,
  required Widget lastInvoiceDate,
  required Widget nextInvoiceDate,
  required Widget expiryDate,
  required Widget amount,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: status),
      Expanded(flex: 5, child: profileName),
      Expanded(flex: 5, child: customerName),
      Expanded(flex: 4, child: frequency),
      Expanded(flex: 4, child: lastInvoiceDate),
      Expanded(flex: 4, child: nextInvoiceDate),
      Expanded(flex: 4, child: expiryDate),
      Expanded(flex: 4, child: amount),
    ],
  );
}
