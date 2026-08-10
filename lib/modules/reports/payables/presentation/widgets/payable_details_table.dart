import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/payables/presentation/pages/payable_details_page.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

const double _columnGap = AppTheme.space14;
const double _groupTreeWidth = 240;

class PayableDetailsTable extends StatefulWidget {
  final List<PayableDetailsRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showGroupTotals;
  final bool groupTotalsOnly;
  final DateFormat? dateFormat;
  final NumberFormat? currencyFormat;

  const PayableDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.groupByFields,
    required this.showGroupTotals,
    required this.groupTotalsOnly,
    this.dateFormat,
    this.currencyFormat,
  });

  @override
  State<PayableDetailsTable> createState() => _PayableDetailsTableState();
}

enum _PayableDetailsEntryType {
  groupHeader,
  data,
  subtotal,
  total,
}

class _PayableDetailsEntry {
  final _PayableDetailsEntryType type;
  final String title;
  final int depth;
  final PayableDetailsRow row;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _PayableDetailsEntry({
    required this.type,
    required this.title,
    required this.depth,
    required this.row,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
    this.hasChildren = false,
    this.continues = false,
  });

  factory _PayableDetailsEntry.groupHeader({
    required String title,
    required int depth,
    required PayableDetailsRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
    required bool hasChildren,
    required bool continues,
  }) {
    return _PayableDetailsEntry(
      type: _PayableDetailsEntryType.groupHeader,
      title: title,
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
      hasChildren: hasChildren,
      continues: continues,
    );
  }

