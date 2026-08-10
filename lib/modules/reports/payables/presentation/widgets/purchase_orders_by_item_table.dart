import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

const double _tableHorizontalPadding = AppTheme.space20 * 2;
const double _columnGap = AppTheme.space14;
const double _groupTreeWidth = 240;
const double _purchaseOrderNumberWidth = 150;
const double _vendorNameWidth = 240;
const double _itemNameWidth = 240;
const double _quantityOrderedWidth = 140;
const double _quantityCancelledWidth = 140;
const double _quantityBilledWidth = 140;
const double _amountWidth = 140;
const double _warehouseLocationNameWidth = 240;
const double _locationWidth = 200;

enum _PurchaseOrdersByItemEntryType { groupHeader, data, subtotal, total }

class _PurchaseOrdersByItemEntry {
  final _PurchaseOrdersByItemEntryType type;
  final String title;
  final int depth;
  final PurchaseOrdersByItemRow row;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _PurchaseOrdersByItemEntry({
    required this.type,
    required this.title,
    required this.depth,
    required this.row,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
    this.hasChildren = false,
    this.continues = false,
  });

  factory _PurchaseOrdersByItemEntry.groupHeader({
    required String title,
    required int depth,
    required PurchaseOrdersByItemRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
    required bool hasChildren,
    required bool continues,
  }) {
    return _PurchaseOrdersByItemEntry(
      type: _PurchaseOrdersByItemEntryType.groupHeader,
      title: title,
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
      hasChildren: hasChildren,
      continues: continues,
    );
  }

