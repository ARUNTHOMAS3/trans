import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class ReceivableDetailsRow {
  final String customerName;
  final String date;
  final String transactionNumber;
  final String referenceNumber;
  final String status;
  final String transactionType;
  final String itemName;
  final String quantityOrdered;
  final String itemPriceBcy;
  final String totalBcy;

  const ReceivableDetailsRow({
    required this.customerName,
    required this.date,
    required this.transactionNumber,
    required this.referenceNumber,
    required this.status,
    required this.transactionType,
    required this.itemName,
    required this.quantityOrdered,
    required this.itemPriceBcy,
    required this.totalBcy,
  });

  String groupKey(String groupBy) {
    switch (groupBy) {
      case 'Customer Name':
        return customerName;
      case 'Warehouse Location Name':
        return 'Warehouse Location Name - Not mentioned';
      case 'Date':
        return date;
      case 'Transaction#':
        return transactionNumber;
      case 'Transaction Type':
        return transactionType;
      case 'Item Name':
        return itemName;
      case 'Account':
        return 'Account - Not mentioned';
      case 'Salesperson':
        return 'Salesperson - Not mentioned';
      case 'Currency':
        return 'INR';
      case 'Created By':
        return 'Created By - Not mentioned';
      default:
        return '';
    }
  }
}

enum _ReceivableDetailsEntryType { groupHeader, data, subtotal, total }

class _ReceivableDetailsEntry {
  final _ReceivableDetailsEntryType type;
  final String title;
  final int depth;
  final ReceivableDetailsRow row;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _ReceivableDetailsEntry({
    required this.type,
    required this.title,
    required this.depth,
    required this.row,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
    this.hasChildren = false,
    this.continues = false,
  });

  factory _ReceivableDetailsEntry.groupHeader({
    required String title,
    required int depth,
    required ReceivableDetailsRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
    required bool hasChildren,
    required bool continues,
  }) {
    return _ReceivableDetailsEntry(
      type: _ReceivableDetailsEntryType.groupHeader,
      title: title,
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
      hasChildren: hasChildren,
      continues: continues,
    );
  }

  factory _ReceivableDetailsEntry.data(
    ReceivableDetailsRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _ReceivableDetailsEntry(
      type: _ReceivableDetailsEntryType.data,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _ReceivableDetailsEntry.subtotal(
    ReceivableDetailsRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _ReceivableDetailsEntry(
      type: _ReceivableDetailsEntryType.subtotal,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _ReceivableDetailsEntry.total(ReceivableDetailsRow row) {
    return _ReceivableDetailsEntry(
      type: _ReceivableDetailsEntryType.total,
      title: '',
      depth: 0,
      row: row,
    );
  }
}

class ReceivableDetailsTable extends StatefulWidget {
  final List<ReceivableDetailsRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showOnlyGroupTotals;
  final bool showGroupTotals;

  const ReceivableDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.groupByFields = const <String>[],
    this.showOnlyGroupTotals = false,
    this.showGroupTotals = false,
  });

  @override
  State<ReceivableDetailsTable> createState() => _ReceivableDetailsTableState();
}

class _ReceivableDetailsTableState extends State<ReceivableDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const String _totalQuantity = '175.00';
  static const String _totalBcy = '\u20B922,657.00';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<String> get _activeGroupFields => widget.groupByFields
      .where((field) => field != 'None')
      .toList(growable: false);

  List<ReceivableDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <ReceivableDetailsRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  ReceivableDetailsRow get _overallTotals {
    return ReceivableDetailsRow(
      customerName: 'Total',
      date: '',
      transactionNumber: '',
      referenceNumber: '',
      status: '',
      transactionType: '',
      itemName: '',
      quantityOrdered: _totalQuantity,
      itemPriceBcy: '',
      totalBcy: _totalBcy,
    );
  }

  double get _tableWidth {
    final isGrouped = _activeGroupFields.isNotEmpty;
    return isGrouped ? 1980 : 1740;
  }

  List<_ReceivableDetailsEntry> _buildEntries() {
    final entries = <_ReceivableDetailsEntry>[];
    final groupFields = _activeGroupFields;

    if (groupFields.isEmpty) {
      entries.addAll(_pageRows.map(_ReceivableDetailsEntry.data));
      entries.add(_ReceivableDetailsEntry.total(_overallTotals));
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
      return <_ReceivableDetailsEntry>[_ReceivableDetailsEntry.total(_overallTotals)];
    }
    final end = (start + widget.pageSize).clamp(0, entries.length);
    final paginatedEntries = entries.sublist(start, end);

    if (end == entries.length) {
      paginatedEntries.add(_ReceivableDetailsEntry.total(_overallTotals));
    }
    return paginatedEntries;
  }

  int get _totalCount {
    if (_activeGroupFields.isEmpty) return widget.rows.length;
    final entries = <_ReceivableDetailsEntry>[];
    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: _activeGroupFields,
      depth: 0,
    );
    return entries.length;
  }

