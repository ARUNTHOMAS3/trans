import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_tooltip.dart';

class AssemblyDetailsRow {
  final String transactionNumber;
  final String assemblyName;
  final double quantityAssembled;
  final String componentName;
  final double quantityConsumed;
  final String date;
  final String status;
  final double totalCost;
  final String hsnSac;
  final String componentHsnSac;

  const AssemblyDetailsRow({
    required this.transactionNumber,
    required this.assemblyName,
    required this.quantityAssembled,
    required this.componentName,
    required this.quantityConsumed,
    required this.date,
    required this.status,
    required this.totalCost,
    required this.hsnSac,
    required this.componentHsnSac,
  });

  factory AssemblyDetailsRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AssemblyDetailsRow(
      transactionNumber: item['transactionNumber']?.toString() ?? '-',
      assemblyName: item['assemblyName']?.toString() ?? '-',
      quantityAssembled: numberValue('quantityAssembled'),
      componentName: item['componentName']?.toString() ?? '-',
      quantityConsumed: numberValue('quantityConsumed'),
      date: item['date']?.toString() ?? '-',
      status: item['status']?.toString() ?? '-',
      totalCost: numberValue('totalCost'),
      hsnSac: item['hsnSac']?.toString() ?? '-',
      componentHsnSac: item['componentHsnSac']?.toString() ?? '-',
    );
  }

  static const emptyTotal = AssemblyDetailsRow(
    transactionNumber: 'Total',
    assemblyName: '',
    quantityAssembled: 0,
    componentName: '',
    quantityConsumed: 0,
    date: '',
    status: '',
    totalCost: 0,
    hsnSac: '',
    componentHsnSac: '',
  );
}

class AssemblyDetailsTable extends StatefulWidget {
  final List<AssemblyDetailsRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final List<String> groupByFields;
  final bool showGroupTotals;

  const AssemblyDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.groupByFields = const <String>[],
    this.showGroupTotals = false,
  });

  @override
  State<AssemblyDetailsTable> createState() => _AssemblyDetailsTableState();
}

