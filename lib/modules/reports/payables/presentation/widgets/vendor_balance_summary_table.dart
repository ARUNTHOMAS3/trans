import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class VendorBalanceSummaryRow {
  final String vendorName;
  final String billedAmount;
  final String amountPaid;
  final String closingBalance;

  const VendorBalanceSummaryRow({
    required this.vendorName,
    required this.billedAmount,
    required this.amountPaid,
    required this.closingBalance,
  });
}

class VendorBalanceSummaryTable extends StatefulWidget {
  final List<VendorBalanceSummaryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const VendorBalanceSummaryTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
  });

  @override
  State<VendorBalanceSummaryTable> createState() =>
      _VendorBalanceSummaryTableState();
}

class _VendorBalanceSummaryTableState extends State<VendorBalanceSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const String _totalBilledAmount = '\u20B90.00';
  static const String _totalAmountPaid = '\u20B90.00';
  static const String _totalClosingBalance = '\u20B912,43,153.05 Dr';

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<VendorBalanceSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <VendorBalanceSummaryRow>[];
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
                  thumbVisibility: _pageRows.length > 6,
                  child: ListView.separated(
                    controller: _verticalController,
                    itemCount: _pageRows.length + (_isGrouped ? 3 : 1),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
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
                      return _VendorBalanceSummaryDataRow(
                        row: _pageRows[rowIndex],
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
        vendorName: Row(
          children: [
            Text('VENDOR NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        billedAmount: _headerText('BILLED AMOUNT', alignRight: true),
        amountPaid: _headerText('AMOUNT PAID', alignRight: true),
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
        vendorName: Text('Total', style: _totalStyle),
        billedAmount: Text(
          _totalBilledAmount,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amountPaid: Text(
          _totalAmountPaid,
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

  String _groupDisplayValue() {
    switch (widget.groupBy) {
      case 'Vendor Name':
        return 'Vendor Name - Not mentioned';
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
        vendorName: Text(_groupDisplayValue(), style: _groupStyle),
        billedAmount: Text(
          _totalBilledAmount,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        amountPaid: Text(
          _totalAmountPaid,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        closingBalance: Text(
          _totalClosingBalance,
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
        vendorName: Text('Current', style: _groupStyle),
        billedAmount: Text(
          _totalBilledAmount,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        amountPaid: Text(
          _totalAmountPaid,
          textAlign: TextAlign.right,
          style: _groupStyle,
        ),
        closingBalance: Text(
          _totalClosingBalance,
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

class _VendorBalanceSummaryDataRow extends StatefulWidget {
  final VendorBalanceSummaryRow row;

  const _VendorBalanceSummaryDataRow({required this.row});

  @override
  State<_VendorBalanceSummaryDataRow> createState() =>
      _VendorBalanceSummaryDataRowState();
}

class _VendorBalanceSummaryDataRowState
    extends State<_VendorBalanceSummaryDataRow> {
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
          vendorName: _linkText(row.vendorName),
          billedAmount: _amountText(row.billedAmount),
          amountPaid: _amountText(row.amountPaid),
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
  required Widget vendorName,
  required Widget billedAmount,
  required Widget amountPaid,
  required Widget closingBalance,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 7, child: vendorName),
      Expanded(flex: 3, child: billedAmount),
      Expanded(flex: 3, child: amountPaid),
      Expanded(flex: 3, child: closingBalance),
    ],
  );
}
