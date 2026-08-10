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

class ExpensesByCustomerRow {
  final String customerName;
  final int expenseCountValue;
  final double expenseAmountValue;
  final double expenseAmountWithTaxValue;

  const ExpensesByCustomerRow({
    required this.customerName,
    required this.expenseCountValue,
    required this.expenseAmountValue,
    required this.expenseAmountWithTaxValue,
  });

  factory ExpensesByCustomerRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String textValue(String key, [String fallback = '-']) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return ExpensesByCustomerRow(
      customerName: textValue('customerName', 'Others'),
      expenseCountValue: numberValue('expenseCount').round(),
      expenseAmountValue: numberValue('expenseAmount'),
      expenseAmountWithTaxValue: numberValue('expenseAmountWithTax'),
    );
  }

  String get expenseCount => expenseCountValue.toString();
  String get expenseAmount => _currencyFormat.format(expenseAmountValue);
  String get expenseAmountWithTax =>
      _currencyFormat.format(expenseAmountWithTaxValue);
}

class ExpensesByCustomerTable extends StatefulWidget {
  final List<ExpensesByCustomerRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ExpensesByCustomerRow>? onOthersSelected;

  const ExpensesByCustomerTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.onOthersSelected,
  });

  @override
  State<ExpensesByCustomerTable> createState() =>
      _ExpensesByCustomerTableState();
}

class _ExpensesByCustomerTableState extends State<ExpensesByCustomerTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<ExpensesByCustomerRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <ExpensesByCustomerRow>[];
    }
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  int get _totalExpenseCount =>
      widget.rows.fold<int>(0, (total, row) => total + row.expenseCountValue);

  double get _totalExpenseAmount => widget.rows.fold<double>(
    0,
    (total, row) => total + row.expenseAmountValue,
  );

  double get _totalExpenseAmountWithTax => widget.rows.fold<double>(
    0,
    (total, row) => total + row.expenseAmountWithTaxValue,
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
                      return _ExpensesByCustomerDataRow(
                        row: _pageRows[index],
                        onOthersSelected: widget.onOthersSelected,
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
        customerName: Row(
          children: [
            Text('CUSTOMER NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        expenseCount: _headerText('EXPENSE COUNT', alignRight: true),
        expenseAmount: _headerText('EXPENSE AMOUNT', alignRight: true),
        expenseAmountWithTax: _headerText(
          'EXPENSE AMOUNT WITH TAX',
          alignRight: true,
        ),
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
        customerName: Text('Total', style: _totalStyle),
        expenseCount: Text(
          _totalExpenseCount.toString(),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        expenseAmount: Text(
          _currencyFormat.format(_totalExpenseAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        expenseAmountWithTax: Text(
          _currencyFormat.format(_totalExpenseAmountWithTax),
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

class _ExpensesByCustomerDataRow extends StatefulWidget {
  final ExpensesByCustomerRow row;
  final ValueChanged<ExpensesByCustomerRow>? onOthersSelected;

  const _ExpensesByCustomerDataRow({
    required this.row,
    required this.onOthersSelected,
  });

  @override
  State<_ExpensesByCustomerDataRow> createState() =>
      _ExpensesByCustomerDataRowState();
}

class _ExpensesByCustomerDataRowState
    extends State<_ExpensesByCustomerDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isOthers = row.customerName == 'Others';
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
      child: _buildTableRow(
        customerName: isOthers
            ? _plainText(row.customerName)
            : _linkText(row.customerName),
        expenseCount: _plainText(row.expenseCount, alignRight: true),
        expenseAmount: _amountText(row.expenseAmount),
        expenseAmountWithTax: _amountText(row.expenseAmountWithTax),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isOthers ? () => widget.onOthersSelected?.call(row) : null,
        child: content,
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

  Widget _linkText(String value) {
    return Text(
      value,
      textAlign: TextAlign.left,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
      overflow: TextOverflow.ellipsis,
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
      overflow: TextOverflow.ellipsis,
    );
  }
}

Widget _buildTableRow({
  required Widget customerName,
  required Widget expenseCount,
  required Widget expenseAmount,
  required Widget expenseAmountWithTax,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 6, child: customerName),
      Expanded(flex: 4, child: expenseCount),
      Expanded(flex: 5, child: expenseAmount),
      Expanded(flex: 5, child: expenseAmountWithTax),
    ],
  );
}