  factory _PayableDetailsEntry.data(
    PayableDetailsRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _PayableDetailsEntry(
      type: _PayableDetailsEntryType.data,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _PayableDetailsEntry.subtotal(
    PayableDetailsRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    return _PayableDetailsEntry(
      type: _PayableDetailsEntryType.subtotal,
      title: '',
      depth: depth,
      row: row,
      ancestorVisible: ancestorVisible,
      ancestorContinues: ancestorContinues,
    );
  }

  factory _PayableDetailsEntry.total(PayableDetailsRow row) {
    return _PayableDetailsEntry(
      type: _PayableDetailsEntryType.total,
      title: '',
      depth: 0,
      row: row,
    );
  }
}

class _PayableDetailsTableState extends State<PayableDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  late DateFormat _dateFormat;
  late NumberFormat _currencyFormat;

  @override
  void initState() {
    super.initState();
    _dateFormat = widget.dateFormat ?? DateFormat('yyyy-MM-dd');
    _currencyFormat = widget.currencyFormat ?? NumberFormat.currency(symbol: '₹ ', decimalDigits: 2);
  }

  @override
  void didUpdateWidget(covariant PayableDetailsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateFormat != null) _dateFormat = widget.dateFormat!;
    if (widget.currencyFormat != null) _currencyFormat = widget.currencyFormat!;
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  List<String> get _activeGroupFields =>
      widget.groupByFields.where((field) => field != 'None').toList(growable: false);

  List<PayableDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <PayableDetailsRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  PayableDetailsRow get _overallTotals {
    final totalQty = widget.rows.fold<double>(0.0, (sum, r) => sum + r.quantity);
    final totalAmount = widget.rows.fold<double>(0.0, (sum, r) => sum + r.amount);
    return PayableDetailsRow(
      status: 'Total',
      date: DateTime.now(),
      transactionNumber: '',
      vendorName: '',
      transactionType: '',
      itemName: '',
      quantity: totalQty,
      rate: 0.0,
      amount: totalAmount,
      currencyCode: widget.rows.isNotEmpty ? widget.rows.first.currencyCode : 'INR',
      account: '',
      customerName: '',
      warehouseLocationName: '',
      projectName: '',
    );
  }

  String _getGroupKeyValue(PayableDetailsRow row, String field, DateFormat dateFormat) {
    switch (field) {
      case 'Date':
        return dateFormat.format(row.date);
      case 'Transaction#':
        return row.transactionNumber.trim().isEmpty ? 'Transaction# - Not mentioned' : row.transactionNumber;
      case 'Vendor Name':
        return row.vendorName.trim().isEmpty ? 'Vendor Name - Not mentioned' : row.vendorName;
      case 'Transaction Type':
        return row.transactionType.trim().isEmpty ? 'Transaction Type - Not mentioned' : row.transactionType;
      case 'Item Name':
        return row.itemName.trim().isEmpty ? 'Item Name - Not mentioned' : row.itemName;
      case 'Account':
        return row.account.trim().isEmpty ? 'Account - Not mentioned' : row.account;
      case 'Customer Name':
        return row.customerName.trim().isEmpty ? 'Customer Name - Not mentioned' : row.customerName;
      case 'Warehouse Location Name':
        return row.warehouseLocationName.trim().isEmpty ? 'Warehouse Location Name - Not mentioned' : row.warehouseLocationName;
      case 'Project Name':
        return row.projectName.trim().isEmpty ? 'Project Name - Not mentioned' : row.projectName;
      case 'Currency Code':
        return row.currencyCode.trim().isEmpty ? 'Currency Code - Not mentioned' : row.currencyCode;
      case 'Location':
        return row.warehouseLocationName.trim().isEmpty ? 'Location - Not mentioned' : row.warehouseLocationName;
      case 'Due Date':
        return row.dueDate == null ? 'Due Date - Not mentioned' : dateFormat.format(row.dueDate!);
      case 'Expected Payment Date':
        return row.expectedPaymentDate == null
            ? 'Expected Payment Date - Not mentioned'
            : dateFormat.format(row.expectedPaymentDate!);
      default:
        return '';
    }
  }

  List<_PayableDetailsEntry> _buildEntries(DateFormat dateFormat) {
    final entries = <_PayableDetailsEntry>[];
    final groupFields = _activeGroupFields;
    if (groupFields.isEmpty) {
      entries.addAll(_pageRows.map(_PayableDetailsEntry.data));
      entries.add(_PayableDetailsEntry.total(_overallTotals));
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
    if (start >= entries.length) return <_PayableDetailsEntry>[_PayableDetailsEntry.total(_overallTotals)];
    final end = (start + widget.pageSize).clamp(0, entries.length);
    final paginatedEntries = entries.sublist(start, end);
    if (end == entries.length) paginatedEntries.add(_PayableDetailsEntry.total(_overallTotals));
    return paginatedEntries;
  }

  int get _totalCount {
    if (_activeGroupFields.isEmpty) return widget.rows.length;
    final entries = <_PayableDetailsEntry>[];
    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: _activeGroupFields,
      depth: 0,
      dateFormat: _dateFormat,
    );
    return entries.length;
  }

  void _appendGroupedEntries({
    required List<_PayableDetailsEntry> entries,
    required List<PayableDetailsRow> rows,
    required List<String> groupFields,
    required int depth,
    required DateFormat dateFormat,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    if (depth >= groupFields.length) {
      if (widget.groupTotalsOnly) return;
      entries.addAll(rows.map((row) => _PayableDetailsEntry.data(
            row,
            depth: depth,
            ancestorVisible: ancestorVisible,
            ancestorContinues: ancestorContinues,
          )));
      return;
    }
    final field = groupFields[depth];
    final groupedRows = <String, List<PayableDetailsRow>>{};
    for (final row in rows) {
      final key = _getGroupKeyValue(row, field, dateFormat);
      groupedRows.putIfAbsent(key, () => <PayableDetailsRow>[]).add(row);
    }
    final groups = groupedRows.entries.toList(growable: false);
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      final hasChildGroups = depth < groupFields.length - 1;
      final hasFollowingSibling = index < groups.length - 1;
      final entryAncestorVisible = _entryAncestorVisible(ancestorVisible, depth);
      final entryAncestorContinues =
          _entryAncestorContinues(ancestorContinues, depth, hasFollowingSibling);

      entries.add(_PayableDetailsEntry.groupHeader(
        title: '$field: ${group.key}',
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
        entries.add(_PayableDetailsEntry.subtotal(
          _subtotalRow(group.key, group.value),
          depth: depth,
          ancestorVisible: entryAncestorVisible,
          ancestorContinues: entryAncestorContinues,
        ));
      }
    }
  }

  PayableDetailsRow _subtotalRow(String title, List<PayableDetailsRow> groupRows) {
    final totalQty = groupRows.fold<double>(0.0, (sum, r) => sum + r.quantity);
    final totalAmount = groupRows.fold<double>(0.0, (sum, r) => sum + r.amount);
    return PayableDetailsRow(
      status: 'Total for $title',
      date: DateTime.now(),
      transactionNumber: '',
      vendorName: '',
      transactionType: '',
      itemName: '',
      quantity: totalQty,
      rate: 0.0,
      amount: totalAmount,
      currencyCode: groupRows.isNotEmpty ? groupRows.first.currencyCode : 'INR',
      account: '',
      customerName: '',
      warehouseLocationName: '',
      projectName: '',
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
    final isGrouped = _activeGroupFields.isNotEmpty;
    final entries = _buildEntries(_dateFormat);

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseWidth = 1390.0 + (isGrouped ? _groupTreeWidth + _columnGap : 0);
        final tableWidth = constraints.maxWidth < baseWidth ? baseWidth : constraints.maxWidth;

        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: tableWidth > constraints.maxWidth,
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
                      if (entry.type == _PayableDetailsEntryType.groupHeader)
                        _buildGroupHeader(entry, showTree: isGrouped)
                      else if (entry.type == _PayableDetailsEntryType.data)
                        _PayableDetailsItemRow(
                          row: entry.row,
                          currencyFormat: _currencyFormat,
                          isGrouped: isGrouped,
                          ancestorVisible: entry.ancestorVisible,
                          ancestorContinues: entry.ancestorContinues,
                        )
                      else if (entry.type == _PayableDetailsEntryType.subtotal)
                        _buildSubtotalRow(entry)
                      else if (entry.type == _PayableDetailsEntryType.total)
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
        status: _headerText('STATUS'),
        date: _headerText('DATE'),
        transactionNumber: _headerText('TRANSACTION#'),
        vendorName: _headerText('VENDOR NAME'),
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
        itemAmountBcy: _headerText('ITEM AMOUNT (BCY)', alignRight: true),
      ),
    );
  }

  Widget _buildGroupHeader(_PayableDetailsEntry entry, {required bool showTree}) {
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
          status: const SizedBox.shrink(),
          date: const SizedBox.shrink(),
          transactionNumber: const SizedBox.shrink(),
          vendorName: const SizedBox.shrink(),
          transactionType: const SizedBox.shrink(),
          itemName: const SizedBox.shrink(),
          quantityOrdered: widget.showGroupTotals
              ? const SizedBox.shrink()
              : _headerNumber(row.quantity),
          itemPriceBcy: const SizedBox.shrink(),
          itemAmountBcy: widget.showGroupTotals
              ? const SizedBox.shrink()
              : _headerCurrency(row.amount),
        ),
      ),
    );
  }

  Widget _buildSubtotalRow(_PayableDetailsEntry entry) {
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
                child: Text(row.status, style: _subtotalStyle),
              ),
              status: const SizedBox.shrink(),
              date: const SizedBox.shrink(),
              transactionNumber: const SizedBox.shrink(),
              vendorName: const SizedBox.shrink(),
              transactionType: const SizedBox.shrink(),
              itemName: const SizedBox.shrink(),
              quantityOrdered: _subtotalQuantity(row.quantity),
              itemPriceBcy: const SizedBox.shrink(),
              itemAmountBcy: _subtotalCurrency(row.amount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(PayableDetailsRow row, {required bool showTree}) {
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
        status: Text(row.status, style: _totalStyle),
        date: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        transactionType: const SizedBox.shrink(),
        itemName: const SizedBox.shrink(),
        quantityOrdered: _totalQuantity(row.quantity),
        itemPriceBcy: const SizedBox.shrink(),
        itemAmountBcy: _totalCurrency(row.amount),
      ),
    );
  }

  Widget _headerText(String value, {bool alignRight = false}) => Text(
        value,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: ReportTableTypography.header,
      );

  Widget _headerNumber(double value) => Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.right,
        style: ReportTableTypography.header,
      );

  Widget _headerCurrency(double value) => Text(
        _currencyFormat.format(value),
        textAlign: TextAlign.right,
        style: ReportTableTypography.header,
      );

  Widget _totalCurrency(double value) => Text(
        _currencyFormat.format(value),
        textAlign: TextAlign.right,
        style: _totalStyle,
      );

  Widget _totalQuantity(double value) => Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.right,
        style: _totalStyle,
      );

  Widget _subtotalQuantity(double value) => Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.right,
        style: _subtotalStyle,
      );

  Widget _subtotalCurrency(double value) => Text(
        _currencyFormat.format(value),
        textAlign: TextAlign.right,
        style: _subtotalStyle,
      );

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );

  TextStyle get _subtotalStyle => AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
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

