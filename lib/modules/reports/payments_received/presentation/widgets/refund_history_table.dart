import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class RefundHistoryRow {
  final String date;
  final String referenceNumber;
  final String transactionNumber;
  final String customerName;
  final String mode;
  final String notes;
  final String amountFcy;
  final String amountBcy;

  const RefundHistoryRow({
    required this.date,
    required this.referenceNumber,
    required this.transactionNumber,
    required this.customerName,
    required this.mode,
    required this.notes,
    required this.amountFcy,
    required this.amountBcy,
  });
}

class RefundHistoryTable extends StatefulWidget {
  final List<RefundHistoryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const RefundHistoryTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
  });

  @override
  State<RefundHistoryTable> createState() => _RefundHistoryTableState();
}

class _RefundHistoryTableState extends State<RefundHistoryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<RefundHistoryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <RefundHistoryRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
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
                  SizedBox(
                    height: 260,
                    child: _pageRows.isEmpty && !_isGrouped
                        ? _buildEmptyBody()
                        : Scrollbar(
                            controller: _verticalController,
                            thumbVisibility: true,
                            child: ListView.separated(
                              controller: _verticalController,
                              itemCount: _pageRows.length + (_isGrouped ? 2 : 0),
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppTheme.borderLight,
                              ),
                              itemBuilder: (context, index) {
                                if (_isGrouped && index == 0) {
                                  return _buildAppliedGroupRow();
                                }
                                if (_isGrouped && index == 1) {
                                  return _buildCurrentGroupRow();
                                }
                                final rowIndex = index - (_isGrouped ? 2 : 0);
                                return _RefundHistoryDataRow(
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
      },
    );
  }

  String _groupDisplayValue() {
    switch (widget.groupBy) {
      case 'Date':
        return '03-08-2026';
      case 'Customer Name':
        return 'Customer Name - Not mentioned';
      case 'Currency ID':
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
        date: Text(_groupDisplayValue(), style: _groupStyle),
        referenceNumber: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        mode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        amountFcy: const SizedBox.shrink(),
        amountBcy: const SizedBox.shrink(),
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
        date: Text('Current', style: _groupStyle),
        referenceNumber: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        customerName: const SizedBox.shrink(),
        mode: const SizedBox.shrink(),
        notes: const SizedBox.shrink(),
        amountFcy: const SizedBox.shrink(),
        amountBcy: const SizedBox.shrink(),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      );

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
        referenceNumber: _headerText('REFERENCE#'),
        transactionNumber: _headerText('TRANSACTION#'),
        customerName: _headerText('CUSTOMER NAME'),
        mode: _headerText('MODE'),
        notes: _headerText('NOTES'),
        amountFcy: _headerText('AMOUNT (FCY)', alignRight: true),
        amountBcy: _headerText('AMOUNT (BCY)', alignRight: true),
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

  Widget _buildEmptyBody() {
    return Center(
      child: Text(
        'There are no transactions during the selected date range.',
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _RefundHistoryDataRow extends StatefulWidget {
  final RefundHistoryRow row;

  const _RefundHistoryDataRow({required this.row});

  @override
  State<_RefundHistoryDataRow> createState() => _RefundHistoryDataRowState();
}

class _RefundHistoryDataRowState extends State<_RefundHistoryDataRow> {
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
          referenceNumber: _linkText(row.referenceNumber),
          transactionNumber: _linkText(row.transactionNumber),
          customerName: _linkText(row.customerName),
          mode: Text(row.mode, style: AppTheme.tableCell),
          notes: Text(row.notes, style: AppTheme.tableCell),
          amountFcy: _blueAmountText(row.amountFcy),
          amountBcy: _blueAmountText(row.amountBcy),
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

  Widget _blueAmountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget date,
  required Widget referenceNumber,
  required Widget transactionNumber,
  required Widget customerName,
  required Widget mode,
  required Widget notes,
  required Widget amountFcy,
  required Widget amountBcy,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 4, child: date),
      Expanded(flex: 4, child: referenceNumber),
      Expanded(flex: 5, child: transactionNumber),
      Expanded(flex: 5, child: customerName),
      Expanded(flex: 4, child: mode),
      Expanded(flex: 5, child: notes),
      Expanded(flex: 5, child: amountFcy),
      Expanded(flex: 5, child: amountBcy),
    ],
  );
}
