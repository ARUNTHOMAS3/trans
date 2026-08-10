import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class TimeToGetPaidRow {
  final String customerName;
  final String zeroToFifteenDays;
  final String sixteenToThirtyDays;
  final String thirtyOneToFortyFiveDays;
  final String aboveFortyFiveDays;

  const TimeToGetPaidRow({
    required this.customerName,
    required this.zeroToFifteenDays,
    required this.sixteenToThirtyDays,
    required this.thirtyOneToFortyFiveDays,
    required this.aboveFortyFiveDays,
  });
}

class TimeToGetPaidTable extends StatefulWidget {
  final List<TimeToGetPaidRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const TimeToGetPaidTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupBy,
  });

  @override
  State<TimeToGetPaidTable> createState() => _TimeToGetPaidTableState();
}

class _TimeToGetPaidTableState extends State<TimeToGetPaidTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<TimeToGetPaidRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <TimeToGetPaidRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1200
            ? 1200.0
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
                    height: 264,
                    child: Scrollbar(
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
                          return _TimeToGetPaidDataRow(row: _pageRows[rowIndex]);
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
                ],
              ),
            ),
          ),
        );
      },
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
        customerName: Text(
          widget.groupBy == 'Currency' ? 'INR' : widget.groupBy,
          style: _groupStyle,
        ),
        zeroToFifteenDays: const SizedBox.shrink(),
        sixteenToThirtyDays: const SizedBox.shrink(),
        thirtyOneToFortyFiveDays: const SizedBox.shrink(),
        aboveFortyFiveDays: const SizedBox.shrink(),
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
        customerName: Text('Current', style: _groupStyle),
        zeroToFifteenDays: const SizedBox.shrink(),
        sixteenToThirtyDays: const SizedBox.shrink(),
        thirtyOneToFortyFiveDays: const SizedBox.shrink(),
        aboveFortyFiveDays: const SizedBox.shrink(),
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
        zeroToFifteenDays: _headerText('0 - 15 DAYS'),
        sixteenToThirtyDays: _headerText('16 - 30 DAYS'),
        thirtyOneToFortyFiveDays: _headerText('31 - 45 DAYS'),
        aboveFortyFiveDays: _headerText('ABOVE 45 DAYS'),
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(value, style: ReportTableTypography.header);
  }
}

class _TimeToGetPaidDataRow extends StatefulWidget {
  final TimeToGetPaidRow row;

  const _TimeToGetPaidDataRow({required this.row});

  @override
  State<_TimeToGetPaidDataRow> createState() => _TimeToGetPaidDataRowState();
}

class _TimeToGetPaidDataRowState extends State<_TimeToGetPaidDataRow> {
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
          zeroToFifteenDays: Text(
            row.zeroToFifteenDays,
            style: AppTheme.tableCell,
          ),
          sixteenToThirtyDays: Text(
            row.sixteenToThirtyDays,
            style: AppTheme.tableCell,
          ),
          thirtyOneToFortyFiveDays: Text(
            row.thirtyOneToFortyFiveDays,
            style: AppTheme.tableCell,
          ),
          aboveFortyFiveDays: Text(
            row.aboveFortyFiveDays,
            style: AppTheme.tableCell,
          ),
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
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget customerName,
  required Widget zeroToFifteenDays,
  required Widget sixteenToThirtyDays,
  required Widget thirtyOneToFortyFiveDays,
  required Widget aboveFortyFiveDays,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 4, child: customerName),
      Expanded(flex: 4, child: zeroToFifteenDays),
      Expanded(flex: 4, child: sixteenToThirtyDays),
      Expanded(flex: 4, child: thirtyOneToFortyFiveDays),
      Expanded(flex: 4, child: aboveFortyFiveDays),
    ],
  );
}