  factory _PurchaseOrdersByItemEntry.data(
    PurchaseOrdersByItemRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _PurchaseOrdersByItemEntry(
      type: _PurchaseOrdersByItemEntryType.data,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _PurchaseOrdersByItemEntry.subtotal(
    PurchaseOrdersByItemRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _PurchaseOrdersByItemEntry(
      type: _PurchaseOrdersByItemEntryType.subtotal,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _PurchaseOrdersByItemEntry.total(PurchaseOrdersByItemRow row) {
    return _PurchaseOrdersByItemEntry(
      type: _PurchaseOrdersByItemEntryType.total,
      title: '',
      depth: 0,
      row: row,
    );
  }
}

class PurchaseOrdersByItemTable extends StatefulWidget {
  final List<PurchaseOrdersByItemRow> rows;
  final PurchaseOrdersByItemTotals totals;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showGroupTotals;

  const PurchaseOrdersByItemTable({
    super.key,
    required this.rows,
    required this.totals,
    required this.currencyFormat,
    required this.dateFormat,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.groupByFields = const <String>[],
    this.showGroupTotals = false,
  });

  @override
  State<PurchaseOrdersByItemTable> createState() =>
      _PurchaseOrdersByItemTableState();
}

class _PurchaseOrdersByItemTableState extends State<PurchaseOrdersByItemTable> {
  final ScrollController _horizontalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('#,##0.00');

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  List<String> get _activeGroupFields =>
      widget.groupByFields.where((field) => field != 'None').toList(growable: false);

  List<PurchaseOrdersByItemRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <PurchaseOrdersByItemRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  PurchaseOrdersByItemRow get _overallTotals => PurchaseOrdersByItemRow(
        purchaseOrderItemId: '',
        purchaseOrderId: '',
        purchaseOrderNumber: 'Total',
        orderDate: null,
        vendorName: '',
        itemName: '',
        quantityOrdered: widget.totals.quantityOrdered,
        quantityCancelled: widget.totals.quantityCancelled,
        quantityBilled: widget.totals.quantityBilled,
        amount: widget.totals.amount,
        warehouseLocationName: '',
        location: '',
      );

  double get _tableWidth {
    final hasTree = _activeGroupFields.isNotEmpty;
    final contentWidth = (hasTree ? _groupTreeWidth + _columnGap : 0) +
        _purchaseOrderNumberWidth +
        _vendorNameWidth +
        _itemNameWidth +
        _quantityOrderedWidth +
        _quantityCancelledWidth +
        _quantityBilledWidth +
        _amountWidth +
        _warehouseLocationNameWidth +
        _locationWidth +
        (_columnGap * 8);
    return contentWidth + _tableHorizontalPadding;
  }

  List<_PurchaseOrdersByItemEntry> _buildEntries(DateFormat dateFormat) {
    final entries = <_PurchaseOrdersByItemEntry>[];
    final groupFields = _activeGroupFields;
    if (groupFields.isEmpty) {
      entries.addAll(_pageRows.map(_PurchaseOrdersByItemEntry.data));
      entries.add(_PurchaseOrdersByItemEntry.total(_overallTotals));
      return entries;
    }
    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: groupFields,
      depth: 0,
      dateFormat: dateFormat,
    );
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= entries.length) return <_PurchaseOrdersByItemEntry>[_PurchaseOrdersByItemEntry.total(_overallTotals)];
    final end = (start + widget.pageSize).clamp(0, entries.length);
    final paginatedEntries = entries.sublist(start, end);
    if (end == entries.length) paginatedEntries.add(_PurchaseOrdersByItemEntry.total(_overallTotals));
    return paginatedEntries;
  }

  int get _totalCount {
    if (_activeGroupFields.isEmpty) return widget.rows.length;
    final entries = <_PurchaseOrdersByItemEntry>[];
    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: _activeGroupFields,
      depth: 0,
      dateFormat: widget.dateFormat,
    );
    return entries.length;
  }

  void _appendGroupedEntries({
    required List<_PurchaseOrdersByItemEntry> entries,
    required List<PurchaseOrdersByItemRow> rows,
    required List<String> groupFields,
    required int depth,
    required DateFormat dateFormat,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    if (depth >= groupFields.length) {
      entries.addAll(rows.map((row) => _PurchaseOrdersByItemEntry.data(
            row,
            depth: depth,
            ancestorVisible: ancestorVisible,
            ancestorContinues: ancestorContinues,
          )));
      return;
    }
    final field = groupFields[depth];
    final groupedRows = <String, List<PurchaseOrdersByItemRow>>{};
    for (final row in rows) {
      final rawKey = row.groupKey(field, dateFormat);
      final key = rawKey.trim().isEmpty ? '$field - Not mentioned' : rawKey;
      groupedRows.putIfAbsent(key, () => <PurchaseOrdersByItemRow>[]).add(row);
    }
    final groups = groupedRows.entries.toList(growable: false);
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      final hasChildGroups = depth < groupFields.length - 1;
      final hasFollowingSibling = index < groups.length - 1;
      final entryAncestorVisible = _entryAncestorVisible(ancestorVisible, depth);
      final entryAncestorContinues =
          _entryAncestorContinues(ancestorContinues, depth, hasFollowingSibling);

      entries.add(_PurchaseOrdersByItemEntry.groupHeader(
        title: group.key,
        depth: depth,
        row: _subtotalRow(group.key, group.value),
        ancestorVisible: entryAncestorVisible,
        ancestorContinues: entryAncestorContinues,
        hasChildren: hasChildGroups,
        continues: hasChildGroups || (depth == 0 && hasFollowingSibling),
      ));

      _appendGroupedEntries(
        entries: entries,
        rows: group.value,
        groupFields: groupFields,
        depth: depth + 1,
        dateFormat: dateFormat,
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
        entries.add(_PurchaseOrdersByItemEntry.subtotal(
          _subtotalRow(group.key, group.value),
          depth: depth,
          ancestorVisible: entryAncestorVisible,
          ancestorContinues: entryAncestorContinues,
        ));
      }
    }
  }

  PurchaseOrdersByItemRow _subtotalRow(
    String title,
    List<PurchaseOrdersByItemRow> groupRows,
  ) {
    return PurchaseOrdersByItemRow(
      purchaseOrderItemId: '',
      purchaseOrderId: '',
      purchaseOrderNumber: 'Total for $title',
      orderDate: null,
      vendorName: '',
      itemName: '',
      quantityOrdered: groupRows.fold<double>(0, (sum, row) => sum + row.quantityOrdered),
      quantityCancelled: groupRows.fold<double>(0, (sum, row) => sum + row.quantityCancelled),
      quantityBilled: groupRows.fold<double>(0, (sum, row) => sum + row.quantityBilled),
      amount: groupRows.fold<double>(0, (sum, row) => sum + row.amount),
      warehouseLocationName: '',
      location: '',
    );
  }

  List<bool> _childAncestorVisible(
    List<bool> entryAncestorVisible,
    List<bool> entryAncestorContinues, {
    required bool includeCurrentGroup,
  }) =>
      <bool>[
        for (var index = 0; index < entryAncestorVisible.length; index += 1)
          entryAncestorVisible[index] && entryAncestorContinues[index],
        if (includeCurrentGroup) true
      ];

  List<bool> _childAncestorContinues(
    List<bool> entryAncestorContinues, {
    required bool includeCurrentGroup,
  }) =>
      <bool>[...entryAncestorContinues, if (includeCurrentGroup) false];

  List<bool> _entryAncestorVisible(List<bool> ancestorVisible, int depth) {
    final values = List<bool>.of(ancestorVisible, growable: true);
    while (values.length < depth) {
      values.add(false);
    }
    if (depth > 0) values[depth - 1] = true;
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
    if (depth > 0) values[depth - 1] = hasFollowingSibling;
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries(widget.dateFormat);
    final isGrouped = _activeGroupFields.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = _tableWidth;

        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: ReportStickyHeaderScrollTable(
                header: _buildHeader(showTree: isGrouped),
                emptyBody: const SizedBox.shrink(),
                children: [
                  if (widget.rows.isEmpty)
                    const ReportTableEmptyBody(
                      minHeight: 300,
                      message: 'No data to display',
                    )
                  else ...[
                    for (final entry in entries)
                      if (entry.type == _PurchaseOrdersByItemEntryType.groupHeader)
                        _buildGroupHeader(entry, showTree: isGrouped)
                      else if (entry.type == _PurchaseOrdersByItemEntryType.data)
                        _PurchaseOrderItemRow(
                          row: entry.row,
                          quantityFormat: _quantityFormat,
                          currencyFormat: widget.currencyFormat,
                          isGrouped: isGrouped,
                          ancestorVisible: entry.ancestorVisible,
                          ancestorContinues: entry.ancestorContinues,
                        )
                      else if (entry.type == _PurchaseOrdersByItemEntryType.subtotal)
                        _buildSubtotalRow(entry)
                      else if (entry.type == _PurchaseOrdersByItemEntryType.total)
                        _buildTotalRow(entry.row, showTree: isGrouped),
                  ],
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
      },
    );
  }

  Widget _buildGroupHeader(_PurchaseOrdersByItemEntry entry, {required bool showTree}) {
    final row = entry.row;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
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
            hasChildren: entry.hasChildren,
            continues: entry.continues,
          ),
          purchaseOrderNumber: const SizedBox.shrink(),
          vendorName: const SizedBox.shrink(),
          itemName: const SizedBox.shrink(),
          quantityOrdered: widget.showGroupTotals
              ? const SizedBox.shrink()
              : _headerNumber(row.quantityOrdered),
          quantityCancelled: widget.showGroupTotals
              ? const SizedBox.shrink()
              : _headerNumber(row.quantityCancelled),
          quantityBilled: widget.showGroupTotals
              ? const SizedBox.shrink()
              : _headerNumber(row.quantityBilled),
          amount: widget.showGroupTotals
              ? const SizedBox.shrink()
              : _headerCurrency(row.amount),
          warehouseLocationName: const SizedBox.shrink(),
          location: const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSubtotalRow(_PurchaseOrdersByItemEntry entry) {
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
                child: Text(row.purchaseOrderNumber, style: _subtotalStyle),
              ),
              purchaseOrderNumber: const SizedBox.shrink(),
              vendorName: const SizedBox.shrink(),
              itemName: const SizedBox.shrink(),
              quantityOrdered: _subtotalQuantity(row.quantityOrdered),
              quantityCancelled: _subtotalQuantity(row.quantityCancelled),
              quantityBilled: _subtotalQuantity(row.quantityBilled),
              amount: _subtotalCurrency(row.amount),
              warehouseLocationName: const SizedBox.shrink(),
              location: const SizedBox.shrink(),
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
        groupTree: showTree ? Text(' ', style: ReportTableTypography.header) : null,
        purchaseOrderNumber: Row(
          children: [
            Text('P.O#', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        vendorName: _headerText('VENDOR NAME'),
        itemName: _headerText('ITEM NAME'),
        quantityOrdered: _headerText('QUANTITY ORDERED', alignRight: true),
        quantityCancelled: _headerText('QUANTITY CANCELLED', alignRight: true),
        quantityBilled: _headerText('QUANTITY BILLED', alignRight: true),
        amount: _headerText('AMOUNT', alignRight: true),
        warehouseLocationName: _headerText('WAREHOUSE LOCATION NAME'),
        location: _headerText('LOCATION'),
      ),
    );
  }

  Widget _buildTotalRow(PurchaseOrdersByItemRow row, {required bool showTree}) {
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
        groupTree: showTree ? const SizedBox.shrink() : null,
        purchaseOrderNumber: Text('Total', style: _totalStyle),
        vendorName: const SizedBox.shrink(),
        itemName: const SizedBox.shrink(),
        quantityOrdered: _totalQuantity(row.quantityOrdered),
        quantityCancelled: _totalQuantity(row.quantityCancelled),
        quantityBilled: _totalQuantity(row.quantityBilled),
        amount: _totalCurrency(row.amount),
        warehouseLocationName: const SizedBox.shrink(),
        location: const SizedBox.shrink(),
      ),
    );
  }

  Widget _headerText(String value, {bool alignRight = false}) => Text(
        value,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: ReportTableTypography.header,
      );

  Widget _headerNumber(double value) => Text(
        _quantityFormat.format(value),
        textAlign: TextAlign.right,
        style: AppTheme.tableHeader.copyWith(
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
      );

  Widget _headerCurrency(double value) => Text(
        widget.currencyFormat.format(value),
        textAlign: TextAlign.right,
        style: AppTheme.tableHeader.copyWith(
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
      );

  Widget _totalQuantity(double value) => Text(
        _quantityFormat.format(value),
        textAlign: TextAlign.right,
        style: _totalStyle,
      );

  Widget _totalCurrency(double value) => Text(
        widget.currencyFormat.format(value),
        textAlign: TextAlign.right,
        style: _totalStyle,
      );

  Widget _subtotalQuantity(double value) => Text(
        _quantityFormat.format(value),
        textAlign: TextAlign.right,
        style: _subtotalStyle,
      );

  Widget _subtotalCurrency(double value) => Text(
        widget.currencyFormat.format(value),
        textAlign: TextAlign.right,
        style: _subtotalStyle,
      );

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

class _PurchaseOrderItemRow extends StatefulWidget {
  final PurchaseOrdersByItemRow row;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;
  final bool isGrouped;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _PurchaseOrderItemRow({
    required this.row,
    required this.quantityFormat,
    required this.currencyFormat,
    required this.isGrouped,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
  });

  @override
  State<_PurchaseOrderItemRow> createState() => _PurchaseOrderItemRowState();
}

class _PurchaseOrderItemRowState extends State<_PurchaseOrderItemRow> {
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
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
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
                purchaseOrderNumber: _linkText(
                  widget.row.purchaseOrderNumber,
                  isUnderlined: _isHovered,
                ),
                vendorName: _linkText(
                  widget.row.vendorName,
                  isUnderlined: _isHovered,
                ),
                itemName: _linkText(widget.row.itemName, isUnderlined: _isHovered),
                quantityOrdered: _bodyText(
                  widget.quantityFormat.format(widget.row.quantityOrdered),
                  align: TextAlign.right,
                ),
                quantityCancelled: _bodyText(
                  widget.quantityFormat.format(widget.row.quantityCancelled),
                  align: TextAlign.right,
                ),
                quantityBilled: _bodyText(
                  widget.quantityFormat.format(widget.row.quantityBilled),
                  align: TextAlign.right,
                ),
                amount: _bodyText(
                  widget.currencyFormat.format(widget.row.amount),
                  align: TextAlign.right,
                  fontWeight: FontWeight.w600,
                ),
                warehouseLocationName: _bodyText(widget.row.warehouseLocationName),
                location: _bodyText(widget.row.location),
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
  required Widget purchaseOrderNumber,
  required Widget vendorName,
  required Widget itemName,
  required Widget quantityOrdered,
  required Widget quantityCancelled,
  required Widget quantityBilled,
  required Widget amount,
  required Widget warehouseLocationName,
  required Widget location,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (groupTree != null) ...[
        SizedBox(width: _groupTreeWidth, child: groupTree),
        const SizedBox(width: _columnGap),
      ],
      SizedBox(width: _purchaseOrderNumberWidth, child: purchaseOrderNumber),
      const SizedBox(width: _columnGap),
      SizedBox(width: _vendorNameWidth, child: vendorName),
      const SizedBox(width: _columnGap),
      SizedBox(width: _itemNameWidth, child: itemName),
      const SizedBox(width: _columnGap),
      SizedBox(width: _quantityOrderedWidth, child: quantityOrdered),
      const SizedBox(width: _columnGap),
      SizedBox(width: _quantityCancelledWidth, child: quantityCancelled),
      const SizedBox(width: _columnGap),
      SizedBox(width: _quantityBilledWidth, child: quantityBilled),
      const SizedBox(width: _columnGap),
      SizedBox(width: _amountWidth, child: amount),
      const SizedBox(width: _columnGap),
      SizedBox(width: _warehouseLocationNameWidth, child: warehouseLocationName),
      const SizedBox(width: _columnGap),
      SizedBox(width: _locationWidth, child: location),
    ],
  );
}

