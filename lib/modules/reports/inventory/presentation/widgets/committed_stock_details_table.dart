import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class CommittedStockDetailsRow {
  final String transactionNumber;
  final String itemName;
  final double committedStock;
  final String? salesperson;
  final String? orderType;
  final String? date;
  final String? customerName;

  const CommittedStockDetailsRow({
    required this.transactionNumber,
    required this.itemName,
    required this.committedStock,
    this.salesperson,
    this.orderType,
    this.date,
    this.customerName,
  });

  factory CommittedStockDetailsRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CommittedStockDetailsRow(
      transactionNumber: item['transactionNumber']?.toString() ?? '-',
      itemName: item['itemName']?.toString() ?? '-',
      committedStock: numberValue('committedStock'),
      salesperson: item['salesperson']?.toString(),
      orderType: item['orderType']?.toString(),
      date: item['date']?.toString(),
      customerName: item['customerName']?.toString(),
    );
  }

  /// Returns the group key for a given groupBy option.
  String groupKey(String groupBy) {
    switch (groupBy) {
      case 'Transaction#':
        return transactionNumber;
      case 'Salesperson':
        return salesperson?.isNotEmpty == true ? salesperson! : 'Not mentioned';
      case 'Order Type':
        return orderType?.isNotEmpty == true ? orderType! : 'Not mentioned';
      case 'Date':
        return date?.isNotEmpty == true ? date! : 'Not mentioned';
      case 'Customer Name':
        return customerName?.isNotEmpty == true ? customerName! : 'Not mentioned';
      case 'Item Name':
        return itemName;
      default:
        return '';
    }
  }
}

class CommittedStockDetailsTable extends StatefulWidget {
  final List<CommittedStockDetailsRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const CommittedStockDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.groupBy = 'None',
  });

  @override
  State<CommittedStockDetailsTable> createState() =>
      _CommittedStockDetailsTableState();
}

class _CommittedStockDetailsTableState
    extends State<CommittedStockDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<CommittedStockDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <CommittedStockDetailsRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final isGrouped = widget.groupBy != 'None';
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
                    child: isGrouped
                        ? _buildGroupedList()
                        : ListView.separated(
                            controller: _verticalController,
                            itemCount: _pageRows.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: AppTheme.borderLight),
                            itemBuilder: (context, index) {
                              return _CommittedStockDetailsDataRow(
                                row: _pageRows[index],
                                formatter: _quantityFormat,
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

  Widget _buildGroupedList() {
    // Build ordered list of (groupKey, [rows]) preserving insertion order
    final Map<String, List<CommittedStockDetailsRow>> grouped = {};
    for (final row in widget.rows) {
      final key = row.groupKey(widget.groupBy);
      grouped.putIfAbsent(key, () => []).add(row);
    }

    final groupLabel = widget.groupBy;
    final items = <Widget>[];
    for (final entry in grouped.entries) {
      // Group header
      items.add(_buildGroupHeader('$groupLabel - ${entry.key}'));
      // Group rows
      for (int i = 0; i < entry.value.length; i++) {
        if (i > 0) {
          items.add(const Divider(height: 1, color: AppTheme.borderLight));
        }
        items.add(_CommittedStockDetailsDataRow(
          row: entry.value[i],
          formatter: _quantityFormat,
        ));
      }
    }

    return ListView(
      controller: _verticalController,
      children: items,
    );
  }

  Widget _buildGroupHeader(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      color: const Color(0xFFF9FAFB),
      child: Text(
        label,
        style: AppTheme.bodyText.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontSize: 13,
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
        transactionNumber: Text(
          'TRANSACTION#',
          style: ReportTableTypography.header,
        ),
        itemName: Text('ITEM NAME', style: ReportTableTypography.header),
        committedStock: Text(
          'COMMITTED STOCK',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
      ),
    );
  }
}

class _CommittedStockDetailsDataRow extends StatefulWidget {
  final CommittedStockDetailsRow row;
  final NumberFormat formatter;

  const _CommittedStockDetailsDataRow({
    required this.row,
    required this.formatter,
  });

  @override
  State<_CommittedStockDetailsDataRow> createState() =>
      _CommittedStockDetailsDataRowState();
}

class _CommittedStockDetailsDataRowState
    extends State<_CommittedStockDetailsDataRow> {
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
          transactionNumber: Text(
            widget.row.transactionNumber,
            style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
          ),
          itemName: Text(widget.row.itemName, style: AppTheme.tableCell),
          committedStock: Text(
            widget.formatter.format(widget.row.committedStock),
            textAlign: TextAlign.right,
            style: AppTheme.tableCell,
          ),
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget transactionNumber,
  required Widget itemName,
  required Widget committedStock,
}) {
  return Row(
    children: [
      Expanded(flex: 3, child: transactionNumber),
      Expanded(flex: 4, child: itemName),
      Expanded(flex: 3, child: committedStock),
    ],
  );
}
