import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_horizontal_scroll_overlay.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'sales_by_customer_table.dart';

class SalesByItemTable extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat currencyFormat;
  final NumberFormat quantityFormat;
  final ValueChanged<Map<String, dynamic>>? onOpenDetails;
  final List<SalesByCustomerComparisonPeriod> comparisonPeriods;

  const SalesByItemTable({
    super.key,
    required this.items,
    required this.currencyFormat,
    required this.quantityFormat,
    this.onOpenDetails,
    this.comparisonPeriods = const <SalesByCustomerComparisonPeriod>[],
  });

  @override
  State<SalesByItemTable> createState() => _SalesByItemTableState();
}

class _SalesByItemTableState extends State<SalesByItemTable>
    with ReportHorizontalScrollMixin<SalesByItemTable> {
  static const double _nameWidth = 320;
  static const double _periodMetricWidth = 150;

  // Standard (non-comparison) vertical scroll
  final ScrollController _verticalController = ScrollController();

  // Comparison: frozen left + scrollable right (synced vertically)
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  bool _isSyncingVertical = false;

  @override
  ScrollController get horizontalScrollController => _horizontalController;

  bool get _isComparisonMode => widget.comparisonPeriods.isNotEmpty;

  // Width of the scrollable metrics portion only (no name column)
  double get _scrollableMetricsWidth =>
      widget.comparisonPeriods.length * _periodMetricWidth * 3;

  @override
  void initState() {
    super.initState();
    initHorizontalScrollListeners();
    _leftVerticalController.addListener(_syncVerticalFromLeft);
    _rightVerticalController.addListener(_syncVerticalFromRight);
  }

  void _syncVerticalFromLeft() => _syncVertical(
        from: _leftVerticalController,
        to: _rightVerticalController,
      );

  void _syncVerticalFromRight() => _syncVertical(
        from: _rightVerticalController,
        to: _leftVerticalController,
      );

  void _syncVertical({
    required ScrollController from,
    required ScrollController to,
  }) {
    if (_isSyncingVertical || !from.hasClients || !to.hasClients) return;
    final maxTarget = to.position.maxScrollExtent;
    final next = from.offset.clamp(0.0, maxTarget).toDouble();
    if ((to.offset - next).abs() < 0.5) return;
    _isSyncingVertical = true;
    to.jumpTo(next);
    _isSyncingVertical = false;
  }

  @override
  void dispose() {
    disposeHorizontalScrollListeners();
    _verticalController.dispose();
    _leftVerticalController
      ..removeListener(_syncVerticalFromLeft)
      ..dispose();
    _rightVerticalController
      ..removeListener(_syncVerticalFromRight)
      ..dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isComparisonMode ? _buildComparisonTable() : _buildStandardTable();
  }

  Widget _buildComparisonTable() {
    final rows = _buildComparisonRowPairs();
    final frozenRows = rows.map((r) => r.frozenCell).toList();
    final metricRows = rows.map((r) => r.metricsCell).toList();

    final frozenColumn = SizedBox(
      width: _nameWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frozen header
          Container(
            height: 84,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(
              left: AppTheme.space20,
              right: AppTheme.space20,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.tableHeaderBg,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
                bottom: BorderSide(color: AppTheme.borderColor),
                right: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
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
          ),
          // Frozen name list
          Expanded(
            child: widget.items.isEmpty
                ? const SizedBox.shrink()
                : ListView(
                    controller: _leftVerticalController,
                    primary: false,
                    padding: EdgeInsets.zero,
                    children: [
                      ...frozenRows,
                      _buildFrozenTotalNameCell(),
                      const SizedBox(height: AppTheme.space64),
                      const SizedBox(height: AppTheme.space24),
                    ],
                  ),
          ),
        ],
      ),
    );

    final scrollableSection = ReportHorizontalScrollOverlay(
      canScrollLeft: canScrollLeft,
      canScrollRight: canScrollRight,
      onScrollLeft: scrollLeft,
      onScrollRight: scrollRight,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: widget.items.isNotEmpty,
        notificationPredicate: (notification) => notification.depth == 0,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          primary: false,
          child: SizedBox(
            width: _scrollableMetricsWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildScrollableComparisonHeader(),
                Expanded(
                  child: Scrollbar(
                    controller: _rightVerticalController,
                    thumbVisibility: widget.items.isNotEmpty,
                    child: widget.items.isEmpty
                        ? const ReportTableEmptyBody()
                        : ListView(
                            controller: _rightVerticalController,
                            primary: false,
                            padding: EdgeInsets.zero,
                            children: [
                              ...metricRows,
                              _buildComparisonTotalMetricsRow(),
                              const SizedBox(height: AppTheme.space64),
                              const SizedBox(height: AppTheme.space24),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        frozenColumn,
        Expanded(child: scrollableSection),
      ],
    );
  }

  Widget _buildFrozenTotalNameCell() {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
          right: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Text(
        'Total',
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildScrollableComparisonHeader() {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.comparisonPeriods.map(
            (period) => _comparisonPeriodHeader(period.label),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTotalMetricsRow() {
    final totalQuantity = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['quantitySold'] as num?)?.toDouble() ?? 0),
    );
    final totalAmount = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
    );

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: widget.comparisonPeriods.map((period) {
          final q = period.isCurrent ? totalQuantity : 0.0;
          final a = period.isCurrent ? totalAmount : 0.0;
          return SizedBox(
            width: _periodMetricWidth * 3,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space10,
                    ),
                    child: Text(
                      widget.quantityFormat.format(q),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space10,
                    ),
                    child: Text(
                      widget.currencyFormat.format(a),
                      textAlign: TextAlign.right,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  /// Returns parallel pairs: one frozen name cell + one metrics cell per row.
  List<_SalesByItemRowPair> _buildComparisonRowPairs() {
    final isGroupedByCustomer = widget.items.isNotEmpty &&
        widget.items.first.containsKey('customerName') &&
        widget.items.first['customerName'] != null;

    final pairs = <_SalesByItemRowPair>[];

    if (isGroupedByCustomer) {
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final item in widget.items) {
        final cn = item['customerName']?.toString() ?? 'Unknown Customer';
        groups.putIfAbsent(cn, () => []).add(item);
      }

      for (final entry in groups.entries) {
        final customerName = entry.key;
        final groupItems = entry.value;

        // Group header pair
        pairs.add(_buildGroupHeaderPair(
          customerName: customerName,
          groupItems: groupItems,
        ));

        // Item rows under the group
        for (final item in groupItems) {
          pairs.add(_buildComparisonDataRowPair(item, isIndented: true));
        }
      }
    } else {
      for (final item in widget.items) {
        pairs.add(_buildComparisonDataRowPair(item, isIndented: false));
      }
    }

    return pairs;
  }

  _SalesByItemRowPair _buildGroupHeaderPair({
    required String customerName,
    required List<Map<String, dynamic>> groupItems,
  }) {
    final frozenCell = Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(
        left: AppTheme.space20,
        right: AppTheme.space20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
          right: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Text(
        customerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),

    );

    final metricsCell = Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: widget.comparisonPeriods.map((period) {
          final q = period.isCurrent
              ? groupItems.fold<double>(
                  0,
                  (s, it) => s + ((it['quantitySold'] as num?)?.toDouble() ?? 0),
                )
              : 0.0;
          final a = period.isCurrent
              ? groupItems.fold<double>(
                  0,
                  (s, it) => s + ((it['amount'] as num?)?.toDouble() ?? 0),
                )
              : 0.0;
          return SizedBox(
            width: _periodMetricWidth * 3,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space10,
                    ),
                    child: Text(
                      widget.quantityFormat.format(q),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space10,
                    ),
                    child: Text(
                      widget.currencyFormat.format(a),
                      textAlign: TextAlign.right,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
        }).toList(),
      ),
    );

    return _SalesByItemRowPair(frozenCell: frozenCell, metricsCell: metricsCell);
  }

  _SalesByItemRowPair _buildComparisonDataRowPair(
    Map<String, dynamic> item, {
    required bool isIndented,
  }) {
    final itemName = item['itemName']?.toString() ?? '-';
    final quantitySold = (item['quantitySold'] as num?)?.toDouble() ?? 0;
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final averagePrice = (item['averagePrice'] as num?)?.toDouble() ?? 0;
    final openDetails = widget.onOpenDetails == null
        ? null
        : () => widget.onOpenDetails!(item);

    return _SalesByItemRowPair(
      frozenCell: _SalesByItemFrozenNameRow(
        itemName: itemName,
        isIndented: isIndented,
        onTap: openDetails,
      ),
      metricsCell: _SalesByItemComparisonMetricsRow(
        quantitySold: quantitySold,
        amount: amount,
        averagePrice: averagePrice,
        periods: widget.comparisonPeriods,
        onOpenDetails: openDetails,
        isIndented: isIndented,
        periodMetricWidth: _periodMetricWidth,
        quantityFormat: widget.quantityFormat,
        currencyFormat: widget.currencyFormat,
      ),
    );
  }

  Widget _buildStandardTable() {
    final totalQuantity = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['quantitySold'] as num?)?.toDouble() ?? 0),
    );
    final totalAmount = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
    );

    final isGroupedByCustomer = widget.items.isNotEmpty &&
        widget.items.first.containsKey('customerName') &&
        widget.items.first['customerName'] != null;

    final List<Widget> tableChildren = [];

    if (isGroupedByCustomer) {
      // Group items by customerName
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final item in widget.items) {
        final customerName = item['customerName']?.toString() ?? 'Unknown Customer';
        groups.putIfAbsent(customerName, () => []).add(item);
      }

      for (final entry in groups.entries) {
        final customerName = entry.key;
        final groupItems = entry.value;

        final groupQuantity = groupItems.fold<double>(
          0,
          (sum, item) => sum + ((item['quantitySold'] as num?)?.toDouble() ?? 0),
        );
        final groupAmount = groupItems.fold<double>(
          0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
        );

        // Add customer group header row
        tableChildren.add(
          _buildCustomerGroupHeaderRow(
            customerName: customerName,
            groupQuantity: groupQuantity,
            groupAmount: groupAmount,
          ),
        );

        // Add item rows under the customer
        for (final item in groupItems) {
          final itemName = item['itemName']?.toString() ?? '-';
          final quantitySold = (item['quantitySold'] as num?)?.toDouble() ?? 0;
          final amount = (item['amount'] as num?)?.toDouble() ?? 0;
          final averagePrice = (item['averagePrice'] as num?)?.toDouble() ?? 0;
          final openDetails = widget.onOpenDetails == null
              ? null
              : () => widget.onOpenDetails!(item);

          tableChildren.add(
            _SalesByItemDataRow(
              itemName: itemName,
              quantityText: widget.quantityFormat.format(quantitySold),
              amountText: widget.currencyFormat.format(amount),
              averagePriceText: widget.currencyFormat.format(averagePrice),
              onOpenDetails: openDetails,
              rowBuilder: _buildTableRow,
              isIndented: true,
            ),
          );
        }
      }
    } else {
      for (final item in widget.items) {
        final itemName = item['itemName']?.toString() ?? '-';
        final quantitySold = (item['quantitySold'] as num?)?.toDouble() ?? 0;
        final amount = (item['amount'] as num?)?.toDouble() ?? 0;
        final averagePrice = (item['averagePrice'] as num?)?.toDouble() ?? 0;
        final openDetails = widget.onOpenDetails == null
            ? null
            : () => widget.onOpenDetails!(item);

        tableChildren.add(
          _SalesByItemDataRow(
            itemName: itemName,
            quantityText: widget.quantityFormat.format(quantitySold),
            amountText: widget.currencyFormat.format(amount),
            averagePriceText: widget.currencyFormat.format(averagePrice),
            onOpenDetails: openDetails,
            rowBuilder: _buildTableRow,
            isIndented: false,
          ),
        );
      }
    }

    return ReportStickyHeaderScrollTable(
      header: _buildHeader(),
      emptyBody: const ReportTableEmptyBody(),
      isEmpty: widget.items.isEmpty,
      children: [
        ...tableChildren,
        if (widget.items.isNotEmpty)
          _buildTotalRow(
            totalQuantity: totalQuantity,
            totalAmount: totalAmount,
          ),
        const SizedBox(height: AppTheme.space64),
        const SizedBox(height: AppTheme.space24),
      ],
    );
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
        quantitySold: Text(
          'QUANTITY SOLD',
          textAlign: TextAlign.center,
          style: ReportTableTypography.header,
        ),
        amount: Text(
          'AMOUNT',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        averagePrice: Text(
          'AVERAGE PRICE',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
      ),
    );
  }


  Widget _comparisonPeriodHeader(String label) {
    return SizedBox(
      width: _periodMetricWidth * 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppTheme.borderColor),
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: ReportTableTypography.header,
            ),
          ),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                _comparisonMetricHeader('QUANTITY SOLD', TextAlign.center),
                _comparisonMetricHeader('AMOUNT', TextAlign.right),
                _comparisonMetricHeader('AVERAGE PRICE', TextAlign.right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonMetricHeader(String text, TextAlign textAlign) {
    return Expanded(
      child: Container(
        height: double.infinity,
        alignment: textAlign == TextAlign.right
            ? Alignment.centerRight
            : (textAlign == TextAlign.center
                ? Alignment.center
                : Alignment.centerLeft),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTheme.borderColor),
          ),
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: ReportTableTypography.header,
        ),
      ),
    );
  }

  Widget _buildTotalRow({
    required double totalQuantity,
    required double totalAmount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: _buildTableRow(
        itemName: Text(
          'Total',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        quantitySold: Text(
          widget.quantityFormat.format(totalQuantity),
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        amount: Text(
          widget.currencyFormat.format(totalAmount),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        averagePrice: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCustomerGroupHeaderRow({
    required String customerName,
    required double groupQuantity,
    required double groupAmount,
  }) {

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: _buildTableRow(
        itemName: Text(
          customerName,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        quantitySold: Text(
          widget.quantityFormat.format(groupQuantity),
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
        amount: Text(
          widget.currencyFormat.format(groupAmount),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
        averagePrice: const SizedBox.shrink(),
      ),
    );
  }


  Widget _buildTableRow({
    required Widget itemName,
    required Widget quantitySold,
    required Widget amount,
    required Widget averagePrice,
  }) {
    return Row(
      children: [
        Expanded(flex: 4, child: itemName),
        Expanded(flex: 2, child: quantitySold),
        Expanded(flex: 2, child: amount),
        const SizedBox(width: AppTheme.space28),
        Expanded(flex: 2, child: averagePrice),
      ],
    );
  }
}

class _SalesByItemDataRow extends StatefulWidget {
  final String itemName;
  final String quantityText;
  final String amountText;
  final String averagePriceText;
  final VoidCallback? onOpenDetails;
  final bool isIndented;
  final Widget Function({
    required Widget itemName,
    required Widget quantitySold,
    required Widget amount,
    required Widget averagePrice,
  })
  rowBuilder;

  const _SalesByItemDataRow({
    required this.itemName,
    required this.quantityText,
    required this.amountText,
    required this.averagePriceText,
    required this.rowBuilder,
    this.onOpenDetails,
    this.isIndented = false,
  });

  @override
  State<_SalesByItemDataRow> createState() => _SalesByItemDataRowState();
}

class _SalesByItemDataRowState extends State<_SalesByItemDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenDetails == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpenDetails,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
            vertical: AppTheme.space16,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: widget.rowBuilder(
            itemName: Padding(
              padding: EdgeInsets.only(
                left: widget.isIndented ? AppTheme.space20 : 0,
              ),
              child: widget.isIndented
                  ? Text(
                      widget.itemName,
                      style: AppTheme.tableCell.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                      ),
                    )
                  : _SalesByItemLinkText(
                      text: widget.itemName,
                      onTap: widget.onOpenDetails,
                      isUnderlined: _isHovered,
                      textAlign: TextAlign.left,
                    ),
            ),
            quantitySold: _SalesByItemLinkText(
              text: widget.quantityText,
              onTap: widget.onOpenDetails,
              isUnderlined: _isHovered,
              textAlign: TextAlign.center,
            ),
            amount: _SalesByItemLinkText(
              text: widget.amountText,
              onTap: widget.onOpenDetails,
              isUnderlined: _isHovered,
              textAlign: TextAlign.right,
            ),
            averagePrice: _SalesByItemLinkText(
              text: widget.averagePriceText,
              onTap: widget.onOpenDetails,
              isUnderlined: _isHovered,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesByItemLinkText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isUnderlined;
  final TextAlign textAlign;

  const _SalesByItemLinkText({
    required this.text,
    required this.onTap,
    required this.isUnderlined,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.linkText.copyWith(
        fontWeight: FontWeight.w500,
        decoration: isUnderlined
            ? TextDecoration.underline
            : TextDecoration.none,
      ),
    );


    if (onTap == null) {
      return textWidget;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppTheme.transparent,
        splashColor: AppTheme.transparent,
        highlightColor: AppTheme.transparent,
        child: textWidget,
      ),
    );
  }
}

class _SalesByItemComparisonDataRow extends StatefulWidget {
  final String itemName;
  final double quantitySold;
  final double amount;
  final double averagePrice;
  final List<SalesByCustomerComparisonPeriod> periods;
  final VoidCallback? onOpenDetails;
  final bool isIndented;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;
  final Widget Function({
    required Widget name,
    required List<Widget> periodCells,
  })
  rowBuilder;

  const _SalesByItemComparisonDataRow({
    required this.itemName,
    required this.quantitySold,
    required this.amount,
    required this.averagePrice,
    required this.periods,
    required this.rowBuilder,
    required this.isIndented,
    required this.quantityFormat,
    required this.currencyFormat,
    // ignore: unused_element_parameter
    this.onOpenDetails,
  });

  @override
  State<_SalesByItemComparisonDataRow> createState() =>
      _SalesByItemComparisonDataRowState();
}

class _SalesByItemComparisonDataRowState
    extends State<_SalesByItemComparisonDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenDetails == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpenDetails,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.space16,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: widget.rowBuilder(
            name: Padding(
              padding: EdgeInsets.only(
                left: widget.isIndented ? AppTheme.space20 + AppTheme.space20 : AppTheme.space20,
              ),
              child: widget.isIndented
                  ? Text(
                      widget.itemName,
                      style: AppTheme.tableCell.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                      ),
                    )
                  : _SalesByItemLinkText(
                      text: widget.itemName,
                      onTap: widget.onOpenDetails,
                      isUnderlined: _isHovered,
                      textAlign: TextAlign.left,
                    ),
            ),
            periodCells: widget.periods.map((period) {
              final quantityVal = period.isCurrent ? widget.quantitySold : 0.0;
              final amountVal = period.isCurrent ? widget.amount : 0.0;
              final averagePriceVal = period.isCurrent ? widget.averagePrice : 0.0;

              return _comparisonMetricCells(
                quantityText: widget.quantityFormat.format(quantityVal),
                amountText: widget.currencyFormat.format(amountVal),
                averagePriceText: widget.currencyFormat.format(averagePriceVal),
                onTap: widget.onOpenDetails,
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }

  Widget _comparisonMetricCells({
    required String quantityText,
    required String amountText,
    required String averagePriceText,
    VoidCallback? onTap,
  }) {
    // ignore: sized_box_for_whitespace
    return Container(
      width: _SalesByItemTableState._periodMetricWidth * 3,
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
              child: _SalesByItemLinkText(
                text: quantityText,
                onTap: onTap,
                textAlign: TextAlign.center,
                isUnderlined: _isHovered,
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
              child: _SalesByItemLinkText(
                text: amountText,
                onTap: onTap,
                textAlign: TextAlign.right,
                isUnderlined: _isHovered,
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
              child: _SalesByItemLinkText(
                text: averagePriceText,
                onTap: onTap,
                textAlign: TextAlign.right,
                isUnderlined: _isHovered,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Holds a parallel pair: frozen name widget + metrics widget, one per row.
class _SalesByItemRowPair {
  final Widget frozenCell;
  final Widget metricsCell;
  const _SalesByItemRowPair({required this.frozenCell, required this.metricsCell});
}

/// Frozen left-column name cell for comparison mode (item table).
class _SalesByItemFrozenNameRow extends StatefulWidget {
  final String itemName;
  final bool isIndented;
  final VoidCallback? onTap;

  const _SalesByItemFrozenNameRow({
    required this.itemName,
    required this.isIndented,
    this.onTap,
  });

  @override
  State<_SalesByItemFrozenNameRow> createState() =>
      _SalesByItemFrozenNameRowState();
}

class _SalesByItemFrozenNameRowState extends State<_SalesByItemFrozenNameRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(
            left: widget.isIndented
                ? AppTheme.space20 + AppTheme.space20
                : AppTheme.space20,
            right: AppTheme.space20,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderColor),
              right: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: _SalesByItemLinkText(
            text: widget.itemName,
            onTap: widget.onTap,
            textAlign: TextAlign.left,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

/// Right-side metrics-only row for the comparison frozen-column layout (item table).
class _SalesByItemComparisonMetricsRow extends StatefulWidget {
  final double quantitySold;
  final double amount;
  final double averagePrice;
  final List<SalesByCustomerComparisonPeriod> periods;
  final VoidCallback? onOpenDetails;
  final bool isIndented;
  final double periodMetricWidth;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;

  const _SalesByItemComparisonMetricsRow({
    required this.quantitySold,
    required this.amount,
    required this.averagePrice,
    required this.periods,
    required this.isIndented,
    required this.periodMetricWidth,
    required this.quantityFormat,
    required this.currencyFormat,
    this.onOpenDetails,
  });

  @override
  State<_SalesByItemComparisonMetricsRow> createState() =>
      _SalesByItemComparisonMetricsRowState();
}

class _SalesByItemComparisonMetricsRowState
    extends State<_SalesByItemComparisonMetricsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenDetails == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border:
              const Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: widget.periods.map((period) {
            final q = period.isCurrent ? widget.quantitySold : 0.0;
            final a = period.isCurrent ? widget.amount : 0.0;
            final avg = period.isCurrent ? widget.averagePrice : 0.0;
            return SizedBox(
              width: widget.periodMetricWidth * 3,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space10),
                      child: _SalesByItemLinkText(
                        text: widget.quantityFormat.format(q),
                        onTap: widget.onOpenDetails,
                        textAlign: TextAlign.center,
                        isUnderlined: _isHovered,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space10),
                      child: _SalesByItemLinkText(
                        text: widget.currencyFormat.format(a),
                        onTap: widget.onOpenDetails,
                        textAlign: TextAlign.right,
                        isUnderlined: _isHovered,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space10),
                      child: _SalesByItemLinkText(
                        text: widget.currencyFormat.format(avg),
                        onTap: widget.onOpenDetails,
                        textAlign: TextAlign.right,
                        isUnderlined: _isHovered,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