Widget _linkText(String value, {required bool isUnderlined}) {
  return Text(
    value,
    softWrap: true,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
    ),
  );
}

Widget _bodyText(
  String value, {
  TextAlign align = TextAlign.left,
  FontWeight fontWeight = FontWeight.w500,
}) {
  return Text(
    value.trim().isEmpty ? '-' : value,
    softWrap: true,
    textAlign: align,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: fontWeight,
    ),
  );
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
    if (!showTree) return label;
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
    final cornerRadius =
        depth > 0 && availableWidth < elbowRadius ? availableWidth : elbowRadius;
    const paddingExt = 12.5;
    for (var level = 0; level < depth; level += 1) {
      final isVisible = level < ancestorVisible.length && ancestorVisible[level];
      if (!isVisible) continue;
      final x = startX + (level * step);
      final shouldContinue =
          level < ancestorContinues.length && ancestorContinues[level];
      final isImmediateParent = level == depth - 1;
      final endY = shouldContinue
          ? size.height + paddingExt
          : isImmediateParent
              ? centerY - cornerRadius
              : centerY;
      canvas.drawLine(Offset(x, -paddingExt), Offset(x, endY), linePaint);
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
  bool shouldRepaint(covariant _GroupTreeMarkerPainter oldDelegate) =>
      oldDelegate.depth != depth ||
      oldDelegate.hasChildren != hasChildren ||
      oldDelegate.continues != continues ||
      !_listEquals(oldDelegate.ancestorVisible, ancestorVisible) ||
      !_listEquals(oldDelegate.ancestorContinues, ancestorContinues);
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
      if (!shouldDraw) continue;
      final x = startX + (level * step);
      canvas.drawLine(Offset(x, -0.5), Offset(x, size.height + 0.5), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroupDataConnectorPainter oldDelegate) =>
      !_listEquals(oldDelegate.ancestorVisible, ancestorVisible) ||
      !_listEquals(oldDelegate.ancestorContinues, ancestorContinues);
}

