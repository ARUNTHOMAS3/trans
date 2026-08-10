import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class FifoCostLotTrackingRow {
  final String productInDate;
  final String productInTransaction;
  final String receivedFrom;
  final String itemName;
  final double quantity;
  final String unit;
  final double quantityRemaining;
  final double costPerUnit;
  final double total;
  final bool hasProductInLot;
  final bool showProductInLotDetails;
  final bool showProductInTransactionDetails;
  final String productOutDate;
  final String productOutTransaction;
  final String dispersedTo;
  final double quantityDispersed;
  final String dispersedUnit;

  const FifoCostLotTrackingRow({
    required this.productInDate,
    required this.productInTransaction,
    required this.receivedFrom,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.quantityRemaining,
    required this.costPerUnit,
    required this.total,
    required this.hasProductInLot,
    required this.showProductInLotDetails,
    required this.showProductInTransactionDetails,
    required this.productOutDate,
    required this.productOutTransaction,
    required this.dispersedTo,
    required this.quantityDispersed,
    required this.dispersedUnit,
  });

  factory FifoCostLotTrackingRow.fromJson(Map<String, dynamic> json) {
    final productInDate = _stringValue(json['productInDate']);
    final productInTransaction = _stringValue(json['productInTransaction']);
    final receivedFrom = _stringValue(json['receivedFrom']);
    final itemName = _stringValue(json['itemName']);
    final quantity = _doubleValue(json['quantity']);
    final quantityRemaining = _doubleValue(json['quantityRemaining']);
    final costPerUnit = _doubleValue(json['costPerUnit']);
    final total = _doubleValue(json['total']);
    final hasLegacyProductInData = productInDate.isNotEmpty ||
        productInTransaction.isNotEmpty ||
        receivedFrom.isNotEmpty ||
        itemName.isNotEmpty ||
        quantity != 0 ||
        quantityRemaining != 0 ||
        costPerUnit != 0 ||
        total != 0;
    final hasProductInLot = json['hasProductInLot'] == true ||
        (json['hasProductInLot'] == null && hasLegacyProductInData);
    final showProductInLotDetails = json['showProductInLotDetails'] == true ||
        (json['showProductInLotDetails'] == null && hasLegacyProductInData);
    final showProductInTransactionDetails =
        json['showProductInTransactionDetails'] == true ||
            (json['showProductInTransactionDetails'] == null &&
                hasLegacyProductInData);

    return FifoCostLotTrackingRow(
      productInDate: productInDate,
      productInTransaction: productInTransaction,
      receivedFrom: receivedFrom,
      itemName: itemName,
      quantity: quantity,
      unit: _stringValue(json['unit'], fallback: 'pcs').toUpperCase(),
      quantityRemaining: quantityRemaining,
      costPerUnit: costPerUnit,
      total: total,
      hasProductInLot: hasProductInLot,
      showProductInLotDetails: showProductInLotDetails,
      showProductInTransactionDetails: showProductInTransactionDetails,
      productOutDate: _stringValue(json['productOutDate']),
      productOutTransaction: _stringValue(json['productOutTransaction']),
      dispersedTo: _stringValue(json['dispersedTo']),
      quantityDispersed: _doubleValue(json['quantityDispersed']),
      dispersedUnit: _stringValue(json['dispersedUnit'], fallback: 'pcs').toUpperCase(),
    );
  }
  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class FifoCostLotTrackingTable extends StatefulWidget {
  final List<FifoCostLotTrackingRow> rows;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const FifoCostLotTrackingTable({
    super.key,
    required this.rows,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<FifoCostLotTrackingTable> createState() =>
      _FifoCostLotTrackingTableState();
}

class _FifoCostLotTrackingTableState extends State<FifoCostLotTrackingTable> {
  final ScrollController _horizontalController = ScrollController();
  final NumberFormat _quantityFormat = ReportFormatterCache.number('0.00');
  final NumberFormat _amountFormat = ReportFormatterCache.number('#,##0.00');

  static const double _tableWidth =
      _dateWidth +
      _transactionWidth +
      _partyWidth +
      _itemWidth +
      _quantityWidth +
      _costWidth +
      _totalWidth +
      _dateWidth +
      _transactionWidth +
      _partyWidth +
      _quantityWidth;
  static const double _dateWidth = 126;
  static const double _transactionWidth = 126;
  static const double _partyWidth = 126;
  static const double _itemWidth = 132;
  static const double _quantityWidth = 154;
  static const double _costWidth = 126;
  static const double _totalWidth = 126;
  static const double _viewportHeight = 505;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  List<FifoCostLotTrackingRow> get _pageRows => widget.rows;

  List<_FifoRowGroup> get _rowGroups {
    final groups = <_FifoRowGroup>[];
    var currentRows = <FifoCostLotTrackingRow>[];

    for (final row in _pageRows) {
      final startsGroup = currentRows.isEmpty ||
          row.showProductInLotDetails ||
          !row.hasProductInLot;
      if (startsGroup && currentRows.isNotEmpty) {
        groups.add(_FifoRowGroup(List.unmodifiable(currentRows)));
        currentRows = <FifoCostLotTrackingRow>[];
      }
      currentRows.add(row);
    }

    if (currentRows.isNotEmpty) {
      groups.add(_FifoRowGroup(List.unmodifiable(currentRows)));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _viewportHeight,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _tableWidth,
            child: ReportStickyHeaderScrollTable(
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildGroupedHeader(), _buildColumnHeader()],
              ),
              emptyBody: const SizedBox.shrink(),
              children: [
                if (widget.rows.isEmpty)
                  const ReportTableEmptyBody(minHeight: 345)
                else ...[
                  for (final group in _rowGroups)
                    _FifoDataRowGroup(
                      rows: group.rows,
                      quantityFormat: _quantityFormat,
                      amountFormat: _amountFormat,
                    ),
                  _buildCurrencyNote(),
                ],
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
      ),
    );
  }

  Widget _buildGroupedHeader() {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          _groupSpacer(_dateWidth + _transactionWidth + _partyWidth),
          _groupTitle(
            'PRODUCT IN',
            _itemWidth + _quantityWidth + _costWidth + _totalWidth,
          ),
          _groupTitle(
            'PRODUCT OUT',
            _dateWidth + _transactionWidth + _partyWidth + _quantityWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader() {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          _headerCell('DATE', _dateWidth),
          _headerCell('TRANSACTIONS', _transactionWidth),
          _headerCell('RECEIVED FROM', _partyWidth),
          _headerCell('ITEM NAME', _itemWidth),
          _headerCell('QUANTITY', _quantityWidth, alignRight: true),
          _headerCell('COST PER UNIT', _costWidth, alignRight: true),
          _headerCell('TOTAL', _totalWidth, alignRight: true),
          _headerCell('DATE', _dateWidth),
          _headerCell('TRANSACTIONS', _transactionWidth),
          _headerCell('DISPERSED TO', _partyWidth),
          _headerCell('QTY DISPERSED', _quantityWidth, alignRight: true),
        ],
      ),
    );
  }

  Widget _buildCurrencyNote() {
    return Container(
      height: 64,
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space14,
        AppTheme.space20,
        AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '**Amount is displayed in your base currency ',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2B7A0B),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              'INR',
              style: AppTheme.captionText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupSpacer(double width) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
    );
  }

  Widget _groupTitle(String title, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Text(title, style: ReportTableTypography.header),
    );
  }

  Widget _headerCell(String label, double width, {bool alignRight = false}) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: ReportTableTypography.header,
      ),
    );
  }

}