class _AssemblyDetailsTableState extends State<AssemblyDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.###');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<String> get _activeGroupFields => widget.groupByFields
      .where((field) => field != 'None')
      .toList(growable: false);

  List<AssemblyDetailsRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) return const <AssemblyDetailsRow>[];
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  AssemblyDetailsRow get _overallTotals {
    return AssemblyDetailsRow(
      transactionNumber: 'Total',
      assemblyName: '',
      quantityAssembled: widget.rows.fold<double>(0, (sum, row) => sum + row.quantityAssembled),
      componentName: '',
      quantityConsumed: widget.rows.fold<double>(0, (sum, row) => sum + row.quantityConsumed),
      date: '',
      status: '',
      totalCost: widget.rows.fold<double>(0, (sum, row) => sum + row.totalCost),
      hsnSac: '',
      componentHsnSac: '',
    );
  }

  List<_AssemblyDetailsEntry> _buildEntries() {
    final entries = <_AssemblyDetailsEntry>[];
    final groupFields = _activeGroupFields;

    if (groupFields.isEmpty) {
      entries.addAll(_pageRows.map(_AssemblyDetailsEntry.data));
      entries.add(_AssemblyDetailsEntry.total(_overallTotals));
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
      return <_AssemblyDetailsEntry>[_AssemblyDetailsEntry.total(_overallTotals)];
    }
    final end = (start + widget.pageSize).clamp(0, entries.length);
    final paginatedEntries = entries.sublist(start, end);

    if (end == entries.length) {
      paginatedEntries.add(_AssemblyDetailsEntry.total(_overallTotals));
    }
    return paginatedEntries;
  }

  int get _totalCount {
    if (_activeGroupFields.isEmpty) return widget.rows.length;
    final entries = <_AssemblyDetailsEntry>[];
    _appendGroupedEntries(
      entries: entries,
      rows: widget.rows,
      groupFields: _activeGroupFields,
      depth: 0,
    );
    return entries.length;
  }

  void _appendGroupedEntries({
    required List<_AssemblyDetailsEntry> entries,
    required List<AssemblyDetailsRow> rows,
    required List<String> groupFields,
    required int depth,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) {
    if (depth >= groupFields.length) {
      entries.addAll(
        rows.map(
          (row) => _AssemblyDetailsEntry.data(
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
    final groupedRows = <String, List<AssemblyDetailsRow>>{};
    for (final row in rows) {
      final key = _groupValue(row, field);
      groupedRows.putIfAbsent(key, () => <AssemblyDetailsRow>[]).add(row);
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
        _AssemblyDetailsEntry.groupHeader(
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
          _AssemblyDetailsEntry.subtotal(
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

  String _groupValue(AssemblyDetailsRow row, String field) {
    final value = switch (field) {
      'Transaction#' => row.transactionNumber,
      'Assembly Name' => row.assemblyName,
      'Component Name' => row.componentName,
      'Date' => _formatDate(row.date),
      'HSN/SAC' => row.hsnSac,
      'Component HSN/SAC' => row.componentHsnSac,
      _ => '',
    };
    return value.trim().isEmpty || value == '-' ? '$field - Not mentioned' : value.trim();
  }

  AssemblyDetailsRow _subtotalRow(String title, List<AssemblyDetailsRow> rows) {
    return AssemblyDetailsRow(
      transactionNumber: 'Total for $title',
      assemblyName: '',
      quantityAssembled: rows.fold<double>(0, (sum, row) => sum + row.quantityAssembled),
      componentName: '',
      quantityConsumed: rows.fold<double>(0, (sum, row) => sum + row.quantityConsumed),
      date: '',
      status: '',
      totalCost: rows.fold<double>(0, (sum, row) => sum + row.totalCost),
      hsnSac: '',
      componentHsnSac: '',
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.isEmpty ? '-' : value;
    return ReportFormatterCache.date('dd-MM-yyyy').format(parsed);
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
          width: 1650,
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
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, index) => _buildEntry(entries[index]),
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

  Widget _buildEntry(_AssemblyDetailsEntry entry) {
    return switch (entry.type) {
      _AssemblyDetailsEntryType.groupHeader => _buildGroupHeader(
          entry,
          showTree: _activeGroupFields.length > 1,
          hasChildren: entry.hasChildren,
        ),
      _AssemblyDetailsEntryType.subtotal => _buildSubtotalRow(entry),
      _AssemblyDetailsEntryType.total => _buildTotalRow(entry.row!),
      _AssemblyDetailsEntryType.data => _AssemblyDetailsDataRow(
          row: entry.row!,
          quantityFormat: _quantityFormat,
          currencyFormat: _currencyFormat,
          indentDepth: _activeGroupFields.length > 1 ? entry.depth : 0,
          ancestorVisible: entry.ancestorVisible,
          ancestorContinues: entry.ancestorContinues,
        ),
    };
  }

  Widget _buildGroupHeader(
    _AssemblyDetailsEntry entry, {
    required bool showTree,
    required bool hasChildren,
  }) {
    final row = entry.row ?? AssemblyDetailsRow.emptyTotal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
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
        transactionNumber: const SizedBox.shrink(),
        assemblyName: const SizedBox.shrink(),
        quantityAssembled: widget.showGroupTotals
            ? const SizedBox.shrink()
            : _groupTotalText(row.quantityAssembled),
        componentName: const SizedBox.shrink(),
        quantityConsumed: widget.showGroupTotals
            ? const SizedBox.shrink()
            : _groupTotalText(row.quantityConsumed),
        date: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        totalCost: widget.showGroupTotals
            ? const SizedBox.shrink()
            : _groupTotalCurrency(row.totalCost),
      ),
    );
  }

  Widget _buildSubtotalRow(_AssemblyDetailsEntry entry) {
    final row = entry.row ?? AssemblyDetailsRow.emptyTotal;
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
                child: Text(row.transactionNumber, style: _subtotalStyle),
              ),
              transactionNumber: const SizedBox.shrink(),
              assemblyName: const SizedBox.shrink(),
              quantityAssembled: _subtotalText(row.quantityAssembled),
              componentName: const SizedBox.shrink(),
              quantityConsumed: _subtotalText(row.quantityConsumed),
              date: const SizedBox.shrink(),
              status: const SizedBox.shrink(),
              totalCost: _subtotalCurrency(row.totalCost),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(AssemblyDetailsRow row) {
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
        groupTree: Text('Total', style: _totalStyle),
        transactionNumber: const SizedBox.shrink(),
        assemblyName: const SizedBox.shrink(),
        quantityAssembled: _totalText(row.quantityAssembled),
        componentName: const SizedBox.shrink(),
        quantityConsumed: _totalText(row.quantityConsumed),
        date: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        totalCost: _totalCurrency(row.totalCost),
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

  Widget _groupTotalText(double value) {
    return Text(
      _quantityFormat.format(value),
      textAlign: TextAlign.right,
      style: _groupHeaderStyle,
    );
  }

  Widget _groupTotalCurrency(double value) {
    return Text(
      _currencyFormat.format(value),
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

  Widget _subtotalCurrency(double value) {
    return Text(
      _currencyFormat.format(value),
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

  Widget _totalCurrency(double value) {
    return Text(
      _currencyFormat.format(value),
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
        groupTree: const SizedBox.shrink(),
        transactionNumber: Text(
          'TRANSACTION#',
          style: ReportTableTypography.header,
        ),
        assemblyName: Text(
          'ASSEMBLY NAME',
          style: ReportTableTypography.header,
        ),
        quantityAssembled: _headerText('QUANTITY ASSEMBLED'),
        componentName: Text(
          'COMPONENT NAME',
          style: ReportTableTypography.header,
        ),
        quantityConsumed: _headerText('QUANTITY CONSUMED'),
        date: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        status: Text('STATUS', style: ReportTableTypography.header),
        totalCost: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('TOTAL COST (BCY)', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const ReportTooltip(
              message:
                  'This is total cost price of the composite item in the base currency',
              child: SizedBox(
                width: AppTheme.space20,
                height: AppTheme.space20,
                child: Icon(
                  Icons.help_outline,
                  size: AppTheme.space14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssemblyDetailsDataRow extends StatefulWidget {
  final AssemblyDetailsRow row;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;
  final int indentDepth;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;

  const _AssemblyDetailsDataRow({
    required this.row,
    required this.quantityFormat,
    required this.currencyFormat,
    this.indentDepth = 0,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
  });

  @override
  State<_AssemblyDetailsDataRow> createState() =>
      _AssemblyDetailsDataRowState();
}

class _AssemblyDetailsDataRowState extends State<_AssemblyDetailsDataRow> {
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
                groupTree: const SizedBox.shrink(),
                transactionNumber: _dataTransactionNumberCell(),
            assemblyName: Text(
              widget.row.assemblyName,
              style: AppTheme.tableCell,
            ),
            quantityAssembled: Text(
              widget.quantityFormat.format(widget.row.quantityAssembled),
              textAlign: TextAlign.right,
              style: AppTheme.tableCell,
            ),
            componentName: Text(
              widget.row.componentName,
              style: AppTheme.tableCell,
            ),
            quantityConsumed: Text(
              widget.quantityFormat.format(widget.row.quantityConsumed),
              textAlign: TextAlign.right,
              style: AppTheme.tableCell,
            ),
            date: Text(
              _formatDate(widget.row.date),
              textAlign: TextAlign.right,
              style: AppTheme.tableCell,
            ),
            status: Text(widget.row.status, style: AppTheme.tableCell),
            totalCost: Text(
              widget.currencyFormat.format(widget.row.totalCost),
              textAlign: TextAlign.right,
              style: AppTheme.tableCell,
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  Widget _dataTransactionNumberCell() {
    final leftPadding = widget.indentDepth > 0
        ? widget.indentDepth * AppTheme.space28
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Text(
        widget.row.transactionNumber,
        style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
      ),
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.isEmpty ? '-' : value;
    return ReportFormatterCache.date('dd-MM-yyyy').format(parsed);
  }
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

class _AssemblyDetailsEntry {
  final _AssemblyDetailsEntryType type;
  final AssemblyDetailsRow? row;
  final String title;
  final int depth;
  final List<bool> ancestorVisible;
  final List<bool> ancestorContinues;
  final bool hasChildren;
  final bool continues;

  const _AssemblyDetailsEntry._({
    required this.type,
    this.row,
    this.title = '',
    this.depth = 0,
    this.ancestorVisible = const <bool>[],
    this.ancestorContinues = const <bool>[],
    this.hasChildren = false,
    this.continues = false,
  });

  factory _AssemblyDetailsEntry.data(
    AssemblyDetailsRow row, {
    int depth = 0,
    List<bool> ancestorVisible = const <bool>[],
    List<bool> ancestorContinues = const <bool>[],
  }) =>
      _AssemblyDetailsEntry._(
        type: _AssemblyDetailsEntryType.data,
        row: row,
        depth: depth,
        ancestorVisible: ancestorVisible,
        ancestorContinues: ancestorContinues,
      );

  factory _AssemblyDetailsEntry.total(AssemblyDetailsRow row) => _AssemblyDetailsEntry._(
        type: _AssemblyDetailsEntryType.total,
        row: row,
      );

  factory _AssemblyDetailsEntry.groupHeader({
    required String title,
    required int depth,
    required AssemblyDetailsRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
    required bool hasChildren,
    required bool continues,
  }) =>
      _AssemblyDetailsEntry._(
        type: _AssemblyDetailsEntryType.groupHeader,
        title: title,
        depth: depth,
        row: row,
        ancestorVisible: ancestorVisible,
        ancestorContinues: ancestorContinues,
        hasChildren: hasChildren,
        continues: continues,
      );

  factory _AssemblyDetailsEntry.subtotal({
    required String title,
    required int depth,
    required AssemblyDetailsRow row,
    required List<bool> ancestorVisible,
    required List<bool> ancestorContinues,
  }) =>
      _AssemblyDetailsEntry._(
        type: _AssemblyDetailsEntryType.subtotal,
        title: title,
        depth: depth,
        row: row,
        ancestorVisible: ancestorVisible,
        ancestorContinues: ancestorContinues,
      );
}

enum _AssemblyDetailsEntryType { data, groupHeader, subtotal, total }

Widget _buildTableRow({
  required Widget groupTree,
  required Widget transactionNumber,
  required Widget assemblyName,
  required Widget quantityAssembled,
  required Widget componentName,
  required Widget quantityConsumed,
  required Widget date,
  required Widget status,
  required Widget totalCost,
}) {
  return Row(
    children: [
      Expanded(flex: 6, child: groupTree),
      Expanded(flex: 3, child: transactionNumber),
      Expanded(flex: 4, child: assemblyName),
      Expanded(flex: 3, child: quantityAssembled),
      Expanded(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.only(left: AppTheme.space16),
          child: componentName,
        ),
      ),
      Expanded(flex: 3, child: quantityConsumed),
      Expanded(flex: 2, child: date),
      Expanded(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.only(left: AppTheme.space16),
          child: status,
        ),
      ),
      Expanded(flex: 3, child: totalCost),
    ],
  );
}