bool _listEquals(List<bool> first, List<bool> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

class PurchaseOrdersByItemRow {
  final String purchaseOrderItemId;
  final String purchaseOrderId;
  final String purchaseOrderNumber;
  final DateTime? orderDate;
  final String vendorName;
  final String itemName;
  final double quantityOrdered;
  final double quantityCancelled;
  final double quantityBilled;
  final double amount;
  final String warehouseLocationName;
  final String location;

  const PurchaseOrdersByItemRow({
    required this.purchaseOrderItemId,
    required this.purchaseOrderId,
    required this.purchaseOrderNumber,
    required this.orderDate,
    required this.vendorName,
    required this.itemName,
    required this.quantityOrdered,
    required this.quantityCancelled,
    required this.quantityBilled,
    required this.amount,
    required this.warehouseLocationName,
    required this.location,
  });

  static List<PurchaseOrdersByItemRow> fromResponse(
    Map<String, dynamic>? response,
  ) {
    final rawRows = response?['rows'];
    if (rawRows is! List) return const <PurchaseOrdersByItemRow>[];
    return rawRows
        .whereType<Map>()
        .map(
          (raw) =>
              PurchaseOrdersByItemRow.fromJson(Map<String, dynamic>.from(raw)),
        )
        .toList(growable: false);
  }

  factory PurchaseOrdersByItemRow.fromJson(Map<String, dynamic> json) {
    return PurchaseOrdersByItemRow(
      purchaseOrderItemId: _stringValue(json['purchaseOrderItemId']),
      purchaseOrderId: _stringValue(json['purchaseOrderId']),
      purchaseOrderNumber: _stringValue(json['purchaseOrderNumber']),
      orderDate: _dateValue(json['orderDate']),
      vendorName: _stringValue(json['vendorName'], fallback: '-'),
      itemName: _stringValue(json['itemName'], fallback: '-'),
      quantityOrdered: _doubleValue(json['quantityOrdered']),
      quantityCancelled: _doubleValue(json['quantityCancelled']),
      quantityBilled: _doubleValue(json['quantityBilled']),
      amount: _doubleValue(json['amount']),
      warehouseLocationName: _stringValue(json['warehouseLocationName']),
      location: _stringValue(json['location']),
    );
  }

  String groupKey(String groupBy, DateFormat dateFormat) {
    switch (groupBy) {
      case 'Date':
        return orderDate != null ? dateFormat.format(orderDate!) : 'Date - Not mentioned';
      case 'P.O#':
        return purchaseOrderNumber.trim().isEmpty ? 'P.O# - Not mentioned' : purchaseOrderNumber;
      case 'Vendor Name':
        return vendorName.trim().isEmpty ? 'Vendor Name - Not mentioned' : vendorName;
      case 'Item Name':
        return itemName.trim().isEmpty ? 'Item Name - Not mentioned' : itemName;
      default:
        return '';
    }
  }
}

class PurchaseOrdersByItemTotals {
  final double quantityOrdered;
  final double quantityCancelled;
  final double quantityBilled;
  final double amount;

  const PurchaseOrdersByItemTotals({
    required this.quantityOrdered,
    required this.quantityCancelled,
    required this.quantityBilled,
    required this.amount,
  });

  factory PurchaseOrdersByItemTotals.fromResponse(
    Map<String, dynamic>? response,
  ) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return PurchaseOrdersByItemTotals(
      quantityOrdered: _doubleValue(totals['quantityOrdered']),
      quantityCancelled: _doubleValue(totals['quantityCancelled']),
      quantityBilled: _doubleValue(totals['quantityBilled']),
      amount: _doubleValue(totals['amount']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
