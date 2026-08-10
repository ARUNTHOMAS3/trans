import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class ApAgingSummaryRow {
  final String vendorName;
  final String current;
  final String oneToFifteen;
  final String sixteenToThirty;
  final String thirtyOneToFortyFive;
  final String overFortyFive;
  final String total;
  final String totalFcy;

  const ApAgingSummaryRow({
    required this.vendorName,
    required this.current,
    required this.oneToFifteen,
    required this.sixteenToThirty,
    required this.thirtyOneToFortyFive,
    required this.overFortyFive,
    required this.total,
    required this.totalFcy,
  });
}

class ApAgingSummaryTable extends StatefulWidget {
  final List<ApAgingSummaryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const ApAgingSummaryTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
  });

  @override
  State<ApAgingSummaryTable> createState() => _ApAgingSummaryTableState();
}

class _ApAgingSummaryTableState extends State<ApAgingSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const String _totalCurrent = '\u20B972,646.05';
  static const String _totalOneToFifteen = '\u20B90.00';
  static const String _totalSixteenToThirty = '\u20B92,100.00';
  static const String _totalThirtyOneToFortyFive = '\u20B90.00';
  static const String _totalOverFortyFive = '\u20B9185.00';
  static const String _totalOutstanding = '\u20B974,931.05';
  static const String _totalFcy = '';

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<ApAgingSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <ApAgingSummaryRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1360
            ? 1360.0
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
                    height: 255,
                    child: Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: _pageRows.length > 5,
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
                          return _ApAgingSummaryDataRow(row: _pageRows[rowIndex]);
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
        current: _headerText('CURRENT'),
        oneToFifteen: _headerText('1-15 DAYS'),
        sixteenToThirty: _headerText('16-30 DAYS'),
        thirtyOneToFortyFive: _headerText('31-45 DAYS'),
        overFortyFive: _headerText('> 45 DAYS'),
        total: _headerText('TOTAL'),
        totalFcy: _headerText('TOTAL (FCY)'),
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
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
        current: _blueTotalText(_totalCurrent),
        oneToFifteen: _blueTotalText(_totalOneToFifteen),
        sixteenToThirty: _blueTotalText(_totalSixteenToThirty),
        thirtyOneToFortyFive: _blueTotalText(_totalThirtyOneToFortyFive),
        overFortyFive: _blueTotalText(_totalOverFortyFive),
        total: _blueTotalText(_totalOutstanding),
        totalFcy: Text(
          _totalFcy,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
      ),
    );
  }

  Widget _blueTotalText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: _totalStyle.copyWith(color: AppTheme.primaryBlue),
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );

  String _groupDisplayValue() {
    switch (widget.groupBy) {
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
        vendorName: Text(_groupDisplayValue(), style: _groupStyle),
        current: const SizedBox.shrink(),
        oneToFifteen: const SizedBox.shrink(),
        sixteenToThirty: const SizedBox.shrink(),
        thirtyOneToFortyFive: const SizedBox.shrink(),
        overFortyFive: const SizedBox.shrink(),
        total: const SizedBox.shrink(),
        totalFcy: const SizedBox.shrink(),
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
        current: const SizedBox.shrink(),
        oneToFifteen: const SizedBox.shrink(),
        sixteenToThirty: const SizedBox.shrink(),
        thirtyOneToFortyFive: const SizedBox.shrink(),
        overFortyFive: const SizedBox.shrink(),
        total: const SizedBox.shrink(),
        totalFcy: const SizedBox.shrink(),
      ),
    );
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      );
}

class _ApAgingSummaryDataRow extends StatefulWidget {
  final ApAgingSummaryRow row;

  const _ApAgingSummaryDataRow({required this.row});

  @override
  State<_ApAgingSummaryDataRow> createState() => _ApAgingSummaryDataRowState();
}

class _ApAgingSummaryDataRowState extends State<_ApAgingSummaryDataRow> {
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
          current: _blueAmountText(row.current),
          oneToFifteen: _blueAmountText(row.oneToFifteen),
          sixteenToThirty: _blueAmountText(row.sixteenToThirty),
          thirtyOneToFortyFive: _blueAmountText(row.thirtyOneToFortyFive),
          overFortyFive: _blueAmountText(row.overFortyFive),
          total: _blueAmountText(row.total),
          totalFcy: _amountText(row.totalFcy),
        ),
      ),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
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
  required Widget current,
  required Widget oneToFifteen,
  required Widget sixteenToThirty,
  required Widget thirtyOneToFortyFive,
  required Widget overFortyFive,
  required Widget total,
  required Widget totalFcy,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 4, child: vendorName),
      Expanded(flex: 2, child: current),
      Expanded(flex: 2, child: oneToFifteen),
      Expanded(flex: 2, child: sixteenToThirty),
      Expanded(flex: 2, child: thirtyOneToFortyFive),
      Expanded(flex: 2, child: overFortyFive),
      Expanded(flex: 2, child: total),
      Expanded(flex: 2, child: totalFcy),
    ],
  );
}