class _FifoRowGroup {
  final List<FifoCostLotTrackingRow> rows;

  const _FifoRowGroup(this.rows);
}

class _FifoDataRowGroup extends StatefulWidget {
  final List<FifoCostLotTrackingRow> rows;
  final NumberFormat quantityFormat;
  final NumberFormat amountFormat;

  const _FifoDataRowGroup({
    required this.rows,
    required this.quantityFormat,
    required this.amountFormat,
  });

  @override
  State<_FifoDataRowGroup> createState() => _FifoDataRowGroupState();
}

class _FifoDataRowGroupState extends State<_FifoDataRowGroup> {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < widget.rows.length; index++)
            _FifoDataRow(
              row: widget.rows[index],
              isHovered: _isHovered,
              drawProductInBottomBorder: index == widget.rows.length - 1,
              showQuantityRemaining: index == widget.rows.length - 1,
              quantityFormat: widget.quantityFormat,
              amountFormat: widget.amountFormat,
            ),
        ],
      ),
    );
  }
}
class _FifoDataRow extends StatefulWidget {
  final FifoCostLotTrackingRow row;
  final bool isHovered;
  final bool drawProductInBottomBorder;
  final bool showQuantityRemaining;
  final NumberFormat quantityFormat;
  final NumberFormat amountFormat;

