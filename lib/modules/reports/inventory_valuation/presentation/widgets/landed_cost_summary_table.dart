import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class LandedCostSummaryRow {
  final String billDate;
  final String billNumber;
  final String vendorName;
  final String description;
  final double billTotal;
  final double allocatedAmount;
  final double unallocatedAmount;

  const LandedCostSummaryRow({
    required this.billDate,
    required this.billNumber,
    required this.vendorName,
    required this.description,
    required this.billTotal,
    required this.allocatedAmount,
    required this.unallocatedAmount,
  });

  factory LandedCostSummaryRow.fromJson(Map<String, dynamic> item) {
    return LandedCostSummaryRow(
      billDate: item['billDate']?.toString() ?? '',
      billNumber: item['billNumber']?.toString() ?? '',
      vendorName: item['vendorName']?.toString() ?? '',
      description: item['description']?.toString() ?? '',
      billTotal: _numberValue(item, 'billTotal'),
      allocatedAmount: _numberValue(item, 'allocatedAmount'),
      unallocatedAmount: _numberValue(item, 'unallocatedAmount'),
    );
  }

  factory LandedCostSummaryRow.fromTotalsJson(Map<String, dynamic>? totals) {
    return LandedCostSummaryRow(
      billDate: 'Total',
      billNumber: '',
      vendorName: '',
      description: '',
      billTotal: _numberValue(totals ?? const <String, dynamic>{}, 'billTotal'),
      allocatedAmount: _numberValue(
        totals ?? const <String, dynamic>{},
        'allocatedAmount',
      ),
      unallocatedAmount: _numberValue(
        totals ?? const <String, dynamic>{},
        'unallocatedAmount',
      ),
    );
  }

  factory LandedCostSummaryRow.emptyTotal() {
    return const LandedCostSummaryRow(
      billDate: 'Total',
      billNumber: '',
      vendorName: '',
      description: '',
      billTotal: 0,
      allocatedAmount: 0,
      unallocatedAmount: 0,
    );
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class LandedCostSummaryTable extends StatefulWidget {
  final List<LandedCostSummaryRow> rows;
  final LandedCostSummaryRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final int? totalCount;
  final bool serverPaginated;

  const LandedCostSummaryTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.totalCount,
    this.serverPaginated = false,
  });

  @override
  State<LandedCostSummaryTable> createState() => _LandedCostSummaryTableState();
}

class _LandedCostSummaryTableState extends State<LandedCostSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  int get _totalCount => widget.totalCount ?? widget.rows.length;

  List<LandedCostSummaryRow> get _pageRows {
    if (widget.serverPaginated) return widget.rows;
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <LandedCostSummaryRow>[];
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
          width: 1320,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              if (widget.rows.isEmpty)
                const ReportTableEmptyBody(minHeight: 345)
              else
                SizedBox(
                  height: 345,
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
                          return _buildTotalRow(widget.totals);
                        }
                        return _LandedCostSummaryDataRow(
                          row: _pageRows[index],
                          currencyFormat: _currencyFormat,
                        );
                      },
                    ),
                  ),
                ),
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
        billDate: Row(
          children: [
            Text('BILL DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        billNumber: Text('BILL#', style: ReportTableTypography.header),
        vendorName: Text('VENDOR NAME', style: ReportTableTypography.header),
        description: Text(
          'DESCRIPTION FOR THE ITEM',
          style: ReportTableTypography.header,
        ),
        billTotal: _headerText('BILL TOTAL(BCY)'),
        allocatedAmount: _headerText('ALLOCATED AMOUNT(BCY)'),
        unallocatedAmount: _headerText('UNALLOCATED AMOUNT (BCY)'),
      ),
    );
  }

  Widget _buildTotalRow(LandedCostSummaryRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        billDate: Text('Total', style: _totalStyle),
        billNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        description: const SizedBox.shrink(),
        billTotal: _totalText(row.billTotal),
        allocatedAmount: _totalText(row.allocatedAmount),
        unallocatedAmount: _totalText(row.unallocatedAmount),
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      overflow: TextOverflow.ellipsis,
      style: ReportTableTypography.header,
    );
  }

  Widget _totalText(double value) {
    return Text(
      _currencyFormat.format(value),
      textAlign: TextAlign.right,
      style: _totalStyle,
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );
}

class _LandedCostSummaryDataRow extends StatefulWidget {
  final LandedCostSummaryRow row;
  final NumberFormat currencyFormat;

  const _LandedCostSummaryDataRow({
    required this.row,
    required this.currencyFormat,
  });

  @override
  State<_LandedCostSummaryDataRow> createState() =>
      _LandedCostSummaryDataRowState();
}

class _LandedCostSummaryDataRowState extends State<_LandedCostSummaryDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
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
          billDate: Text(widget.row.billDate, style: AppTheme.tableCell),
          billNumber: Text(
            widget.row.billNumber,
            style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
          ),
          vendorName: Text(
            widget.row.vendorName,
            style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
          ),
          description: Text(widget.row.description, style: AppTheme.tableCell),
          billTotal: _currencyCell(widget.row.billTotal),
          allocatedAmount: _currencyCell(
            widget.row.allocatedAmount,
            isStrong: true,
          ),
          unallocatedAmount: _currencyCell(widget.row.unallocatedAmount),
        ),
      ),
    );
  }

  Widget _currencyCell(double value, {bool isStrong = false}) {
    return Text(
      widget.currencyFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        fontWeight: isStrong ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget billDate,
  required Widget billNumber,
  required Widget vendorName,
  required Widget description,
  required Widget billTotal,
  required Widget allocatedAmount,
  required Widget unallocatedAmount,
}) {
  return Row(
    children: [
      Expanded(flex: 3, child: billDate),
      Expanded(flex: 3, child: billNumber),
      Expanded(flex: 4, child: vendorName),
      Expanded(flex: 5, child: description),
      Expanded(flex: 3, child: billTotal),
      Expanded(flex: 4, child: allocatedAmount),
      Expanded(flex: 4, child: unallocatedAmount),
    ],
  );
}
