import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class InventoryAdjustmentSummaryRow {
  final String referenceNumber;
  final String date;
  final String status;
  final String inventoryAdjustment;
  final String adjustmentType;
  final double quantityIncreased;
  final double quantityDecreased;
  final double valueIncreased;
  final double valueDecreased;

  const InventoryAdjustmentSummaryRow({
    required this.referenceNumber,
    required this.date,
    required this.status,
    required this.inventoryAdjustment,
    required this.adjustmentType,
    required this.quantityIncreased,
    required this.quantityDecreased,
    required this.valueIncreased,
    required this.valueDecreased,
  });

  factory InventoryAdjustmentSummaryRow.fromJson(Map<String, dynamic> item) {
    return InventoryAdjustmentSummaryRow(
      referenceNumber: item['referenceNumber']?.toString() ?? '-',
      date: item['date']?.toString() ?? '-',
      status: item['status']?.toString() ?? '-',
      inventoryAdjustment: item['inventoryAdjustment']?.toString() ?? '-',
      adjustmentType: item['adjustmentType']?.toString() ?? '-',
      quantityIncreased: _numberValue(item, 'quantityIncreased'),
      quantityDecreased: _numberValue(item, 'quantityDecreased'),
      valueIncreased: _numberValue(item, 'valueIncreased'),
      valueDecreased: _numberValue(item, 'valueDecreased'),
    );
  }

  factory InventoryAdjustmentSummaryRow.fromTotals(Map<String, dynamic> item) {
    return InventoryAdjustmentSummaryRow(
      referenceNumber: 'Total',
      date: '',
      status: '',
      inventoryAdjustment: '',
      adjustmentType: '',
      quantityIncreased: _numberValue(item, 'quantityIncreased'),
      quantityDecreased: _numberValue(item, 'quantityDecreased'),
      valueIncreased: _numberValue(item, 'valueIncreased'),
      valueDecreased: _numberValue(item, 'valueDecreased'),
    );
  }

  factory InventoryAdjustmentSummaryRow.totalFromRows(List<InventoryAdjustmentSummaryRow> rows) {
    return InventoryAdjustmentSummaryRow(
      referenceNumber: 'Total',
      date: '',
      status: '',
      inventoryAdjustment: '',
      adjustmentType: '',
      quantityIncreased: rows.fold<double>(0, (sum, row) => sum + row.quantityIncreased),
      quantityDecreased: rows.fold<double>(0, (sum, row) => sum + row.quantityDecreased),
      valueIncreased: rows.fold<double>(0, (sum, row) => sum + row.valueIncreased),
      valueDecreased: rows.fold<double>(0, (sum, row) => sum + row.valueDecreased),
    );
  }

  String groupKey(String groupBy) {
    switch (groupBy) {
      case 'Date': return date;
      case 'Reference Number': return referenceNumber;
      case 'Status': return status;
      case 'Inventory Adjustment Reason': return inventoryAdjustment;
      case 'Adjustment Type': return adjustmentType;
      case 'Location': return 'Location - Not mentioned';
      default: return '';
    }
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

const double _adjustmentTableHorizontalPadding = AppTheme.space20 * 2;
const double _adjustmentColumnGap = AppTheme.space14;
const double _adjustmentGroupTreeWidth = 240;
const double _referenceNumberWidth = 150;
const double _dateWidth = 120;
const double _statusWidth = 140;
const double _inventoryAdjustmentWidth = 180;
const double _adjustmentTypeWidth = 150;
const double _quantityIncreasedWidth = 150;
const double _quantityDecreasedWidth = 160;
const double _valueIncreasedWidth = 150;
const double _valueDecreasedWidth = 150;

enum _AdjustmentSummaryEntryType { groupHeader, data, subtotal, total }

class _AdjustmentSummaryEntry {
  final _AdjustmentSummaryEntryType type;
  final String title;
  final int depth;
  final InventoryAdjustmentSummaryRow row;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _AdjustmentSummaryEntry({required this.type, required this.title, required this.depth, required this.row, this.ancestorVisible = const <bool>[], this.ancestorContinues = const <bool>[], this.hasChildren = false, this.continues = false});

  factory _AdjustmentSummaryEntry.groupHeader({required String title, required int depth, required InventoryAdjustmentSummaryRow row, required List<bool> ancestorVisible, required List<bool> ancestorContinues, required bool hasChildren, required bool continues}) {
    return _AdjustmentSummaryEntry(type: _AdjustmentSummaryEntryType.groupHeader, title: title, depth: depth, row: row, ancestorVisible: ancestorVisible, ancestorContinues: ancestorContinues, hasChildren: hasChildren, continues: continues);
  }

  factory _AdjustmentSummaryEntry.data(InventoryAdjustmentSummaryRow row, {int depth = 0, List<bool> ancestorVisible = const <bool>[], List<bool> ancestorContinues = const <bool>[]}) {
    return _AdjustmentSummaryEntry(type: _AdjustmentSummaryEntryType.data, title: '', depth: depth, row: row, ancestorVisible: ancestorVisible, ancestorContinues: ancestorContinues);
  }

  factory _AdjustmentSummaryEntry.subtotal(InventoryAdjustmentSummaryRow row, {int depth = 0, List<bool> ancestorVisible = const <bool>[], List<bool> ancestorContinues = const <bool>[]}) {
    return _AdjustmentSummaryEntry(type: _AdjustmentSummaryEntryType.subtotal, title: '', depth: depth, row: row, ancestorVisible: ancestorVisible, ancestorContinues: ancestorContinues);
  }

  factory _AdjustmentSummaryEntry.total(InventoryAdjustmentSummaryRow row) {
    return _AdjustmentSummaryEntry(type: _AdjustmentSummaryEntryType.total, title: '', depth: 0, row: row);
  }
}

class InventoryAdjustmentSummaryTable extends StatefulWidget {
  final List<InventoryAdjustmentSummaryRow> rows;
  final InventoryAdjustmentSummaryRow totals;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showGroupTotals;

  const InventoryAdjustmentSummaryTable({super.key, required this.rows, required this.totals, required this.page, required this.pageSize, required this.onPageChanged, this.groupByFields = const <String>[], this.showGroupTotals = false});

  @override
  State<InventoryAdjustmentSummaryTable> createState() => _InventoryAdjustmentSummaryTableState();
}

class _InventoryAdjustmentSummaryTableState extends State<InventoryAdjustmentSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 2);

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<String> get _activeGroupFields => widget.groupByFields.where((field) => field != 'None').toList(growable: false);

  List<InventoryAdjustmentSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <InventoryAdjustmentSummaryRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  InventoryAdjustmentSummaryRow get _overallTotals => widget.totals;

  double get _tableWidth {
    final hasTree = _activeGroupFields.isNotEmpty;
    final contentWidth = (hasTree ? _adjustmentGroupTreeWidth + _adjustmentColumnGap : 0) + _referenceNumberWidth + _dateWidth + _statusWidth + _inventoryAdjustmentWidth + _adjustmentTypeWidth + _quantityIncreasedWidth + _quantityDecreasedWidth + _valueIncreasedWidth + _valueDecreasedWidth + (_adjustmentColumnGap * 8);
    return contentWidth + _adjustmentTableHorizontalPadding;
  }

  List<_AdjustmentSummaryEntry> _buildEntries() {
    final entries = <_AdjustmentSummaryEntry>[];
    final groupFields = _activeGroupFields;
    if (groupFields.isEmpty) {
      entries.addAll(_pageRows.map(_AdjustmentSummaryEntry.data));
      entries.add(_AdjustmentSummaryEntry.total(_overallTotals));
      return entries;
    }
    _appendGroupedEntries(entries: entries, rows: widget.rows, groupFields: groupFields, depth: 0);
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= entries.length) return <_AdjustmentSummaryEntry>[_AdjustmentSummaryEntry.total(_overallTotals)];
    final end = (start + widget.pageSize).clamp(0, entries.length);
    final paginatedEntries = entries.sublist(start, end);
    if (end == entries.length) paginatedEntries.add(_AdjustmentSummaryEntry.total(_overallTotals));
    return paginatedEntries;
  }

  int get _totalCount {
    if (_activeGroupFields.isEmpty) return widget.rows.length;
    final entries = <_AdjustmentSummaryEntry>[];
    _appendGroupedEntries(entries: entries, rows: widget.rows, groupFields: _activeGroupFields, depth: 0);
    return entries.length;
  }

  void _appendGroupedEntries({required List<_AdjustmentSummaryEntry> entries, required List<InventoryAdjustmentSummaryRow> rows, required List<String> groupFields, required int depth, List<bool> ancestorVisible = const <bool>[], List<bool> ancestorContinues = const <bool>[]}) {
    if (depth >= groupFields.length) {
      entries.addAll(rows.map((row) => _AdjustmentSummaryEntry.data(row, depth: depth, ancestorVisible: ancestorVisible, ancestorContinues: ancestorContinues)));
      return;
    }
    final field = groupFields[depth];
    final groupedRows = <String, List<InventoryAdjustmentSummaryRow>>{};
    for (final row in rows) {
      final rawKey = row.groupKey(field);
      final key = rawKey.trim().isEmpty ? '$field - Not mentioned' : rawKey;
      groupedRows.putIfAbsent(key, () => <InventoryAdjustmentSummaryRow>[]).add(row);
    }
    final groups = groupedRows.entries.toList(growable: false);
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      final hasChildGroups = depth < groupFields.length - 1;
      final hasFollowingSibling = index < groups.length - 1;
      final entryAncestorVisible = _entryAncestorVisible(ancestorVisible, depth);
      final entryAncestorContinues = _entryAncestorContinues(ancestorContinues, depth, hasFollowingSibling);
      entries.add(_AdjustmentSummaryEntry.groupHeader(title: group.key, depth: depth, row: _subtotalRow(group.key, group.value), ancestorVisible: entryAncestorVisible, ancestorContinues: entryAncestorContinues, hasChildren: hasChildGroups, continues: hasChildGroups || (depth == 0 && hasFollowingSibling)));
      _appendGroupedEntries(entries: entries, rows: group.value, groupFields: groupFields, depth: depth + 1, ancestorVisible: _childAncestorVisible(entryAncestorVisible, entryAncestorContinues, includeCurrentGroup: hasChildGroups), ancestorContinues: _childAncestorContinues(entryAncestorContinues, includeCurrentGroup: hasChildGroups));
      if (widget.showGroupTotals) {
        entries.add(_AdjustmentSummaryEntry.subtotal(_subtotalRow(group.key, group.value), depth: depth, ancestorVisible: entryAncestorVisible, ancestorContinues: entryAncestorContinues));
      }
    }
  }

  InventoryAdjustmentSummaryRow _subtotalRow(String title, List<InventoryAdjustmentSummaryRow> groupRows) {
    return InventoryAdjustmentSummaryRow(
      referenceNumber: 'Total for $title',
      date: '', status: '', inventoryAdjustment: '', adjustmentType: '',
      quantityIncreased: groupRows.fold<double>(0, (sum, row) => sum + row.quantityIncreased),
      quantityDecreased: groupRows.fold<double>(0, (sum, row) => sum + row.quantityDecreased),
      valueIncreased: groupRows.fold<double>(0, (sum, row) => sum + row.valueIncreased),
      valueDecreased: groupRows.fold<double>(0, (sum, row) => sum + row.valueDecreased),
    );
  }

  List<bool> _childAncestorVisible(List<bool> entryAncestorVisible, List<bool> entryAncestorContinues, {required bool includeCurrentGroup}) => <bool>[for (var index = 0; index < entryAncestorVisible.length; index += 1) entryAncestorVisible[index] && entryAncestorContinues[index], if (includeCurrentGroup) true];
  List<bool> _childAncestorContinues(List<bool> entryAncestorContinues, {required bool includeCurrentGroup}) => <bool>[...entryAncestorContinues, if (includeCurrentGroup) false];
  List<bool> _entryAncestorVisible(List<bool> ancestorVisible, int depth) { final values = List<bool>.of(ancestorVisible, growable: true); while (values.length < depth) { values.add(false); } if (depth > 0) values[depth - 1] = true; return values; }
  List<bool> _entryAncestorContinues(List<bool> ancestorContinues, int depth, bool hasFollowingSibling) { final values = List<bool>.of(ancestorContinues, growable: true); while (values.length < depth) { values.add(false); } if (depth > 0) values[depth - 1] = hasFollowingSibling; return values; }

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
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        switch (entry.type) {
                          case _AdjustmentSummaryEntryType.groupHeader:
                            return _buildGroupHeader(entry, showTree: isGrouped);
                          case _AdjustmentSummaryEntryType.data:
                            return _InventoryAdjustmentSummaryDataRow(row: entry.row, quantityFormatter: _quantityFormat, currencyFormatter: _currencyFormat, isGrouped: isGrouped, ancestorVisible: entry.ancestorVisible, ancestorContinues: entry.ancestorContinues);
                          case _AdjustmentSummaryEntryType.subtotal:
                            return _buildSubtotalRow(entry);
                          case _AdjustmentSummaryEntryType.total:
                            return _buildTotalRow(entry.row, showTree: isGrouped);
                        }
                      },
                    ),
                  ),
                ),
              ReportPaginationFooter(totalCount: _totalCount, page: widget.page, pageSize: widget.pageSize, onPageChanged: widget.onPageChanged),
              const SizedBox(height: AppTheme.space28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(_AdjustmentSummaryEntry entry, {required bool showTree}) {
    final row = entry.row;
    return Container(
      color: AppTheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
        child: _buildTableRow(
          groupTree: _GroupTreeLabel(title: entry.title, depth: entry.depth, showTree: showTree, ancestorVisible: entry.ancestorVisible, ancestorContinues: entry.ancestorContinues, hasChildren: entry.hasChildren, continues: entry.continues),
          referenceNumber: const SizedBox.shrink(), date: const SizedBox.shrink(), status: const SizedBox.shrink(), inventoryAdjustment: const SizedBox.shrink(), adjustmentType: const SizedBox.shrink(),
          quantityIncreased: widget.showGroupTotals ? const SizedBox.shrink() : _headerNumber(row.quantityIncreased),
          quantityDecreased: widget.showGroupTotals ? const SizedBox.shrink() : _headerNumber(row.quantityDecreased),
          valueIncreased: widget.showGroupTotals ? const SizedBox.shrink() : _headerCurrency(row.valueIncreased),
          valueDecreased: widget.showGroupTotals ? const SizedBox.shrink() : _headerCurrency(row.valueDecreased),
        ),
      ),
    );
  }

  Widget _buildSubtotalRow(_AdjustmentSummaryEntry entry) {
    final row = entry.row;
    final labelIndent = (entry.depth + 1) * AppTheme.space28;
    final showConnector = entry.ancestorVisible.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(color: AppTheme.backgroundColor, border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
      child: Stack(
        children: [
          if (showConnector) Positioned.fill(child: CustomPaint(painter: _GroupDataConnectorPainter(ancestorVisible: entry.ancestorVisible, ancestorContinues: entry.ancestorContinues))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
            child: _buildTableRow(
              groupTree: Padding(padding: EdgeInsets.only(left: labelIndent), child: Text(row.referenceNumber, style: _subtotalStyle)),
              referenceNumber: const SizedBox.shrink(), date: const SizedBox.shrink(), status: const SizedBox.shrink(), inventoryAdjustment: const SizedBox.shrink(), adjustmentType: const SizedBox.shrink(),
              quantityIncreased: _subtotalQuantity(row.quantityIncreased), quantityDecreased: _subtotalQuantity(row.quantityDecreased), valueIncreased: _subtotalCurrency(row.valueIncreased), valueDecreased: _subtotalCurrency(row.valueDecreased),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool showTree}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space10),
      decoration: const BoxDecoration(color: AppTheme.tableHeaderBg, border: Border(top: BorderSide(color: AppTheme.borderColor), bottom: BorderSide(color: AppTheme.borderColor))),
      child: _buildTableRow(
        groupTree: showTree ? Text(' ', style: ReportTableTypography.header) : null,
        referenceNumber: Text('REFERENCE NUMBER', style: ReportTableTypography.header),
        date: Row(mainAxisSize: MainAxisSize.min, children: [Text('DATE', style: ReportTableTypography.header), const SizedBox(width: AppTheme.space4), const Icon(Icons.unfold_more, size: AppTheme.space14, color: AppTheme.textSecondary)]),
        status: Text('STATUS', style: ReportTableTypography.header),
        inventoryAdjustment: Text('INVENTORY ADJUSTMENT', style: ReportTableTypography.header),
        adjustmentType: Text('ADJUSTMENT TYPE', style: ReportTableTypography.header),
        quantityIncreased: _headerText('QUANTITY INCREASED'), quantityDecreased: _headerText('QUANTITY DECREASED'), valueIncreased: _headerText('VALUE INCREASED'), valueDecreased: _headerText('VALUE DECREASED'),
      ),
    );
  }

  Widget _buildTotalRow(InventoryAdjustmentSummaryRow row, {required bool showTree}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        groupTree: showTree ? const SizedBox.shrink() : null,
        referenceNumber: Text('Total', style: _totalStyle), date: const SizedBox.shrink(), status: const SizedBox.shrink(), inventoryAdjustment: const SizedBox.shrink(), adjustmentType: const SizedBox.shrink(),
        quantityIncreased: _totalQuantity(row.quantityIncreased), quantityDecreased: _totalQuantity(row.quantityDecreased), valueIncreased: _totalCurrency(row.valueIncreased), valueDecreased: _totalCurrency(row.valueDecreased),
      ),
    );
  }

  Widget _headerText(String value) => Text(value, textAlign: TextAlign.right, style: ReportTableTypography.header);
  Widget _headerNumber(double value) => Text(_quantityFormat.format(value), textAlign: TextAlign.right, style: AppTheme.tableHeader.copyWith(color: AppTheme.textPrimary, fontSize: 13));
  Widget _headerCurrency(double value) => Text(_currencyFormat.format(value), textAlign: TextAlign.right, style: AppTheme.tableHeader.copyWith(color: AppTheme.textPrimary, fontSize: 13));
  Widget _totalQuantity(double value) => Text(_quantityFormat.format(value), textAlign: TextAlign.right, style: _totalStyle);
  Widget _totalCurrency(double value) => Text(_currencyFormat.format(value), textAlign: TextAlign.right, style: _totalStyle);
  Widget _subtotalQuantity(double value) => Text(_quantityFormat.format(value), textAlign: TextAlign.right, style: _subtotalStyle);
  Widget _subtotalCurrency(double value) => Text(_currencyFormat.format(value), textAlign: TextAlign.right, style: _subtotalStyle);

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 15);
  TextStyle get _subtotalStyle => AppTheme.bodyText.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13);
}

