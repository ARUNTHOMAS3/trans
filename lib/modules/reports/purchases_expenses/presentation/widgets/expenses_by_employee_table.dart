import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  symbol: '\u20B9',
  decimalDigits: 2,
);

class ExpensesByEmployeeRow {
  final String employee;
  final double distanceValue;
  final int expenseCountValue;
  final double amountValue;
  final double amountWithTaxValue;

  const ExpensesByEmployeeRow({
    required this.employee,
    required this.distanceValue,
    required this.expenseCountValue,
    required this.amountValue,
    required this.amountWithTaxValue,
  });

  factory ExpensesByEmployeeRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String textValue(String key, [String fallback = '-']) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return ExpensesByEmployeeRow(
      employee: textValue('employeeName', 'Others'),
      distanceValue: numberValue('distance'),
      expenseCountValue: numberValue('expenseCount').round(),
      amountValue: numberValue('amount'),
      amountWithTaxValue: numberValue('amountWithTax'),
    );
  }

  String get distance {
    final distanceText = distanceValue.toStringAsFixed(3);
    return distanceText;
  }

  String get expenseCount => expenseCountValue.toString();
  String get amount => _currencyFormat.format(amountValue);
  String get amountWithTax => _currencyFormat.format(amountWithTaxValue);
}

class ExpensesByEmployeeTable extends StatefulWidget {
  final List<ExpensesByEmployeeRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const ExpensesByEmployeeTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<ExpensesByEmployeeTable> createState() =>
      _ExpensesByEmployeeTableState();
}

class _ExpensesByEmployeeTableState extends State<ExpensesByEmployeeTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<ExpensesByEmployeeRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <ExpensesByEmployeeRow>[];
    }
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _totalDistance =>
      widget.rows.fold<double>(0, (total, row) => total + row.distanceValue);

  int get _totalExpenseCount =>
      widget.rows.fold<int>(0, (total, row) => total + row.expenseCountValue);

  double get _totalAmount =>
      widget.rows.fold<double>(0, (total, row) => total + row.amountValue);

  double get _totalAmountWithTax => widget.rows.fold<double>(
    0,
    (total, row) => total + row.amountWithTaxValue,
  );

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
          width: 1380,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 260,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: _pageRows.length > 6,
                  child: ListView.separated(
                    controller: _verticalController,
                    itemCount: _pageRows.length + 1,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) {
                      if (index == _pageRows.length) return _buildTotalRow();
                      return _ExpensesByEmployeeDataRow(row: _pageRows[index]);
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
        employee: Row(
          children: [
            Text('EMPLOYEE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        distance: _headerText('DISTANCE', alignRight: true),
        expenseCount: _headerText('EXPENSE COUNT', alignRight: true),
        amount: _headerText('AMOUNT', alignRight: true),
        amountWithTax: _headerText('AMOUNT WITH TAX', alignRight: true),
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
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: _buildTableRow(
        employee: Text('Total', style: _totalStyle),
        distance: Text(
          _totalDistance == 0 ? '' : _totalDistance.toStringAsFixed(3),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        expenseCount: Text(
          _totalExpenseCount == 0 ? '' : _totalExpenseCount.toString(),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amount: Text(
          _currencyFormat.format(_totalAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amountWithTax: Text(
          _currencyFormat.format(_totalAmountWithTax),
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
}

class _ExpensesByEmployeeDataRow extends StatefulWidget {
  final ExpensesByEmployeeRow row;

  const _ExpensesByEmployeeDataRow({required this.row});

  @override
  State<_ExpensesByEmployeeDataRow> createState() =>
      _ExpensesByEmployeeDataRowState();
}

class _ExpensesByEmployeeDataRowState
    extends State<_ExpensesByEmployeeDataRow> {
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
          employee: _plainText(row.employee),
          distance: _plainText(row.distance, alignRight: true),
          expenseCount: _plainText(row.expenseCount, alignRight: true),
          amount: _amountText(row.amount),
          amountWithTax: _amountText(row.amountWithTax),
        ),
      ),
    );
  }

  Widget _plainText(String value, {bool alignRight = false}) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
    );
  }

  Widget _amountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget employee,
  required Widget distance,
  required Widget expenseCount,
  required Widget amount,
  required Widget amountWithTax,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 5, child: employee),
      Expanded(flex: 4, child: distance),
      Expanded(flex: 4, child: expenseCount),
      Expanded(flex: 5, child: amount),
      Expanded(flex: 5, child: amountWithTax),
    ],
  );
}
