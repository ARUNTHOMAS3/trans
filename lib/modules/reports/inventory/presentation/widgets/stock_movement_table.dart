import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class StockMovementRow {
  final String transactionDate;
  final String productName;
  final String warehouseName;
  final String transactionType;
  final String referenceNo;
  final double quantityIn;
  final double quantityOut;
  final double runningBalance;
  final double rate;
  final double value;

  const StockMovementRow({
    required this.transactionDate,
    required this.productName,
    required this.warehouseName,
    required this.transactionType,
    required this.referenceNo,
    required this.quantityIn,
    required this.quantityOut,
    required this.runningBalance,
    required this.rate,
    required this.value,
  });

  factory StockMovementRow.fromJson(Map<String, dynamic> item) {
    return StockMovementRow(
      transactionDate: item['transactionDate']?.toString() ?? '-',
      productName: item['productName']?.toString() ?? '-',
      warehouseName: item['warehouseName']?.toString() ?? '-',
      transactionType: item['transactionType']?.toString() ?? '-',
      referenceNo: item['referenceNo']?.toString() ?? '-',
      quantityIn: _numberValue(item, 'quantityIn'),
      quantityOut: _numberValue(item, 'quantityOut'),
      runningBalance: _numberValue(item, 'runningBalance'),
      rate: _numberValue(item, 'rate'),
      value: _numberValue(item, 'value'),
    );
  }

  factory StockMovementRow.fromTotals(Map<String, dynamic> item) {
    return StockMovementRow(
      transactionDate: 'Total',
      productName: '',
      warehouseName: '',
      transactionType: '',
      referenceNo: '',
      quantityIn: _numberValue(item, 'quantityIn'),
      quantityOut: _numberValue(item, 'quantityOut'),
      runningBalance: 0,
      rate: 0,
      value: _numberValue(item, 'value'),
    );
  }

  factory StockMovementRow.totalFromRows(List<StockMovementRow> rows) {
    return StockMovementRow(
      transactionDate: 'Total',
      productName: '',
      warehouseName: '',
      transactionType: '',
      referenceNo: '',
      quantityIn: rows.fold<double>(0, (sum, row) => sum + row.quantityIn),
      quantityOut: rows.fold<double>(0, (sum, row) => sum + row.quantityOut),
      runningBalance: 0,
      rate: 0,
      value: rows.fold<double>(0, (sum, row) => sum + row.value),
    );
  }

  double get quantity => quantityIn > 0 ? quantityIn : quantityOut;

  String get movementType => quantityIn > 0 ? 'Inward' : 'Outward';

  String get source {
    if (movementType == 'Inward') return transactionType;
    return warehouseName;
  }

  String get destination {
    if (movementType == 'Inward') return warehouseName;
    return transactionType;
  }

  String groupKey(String groupBy) {
    switch (groupBy) {
      case 'Transaction Date':
        return transactionDate;
      case 'Transaction Number':
        return referenceNo;
      case 'Item Name':
        return productName;
      case 'Transaction':
        return transactionType;
      case 'Movement Type':
        return movementType;
      case 'Source':
        return source;
      case 'Destination':
        return destination;
      default:
        return '';
    }
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

const double _stockMovementHorizontalPadding = AppTheme.space20 * 2;
const double _stockMovementColumnGap = AppTheme.space14;
const double _stockMovementGroupTreeWidth = 240;
const double _stockMovementTransactionDateWidth = 150;
const double _stockMovementTransactionNumberWidth = 170;
const double _stockMovementItemNameWidth = 240;
const double _stockMovementTransactionWidth = 250;
const double _stockMovementQuantityWidth = 110;
const double _stockMovementMovementTypeWidth = 150;
const double _stockMovementSourceWidth = 200;
const double _stockMovementDestinationWidth = 200;

enum _StockMovementEntryType { groupHeader, data, subtotal, total }

class _StockMovementEntry {
  final _StockMovementEntryType type;
  final String title;
  final int depth;
  final StockMovementRow row;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _StockMovementEntry({
    required this.type,
    required this.title,
    required this.depth,
    required this.row,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
    this.hasChildren = false,
    this.continues = false,
  });

  factory _StockMovementEntry.groupHeader({
    required String title,
    required int depth,
    required StockMovementRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
    required bool hasChildren,
    required bool continues,
  }) {
    return _StockMovementEntry(
      type: _StockMovementEntryType.groupHeader,
      title: title,
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
      hasChildren: hasChildren,
      continues: continues,
    );
  }

  factory _StockMovementEntry.data(
    StockMovementRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _StockMovementEntry(
      type: _StockMovementEntryType.data,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _StockMovementEntry.subtotal(
    StockMovementRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _StockMovementEntry(
      type: _StockMovementEntryType.subtotal,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _StockMovementEntry.total(StockMovementRow row) {
    return _StockMovementEntry(
      type: _StockMovementEntryType.total,
      title: '',
      depth: 0,
      row: row,
    );
  }
}

class StockMovementTable extends StatefulWidget {
  final List<StockMovementRow> rows;
  final StockMovementRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showGroupTotals;

  const StockMovementTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.groupByFields = const <String>[],
    this.showGroupTotals = false,
  });

  @override
  State<StockMovementTable> createState() => _StockMovementTableState();
}

class _StockMovementTableState extends State<StockMovementTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<String> get _activeGroupFields => widget.groupByFields
      .where((field) => field != 'None')
      .toList(growable: false);

  List<StockMovementRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <StockMovementRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  StockMovementRow get _overallTotals {
    return StockMovementRow(
      transactionDate: 'Total',
      productName: '',
      warehouseName: '',
      transactionType: '',
      referenceNo: '',
      quantityIn: widget.rows.fold<double>(0, (sum, row) => sum + row.quantityIn),
      quantityOut: widget.rows.fold<double>(0, (sum, row) => sum + row.quantityOut),
      runningBalance: 0,
      rate: 0,
      value: widget.rows.fold<double>(0, (sum, row) => sum + row.value),
    );
  }

  double get _tableWidth {
    final hasTree = _activeGroupFields.isNotEmpty;
    final contentWidth =
        (hasTree ? _stockMovementGroupTreeWidth + _stockMovementColumnGap : 0) +
        _stockMovementTransactionDateWidth +
        _stockMovementTransactionNumberWidth +
        _stockMovementItemNameWidth +
        _stockMovementTransactionWidth +
        _stockMovementQuantityWidth +
        _stockMovementMovementTypeWidth +
        _stockMovementSourceWidth +
        _stockMovementDestinationWidth +
        (_stockMovementColumnGap * 7);
    return contentWidth + _stockMovementHorizontalPadding;
  }

  List<_StockMovementEntry> _buildEntries() {
    final entries = <_StockMovementEntry>[];
    final groupFields = _activeGroupFields;

    if (groupFields.isEmpty) {
      entries.addAll(_pageRows.map(_StockMovementEntry.data));
      entries.add(_StockMovementEntry.total(_overallTotals));
      return entries;
    }

    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: groupFields,
      depth: 0,
    );

    // Paginate the grouped entries list
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= entries.length) {
      return <_StockMovementEntry>[_StockMovementEntry.total(_overallTotals)];
    }
    final end = (start + widget.pageSize).clamp(0, entries.length);
    final paginatedEntries = entries.sublist(start, end);

    if (end == entries.length) {
      paginatedEntries.add(_StockMovementEntry.total(_overallTotals));
    }
    return paginatedEntries;
  }

  int get _totalCount {
    if (_activeGroupFields.isEmpty) return widget.rows.length;
    final entries = <_StockMovementEntry>[];
    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: _activeGroupFields,
      depth: 0,
    );
    return entries.length;
  }

  void _appendGroupedEntries({
    required List<_StockMovementEntry> entries,
    required List<StockMovementRow> rows,
    required List<String> groupFields,
    required int depth,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    if (depth >= groupFields.length) {
      entries.addAll(
        rows.map(
          (row) => _StockMovementEntry.data(
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
    final groupedRows = <String, List<StockMovementRow>>{};
    for (final row in rows) {
      final key = row.groupKey(field);
      groupedRows.putIfAbsent(key, () => <StockMovementRow>[]).add(row);
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
        _StockMovementEntry.groupHeader(
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
          _StockMovementEntry.subtotal(
            _subtotalRow(group.key, group.value),
            depth: depth,
            ancestorVisible: entryAncestorVisible,
            ancestorContinues: entryAncestorContinues,
          ),
        );
      }
    }
  }

  StockMovementRow _subtotalRow(String title, List<StockMovementRow> groupRows) {
    final totalQtyIn = groupRows.fold<double>(0, (sum, row) => sum + row.quantityIn);
    final totalQtyOut = groupRows.fold<double>(0, (sum, row) => sum + row.quantityOut);
    return StockMovementRow(
      transactionDate: 'Total for $title',
      productName: '',
      warehouseName: '',
      transactionType: '',
      referenceNo: '',
      quantityIn: totalQtyIn,
      quantityOut: totalQtyOut,
      runningBalance: 0,
      rate: 0,
      value: groupRows.fold<double>(0, (sum, row) => sum + row.value),
    );
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

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();
    final isGrouped = _activeGroupFields.isNotEmpty;

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
            header: _buildHeader(showTree: isGrouped),
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
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        switch (entry.type) {
                          case _StockMovementEntryType.groupHeader:
                            return _buildGroupHeader(entry, showTree: isGrouped);
                          case _StockMovementEntryType.data:
                            return _StockMovementDataRow(
                              row: entry.row,
                              formatter: _quantityFormat,
                              isGrouped: isGrouped,
                              ancestorVisible: entry.ancestorVisible,
                              ancestorContinues: entry.ancestorContinues,
                            );
                          case _StockMovementEntryType.subtotal:
                            return _buildSubtotalRow(entry);
                          case _StockMovementEntryType.total:
                            return _buildTotalRow(entry.row, showTree: isGrouped);
                        }
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

  Widget _buildGroupHeader(_StockMovementEntry entry, {required bool showTree}) {
    final row = entry.row;
    final hasChildren = entry.hasChildren;

    return Container(
      color: AppTheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space12,
        ),
        child: _buildTableRow(
          groupTree: _GroupTreeLabel(
            title: entry.title,
            depth: entry.depth,
            showTree: showTree,
            ancestorVisible: entry.ancestorVisible,
            ancestorContinues: entry.ancestorContinues,
            hasChildren: hasChildren,
            continues: entry.continues,
          ),
          transactionDate: const SizedBox.shrink(),
          transactionNumber: const SizedBox.shrink(),
          itemName: const SizedBox.shrink(),
          transaction: const SizedBox.shrink(),
          quantity: widget.showGroupTotals
              ? const SizedBox.shrink()
              : Text(
                  _quantityFormat.format(row.quantityIn + row.quantityOut),
                  textAlign: TextAlign.right,
                  style: AppTheme.tableHeader.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
          movementType: const SizedBox.shrink(),
          source: const SizedBox.shrink(),
          destination: const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSubtotalRow(_StockMovementEntry entry) {
    final row = entry.row;
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
              groupTree: Padding(
                padding: EdgeInsets.only(left: labelIndent),
                child: Text(row.transactionDate, style: _subtotalStyle),
              ),
              transactionDate: const SizedBox.shrink(),
              transactionNumber: const SizedBox.shrink(),
              itemName: const SizedBox.shrink(),
              transaction: const SizedBox.shrink(),
              quantity: Text(
                _quantityFormat.format(row.quantityIn + row.quantityOut),
                textAlign: TextAlign.right,
                style: _subtotalStyle,
              ),
              movementType: const SizedBox.shrink(),
              source: const SizedBox.shrink(),
              destination: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool showTree}) {
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
        groupTree: showTree
            ? Text(' ', style: ReportTableTypography.header)
            : null,
        transactionDate: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TRANSACTION DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        transactionNumber: Text(
          'TRANSACTION NUMBER',
          style: ReportTableTypography.header,
        ),
        itemName: Text('ITEM NAME', style: ReportTableTypography.header),
        transaction: Text('TRANSACTION', style: ReportTableTypography.header),
        quantity: _headerText('QUANTITY'),
        movementType: Text(
          'MOVEMENT TYPE',
          style: ReportTableTypography.header,
        ),
        source: Text('SOURCE', style: ReportTableTypography.header),
        destination: Text('DESTINATION', style: ReportTableTypography.header),
      ),
    );
  }

  Widget _buildTotalRow(StockMovementRow row, {required bool showTree}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        groupTree: showTree ? const SizedBox.shrink() : null,
        transactionDate: Text('Total', style: _totalStyle),
        transactionNumber: const SizedBox.shrink(),
        itemName: const SizedBox.shrink(),
        transaction: const SizedBox.shrink(),
        quantity: Text(
          _quantityFormat.format(row.quantityIn + row.quantityOut),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        movementType: const SizedBox.shrink(),
        source: const SizedBox.shrink(),
        destination: const SizedBox.shrink(),
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

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );

  TextStyle get _subtotalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 13,
  );
}

class _StockMovementDataRow extends StatefulWidget {
  final StockMovementRow row;
  final NumberFormat formatter;
  final bool isGrouped;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _StockMovementDataRow({
    required this.row,
    required this.formatter,
    required this.isGrouped,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
  });

  @override
  State<_StockMovementDataRow> createState() => _StockMovementDataRowState();
}

class _StockMovementDataRowState extends State<_StockMovementDataRow> {
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
                groupTree: widget.isGrouped ? const SizedBox.shrink() : null,
                transactionDate: Text(
                  widget.row.transactionDate,
                  style: AppTheme.tableCell,
                ),
                transactionNumber: Text(
                  widget.row.referenceNo,
                  style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
                ),
                itemName: Text(
                  widget.row.productName,
                  style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
                ),
                transaction: Text(
                  widget.row.transactionType,
                  style: AppTheme.tableCell,
                ),
                quantity: Text(
                  widget.formatter.format(widget.row.quantity),
                  textAlign: TextAlign.right,
                  style: AppTheme.tableCell,
                ),
                movementType: Text(
                  widget.row.movementType,
                  style: AppTheme.tableCell,
                ),
                source: Text(widget.row.source, style: AppTheme.tableCell),
                destination: Text(widget.row.destination, style: AppTheme.tableCell),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  Widget? groupTree,
  required Widget transactionDate,
  required Widget transactionNumber,
  required Widget itemName,
  required Widget transaction,
  required Widget quantity,
  required Widget movementType,
  required Widget source,
  required Widget destination,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (groupTree != null) ...[
        _stockMovementCell(groupTree, _stockMovementGroupTreeWidth),
        _stockMovementGap(),
      ],
      _stockMovementCell(transactionDate, _stockMovementTransactionDateWidth),
      _stockMovementGap(),
      _stockMovementCell(
        transactionNumber,
        _stockMovementTransactionNumberWidth,
      ),
      _stockMovementGap(),
      _stockMovementCell(itemName, _stockMovementItemNameWidth),
      _stockMovementGap(),
      _stockMovementCell(transaction, _stockMovementTransactionWidth),
      _stockMovementGap(),
      _stockMovementCell(quantity, _stockMovementQuantityWidth),
      _stockMovementGap(),
      _stockMovementCell(movementType, _stockMovementMovementTypeWidth),
      _stockMovementGap(),
      _stockMovementCell(source, _stockMovementSourceWidth),
      _stockMovementGap(),
      _stockMovementCell(destination, _stockMovementDestinationWidth),
    ],
  );
}

Widget _stockMovementCell(Widget child, double width) {
  return SizedBox(width: width, child: child);
}

Widget _stockMovementGap() {
  return const SizedBox(width: _stockMovementColumnGap);
}

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

    const paddingExt = 12.5;

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
          ? size.height + paddingExt
          : isImmediateParent
              ? centerY - cornerRadius
              : centerY;
      canvas.drawLine(
        Offset(x, -paddingExt),
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
        Offset(markerX, size.height + paddingExt),
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
      canvas.drawLine(Offset(x, -0.5), Offset(x, size.height + 0.5), linePaint);
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