class _InventoryAdjustmentSummaryDataRow extends StatefulWidget {
  final InventoryAdjustmentSummaryRow row;
  final NumberFormat quantityFormatter;
  final NumberFormat currencyFormatter;
  final bool isGrouped;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _InventoryAdjustmentSummaryDataRow({required this.row, required this.quantityFormatter, required this.currencyFormatter, required this.isGrouped, this.ancestorVisible = const <bool>[], this.ancestorContinues = const <bool>[]});

  @override
  State<_InventoryAdjustmentSummaryDataRow> createState() => _InventoryAdjustmentSummaryDataRowState();
}

class _InventoryAdjustmentSummaryDataRowState extends State<_InventoryAdjustmentSummaryDataRow> {
  bool _isHovered = false;
  void _setHovered(bool value) { if (!mounted || _isHovered == value) return; setState(() => _isHovered = value); }

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
            if (showConnector) Positioned.fill(child: CustomPaint(painter: _GroupDataConnectorPainter(ancestorVisible: widget.ancestorVisible, ancestorContinues: widget.ancestorContinues))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
              child: _buildTableRow(
                groupTree: widget.isGrouped ? const SizedBox.shrink() : null,
                referenceNumber: Text(widget.row.referenceNumber, style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue)),
                date: Text(widget.row.date, style: AppTheme.tableCell),
                status: Text(widget.row.status, style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue)),
                inventoryAdjustment: Text(widget.row.inventoryAdjustment, style: AppTheme.tableCell),
                adjustmentType: Text(widget.row.adjustmentType, style: AppTheme.tableCell),
                quantityIncreased: _quantityCell(widget.row.quantityIncreased),
                quantityDecreased: _quantityCell(widget.row.quantityDecreased),
                valueIncreased: _currencyCell(widget.row.valueIncreased),
                valueDecreased: _currencyCell(widget.row.valueDecreased),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityCell(double value) => Text(widget.quantityFormatter.format(value), textAlign: TextAlign.right, style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue));
  Widget _currencyCell(double value) => Text(widget.currencyFormatter.format(value), textAlign: TextAlign.right, style: AppTheme.tableCell);
}