class _PayableDetailsItemRow extends StatefulWidget {
  final PayableDetailsRow row;
  final NumberFormat currencyFormat;
  final bool isGrouped;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _PayableDetailsItemRow({
    required this.row,
    required this.currencyFormat,
    required this.isGrouped,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
  });

  @override
  State<_PayableDetailsItemRow> createState() => _PayableDetailsItemRowState();
}

class _PayableDetailsItemRowState extends State<_PayableDetailsItemRow> {
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
                status: _statusText(widget.row.status),
                date: _bodyText(DateFormat('dd-MM-yyyy').format(widget.row.date)),
                transactionNumber: _linkText(widget.row.transactionNumber, isUnderlined: _isHovered),
                vendorName: _bodyText(widget.row.vendorName),
                transactionType: _bodyText(widget.row.transactionType),
                itemName: _bodyText(widget.row.itemName),
                quantityOrdered: _bodyText(
                  widget.row.quantity.toStringAsFixed(2),
                  align: TextAlign.right,
                ),
                itemPriceBcy: _bodyText(
                  widget.currencyFormat.format(widget.row.rate),
                  align: TextAlign.right,
                ),
                itemAmountBcy: _bodyText(
                  widget.currencyFormat.format(widget.row.amount),
                  align: TextAlign.right,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _linkText(String value, {required bool isUnderlined}) {
  return Text(
    value.isEmpty ? '-' : value,
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
  Color? color,
}) {
  return Text(
    value.trim().isEmpty ? '-' : value,
    softWrap: true,
    textAlign: align,
    style: AppTheme.bodyText.copyWith(
      color: color ?? AppTheme.textPrimary,
      fontWeight: fontWeight,
    ),
  );
}

Widget _statusText(String value) {
  final normalized = value.trim();
  final color = normalized.toLowerCase().contains('paid')
      ? AppTheme.successGreen
      : AppTheme.primaryBlue;
  return Text(
    normalized.isEmpty ? '-' : normalized,
    softWrap: true,
    style: AppTheme.bodyText.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    ),
  );
}

Widget _buildTableRow({
  Widget? groupTree,
  required Widget status,
  required Widget date,
  required Widget transactionNumber,
  required Widget vendorName,
  required Widget transactionType,
  required Widget itemName,
  required Widget quantityOrdered,
  required Widget itemPriceBcy,
  required Widget itemAmountBcy,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (groupTree != null) ...[
        SizedBox(width: _groupTreeWidth, child: groupTree),
        const SizedBox(width: _columnGap),
      ],
      Expanded(flex: 3, child: status),
      const SizedBox(width: _columnGap),
      Expanded(flex: 4, child: date),
      const SizedBox(width: _columnGap),
      Expanded(flex: 4, child: transactionNumber),
      const SizedBox(width: _columnGap),
      Expanded(flex: 4, child: vendorName),
      const SizedBox(width: _columnGap),
      Expanded(flex: 4, child: transactionType),
      const SizedBox(width: _columnGap),
      Expanded(flex: 4, child: itemName),
      const SizedBox(width: _columnGap),
      Expanded(flex: 5, child: quantityOrdered),
      const SizedBox(width: _columnGap),
      Expanded(flex: 4, child: itemPriceBcy),
      const SizedBox(width: _columnGap),
      Expanded(flex: 4, child: itemAmountBcy),
    ],
  );
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
