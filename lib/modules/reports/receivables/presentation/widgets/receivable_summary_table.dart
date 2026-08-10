import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class ReceivableSummaryRow {
  final String customerName;
  final String date;
  final String transactionNumber;
  final String referenceNumber;
  final String status;
  final String transactionType;
  final String totalBcy;
  final String totalFcy;
  final String balanceBcy;
  final String balanceFcy;

  const ReceivableSummaryRow({
    required this.customerName,
    required this.date,
    required this.transactionNumber,
    required this.referenceNumber,
    required this.status,
    required this.transactionType,
    required this.totalBcy,
    required this.totalFcy,
    required this.balanceBcy,
    required this.balanceFcy,
  });

  String groupKey(String groupBy) {
    switch (groupBy) {
      case 'Customer Name':
        return customerName;
      case 'Date':
        return date;
      case 'Transaction Type':
        return transactionType;
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

enum _ReceivableSummaryEntryType { groupHeader, data, subtotal, total }

class _ReceivableSummaryEntry {
  final _ReceivableSummaryEntryType type;
  final String title;
  final int depth;
  final ReceivableSummaryRow row;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _ReceivableSummaryEntry({
    required this.type,
    required this.title,
    required this.depth,
    required this.row,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
    this.hasChildren = false,
    this.continues = false,
  });

  factory _ReceivableSummaryEntry.groupHeader({
    required String title,
    required int depth,
    required ReceivableSummaryRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
    required bool hasChildren,
    required bool continues,
  }) {
    return _ReceivableSummaryEntry(
      type: _ReceivableSummaryEntryType.groupHeader,
      title: title,
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
      hasChildren: hasChildren,
      continues: continues,
    );
  }

  factory _ReceivableSummaryEntry.data(
    ReceivableSummaryRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _ReceivableSummaryEntry(
      type: _ReceivableSummaryEntryType.data,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _ReceivableSummaryEntry.subtotal(
    ReceivableSummaryRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _ReceivableSummaryEntry(
      type: _ReceivableSummaryEntryType.subtotal,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _ReceivableSummaryEntry.total(ReceivableSummaryRow row) {
    return _ReceivableSummaryEntry(
      type: _ReceivableSummaryEntryType.total,
      title: '',
      depth: 0,
      row: row,
    );
  }
}

class ReceivableSummaryTable extends StatefulWidget {
  final List<ReceivableSummaryRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showOnlyGroupTotals;
  final bool showGroupTotals;

  const ReceivableSummaryTable({
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
  State<ReceivableSummaryTable> createState() => _ReceivableSummaryTableState();
}

class _ReceivableSummaryTableState extends State<ReceivableSummaryTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const String _totalBcy = '\u20B923,779.00';
  static const String _balanceBcy = '\u20B923,149.00';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<String> get _activeGroupFields => widget.groupByFields
      .where((field) => field != 'None')
      .toList(growable: false);

  List<ReceivableSummaryRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <ReceivableSummaryRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  ReceivableSummaryRow get _overallTotals {
    return ReceivableSummaryRow(
      customerName: 'Total',
      date: '',
      transactionNumber: '',
      referenceNumber: '',
      status: '',
      transactionType: '',
      totalBcy: _totalBcy,
      totalFcy: '',
      balanceBcy: _balanceBcy,
      balanceFcy: '',
    );
  }

  double get _tableWidth {
    final isGrouped = _activeGroupFields.isNotEmpty;
    return isGrouped ? 1960 : 1720;
  }

  List<_ReceivableSummaryEntry> _buildEntries() {
    final entries = <_ReceivableSummaryEntry>[];
    final groupFields = _activeGroupFields;

    if (groupFields.isEmpty) {
      entries.addAll(_pageRows.map(_ReceivableSummaryEntry.data));
      entries.add(_ReceivableSummaryEntry.total(_overallTotals));
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
      return <_ReceivableSummaryEntry>[_ReceivableSummaryEntry.total(_overallTotals)];
    }
    final end = (start + widget.pageSize).clamp(0, entries.length);
    final paginatedEntries = entries.sublist(start, end);

    if (end == entries.length) {
      paginatedEntries.add(_ReceivableSummaryEntry.total(_overallTotals));
    }
    return paginatedEntries;
  }

  int get _totalCount {
    if (_activeGroupFields.isEmpty) return widget.rows.length;
    final entries = <_ReceivableSummaryEntry>[];
    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: _activeGroupFields,
      depth: 0,
    );
    return entries.length;
  }

  void _appendGroupedEntries({
    required List<_ReceivableSummaryEntry> entries,
    required List<ReceivableSummaryRow> rows,
    required List<String> groupFields,
    required int depth,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    if (depth >= groupFields.length) {
      if (widget.showOnlyGroupTotals) return;
      entries.addAll(
        rows.map(
          (row) => _ReceivableSummaryEntry.data(
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
    final groupedRows = <String, List<ReceivableSummaryRow>>{};
    for (final row in rows) {
      final key = row.groupKey(field);
      groupedRows.putIfAbsent(key, () => <ReceivableSummaryRow>[]).add(row);
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
        _ReceivableSummaryEntry.groupHeader(
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
          _ReceivableSummaryEntry.subtotal(
            _subtotalRow(group.key, group.value, showTotals: true),
            depth: depth,
            ancestorVisible: entryAncestorVisible,
            ancestorContinues: entryAncestorContinues,
          ),
        );
      }
    }
  }

  ReceivableSummaryRow _subtotalRow(
    String title,
    List<ReceivableSummaryRow> groupRows, {
    required bool showTotals,
  }) {
    if (!showTotals) {
      return ReceivableSummaryRow(
        customerName: 'Total for $title',
        date: '',
        transactionNumber: '',
        referenceNumber: '',
        status: '',
        transactionType: '',
        totalBcy: '',
        totalFcy: '',
        balanceBcy: '',
        balanceFcy: '',
      );
    }
    final totalBcyVal = groupRows.fold<double>(0, (sum, row) => sum + _parseCurrency(row.totalBcy));
    final totalFcyVal = groupRows.fold<double>(0, (sum, row) => sum + _parseCurrency(row.totalFcy));
    final balanceBcyVal = groupRows.fold<double>(0, (sum, row) => sum + _parseCurrency(row.balanceBcy));
    final balanceFcyVal = groupRows.fold<double>(0, (sum, row) => sum + _parseCurrency(row.balanceFcy));

    return ReceivableSummaryRow(
      customerName: 'Total for $title',
      date: '',
      transactionNumber: '',
      referenceNumber: '',
      status: '',
      transactionType: '',
      totalBcy: _formatCurrency(totalBcyVal),
      totalFcy: _formatCurrency(totalFcyVal),
      balanceBcy: _formatCurrency(balanceBcyVal),
      balanceFcy: _formatCurrency(balanceFcyVal),
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
                          case _ReceivableSummaryEntryType.groupHeader:
                            return _buildGroupHeader(entry, showTree: isGrouped);
                          case _ReceivableSummaryEntryType.data:
                            return _ReceivableSummaryDataRow(
                              row: entry.row,
                              isGrouped: isGrouped,
                              ancestorVisible: entry.ancestorVisible,
                              ancestorContinues: entry.ancestorContinues,
                            );
                          case _ReceivableSummaryEntryType.subtotal:
                            return _buildSubtotalRow(entry);
                          case _ReceivableSummaryEntryType.total:
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

  Widget _buildGroupHeader(_ReceivableSummaryEntry entry, {required bool showTree}) {
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
          totalBcy: row.totalBcy.isNotEmpty
              ? _amountText(row.totalBcy, style: _groupHeaderStyle)
              : const SizedBox.shrink(),
          totalFcy: row.totalFcy.isNotEmpty
              ? _amountText(row.totalFcy, style: _groupHeaderStyle)
              : const SizedBox.shrink(),
          balanceBcy: row.balanceBcy.isNotEmpty
              ? _amountText(row.balanceBcy, style: _groupHeaderStyle)
              : const SizedBox.shrink(),
          balanceFcy: row.balanceFcy.isNotEmpty
              ? _amountText(row.balanceFcy, style: _groupHeaderStyle)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSubtotalRow(_ReceivableSummaryEntry entry) {
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
              totalBcy: _amountText(row.totalBcy, style: _subtotalStyle),
              totalFcy: _amountText(row.totalFcy, style: _subtotalStyle),
              balanceBcy: _amountText(row.balanceBcy, style: _subtotalStyle),
              balanceFcy: _amountText(row.balanceFcy, style: _subtotalStyle),
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
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        transactionNumber: _headerText('TRANSACTION#'),
        referenceNumber: _headerText('REFERENCE#'),
        status: _headerText('STATUS'),
        transactionType: _headerText('TRANSACTION TYPE'),
        totalBcy: _headerText('TOTAL (BCY)', alignRight: true),
        totalFcy: _headerText('TOTAL (FCY)', alignRight: true),
        balanceBcy: _headerText('BALANCE (BCY)', alignRight: true),
        balanceFcy: _headerText('BALANCE (FCY)', alignRight: true),
      ),
    );
  }

  Widget _buildTotalRow(ReceivableSummaryRow row, {required bool showTree}) {
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
        totalBcy: Text(
          row.totalBcy,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        totalFcy: const SizedBox.shrink(),
        balanceBcy: Text(
          row.balanceBcy,
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        balanceFcy: const SizedBox.shrink(),
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

class _ReceivableSummaryDataRow extends StatefulWidget {
  final ReceivableSummaryRow row;
  final bool isGrouped;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _ReceivableSummaryDataRow({
    required this.row,
    required this.isGrouped,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
  });

  @override
  State<_ReceivableSummaryDataRow> createState() =>
      _ReceivableSummaryDataRowState();
}

class _ReceivableSummaryDataRowState extends State<_ReceivableSummaryDataRow> {
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
                totalBcy: _blueAmountText(row.totalBcy),
                totalFcy: _amountText(row.totalFcy),
                balanceBcy: _amountText(row.balanceBcy),
                balanceFcy: _amountText(row.balanceFcy),
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
  required Widget totalBcy,
  required Widget totalFcy,
  required Widget balanceBcy,
  required Widget balanceFcy,
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
      Expanded(flex: 3, child: totalBcy),
      Expanded(flex: 3, child: totalFcy),
      Expanded(flex: 3, child: balanceBcy),
      Expanded(flex: 3, child: balanceFcy),
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