Widget _buildTableRow({Widget? groupTree, required Widget referenceNumber, required Widget date, required Widget status, required Widget inventoryAdjustment, required Widget adjustmentType, required Widget quantityIncreased, required Widget quantityDecreased, required Widget valueIncreased, required Widget valueDecreased}) {
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (groupTree != null) ...[_adjustmentCell(groupTree, _adjustmentGroupTreeWidth), _adjustmentGap()],
    _adjustmentCell(referenceNumber, _referenceNumberWidth), _adjustmentGap(),
    _adjustmentCell(date, _dateWidth), _adjustmentGap(),
    _adjustmentCell(status, _statusWidth), _adjustmentGap(),
    _adjustmentCell(inventoryAdjustment, _inventoryAdjustmentWidth), _adjustmentGap(),
    _adjustmentCell(adjustmentType, _adjustmentTypeWidth), _adjustmentGap(),
    _adjustmentCell(quantityIncreased, _quantityIncreasedWidth), _adjustmentGap(),
    _adjustmentCell(quantityDecreased, _quantityDecreasedWidth), _adjustmentGap(),
    _adjustmentCell(valueIncreased, _valueIncreasedWidth), _adjustmentGap(),
    _adjustmentCell(valueDecreased, _valueDecreasedWidth),
  ]);
}

