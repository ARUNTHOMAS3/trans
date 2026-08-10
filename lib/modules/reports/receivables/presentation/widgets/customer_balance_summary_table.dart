import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class CustomerBalanceSummaryRow {
  final String customerName;
  final String invoicedAmount;
  final String amountReceived;
  final String closingBalance;

  const CustomerBalanceSummaryRow({
    required this.customerName,
    required this.invoicedAmount,
    required this.amountReceived,
    required this.closingBalance,
  });
}

class CustomerBalanceSummaryTable extends StatefulWidget {
  final List<CustomerBalanceSummaryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const CustomerBalanceSummaryTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<CustomerBalanceSummaryTable> createState() =>
      _CustomerBalanceSummaryTableState();
}

class _CustomerBalanceSummaryTableState
    extends State<CustomerBalanceSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const String _totalInvoicedAmount = '\u20B9839.00';
  static const String _totalAmountReceived = '\u20B9630.00';
  static const String _totalClosingBalance = '\u20B914,62,603.00 Cr';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<CustomerBalanceSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <CustomerBalanceSummaryRow>[];
    }
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
          width: 1380,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 310,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _verticalController,
                    itemCount: _pageRows.length + 1,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) {
                      if (index == _pageRows.length) {
                        return _buildTotalRow();
                      }
                      return _CustomerBalanceSummaryDataRow(
                        row: _pageRows[index],
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
        invoicedAmount: _headerText('INVOICED AMOUNT', alignRight: true),
        amountReceived: _headerText('AMOUNT RECEIVED', alignRight: true),
        closingBalance: _headerText('CLOSING BALANCE', alignRight: true),
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
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        customerName: Text('Total', style: _totalStyle),
        invoicedAmount: Text(
          _totalInvoicedAmount,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amountReceived: Text(
          _totalAmountReceived,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        closingBalance: Text(
          _totalClosingBalance,
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

class _CustomerBalanceSummaryDataRow extends StatefulWidget {
  final CustomerBalanceSummaryRow row;

  const _CustomerBalanceSummaryDataRow({required this.row});

  @override
  State<_CustomerBalanceSummaryDataRow> createState() =>
      _CustomerBalanceSummaryDataRowState();
}

class _CustomerBalanceSummaryDataRowState
    extends State<_CustomerBalanceSummaryDataRow> {
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
          customerName: _linkText(row.customerName),
          invoicedAmount: _amountText(row.invoicedAmount),
          amountReceived: _amountText(row.amountReceived),
          closingBalance: _amountText(row.closingBalance),
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
      style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
    );
  }
}

Widget _buildTableRow({
  required Widget customerName,
  required Widget invoicedAmount,
  required Widget amountReceived,
  required Widget closingBalance,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 7, child: customerName),
      Expanded(flex: 3, child: invoicedAmount),
      Expanded(flex: 3, child: amountReceived),
      Expanded(flex: 3, child: closingBalance),
    ],
  );
}
