import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class BatchDetailsRow {
  final String itemName;
  final String sku;
  final String batchNumber;
  final String manufacturerBatch;
  final String manufacturedDate;
  final String expiryDate;
  final String locationName;
  final String batchStatus;
  final double quantityIn;
  final double quantityAvailable;
  final String unit;

  const BatchDetailsRow({
    required this.itemName,
    required this.sku,
    required this.batchNumber,
    required this.manufacturerBatch,
    required this.manufacturedDate,
    required this.expiryDate,
    required this.locationName,
    required this.batchStatus,
    required this.quantityIn,
    required this.quantityAvailable,
    required this.unit,
  });

  factory BatchDetailsRow.fromJson(Map<String, dynamic> json) {
    return BatchDetailsRow(
      itemName: _stringValue(json['itemName']),
      sku: _stringValue(json['sku']),
      batchNumber: _stringValue(json['batchNumber']),
      manufacturerBatch: _stringValue(json['manufacturerBatch']),
      manufacturedDate: _stringValue(json['manufacturedDate']),
      expiryDate: _stringValue(json['expiryDate']),
      locationName: _stringValue(
        json['locationName'],
        fallback: _stringValue(json['warehouseName']),
      ),
      batchStatus: _stringValue(json['batchStatus'], fallback: 'Active'),
      quantityIn: _numberValue(json['quantityIn']),
      quantityAvailable: _numberValue(json['quantityAvailable']),
      unit: _stringValue(json['unit']),
    );
  }

  factory BatchDetailsRow.totalFromJson(Map<String, dynamic>? totals) {
    return BatchDetailsRow(
      itemName: 'Total',
      sku: '',
      batchNumber: '',
      manufacturerBatch: '',
      manufacturedDate: '',
      expiryDate: '',
      locationName: '',
      batchStatus: '',
      quantityIn: _numberValue(totals?['quantityIn']),
      quantityAvailable: _numberValue(totals?['quantityAvailable']),
      unit: '',
    );
  }

  static const emptyTotal = BatchDetailsRow(
    itemName: 'Total',
    sku: '',
    batchNumber: '',
    manufacturerBatch: '',
    manufacturedDate: '',
    expiryDate: '',
    locationName: '',
    batchStatus: '',
    quantityIn: 0,
    quantityAvailable: 0,
    unit: '',
  );

  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class BatchDetailsTable extends StatefulWidget {
  final List<BatchDetailsRow> rows;
  final BatchDetailsRow totals;
  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showGroupTotals;

  const BatchDetailsTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    this.groupByFields = const <String>[],
    this.showGroupTotals = false,
  });

  @override
  State<BatchDetailsTable> createState() => _BatchDetailsTableState();
}

