import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_horizontal_scroll_overlay.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class SalesByCustomerComparisonPeriod {
  final String label;
  final bool isCurrent;

  const SalesByCustomerComparisonPeriod({
    required this.label,
    required this.isCurrent,
  });
}

class SalesByCustomerTable extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat currencyFormat;
  final ValueChanged<Map<String, dynamic>>? onOpenTransactions;
  final List<SalesByCustomerComparisonPeriod> comparisonPeriods;

  const SalesByCustomerTable({
    super.key,
    required this.items,
    required this.currencyFormat,
    this.onOpenTransactions,
    this.comparisonPeriods = const <SalesByCustomerComparisonPeriod>[],
  });

  @override
  State<SalesByCustomerTable> createState() => _SalesByCustomerTableState();
}

class _SalesByCustomerTableState extends State<SalesByCustomerTable>
    with ReportHorizontalScrollMixin<SalesByCustomerTable> {
  static const double _nameWidth = 320;
  static const double _periodMetricWidth = 150;
  static const double _customerTypeWidth = 160;

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
      (widget.comparisonPeriods.length * _periodMetricWidth * 3) +
      _customerTypeWidth;

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

  Widget _buildStandardTable() {
    final totalInvoiceCount = widget.items.fold<int>(
      0,
      (sum, item) => sum + ((item['invoiceCount'] as num?)?.toInt() ?? 0),
    );
    final totalSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['totalSales'] as num?)?.toDouble() ?? 0),
    );
    final totalSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['salesWithTax'] as num?)?.toDouble() ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        Expanded(
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: widget.items.isNotEmpty,
            child: widget.items.isEmpty
                ? const ReportTableEmptyBody()
                : ListView(
                    controller: _verticalController,
                    padding: EdgeInsets.zero,
                    children: [
                      ...widget.items.map((item) {
                        final customerName =
                            item['customerName']?.toString() ?? '-';
                        final invoiceCount =
                            (item['invoiceCount'] as num?)?.toInt() ?? 0;
                        final sales =
                            (item['totalSales'] as num?)?.toDouble() ?? 0;
                        final salesWithTax =
                            (item['salesWithTax'] as num?)?.toDouble() ?? 0;
                        final customerType =
                            item['customerType']?.toString() ?? '-';
                        final openTransactions =
                            widget.onOpenTransactions == null
                            ? null
                            : () => widget.onOpenTransactions!(item);

                        return _SalesByCustomerDataRow(
                          customerName: customerName,
                          invoiceCount: invoiceCount,
                          salesText: widget.currencyFormat.format(sales),
                          salesWithTaxText: widget.currencyFormat.format(
                            salesWithTax,
                          ),
                          customerType: customerType,
                          onOpenTransactions: openTransactions,
                          rowBuilder: _buildTableRow,
                        );
                      }),
                      _buildTotalRow(
                        totalInvoiceCount: totalInvoiceCount,
                        totalSales: totalSales,
                        totalSalesWithTax: totalSalesWithTax,
                      ),
                      const SizedBox(height: AppTheme.space64),
                      const SizedBox(height: AppTheme.space24),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    final frozenColumn = _buildFrozenNameColumn();

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
                              ...widget.items.map(
                                (item) => _buildComparisonMetricsRow(item),
                              ),
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

  Widget _buildFrozenNameColumn() {
    return SizedBox(
      width: _nameWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frozen header cell
          Container(
            height: 84,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
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
                Text('NAME', style: ReportTableTypography.header),
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
                      ...widget.items.map(_buildFrozenNameCell),
                      _buildFrozenTotalNameCell(),
                      const SizedBox(height: AppTheme.space64),
                      const SizedBox(height: AppTheme.space24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrozenNameCell(Map<String, dynamic> item) {
    final customerName = item['customerName']?.toString() ?? '-';
    final openTransactions = widget.onOpenTransactions == null
        ? null
        : () => widget.onOpenTransactions!(item);
    return _SalesByCustomerFrozenNameRow(
      label: customerName,
      onTap: openTransactions,
    );
  }

  Widget _buildFrozenTotalNameCell() {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space24,
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
          _comparisonHeaderCell(
            width: _customerTypeWidth,
            child: Text(
              'CUSTOMER TYPE',
              style: ReportTableTypography.header,
            ),
            rowSpan: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMetricsRow(Map<String, dynamic> item) {
    final customerType = item['customerType']?.toString() ?? '-';
    final currentMetrics = _comparisonMetricsFor(item, isCurrent: true);
    final previousMetrics = const _SalesByCustomerComparisonMetrics.empty();
    final openTransactions = widget.onOpenTransactions == null
        ? null
        : () => widget.onOpenTransactions!(item);

    return _SalesByCustomerComparisonMetricsRow(
      customerType: customerType,
      periods: widget.comparisonPeriods,
      currentMetrics: currentMetrics,
      previousMetrics: previousMetrics,
      currencyFormat: widget.currencyFormat,
      onOpenTransactions: openTransactions,
      customerTypeWidth: _customerTypeWidth,
      periodMetricWidth: _periodMetricWidth,
      metricCellsBuilder: _comparisonMetricCells,
    );
  }

  Widget _buildComparisonTotalMetricsRow() {
    final totalInvoiceCount = widget.items.fold<int>(
      0,
      (sum, item) => sum + ((item['invoiceCount'] as num?)?.toInt() ?? 0),
    );
    final totalSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['totalSales'] as num?)?.toDouble() ?? 0),
    );
    final totalSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['salesWithTax'] as num?)?.toDouble() ?? 0),
    );
    final currentMetrics = _SalesByCustomerComparisonMetrics(
      invoiceCount: totalInvoiceCount,
      sales: totalSales,
      salesWithTax: totalSalesWithTax,
    );
    final previousMetrics = const _SalesByCustomerComparisonMetrics.empty();

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          ...widget.comparisonPeriods.map((period) {
            final metrics =
                period.isCurrent ? currentMetrics : previousMetrics;
            return _comparisonMetricCells(
              invoiceCountText: '${metrics.invoiceCount}',
              salesText: widget.currencyFormat.format(metrics.sales),
              salesWithTaxText:
                  widget.currencyFormat.format(metrics.salesWithTax),
              linkStyle: false,
            );
          }),
          SizedBox(width: _customerTypeWidth),
        ],
      ),
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
        name: Row(
          children: [
            Text('NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        invoiceCount: Text(
          'INVOICE COUNT',
          textAlign: TextAlign.center,
          style: ReportTableTypography.header,
        ),
        sales: Text(
          'SALES',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        salesWithTax: Text(
          'SALES WITH TAX',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        customerType: Text(
          'CUSTOMER TYPE',
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
                _comparisonMetricHeader('INVOICE COUNT', TextAlign.center),
                _comparisonMetricHeader('SALES', TextAlign.right),
                _comparisonMetricHeader('SALES WITH TAX', TextAlign.right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonMetricHeader(String label, TextAlign align) {
    return Container(
      width: _periodMetricWidth,
      alignment: align == TextAlign.center
          ? Alignment.center
          : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      child: Text(
        label,
        textAlign: align,
        style: ReportTableTypography.header,
      ),
    );
  }

  Widget _comparisonHeaderCell({
    required double width,
    required Widget child,
    required bool rowSpan,
  }) {
    return Container(
      width: width,
      height: rowSpan ? 82 : null,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderColor)),
      ),
      child: child,
    );
  }


  _SalesByCustomerComparisonMetrics _comparisonMetricsFor(
    Map<String, dynamic> item, {
    required bool isCurrent,
  }) {
    if (!isCurrent) return const _SalesByCustomerComparisonMetrics.empty();
    return _SalesByCustomerComparisonMetrics(
      invoiceCount: (item['invoiceCount'] as num?)?.toInt() ?? 0,
      sales: (item['totalSales'] as num?)?.toDouble() ?? 0,
      salesWithTax: (item['salesWithTax'] as num?)?.toDouble() ?? 0,
    );
  }

  Widget _comparisonMetricCells({
    required String invoiceCountText,
    required String salesText,
    required String salesWithTaxText,
    required bool linkStyle,
    VoidCallback? onTap,
    bool isUnderlined = false,
  }) {
    Widget metricText(String text, TextAlign textAlign) {
      if (linkStyle) {
        return _SalesByCustomerLinkText(
          text: text,
          onTap: onTap,
          textAlign: textAlign,
          isUnderlined: isUnderlined,
        );
      }
      return _SalesByCustomerStaticText(text: text, textAlign: textAlign);
    }

    return SizedBox(
      width: _periodMetricWidth * 3,
      child: Row(
        children: [
          SizedBox(
            width: _periodMetricWidth,
            child: metricText(invoiceCountText, TextAlign.center),
          ),
          SizedBox(
            width: _periodMetricWidth,
            child: metricText(salesText, TextAlign.right),
          ),
          SizedBox(
            width: _periodMetricWidth,
            child: metricText(salesWithTaxText, TextAlign.right),
          ),
        ],
      ),
    );
  }


  Widget _buildTotalRow({
    required int totalInvoiceCount,
    required double totalSales,
    required double totalSalesWithTax,
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
        name: Text(
          'Total',
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        invoiceCount: Text(
          '$totalInvoiceCount',
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        sales: Text(
          widget.currencyFormat.format(totalSales),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        salesWithTax: Text(
          widget.currencyFormat.format(totalSalesWithTax),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        customerType: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTableRow({
    required Widget name,
    required Widget invoiceCount,
    required Widget sales,
    required Widget salesWithTax,
    required Widget customerType,
  }) {
    return Row(
      children: [
        Expanded(flex: 4, child: name),
        Expanded(flex: 2, child: invoiceCount),
        Expanded(flex: 2, child: sales),
        Expanded(flex: 2, child: salesWithTax),
        const SizedBox(width: AppTheme.space20),
        Expanded(flex: 2, child: customerType),
      ],
    );
  }
}

class _SalesByCustomerComparisonMetrics {
  final int invoiceCount;
  final double sales;
  final double salesWithTax;

  const _SalesByCustomerComparisonMetrics({
    required this.invoiceCount,
    required this.sales,
    required this.salesWithTax,
  });

  const _SalesByCustomerComparisonMetrics.empty()
      : invoiceCount = 0,
        sales = 0,
        salesWithTax = 0;
}

class _SalesByCustomerComparisonDataRow extends StatefulWidget {
  final String customerName;
  final String customerType;
  final List<SalesByCustomerComparisonPeriod> periods;
  final _SalesByCustomerComparisonMetrics currentMetrics;
  final _SalesByCustomerComparisonMetrics previousMetrics;
  final NumberFormat currencyFormat;
  final VoidCallback? onOpenTransactions;
  final Widget Function({
    required Widget name,
    required List<Widget> periodCells,
    required Widget customerType,
  }) rowBuilder;

  const _SalesByCustomerComparisonDataRow({
    required this.customerName,
    required this.customerType,
    required this.periods,
    required this.currentMetrics,
    required this.previousMetrics,
    required this.currencyFormat,
    required this.rowBuilder,
    // ignore: unused_element_parameter
    this.onOpenTransactions,
  });

  @override
  State<_SalesByCustomerComparisonDataRow> createState() =>
      _SalesByCustomerComparisonDataRowState();
}

class _SalesByCustomerComparisonDataRowState
    extends State<_SalesByCustomerComparisonDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenTransactions == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space14),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: widget.rowBuilder(
          name: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
            child: _SalesByCustomerLinkText(
              text: widget.customerName,
              onTap: widget.onOpenTransactions,
              textAlign: TextAlign.left,
              isUnderlined: _isHovered,
            ),
          ),
          periodCells: widget.periods.map((period) {
            final metrics = period.isCurrent
                ? widget.currentMetrics
                : widget.previousMetrics;
            return _comparisonMetricCells(
              invoiceCountText: '${metrics.invoiceCount}',
              salesText: widget.currencyFormat.format(metrics.sales),
              salesWithTaxText: widget.currencyFormat.format(
                metrics.salesWithTax,
              ),
              linkStyle: true,
              onTap: widget.onOpenTransactions,
              isUnderlined: _isHovered,
            );
          }).toList(growable: false),
          customerType: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
            child: Text(widget.customerType, style: AppTheme.tableCell),
          ),
        ),
      ),
    );
  }

  Widget _comparisonMetricCells({
    required String invoiceCountText,
    required String salesText,
    required String salesWithTaxText,
    required bool linkStyle,
    VoidCallback? onTap,
    bool isUnderlined = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: _SalesByCustomerTableState._periodMetricWidth,
          child: _SalesByCustomerLinkText(
            text: invoiceCountText,
            onTap: onTap,
            textAlign: TextAlign.center,
            isUnderlined: isUnderlined,
          ),
        ),
        SizedBox(
          width: _SalesByCustomerTableState._periodMetricWidth,
          child: _SalesByCustomerLinkText(
            text: salesText,
            onTap: onTap,
            textAlign: TextAlign.right,
            isUnderlined: isUnderlined,
          ),
        ),
        SizedBox(
          width: _SalesByCustomerTableState._periodMetricWidth,
          child: _SalesByCustomerLinkText(
            text: salesWithTaxText,
            onTap: onTap,
            textAlign: TextAlign.right,
            isUnderlined: isUnderlined,
          ),
        ),
      ],
    );
  }
}

class _SalesByCustomerDataRow extends StatefulWidget {
  final String customerName;
  final int invoiceCount;
  final String salesText;
  final String salesWithTaxText;
  final String customerType;
  final VoidCallback? onOpenTransactions;
  final Widget Function({
    required Widget name,
    required Widget invoiceCount,
    required Widget sales,
    required Widget salesWithTax,
    required Widget customerType,
  }) rowBuilder;

  const _SalesByCustomerDataRow({
    required this.customerName,
    required this.invoiceCount,
    required this.salesText,
    required this.salesWithTaxText,
    required this.customerType,
    required this.rowBuilder,
    this.onOpenTransactions,
  });

  @override
  State<_SalesByCustomerDataRow> createState() =>
      _SalesByCustomerDataRowState();
}

class _SalesByCustomerDataRowState extends State<_SalesByCustomerDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenTransactions == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space16,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: widget.rowBuilder(
          name: _SalesByCustomerLinkText(
            text: widget.customerName,
            onTap: widget.onOpenTransactions,
            textAlign: TextAlign.left,
            isUnderlined: _isHovered,
          ),
          invoiceCount: _SalesByCustomerLinkText(
            text: '${widget.invoiceCount}',
            onTap: widget.onOpenTransactions,
            textAlign: TextAlign.center,
            isUnderlined: _isHovered,
          ),
          sales: _SalesByCustomerLinkText(
            text: widget.salesText,
            onTap: widget.onOpenTransactions,
            textAlign: TextAlign.right,
            isUnderlined: _isHovered,
          ),
          salesWithTax: _SalesByCustomerLinkText(
            text: widget.salesWithTaxText,
            onTap: widget.onOpenTransactions,
            textAlign: TextAlign.right,
            isUnderlined: _isHovered,
          ),
          customerType: Text(widget.customerType, style: AppTheme.tableCell),
        ),
      ),
    );
  }
}