Widget _adjustmentCell(Widget child, double width) => SizedBox(width: width, child: child);
Widget _adjustmentGap() => const SizedBox(width: _adjustmentColumnGap);

class _GroupTreeLabel extends StatelessWidget {
  final String title;
  final int depth;
  final bool showTree;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _GroupTreeLabel({required this.title, required this.depth, required this.showTree, required this.ancestorVisible, required this.ancestorContinues, required this.hasChildren, required this.continues});

  @override
  Widget build(BuildContext context) {
    final label = Text(title, overflow: TextOverflow.ellipsis, style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700));
    if (!showTree) return label;
    return Row(children: [
      SizedBox(width: AppTheme.space20 + (depth * AppTheme.space20), height: _GroupTreeMarkerPainter.rowHeight, child: CustomPaint(painter: _GroupTreeMarkerPainter(depth: depth, ancestorVisible: ancestorVisible, ancestorContinues: ancestorContinues, hasChildren: hasChildren, continues: continues))),
      const SizedBox(width: AppTheme.space4),
      Expanded(child: label),
    ]);
  }
}

class _GroupTreeMarkerPainter extends CustomPainter {
  static const double rowHeight = 40;
  final int depth;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _GroupTreeMarkerPainter({required this.depth, required this.ancestorVisible, required this.ancestorContinues, required this.hasChildren, required this.continues});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = AppTheme.borderLight..strokeWidth = 1..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final circlePaint = Paint()..color = AppTheme.backgroundColor..style = PaintingStyle.fill;
    final circleBorderPaint = Paint()..color = AppTheme.borderLight..strokeWidth = 1..style = PaintingStyle.stroke;
    const step = AppTheme.space20;
    const startX = AppTheme.space6;
    final centerY = size.height / 2;
    final markerX = startX + (depth * step);
    const elbowRadius = AppTheme.space6;
    const circleRadius = 5.0;
    final parentX = depth > 0 ? startX + ((depth - 1) * step) : markerX;
    final branchEndX = markerX - circleRadius;
    final availableWidth = branchEndX - parentX;
    final cornerRadius = depth > 0 && availableWidth < elbowRadius ? availableWidth : elbowRadius;
    const paddingExt = 12.5;
    for (var level = 0; level < depth; level += 1) {
      final isVisible = level < ancestorVisible.length && ancestorVisible[level];
      if (!isVisible) continue;
      final x = startX + (level * step);
      final shouldContinue = level < ancestorContinues.length && ancestorContinues[level];
      final isImmediateParent = level == depth - 1;
      final endY = shouldContinue ? size.height + paddingExt : isImmediateParent ? centerY - cornerRadius : centerY;
      canvas.drawLine(Offset(x, -paddingExt), Offset(x, endY), linePaint);
    }
    if (depth > 0) {
      final branchPath = Path()..moveTo(parentX, centerY - cornerRadius)..quadraticBezierTo(parentX, centerY, parentX + cornerRadius, centerY)..lineTo(branchEndX, centerY);
      canvas.drawPath(branchPath, linePaint);
    }
    if (continues || hasChildren) canvas.drawLine(Offset(markerX, centerY), Offset(markerX, size.height + paddingExt), linePaint);
    canvas.drawCircle(Offset(markerX, centerY), 5, circlePaint);
    canvas.drawCircle(Offset(markerX, centerY), 5, circleBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _GroupTreeMarkerPainter oldDelegate) => oldDelegate.depth != depth || oldDelegate.hasChildren != hasChildren || oldDelegate.continues != continues || !_listEquals(oldDelegate.ancestorVisible, ancestorVisible) || !_listEquals(oldDelegate.ancestorContinues, ancestorContinues);
}

class _GroupDataConnectorPainter extends CustomPainter {
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  const _GroupDataConnectorPainter({required this.ancestorVisible, required this.ancestorContinues});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = AppTheme.borderLight..strokeWidth = 1..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    const step = AppTheme.space20;
    const startX = AppTheme.space20 + AppTheme.space6;
    for (var level = 0; level < ancestorVisible.length; level += 1) {
      final shouldDraw = ancestorVisible[level] && level < ancestorContinues.length && ancestorContinues[level];
      if (!shouldDraw) continue;
      final x = startX + (level * step);
      canvas.drawLine(Offset(x, -0.5), Offset(x, size.height + 0.5), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroupDataConnectorPainter oldDelegate) => !_listEquals(oldDelegate.ancestorVisible, ancestorVisible) || !_listEquals(oldDelegate.ancestorContinues, ancestorContinues);
}

bool _listEquals(List<bool> first, List<bool> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
