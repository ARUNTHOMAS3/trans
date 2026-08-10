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

class ExpenseSummaryByCategoryRow {
  final String categoryName;
  final double amountValue;
  final double amountWithTaxValue;

  const ExpenseSummaryByCategoryRow({
    required this.categoryName,
    required this.amountValue,
    required this.amountWithTaxValue,
  });

  factory ExpenseSummaryByCategoryRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String textValue(String key, [String fallback = '-']) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    return ExpenseSummaryByCategoryRow(
      categoryName: textValue('categoryName'),
      amountValue: numberValue('amount'),
      amountWithTaxValue: numberValue('amountWithTax'),
    );
  }

  String get amount => _currencyFormat.format(amountValue);
  String get amountWithTax => _currencyFormat.format(amountWithTaxValue);
}

class ExpenseSummaryByCategoryTable extends StatefulWidget {
  final List<ExpenseSummaryByCategoryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ExpenseSummaryByCategoryRow>? onCategorySelected;

  const ExpenseSummaryByCategoryTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.onCategorySelected,
  });

  @override
  State<ExpenseSummaryByCategoryTable> createState() =>
      _ExpenseSummaryByCategoryTableState();
}

class _ExpenseSummaryByCategoryTableState
    extends State<ExpenseSummaryByCategoryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<ExpenseSummaryByCategoryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <ExpenseSummaryByCategoryRow>[];
    }
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

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
                height: 280,
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
                      return _ExpenseSummaryByCategoryDataRow(
                        row: _pageRows[index],
                        onCategorySelected: widget.onCategorySelected,
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
        categoryName: Row(
          children: [
            Text('CATEGORY NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
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
        categoryName: Text('Total', style: _totalStyle),
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

class _ExpenseSummaryByCategoryDataRow extends StatefulWidget {
  final ExpenseSummaryByCategoryRow row;
  final ValueChanged<ExpenseSummaryByCategoryRow>? onCategorySelected;

  const _ExpenseSummaryByCategoryDataRow({
    required this.row,
    required this.onCategorySelected,
  });

  @override
  State<_ExpenseSummaryByCategoryDataRow> createState() =>
      _ExpenseSummaryByCategoryDataRowState();
}

class _ExpenseSummaryByCategoryDataRowState
    extends State<_ExpenseSummaryByCategoryDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isClickable = widget.onCategorySelected != null;
    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isClickable
            ? () => widget.onCategorySelected?.call(widget.row)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
            vertical: AppTheme.space12,
          ),
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          child: _buildTableRow(
            categoryName: _plainText(row.categoryName),
            amount: _blueAmountText(row.amount),
            amountWithTax: _blueAmountText(row.amountWithTax),
          ),
        ),
      ),
    );
  }

  Widget _plainText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
    );
  }

  Widget _blueAmountText(String value) {
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
  required Widget categoryName,
  required Widget amount,
  required Widget amountWithTax,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 7, child: categoryName),
      Expanded(flex: 4, child: amount),
      Expanded(flex: 4, child: amountWithTax),
    ],
  );
}