class _SalesByCustomerStaticText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const _SalesByCustomerStaticText({
    required this.text,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }
}


class _SalesByCustomerLinkText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final bool isUnderlined;

  const _SalesByCustomerLinkText({
    required this.text,
    required this.onTap,
    required this.textAlign,
    required this.isUnderlined,
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

/// Frozen left-column name cell for comparison mode.
class _SalesByCustomerFrozenNameRow extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _SalesByCustomerFrozenNameRow({required this.label, this.onTap});

  @override
  State<_SalesByCustomerFrozenNameRow> createState() =>
      _SalesByCustomerFrozenNameRowState();
}

class _SalesByCustomerFrozenNameRowState
    extends State<_SalesByCustomerFrozenNameRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space24,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderColor),
              right: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: _SalesByCustomerLinkText(
            text: widget.label,
            onTap: widget.onTap,
            textAlign: TextAlign.left,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

/// Right-side metrics-only row for the comparison frozen-column layout.
class _SalesByCustomerComparisonMetricsRow extends StatefulWidget {
  final String customerType;
  final List<SalesByCustomerComparisonPeriod> periods;
  final _SalesByCustomerComparisonMetrics currentMetrics;
  final _SalesByCustomerComparisonMetrics previousMetrics;
  final NumberFormat currencyFormat;
  final VoidCallback? onOpenTransactions;
  final double customerTypeWidth;
  final double periodMetricWidth;
  final Widget Function({
    required String invoiceCountText,
    required String salesText,
    required String salesWithTaxText,
    required bool linkStyle,
    VoidCallback? onTap,
    bool isUnderlined,
  }) metricCellsBuilder;

  const _SalesByCustomerComparisonMetricsRow({
    required this.customerType,
    required this.periods,
    required this.currentMetrics,
    required this.previousMetrics,
    required this.currencyFormat,
    required this.customerTypeWidth,
    required this.periodMetricWidth,
    required this.metricCellsBuilder,
    this.onOpenTransactions,
  });

  @override
  State<_SalesByCustomerComparisonMetricsRow> createState() =>
      _SalesByCustomerComparisonMetricsRowState();
}

class _SalesByCustomerComparisonMetricsRowState
    extends State<_SalesByCustomerComparisonMetricsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenTransactions == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            ...widget.periods.map((period) {
              final metrics = period.isCurrent
                  ? widget.currentMetrics
                  : widget.previousMetrics;
              return widget.metricCellsBuilder(
                invoiceCountText: '${metrics.invoiceCount}',
                salesText: widget.currencyFormat.format(metrics.sales),
                salesWithTaxText:
                    widget.currencyFormat.format(metrics.salesWithTax),
                linkStyle: true,
                onTap: widget.onOpenTransactions,
                isUnderlined: _isHovered,
              );
            }),
            SizedBox(
              width: widget.customerTypeWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space24,
                ),
                child: Text(
                  widget.customerType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.tableCell,
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
}