  const _FifoDataRow({
    required this.row,
    required this.isHovered,
    required this.drawProductInBottomBorder,
    required this.showQuantityRemaining,
    required this.quantityFormat,
    required this.amountFormat,
  });

  @override
  State<_FifoDataRow> createState() => _FifoDataRowState();
}

class _FifoDataRowState extends State<_FifoDataRow> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: widget.isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
        ),
        constraints: const BoxConstraints(minHeight: 72),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasProductInDetails) ...[
                _cell(
                  widget.row.productInDate,
                  _FifoCostLotTrackingTableState._dateWidth,
                  includeBottomBorder: widget.drawProductInBottomBorder,
                ),
                _linkCell(
                  widget.row.productInTransaction,
                  _FifoCostLotTrackingTableState._transactionWidth,
                  includeBottomBorder: widget.drawProductInBottomBorder,
                ),
                _linkCell(
                  widget.row.receivedFrom,
                  _FifoCostLotTrackingTableState._partyWidth,
                  includeBottomBorder: widget.drawProductInBottomBorder,
                ),
                _cell(
                  widget.row.showProductInLotDetails ? widget.row.itemName : '',
                  _FifoCostLotTrackingTableState._itemWidth,
                  includeBottomBorder: widget.drawProductInBottomBorder,
                ),
                _quantityCell(
                  showLotQuantity: widget.row.showProductInTransactionDetails,
                  showQuantityRemaining: widget.showQuantityRemaining,
                ),
                _numberCell(
                  widget.row.showProductInTransactionDetails
                      ? widget.amountFormat.format(widget.row.costPerUnit)
                      : '',
                  _FifoCostLotTrackingTableState._costWidth,
                  includeBottomBorder: widget.drawProductInBottomBorder,
                ),
                _numberCell(
                  widget.row.showProductInTransactionDetails
                      ? widget.amountFormat.format(widget.row.total)
                      : '',
                  _FifoCostLotTrackingTableState._totalWidth,
                  includeBottomBorder: widget.drawProductInBottomBorder,
                ),
              ] else
                _emptyDetailSpan(
                  _productInWidth,
                  includeBottomBorder: widget.drawProductInBottomBorder,
                ),
              if (_hasProductOutDetails) ...[
                _cell(
                  widget.row.productOutDate,
                  _FifoCostLotTrackingTableState._dateWidth,
                  includeBottomBorder: true,
                ),
                _linkCell(
                  widget.row.productOutTransaction,
                  _FifoCostLotTrackingTableState._transactionWidth,
                  includeBottomBorder: true,
                ),
                _linkCell(
                  widget.row.dispersedTo,
                  _FifoCostLotTrackingTableState._partyWidth,
                  includeBottomBorder: true,
                ),
                _dispersedQuantityCell(),
              ] else
                _emptyDetailSpan(_productOutWidth, includeBottomBorder: true),
            ],
          ),
        ),
    );
  }

  bool get _hasProductInDetails => widget.row.hasProductInLot;
  bool get _hasProductOutDetails =>
      widget.row.productOutDate.trim().isNotEmpty ||
      widget.row.productOutTransaction.trim().isNotEmpty ||
      widget.row.dispersedTo.trim().isNotEmpty ||
      widget.row.quantityDispersed != 0;

  double get _productInWidth =>
      _FifoCostLotTrackingTableState._dateWidth +
      _FifoCostLotTrackingTableState._transactionWidth +
      _FifoCostLotTrackingTableState._partyWidth +
      _FifoCostLotTrackingTableState._itemWidth +
      _FifoCostLotTrackingTableState._quantityWidth +
      _FifoCostLotTrackingTableState._costWidth +
      _FifoCostLotTrackingTableState._totalWidth;
  double get _productOutWidth =>
      _FifoCostLotTrackingTableState._dateWidth +
      _FifoCostLotTrackingTableState._transactionWidth +
      _FifoCostLotTrackingTableState._partyWidth +
      _FifoCostLotTrackingTableState._quantityWidth;

  Widget _emptyDetailSpan(
    double width, {
    required bool includeBottomBorder,
  }) {
    return Container(
      width: width,
      decoration: _cellDecoration(includeBottomBorder: includeBottomBorder),
    );
  }

  Widget _quantityCell({
    required bool showLotQuantity,
    required bool showQuantityRemaining,
  }) {
    return Container(
      width: _FifoCostLotTrackingTableState._quantityWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space10,
      ),
      decoration: _cellDecoration(
        includeBottomBorder: widget.drawProductInBottomBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (showLotQuantity) ...[
            Text(
              widget.quantityFormat.format(widget.row.quantity),
              textAlign: TextAlign.right,
              style: AppTheme.tableCell,
            ),
            const SizedBox(height: 2),
            Text(
              widget.row.unit,
              textAlign: TextAlign.right,
              style: AppTheme.tableCell.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (widget.row.hasProductInLot && showQuantityRemaining) ...[
            const SizedBox(height: AppTheme.space8),
            Text(
              'Qty remaining: ${widget.quantityFormat.format(widget.row.quantityRemaining)}',
              textAlign: TextAlign.right,
              style: AppTheme.tableCell.copyWith(
                color: AppTheme.errorRed,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dispersedQuantityCell() {
    final value = widget.row.quantityDispersed == 0
        ? ''
        : widget.quantityFormat.format(widget.row.quantityDispersed);
    return Container(
      width: _FifoCostLotTrackingTableState._quantityWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space10,
      ),
      decoration: _cellDecoration(includeBottomBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, textAlign: TextAlign.right, style: AppTheme.tableCell),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              widget.row.dispersedUnit,
              textAlign: TextAlign.right,
              style: AppTheme.tableCell.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberCell(
    String value,
    double width, {
    required bool includeBottomBorder,
  }) {
    return Container(
      width: width,
      alignment: Alignment.topRight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space10,
      ),
      decoration: _cellDecoration(includeBottomBorder: includeBottomBorder),
      child: Text(value, textAlign: TextAlign.right, style: AppTheme.tableCell),
    );
  }

  Widget _linkCell(
    String value,
    double width, {
    required bool includeBottomBorder,
  }) {
    return _cell(
      value,
      width,
      linkStyle: value.trim().isNotEmpty,
      includeBottomBorder: includeBottomBorder,
    );
  }

  Widget _cell(
    String value,
    double width, {
    bool linkStyle = false,
    required bool includeBottomBorder,
  }) {
    return Container(
      width: width,
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space10,
      ),
      decoration: _cellDecoration(includeBottomBorder: includeBottomBorder),
      child: Text(
        value,
        style: linkStyle
            ? AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue)
            : AppTheme.tableCell,
      ),
    );
  }

  BoxDecoration _cellDecoration({required bool includeBottomBorder}) {
    return BoxDecoration(
      border: Border(
        right: const BorderSide(color: AppTheme.borderLight),
        bottom: includeBottomBorder
            ? const BorderSide(color: AppTheme.borderLight)
            : BorderSide.none,
      ),
    );
  }
}