  void _appendGroupedEntries({
    required List<_ReceivableDetailsEntry> entries,
    required List<ReceivableDetailsRow> rows,
    required List<String> groupFields,
    required int depth,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    if (depth >= groupFields.length) {
      if (widget.showOnlyGroupTotals) return;
      entries.addAll(
        rows.map(
          (row) => _ReceivableDetailsEntry.data(
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
    final groupedRows = <String, List<ReceivableDetailsRow>>{};
    for (final row in rows) {
      final key = row.groupKey(field);
      groupedRows.putIfAbsent(key, () => <ReceivableDetailsRow>[]).add(row);
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

      final showHeaderTotals = widget.showOnlyGroupTotals || !widget.showGroupTotals;

      entries.add(
        _ReceivableDetailsEntry.groupHeader(
          title: group.key,
          depth: depth,
          row: _subtotalRow(group.key, group.value, showTotals: showHeaderTotals),
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
          _ReceivableDetailsEntry.subtotal(
            _subtotalRow(group.key, group.value, showTotals: true),
            depth: depth,
            ancestorVisible: entryAncestorVisible,
            ancestorContinues: entryAncestorContinues,
          ),
        );
      }
    }
  }

  ReceivableDetailsRow _subtotalRow(
    String title,
    List<ReceivableDetailsRow> groupRows, {
    required bool showTotals,
  }) {
    if (!showTotals) {
      return ReceivableDetailsRow(
        customerName: 'Total for $title',
        date: '',
        transactionNumber: '',
        referenceNumber: '',
        status: '',
        transactionType: '',
        itemName: '',
        quantityOrdered: '',
        itemPriceBcy: '',
        totalBcy: '',
      );
    }
    final totalQtyVal = groupRows.fold<double>(0, (sum, row) => sum + _parseQty(row.quantityOrdered));
    final totalBcyVal = groupRows.fold<double>(0, (sum, row) => sum + _parseCurrency(row.totalBcy));

    return ReceivableDetailsRow(
      customerName: 'Total for $title',
      date: '',
      transactionNumber: '',
      referenceNumber: '',
      status: '',
      transactionType: '',
      itemName: '',
      quantityOrdered: totalQtyVal.toStringAsFixed(2),
      itemPriceBcy: '',
      totalBcy: _formatCurrency(totalBcyVal),
    );
  }

  double _parseQty(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
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
                const SizedBox.shrink()
              else
                SizedBox(
                  height: 360,
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
                          case _ReceivableDetailsEntryType.groupHeader:
                            return _buildGroupHeader(entry, showTree: isGrouped);
                          case _ReceivableDetailsEntryType.data:
                            return _ReceivableDetailsDataRow(
                              row: entry.row,
                              isGrouped: isGrouped,
                              ancestorVisible: entry.ancestorVisible,
                              ancestorContinues: entry.ancestorContinues,
                            );
                          case _ReceivableDetailsEntryType.subtotal:
                            return _buildSubtotalRow(entry);
                          case _ReceivableDetailsEntryType.total:
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

  Widget _buildGroupHeader(_ReceivableDetailsEntry entry, {required bool showTree}) {
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
          customerName: const SizedBox.shrink(),
          date: const SizedBox.shrink(),
          transactionNumber: const SizedBox.shrink(),
          referenceNumber: const SizedBox.shrink(),
          status: const SizedBox.shrink(),
          transactionType: const SizedBox.shrink(),
          itemName: const SizedBox.shrink(),
          quantityOrdered: row.quantityOrdered.isNotEmpty
              ? _amountText(row.quantityOrdered, style: _groupHeaderStyle)
              : const SizedBox.shrink(),
          itemPriceBcy: const SizedBox.shrink(),
          totalBcy: row.totalBcy.isNotEmpty
              ? _amountText(row.totalBcy, style: _groupHeaderStyle)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSubtotalRow(_ReceivableDetailsEntry entry) {
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
                child: Text(row.customerName, style: _subtotalStyle),
              ),
              customerName: const SizedBox.shrink(),
              date: const SizedBox.shrink(),
              transactionNumber: const SizedBox.shrink(),
              referenceNumber: const SizedBox.shrink(),
              status: const SizedBox.shrink(),
              transactionType: const SizedBox.shrink(),
              itemName: const SizedBox.shrink(),
              quantityOrdered: _amountText(row.quantityOrdered, style: _subtotalStyle),
              itemPriceBcy: const SizedBox.shrink(),
              totalBcy: _amountText(row.totalBcy, style: _subtotalStyle),
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
        customerName: _headerText('CUSTOMER NAME'),
        date: _headerText('DATE'),
        transactionNumber: _headerText('TRANSACTION#'),
        referenceNumber: _headerText('REFERENCE#'),
        status: _headerText('STATUS'),
        transactionType: _headerText('TRANSACTION TYPE'),
        itemName: Row(
          children: [
            Text('ITEM NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        quantityOrdered: _headerText('QUANTITY ORDERED', alignRight: true),
        itemPriceBcy: _headerText('ITEM PRICE (BCY)', alignRight: true),
        totalBcy: _headerText('TOTAL (BCY)', alignRight: true),
      ),
    );
  }

  Widget _buildTotalRow(ReceivableDetailsRow row, {required bool showTree}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        groupTree: showTree ? const SizedBox.shrink() : null,
        customerName: Text('Total', style: _totalStyle),
        date: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        transactionType: const SizedBox.shrink(),
        itemName: const SizedBox.shrink(),
        quantityOrdered: Text(
          row.quantityOrdered,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        itemPriceBcy: const SizedBox.shrink(),
        totalBcy: Text(
          row.totalBcy,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
      ),
    );
  }

  Widget _headerText(String value, {bool alignRight = false}) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: ReportTableTypography.header,
    );
  }

  Widget _amountText(String value, {TextStyle? style}) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: style ?? AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
    );
  }

  TextStyle get _groupHeaderStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      );

  TextStyle get _subtotalStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      );

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );
}

class _ReceivableDetailsDataRow extends StatefulWidget {
  final ReceivableDetailsRow row;
  final bool isGrouped;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _ReceivableDetailsDataRow({
    required this.row,
    required this.isGrouped,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
  });

