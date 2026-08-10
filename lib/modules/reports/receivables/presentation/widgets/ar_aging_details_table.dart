import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class ArAgingDetailsRow {
  final String date;
  final String dueDate;
  final String transactionNumber;
  final String type;
  final String status;
  final String customerName;
  final String age;
  final String amount;
  final String balanceDue;

  const ArAgingDetailsRow({
    required this.date,
    required this.dueDate,
    required this.transactionNumber,
    required this.type,
    required this.status,
    required this.customerName,
    required this.age,
    required this.amount,
    required this.balanceDue,
  });
}

class ArAgingDetailsTable extends StatefulWidget {
  final List<ArAgingDetailsRow> rows;
  final int page;
  final String groupBy;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const ArAgingDetailsTable({
    super.key,
    required this.rows,
    required this.groupBy,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<ArAgingDetailsTable> createState() => _ArAgingDetailsTableState();
}

class _ArAgingDetailsTableState extends State<ArAgingDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const String _totalAmount = '\u20B97,11,180.00';
  static const String _totalBalanceDue = '\u20B97,11,080.00';

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<ArAgingDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <ArAgingDetailsRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1490,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 345,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _verticalController,
                    itemCount: _pageRows.length + (_isGrouped ? 3 : 2),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) {
                      if (_isGrouped && index == 0) {
                        return _buildAppliedGroupRow();
                      }
                      final currentIndex = _isGrouped ? 1 : 0;
                      if (index == currentIndex) return _buildCurrentGroupRow();
                      final totalIndex = _pageRows.length + (_isGrouped ? 2 : 1);
                      if (index == totalIndex) return _buildTotalRow();
                      final rowIndex = index - (_isGrouped ? 2 : 1);
                      return _ArAgingDetailsDataRow(row: _pageRows[rowIndex]);
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
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        dueDate: _headerText('DUE DATE'),
        transactionNumber: _headerText('TRANSACTION#'),
        type: _headerText('TYPE'),
        status: _headerText('STATUS'),
        customerName: _headerText('CUSTOMER NAME'),
        age: _headerText('AGE'),
        amount: _headerText('AMOUNT', alignRight: true),
        balanceDue: _headerText('BALANCE DUE', alignRight: true),
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

  Widget _buildAppliedGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        date: Text(_groupDisplayValue(), style: _groupStyle),
        dueDate: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        age: const SizedBox.shrink(),
        amount: _totalText(_totalAmount),
        balanceDue: _totalText(_totalBalanceDue),
      ),
    );
  }

  String _groupDisplayValue() {
    switch (widget.groupBy) {
      case 'Salesperson':
        return 'ALTHAF';
      case 'Currency':
        return 'INR';
      case 'Customer Name':
        return 'Customer Name - Not mentioned';
      default:
        return widget.groupBy;
    }
  }
  Widget _buildCurrentGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        date: Text('Current', style: _groupStyle),
        dueDate: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        age: const SizedBox.shrink(),
        amount: _totalText(_totalAmount),
        balanceDue: _totalText(_totalBalanceDue),
      ),
    );
  }

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        date: Text('Total', style: _totalStyle),
        dueDate: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        age: const SizedBox.shrink(),
        amount: _totalText(_totalAmount),
        balanceDue: _totalText(_totalBalanceDue),
      ),
    );
  }

  Widget _totalText(String value) {
    return Text(value, textAlign: TextAlign.right, style: _totalStyle);
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
  );

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );
}

class _ArAgingDetailsDataRow extends StatefulWidget {
  final ArAgingDetailsRow row;

  const _ArAgingDetailsDataRow({required this.row});

  @override
  State<_ArAgingDetailsDataRow> createState() => _ArAgingDetailsDataRowState();
}

class _ArAgingDetailsDataRowState extends State<_ArAgingDetailsDataRow> {
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
          vertical: AppTheme.space12,
        ),
        color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
        child: _buildTableRow(
          date: Text(row.date, style: AppTheme.tableCell),
          dueDate: Text(row.dueDate, style: AppTheme.tableCell),
          transactionNumber: _linkText(row.transactionNumber),
          type: Text(row.type, style: AppTheme.tableCell),
          status: Text(
            row.status,
            style: AppTheme.tableCell.copyWith(
              color: row.status == 'Partially Paid'
                  ? AppTheme.successTextDark
                  : AppTheme.primaryBlue,
            ),
          ),
          customerName: _linkText(row.customerName),
          age: Text(row.age, style: AppTheme.tableCell),
          amount: _amountText(row.amount),
          balanceDue: _amountText(row.balanceDue),
        ),
      ),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }

  Widget _amountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }
}

Widget _buildTableRow({
  required Widget date,
  required Widget dueDate,
  required Widget transactionNumber,
  required Widget type,
  required Widget status,
  required Widget customerName,
  required Widget age,
  required Widget amount,
  required Widget balanceDue,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: date),
      Expanded(flex: 2, child: dueDate),
      Expanded(flex: 2, child: transactionNumber),
      Expanded(flex: 2, child: type),
      Expanded(flex: 2, child: status),
      Expanded(flex: 4, child: customerName),
      Expanded(flex: 2, child: age),
      Expanded(flex: 2, child: amount),
      Expanded(flex: 2, child: balanceDue),
    ],
  );
}