class _BatchDetailsTableState extends State<BatchDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _quantityFormat = NumberFormat('#,##0.00');

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1420,
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
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppTheme.borderLight,
                      ),
                      itemBuilder: (context, index) => _buildEntry(entries[index]),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space20,
                  AppTheme.space12,
                  AppTheme.space20,
                  AppTheme.space4,
                ),
                child: Text(
                  '*The generated report shows batches created within the selected date range. Quantities shown are as of today.',
                  style: AppTheme.metaHelper,
                ),
              ),
              ReportPaginationFooter(
                totalCount: widget.totalCount,
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

  List<String> get _activeGroupFields => widget.groupByFields
      .where((field) => field != 'None')
      .toList(growable: false);

  List<_BatchDetailsEntry> _buildEntries() {
    final entries = <_BatchDetailsEntry>[];
    final groupFields = _activeGroupFields;

    if (groupFields.isEmpty) {
      entries.addAll(widget.rows.map(_BatchDetailsEntry.data));
      entries.add(_BatchDetailsEntry.total(widget.totals));
      return entries;
    }

    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: groupFields,
      depth: 0,
    );
    entries.add(_BatchDetailsEntry.total(widget.totals));
    return entries;
  }

  void _appendGroupedEntries({
    required List<_BatchDetailsEntry> entries,
    required List<BatchDetailsRow> rows,
    required List<String> groupFields,
    required int depth,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    if (depth >= groupFields.length) {
      entries.addAll(
        rows.map(
          (row) => _BatchDetailsEntry.data(
            row,
            depth: depth,
            ancestorVisible: ancestorVisible,
            ancestorContinues: ancestorContinues,
          ),
        ),
      );
      return;
    }

    final field = groupFields[depth];
    final groupedRows = LinkedHashMap<String, List<BatchDetailsRow>>();
    for (final row in rows) {
      final key = _groupValue(row, field);
      groupedRows.putIfAbsent(key, () => <BatchDetailsRow>[]).add(row);
    }

    final groups = groupedRows.entries.toList(growable: false);
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      final hasChildGroups = depth < groupFields.length - 1;
      final hasFollowingSibling = index < groups.length - 1;
      final entryAncestorVisible = _entryAncestorVisible(
        ancestorVisible,
        depth,
      );
      final entryAncestorContinues = _entryAncestorContinues(
        ancestorContinues,
        depth,
        hasFollowingSibling,
      );

      entries.add(
        _BatchDetailsEntry.groupHeader(
          title: group.key,
          depth: depth,
          row: _subtotalRow(group.key, group.value),
          ancestorVisible: entryAncestorVisible,
          ancestorContinues: entryAncestorContinues,
          hasChildren: hasChildGroups,
          continues: hasChildGroups || (depth == 0 && hasFollowingSibling),
        ),
      );
      _appendGroupedEntries(
        entries: entries,
        rows: group.value,
        groupFields: groupFields,
        depth: depth + 1,
        ancestorVisible: _childAncestorVisible(
          entryAncestorVisible,
          entryAncestorContinues,
          includeCurrentGroup: hasChildGroups,
        ),
        ancestorContinues: _childAncestorContinues(
          entryAncestorContinues,
          includeCurrentGroup: hasChildGroups,
        ),
      );
      if (widget.showGroupTotals) {
        entries.add(
          _BatchDetailsEntry.subtotal(
            title: group.key,
            depth: depth,
            row: _subtotalRow(group.key, group.value),
            ancestorVisible: entryAncestorVisible,
            ancestorContinues: entryAncestorContinues,
          ),
        );
      }
    }
  }

  List<bool> _entryAncestorVisible(List<bool> ancestorVisible, int depth) {
    final values = List<bool>.of(ancestorVisible, growable: true);
    while (values.length < depth) {
      values.add(false);
    }
    if (depth > 0) {
      values[depth - 1] = true;
    }
    return values;
  }

  List<bool> _entryAncestorContinues(
    List<bool> ancestorContinues,
    int depth,
    bool hasFollowingSibling,
  ) {
    final values = List<bool>.of(ancestorContinues, growable: true);
    while (values.length < depth) {
      values.add(false);
    }
    if (depth > 0) {
      values[depth - 1] = hasFollowingSibling;
    }
    return values;
  }

  List<bool> _childAncestorVisible(
    List<bool> entryAncestorVisible,
    List<bool> entryAncestorContinues, {
    required bool includeCurrentGroup,
  }) {
    return <bool>[
      for (var index = 0; index < entryAncestorVisible.length; index += 1)
        entryAncestorVisible[index] && entryAncestorContinues[index],
      if (includeCurrentGroup) true,
    ];
  }

  List<bool> _childAncestorContinues(
    List<bool> entryAncestorContinues, {
    required bool includeCurrentGroup,
  }) {
    return <bool>[
      ...entryAncestorContinues,
      if (includeCurrentGroup) false,
    ];
  }

  String _groupValue(BatchDetailsRow row, String field) {
    final value = switch (field) {
      'Item Name' => row.itemName,
      'SKU' => row.sku,
      'Batch Number' => row.batchNumber,
      'Manufactured Date' => row.manufacturedDate,
      'Expiry Date' => row.expiryDate,
      'Location Name' => row.locationName,
      _ => '',
    };
    return value.trim().isEmpty ? '$field - Not mentioned' : value.trim();
  }

  BatchDetailsRow _subtotalRow(String title, List<BatchDetailsRow> rows) {
    return BatchDetailsRow(
      itemName: 'Total for $title',
      sku: '',
      batchNumber: '',
      manufacturerBatch: '',
      manufacturedDate: '',
      expiryDate: '',
      locationName: '',
      batchStatus: '',
      quantityIn: rows.fold<double>(0, (sum, row) => sum + row.quantityIn),
      quantityAvailable: rows.fold<double>(
        0,
        (sum, row) => sum + row.quantityAvailable,
      ),
      unit: '',
    );
  }

  Widget _buildEntry(_BatchDetailsEntry entry) {
    return switch (entry.type) {
      _BatchDetailsEntryType.groupHeader => _buildGroupHeader(
          entry,
          showTree: _activeGroupFields.length > 1,
          hasChildren: entry.hasChildren,
        ),
      _BatchDetailsEntryType.subtotal => _buildSubtotalRow(entry),
      _BatchDetailsEntryType.total => _buildTotalRow(entry.row!),
      _BatchDetailsEntryType.data => _BatchDetailsDataRow(
          row: entry.row!,
          quantityFormat: _quantityFormat,
          indentDepth: _activeGroupFields.length > 1 ? entry.depth : 0,
          ancestorVisible: entry.ancestorVisible,
          ancestorContinues: entry.ancestorContinues,
        ),
    };
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
        itemName: Row(
          children: [
            Text('ITEM NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        sku: _headerText('SKU'),
        batchNumber: _headerText('BATCH NUMBER'),
        manufacturerBatch: _headerText('MANUFACTURER BATCH'),
        manufacturedDate: _headerText('MANUFACTURED DATE'),
        expiryDate: _headerText('EXPIRY DATE'),
        batchStatus: _headerText('BATCH STATUS'),
        quantityIn: _headerText('QUANTITY IN', alignRight: true),
        quantityAvailable: _headerText('QUANTITY AVAILABLE', alignRight: true),
      ),
    );
  }

  Widget _buildGroupHeader(
    _BatchDetailsEntry entry, {
    required bool showTree,
    required bool hasChildren,
  }) {
    final row = entry.row ?? BatchDetailsRow.emptyTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        itemName: _GroupTreeLabel(
          title: entry.title,
          depth: entry.depth,
          showTree: showTree,
          ancestorVisible: entry.ancestorVisible,
          ancestorContinues: entry.ancestorContinues,
          hasChildren: hasChildren,
          continues: entry.continues,
        ),
        sku: const SizedBox.shrink(),
        batchNumber: const SizedBox.shrink(),
        manufacturerBatch: const SizedBox.shrink(),
        manufacturedDate: const SizedBox.shrink(),
        expiryDate: const SizedBox.shrink(),
        batchStatus: const SizedBox.shrink(),
        quantityIn: widget.showGroupTotals
            ? const SizedBox.shrink()
            : _groupTotalText(row.quantityIn),
        quantityAvailable: widget.showGroupTotals
            ? const SizedBox.shrink()
            : _groupTotalText(row.quantityAvailable),
      ),
    );
  }

  Widget _buildSubtotalRow(_BatchDetailsEntry entry) {
    final row = entry.row ?? BatchDetailsRow.emptyTotal;
    final labelIndent = (entry.depth + 1) * AppTheme.space28;
    final showConnector = entry.ancestorVisible.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Stack(
        children: [
          if (showConnector)
            Positioned.fill(
              child: CustomPaint(
                painter: _GroupDataConnectorPainter(
                  ancestorVisible: entry.ancestorVisible,
                  ancestorContinues: entry.ancestorContinues,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space20,
              vertical: AppTheme.space12,
            ),
            child: _buildTableRow(
              itemName: Padding(
                padding: EdgeInsets.only(left: labelIndent),
                child: Text(row.itemName, style: _subtotalStyle),
              ),
              sku: const SizedBox.shrink(),
              batchNumber: const SizedBox.shrink(),
              manufacturerBatch: const SizedBox.shrink(),
              manufacturedDate: const SizedBox.shrink(),
              expiryDate: const SizedBox.shrink(),
              batchStatus: const SizedBox.shrink(),
              quantityIn: _subtotalText(row.quantityIn),
              quantityAvailable: _subtotalText(row.quantityAvailable),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BatchDetailsRow row) {
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
        itemName: Text('Total', style: _totalStyle),
        sku: const SizedBox.shrink(),
        batchNumber: const SizedBox.shrink(),
        manufacturerBatch: const SizedBox.shrink(),
        manufacturedDate: const SizedBox.shrink(),
        expiryDate: const SizedBox.shrink(),
        batchStatus: const SizedBox.shrink(),
        quantityIn: _totalText(row.quantityIn),
        quantityAvailable: _totalText(row.quantityAvailable),
      ),
    );
  }

  Widget _headerText(String value, {bool alignRight = false}) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      overflow: TextOverflow.ellipsis,
      style: ReportTableTypography.header,
    );
  }

  Widget _groupTotalText(double value) {
    return Text(
      _quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: _groupHeaderStyle,
    );
  }

  Widget _subtotalText(double value) {
    return Text(
      _quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: _subtotalStyle,
    );
  }

  Widget _totalText(double value) {
    return Text(
      _quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: _totalStyle,
    );
  }

  TextStyle get _groupHeaderStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      );

  TextStyle get _subtotalStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      );

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      );
}