  @override
  State<_ReceivableDetailsDataRow> createState() =>
      _ReceivableDetailsDataRowState();
}

class _ReceivableDetailsDataRowState extends State<_ReceivableDetailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
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
                customerName: _linkText(row.customerName),
                date: Text(row.date, style: AppTheme.tableCell),
                transactionNumber: _linkText(row.transactionNumber),
                referenceNumber: _optionalLinkText(row.referenceNumber),
                status: Text(row.status, style: _statusStyle(row.status)),
                transactionType: Text(row.transactionType, style: AppTheme.tableCell),
                itemName: Text(row.itemName, style: AppTheme.tableCell),
                quantityOrdered: _amountText(row.quantityOrdered),
                itemPriceBcy: _amountText(row.itemPriceBcy),
                totalBcy: _blueAmountText(row.totalBcy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }

  Widget _optionalLinkText(String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return _linkText(value);
  }

  Widget _blueAmountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _amountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
    );
  }

  TextStyle _statusStyle(String status) {
    final color = switch (status) {
      'Paid' => AppTheme.successTextDark,
      'Sent' => AppTheme.primaryBlue,
      'Open' => AppTheme.primaryBlue,
      _ => AppTheme.textMuted,
    };

    return AppTheme.tableCell.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );
  }
}

Widget _buildTableRow({
  Widget? groupTree,
  required Widget customerName,
  required Widget date,
  required Widget transactionNumber,
  required Widget referenceNumber,
  required Widget status,
  required Widget transactionType,
  required Widget itemName,
  required Widget quantityOrdered,
  required Widget itemPriceBcy,
  required Widget totalBcy,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (groupTree != null) ...[
        Expanded(flex: 6, child: groupTree),
      ],
      Expanded(flex: 4, child: customerName),
      Expanded(flex: 3, child: date),
      Expanded(flex: 3, child: transactionNumber),
      Expanded(flex: 3, child: referenceNumber),
      Expanded(flex: 3, child: status),
      Expanded(flex: 4, child: transactionType),
      Expanded(flex: 4, child: itemName),
      Expanded(flex: 3, child: quantityOrdered),
      Expanded(flex: 3, child: itemPriceBcy),
      Expanded(flex: 3, child: totalBcy),
    ],
  );
}

double _parseCurrency(String value) {
  final normalized = value.replaceAll('\u20B9', '').replaceAll(',', '').replaceAll('Dr', '').trim();
  return double.tryParse(normalized) ?? 0;
}

String _formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  var integer = parts.first;
  final decimal = parts.last;
  if (integer.length > 3) {
    final lastThree = integer.substring(integer.length - 3);
    var prefix = integer.substring(0, integer.length - 3);
    final groups = <String>[];
    while (prefix.length > 2) {
      groups.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    if (prefix.isNotEmpty) groups.insert(0, prefix);
    integer = '${groups.join(',')},$lastThree';
  }
  return '\u20B9$sign$integer.$decimal';
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
