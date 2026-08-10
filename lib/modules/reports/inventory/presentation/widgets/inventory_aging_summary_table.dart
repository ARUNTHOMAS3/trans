import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_frozen_first_column_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';

class InventoryAgingBucket {
  final String label;
  final double quantity;
  final double assetValue;

  const InventoryAgingBucket({
    required this.label,
    required this.quantity,
    required this.assetValue,
  });

  factory InventoryAgingBucket.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return InventoryAgingBucket(
      label: item['label']?.toString() ?? '-',
      quantity: numberValue('quantity'),
      assetValue: numberValue('assetValue'),
    );
  }
}

class InventoryAgingSummaryRow {
  final String itemName;
  final List<InventoryAgingBucket> buckets;

  const InventoryAgingSummaryRow({
    required this.itemName,
    required this.buckets,
  });

  factory InventoryAgingSummaryRow.fromJson(Map<String, dynamic> item) {
    final rawBuckets = item['buckets'];
    return InventoryAgingSummaryRow(
      itemName: item['itemName']?.toString() ?? '-',
      buckets: rawBuckets is List
          ? rawBuckets
                .whereType<Map>()
                .map(
                  (bucket) => InventoryAgingBucket.fromJson(
                    Map<String, dynamic>.from(bucket),
                  ),
                )
                .toList(growable: false)
          : const <InventoryAgingBucket>[],
    );
  }
}

class InventoryAgingSummaryTable extends StatefulWidget {
  final List<InventoryAgingSummaryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> bucketLabels;

  const InventoryAgingSummaryTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.bucketLabels,
  });

  @override
  State<InventoryAgingSummaryTable> createState() =>
      _InventoryAgingSummaryTableState();
}

class _InventoryAgingSummaryTableState
    extends State<InventoryAgingSummaryTable> {
  static const double _itemColumnWidth = 240;
  static const double _quantityColumnWidth = 122;
  static const double _assetColumnWidth = 204;
  static const double _rowHeight = 41;
  static const double _bodyHeight = 345;

  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');
  final NumberFormat _assetFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  List<InventoryAgingSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <InventoryAgingSummaryRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  double get _scrollableContentWidth =>
      widget.bucketLabels.length * (_quantityColumnWidth + _assetColumnWidth);

  double get _scrollableWidth =>
      _scrollableContentWidth + (AppTheme.space20 * 2);

  List<InventoryAgingBucket> get _totalBuckets {
    return widget.bucketLabels
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          return InventoryAgingBucket(
            label: entry.value,
            quantity: widget.rows.fold<double>(0, (sum, row) {
              if (index >= row.buckets.length) return sum;
              return sum + row.buckets[index].quantity;
            }),
            assetValue: widget.rows.fold<double>(0, (sum, row) {
              if (index >= row.buckets.length) return sum;
              return sum + row.buckets[index].assetValue;
            }),
          );
        })
        .toList(growable: false);
  }

  int get _totalRowIndex => _pageRows.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final table = ReportFrozenFirstColumnTable(
          frozenColumnWidth: _itemColumnWidth,
          scrollableWidth: _scrollableWidth,
          bodyHeight: _bodyHeight,
          rowHeight: _rowHeight,
          rowCount: widget.rows.isEmpty ? 0 : _pageRows.length + 1,
          isEmpty: widget.rows.isEmpty,
          emptyBody: const ReportTableEmptyBody(minHeight: _bodyHeight),
          frozenHeader: Text('ITEM NAME', style: ReportTableTypography.header),
          scrollableHeader: _buildScrollableHeader(),
          rowHoverEnabled: (index) => index != _totalRowIndex,
          frozenCellBuilder: _buildFrozenCell,
          scrollableCellBuilder: _buildScrollableCells,
        );
        final footer = <Widget>[
          if (widget.rows.isNotEmpty) _buildFifoNote(),
          ReportPaginationFooter(
            totalCount: widget.rows.length,
            page: widget.page,
            pageSize: widget.pageSize,
            onPageChanged: widget.onPageChanged,
          ),
          const SizedBox(height: AppTheme.space28),
        ];

        if (!constraints.hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [table, ...footer],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: table),
            ...footer,
          ],
        );
      },
    );
  }

  Widget _buildScrollableHeader() {
    return Row(
      children: [
        for (final label in widget.bucketLabels) ...[
          SizedBox(
            width: _quantityColumnWidth,
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.right,
              style: ReportTableTypography.header,
            ),
          ),
          SizedBox(
            width: _assetColumnWidth,
            child: Text(
              'ASSET VALUE (${label.toUpperCase()})',
              textAlign: TextAlign.right,
              style: ReportTableTypography.header,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFrozenCell(BuildContext context, int index, bool isHovered) {
    final isTotal = index == _totalRowIndex;
    final text = isTotal ? 'Total' : _pageRows[index].itemName;
    final style = isTotal
        ? _totalStyle
        : AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      child: Text(text, style: style),
    );
  }

  Widget _buildScrollableCells(
    BuildContext context,
    int index,
    bool isHovered,
  ) {
    final buckets = index == _totalRowIndex
        ? _totalBuckets
        : _pageRows[index].buckets;
    final textStyle = index == _totalRowIndex
        ? _totalStyle
        : AppTheme.tableCell;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      child: Row(
        children: [
          for (
            var bucketIndex = 0;
            bucketIndex < widget.bucketLabels.length;
            bucketIndex++
          ) ...[
            SizedBox(
              width: _quantityColumnWidth,
              child: Text(
                _quantityFormat.format(
                  _bucketAt(buckets, bucketIndex).quantity,
                ),
                textAlign: TextAlign.right,
                style: textStyle,
              ),
            ),
            SizedBox(
              width: _assetColumnWidth,
              child: Text(
                _assetFormat.format(_bucketAt(buckets, bucketIndex).assetValue),
                textAlign: TextAlign.right,
                style: textStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InventoryAgingBucket _bucketAt(
    List<InventoryAgingBucket> buckets,
    int index,
  ) {
    if (index >= 0 && index < buckets.length) return buckets[index];
    return const InventoryAgingBucket(label: '-', quantity: 0, assetValue: 0);
  }

  Widget _buildFifoNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space12,
        AppTheme.space20,
        0,
      ),
      child: Text(
        '*The stock and asset values displayed in this report are organized according to the FIFO method.',
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );
}