class _BatchDetailsEntry {
  final _BatchDetailsEntryType type;
  final BatchDetailsRow? row;
  final String title;
  final int depth;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _BatchDetailsEntry._({
    required this.type,
    this.row,
    this.title = '',
    this.depth = 0,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
    this.hasChildren = false,
    this.continues = false,
  });

  factory _BatchDetailsEntry.data(
    BatchDetailsRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) =>
      _BatchDetailsEntry._(
        type: _BatchDetailsEntryType.data,
        row: row,
        depth: depth,
        ancestorVisible: ancestorVisible,
        ancestorContinues: ancestorContinues,
      );

  factory _BatchDetailsEntry.total(BatchDetailsRow row) => _BatchDetailsEntry._(
        type: _BatchDetailsEntryType.total,
        row: row,
      );

  factory _BatchDetailsEntry.groupHeader({
    required String title,
    required int depth,
    required BatchDetailsRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
    required bool hasChildren,
    required bool continues,
  }) =>
      _BatchDetailsEntry._(
        type: _BatchDetailsEntryType.groupHeader,
        title: title,
        depth: depth,
        row: row,
        ancestorVisible: ancestorVisible,
        ancestorContinues: ancestorContinues,
        hasChildren: hasChildren,
        continues: continues,
      );

  factory _BatchDetailsEntry.subtotal({
    required String title,
    required int depth,
    required BatchDetailsRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
  }) =>
      _BatchDetailsEntry._(
        type: _BatchDetailsEntryType.subtotal,
        title: title,
        depth: depth,
        row: row,
        ancestorVisible: ancestorVisible,
        ancestorContinues: ancestorContinues,
      );
}

