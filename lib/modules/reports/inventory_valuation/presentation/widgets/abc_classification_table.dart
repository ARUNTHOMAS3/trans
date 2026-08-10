import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class AbcClassificationRow {
  final String itemName;
  final double cumulativeValue;
  final double cumulativeShare;
  final String currentClass;

  const AbcClassificationRow({
    required this.itemName,
    required this.cumulativeValue,
    required this.cumulativeShare,
    required this.currentClass,
  });
}

class AbcClassificationTable extends StatefulWidget {
  final List<AbcClassificationRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const AbcClassificationTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<AbcClassificationTable> createState() => _AbcClassificationTableState();
}

class _AbcClassificationTableState extends State<AbcClassificationTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _valueFormat = ReportFormatterCache.number('0.##');
  final NumberFormat _shareFormat = ReportFormatterCache.number('0.#');

  static const double _itemWidth = 600;
  static const double _valueWidth = 255;
  static const double _shareWidth = 260;
  static const double _classWidth = 240;
  static const double _tableWidth =
      _itemWidth + _valueWidth + _shareWidth + _classWidth;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<AbcClassificationRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <AbcClassificationRow>[];
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
          width: _tableWidth,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              if (widget.rows.isEmpty)
                const ReportTableEmptyBody(minHeight: 445)
              else
                SizedBox(
                  height: 445,
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _verticalController,
                      itemCount: _pageRows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, index) {
                        return _buildDataRow(_pageRows[index]);
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
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          _headerCell('ITEM NAME', _itemWidth, showSort: true),
          _headerCell('CUMULATIVE VALUE', _valueWidth, alignRight: true),
          _headerCell('CUMULATIVE SHARE', _shareWidth, alignRight: true),
          _headerCell('CURRENT CLASS', _classWidth, alignCenter: true),
        ],
      ),
    );
  }

  Widget _buildDataRow(AbcClassificationRow row) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          _bodyCell(
            SizedBox(
              width: _itemWidth - (AppTheme.space20 * 2),
              child: Text(
                row.itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _itemWidth,
          ),
          _bodyCell(
            _numberText(_valueFormat.format(row.cumulativeValue)),
            _valueWidth,
            alignRight: true,
          ),
          _bodyCell(
            _numberText(_shareFormat.format(row.cumulativeShare)),
            _shareWidth,
            alignRight: true,
          ),
          _classCell(row.currentClass),
        ],
      ),
    );
  }

  Widget _headerCell(
    String text,
    double width, {
    bool alignRight = false,
    bool alignCenter = false,
    bool showSort = false,
  }) {
    return Container(
      width: width,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      alignment: alignCenter
          ? Alignment.center
          : alignRight
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: ReportTableTypography.header),
          if (showSort) ...[
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _bodyCell(Widget child, double width, {bool alignRight = false}) {
    return Container(
      width: width,
      height: 37,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    );
  }

  Widget _classCell(String value) {
    return Container(
      width: _classWidth,
      height: 37,
      alignment: Alignment.center,
      color: AppTheme.successBg.withValues(alpha: 0.38),
      child: Text(
        value,
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.successDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _numberText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
    );
  }
}
