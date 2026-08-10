import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class ArAgingSummaryTable extends StatefulWidget {
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const ArAgingSummaryTable({
    super.key,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<ArAgingSummaryTable> createState() => _ArAgingSummaryTableState();
}

class _ArAgingSummaryTableState extends State<ArAgingSummaryTable> {
  final ScrollController _horizontalController = ScrollController();

  static const int _totalCount = 0;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
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
          width: 1360,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              const ReportTableEmptyBody(minHeight: 345),
              ReportPaginationFooter(
                totalCount: _totalCount,
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
        current: _headerText('CURRENT'),
        oneToFifteen: _headerText('1-15 DAYS'),
        sixteenToThirty: _headerText('16-30 DAYS'),
        thirtyOneToFortyFive: _headerText('31-45 DAYS'),
        overFortyFive: _headerText('> 45 DAYS'),
        total: _headerText('TOTAL'),
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
}

Widget _buildTableRow({
  required Widget customerName,
  required Widget current,
  required Widget oneToFifteen,
  required Widget sixteenToThirty,
  required Widget thirtyOneToFortyFive,
  required Widget overFortyFive,
  required Widget total,
}) {
  return Row(
    children: [
      Expanded(flex: 4, child: customerName),
      Expanded(flex: 2, child: current),
      Expanded(flex: 2, child: oneToFifteen),
      Expanded(flex: 2, child: sixteenToThirty),
      Expanded(flex: 2, child: thirtyOneToFortyFive),
      Expanded(flex: 2, child: overFortyFive),
      Expanded(flex: 2, child: total),
    ],
  );
}