enum _BatchDetailsEntryType { data, groupHeader, subtotal, total }

class _GroupTreeLabel extends StatelessWidget {
  final String title;
  final int depth;
  final bool showTree;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _GroupTreeLabel({
    required this.title,
    required this.depth,
    required this.showTree,
    required this.ancestorVisible,
    required this.ancestorContinues,
    required this.hasChildren,
    required this.continues,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );

    if (!showTree) {
      return label;
    }

    return Row(
      children: [
        SizedBox(
          width: AppTheme.space20 + (depth * AppTheme.space20),
          height: _GroupTreeMarkerPainter.rowHeight,
          child: CustomPaint(
            painter: _GroupTreeMarkerPainter(
              depth: depth,
              ancestorVisible: ancestorVisible,
              ancestorContinues: ancestorContinues,
              hasChildren: hasChildren,
              continues: continues,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space4),
        Expanded(child: label),
      ],
    );
  }
}

class _GroupTreeMarkerPainter extends CustomPainter {
  static const double rowHeight = 40;

  final int depth;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _GroupTreeMarkerPainter({
    required this.depth,
    required this.ancestorVisible,
    required this.ancestorContinues,
    required this.hasChildren,
    required this.continues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final circlePaint = Paint()
      ..color = AppTheme.backgroundColor
      ..style = PaintingStyle.fill;
    final circleBorderPaint = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const step = AppTheme.space20;
    const startX = AppTheme.space6;
    final centerY = size.height / 2;
    final markerX = startX + (depth * step);
    const elbowRadius = AppTheme.space6;
    const circleRadius = 5.0;
    final parentX = depth > 0 ? startX + ((depth - 1) * step) : markerX;
    final branchEndX = markerX - circleRadius;
    final availableWidth = branchEndX - parentX;
    final cornerRadius = depth > 0 && availableWidth < elbowRadius
        ? availableWidth
        : elbowRadius;

    for (var level = 0; level < depth; level += 1) {
      final isVisible = level < ancestorVisible.length && ancestorVisible[level];
      if (!isVisible) {
        continue;
      }
      final x = startX + (level * step);
      final shouldContinue = level < ancestorContinues.length &&
          ancestorContinues[level];
      final isImmediateParent = level == depth - 1;
      final endY = shouldContinue
          ? size.height
          : isImmediateParent
              ? centerY - cornerRadius
              : centerY;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, endY),
        linePaint,
      );
    }

    if (depth > 0) {
      final branchPath = Path()
        ..moveTo(parentX, centerY - cornerRadius)
        ..quadraticBezierTo(
          parentX,
          centerY,
          parentX + cornerRadius,
          centerY,
        )
        ..lineTo(branchEndX, centerY);
      canvas.drawPath(branchPath, linePaint);
    }

    if (continues || hasChildren) {
      canvas.drawLine(
        Offset(markerX, centerY),
        Offset(markerX, size.height),
        linePaint,
      );
    }

    canvas.drawCircle(Offset(markerX, centerY), 5, circlePaint);
    canvas.drawCircle(Offset(markerX, centerY), 5, circleBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _GroupTreeMarkerPainter oldDelegate) {
    return oldDelegate.depth != depth ||
        oldDelegate.hasChildren != hasChildren ||
        oldDelegate.continues != continues ||
        !_listEquals(oldDelegate.ancestorVisible, ancestorVisible) ||
        !_listEquals(oldDelegate.ancestorContinues, ancestorContinues);
  }

  bool _listEquals(List<bool> first, List<bool> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index += 1) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
}

class _GroupDataConnectorPainter extends CustomPainter {
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _GroupDataConnectorPainter({
    required this.ancestorVisible,
    required this.ancestorContinues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const step = AppTheme.space20;
    const startX = AppTheme.space20 + AppTheme.space6;

    for (var level = 0; level < ancestorVisible.length; level += 1) {
      final shouldDraw = ancestorVisible[level] &&
          level < ancestorContinues.length &&
          ancestorContinues[level];
      if (!shouldDraw) {
        continue;
      }
      final x = startX + (level * step);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroupDataConnectorPainter oldDelegate) {
    return !_listEquals(oldDelegate.ancestorVisible, ancestorVisible) ||
        !_listEquals(oldDelegate.ancestorContinues, ancestorContinues);
  }

  bool _listEquals(List<bool> first, List<bool> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index += 1) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
}

class _BatchDetailsDataRow extends StatefulWidget {
  final BatchDetailsRow row;
  final NumberFormat quantityFormat;
  final int indentDepth;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _BatchDetailsDataRow({
    required this.row,
    required this.quantityFormat,
    this.indentDepth = 0,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
  });

  @override
  State<_BatchDetailsDataRow> createState() => _BatchDetailsDataRowState();
}

class _BatchDetailsDataRowState extends State<_BatchDetailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final showConnector = widget.ancestorVisible.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
        child: Stack(
          children: [
            if (showConnector)
              Positioned.fill(
                child: CustomPaint(
                  painter: _GroupDataConnectorPainter(
                    ancestorVisible: widget.ancestorVisible,
                    ancestorContinues: widget.ancestorContinues,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space20,
                vertical: AppTheme.space12,
              ),
              child: _buildTableRow(
                itemName: _dataItemNameCell(),
                sku: _bodyText(widget.row.sku),
                batchNumber: _linkText(widget.row.batchNumber),
                manufacturerBatch: _bodyText(widget.row.manufacturerBatch),
                manufacturedDate: _bodyText(widget.row.manufacturedDate),
                expiryDate: _bodyText(widget.row.expiryDate),
                batchStatus: _bodyText(widget.row.batchStatus),
                quantityIn: _quantityCell(widget.row.quantityIn),
                quantityAvailable: _quantityCell(widget.row.quantityAvailable),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataItemNameCell() {
    final leftPadding = widget.indentDepth > 0
        ? widget.indentDepth * AppTheme.space28
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: _linkText(widget.row.itemName),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }

  Widget _bodyText(String value) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.tableCell,
    );
  }

  Widget _quantityCell(double value) {
    return Text(
      widget.quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w500),
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget sku,
  required Widget batchNumber,
  required Widget manufacturerBatch,
  required Widget manufacturedDate,
  required Widget expiryDate,
  required Widget batchStatus,
  required Widget quantityIn,
  required Widget quantityAvailable,
}) {
  return Row(
    children: [
      Expanded(flex: 5, child: itemName),
      Expanded(flex: 3, child: sku),
      Expanded(flex: 4, child: batchNumber),
      Expanded(flex: 4, child: manufacturerBatch),
      Expanded(flex: 4, child: manufacturedDate),
      Expanded(flex: 3, child: expiryDate),
      Expanded(flex: 4, child: batchStatus),
      Expanded(flex: 3, child: quantityIn),
      Expanded(flex: 4, child: quantityAvailable),
    ],
  );
}
