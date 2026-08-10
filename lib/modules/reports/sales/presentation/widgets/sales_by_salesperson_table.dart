import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_horizontal_scroll_overlay.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'sales_by_customer_table.dart';

class SalesBySalespersonTable extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final NumberFormat currencyFormat;
  final ValueChanged<Map<String, dynamic>>? onOpenOverview;
  final List<SalesByCustomerComparisonPeriod> comparisonPeriods;

  const SalesBySalespersonTable({
    super.key,
    required this.items,
    required this.currencyFormat,
    this.onOpenOverview,
    this.comparisonPeriods = const <SalesByCustomerComparisonPeriod>[],
  });

  @override
  State<SalesBySalespersonTable> createState() => _SalesBySalespersonTableState();
}

class _SalesBySalespersonTableState extends State<SalesBySalespersonTable>
    with ReportHorizontalScrollMixin<SalesBySalespersonTable> {
  static const double _nameWidth = 240;
  static const double _periodWidth = 1080;

  static const List<double> _metricWidths = [
    110, // Invoice Count
    120, // Invoice Sales
    160, // Invoice Sales With Tax
    130, // Credit Note Count
    130, // Credit Note Sales
    170, // Credit Note Sales With Tax
    110, // Total Sales
    150, // Total Sales With Tax
  ];

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
      widget.comparisonPeriods.length * _periodWidth;

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
    final frozenColumn = SizedBox(
      width: _nameWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                              ...widget.items.map(_buildComparisonDataRow),
                              _buildComparisonTotalRow(),
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

  Widget _buildFrozenNameCell(Map<String, dynamic> item) {
    final salespersonName = item['salespersonName']?.toString() ?? '-';
    final openOverview = widget.onOpenOverview == null
        ? null
        : () => widget.onOpenOverview!(item);
    return _SalesBySalespersonFrozenNameRow(
      label: salespersonName,
      onTap: openOverview,
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

  Widget _buildComparisonDataRow(Map<String, dynamic> item) {
    final invoiceCount = (item['invoiceCount'] as num?)?.toInt() ?? 0;
    final invoiceSales = (item['invoiceSales'] as num?)?.toDouble() ?? 0;
    final invoiceSalesWithTax =
        (item['invoiceSalesWithTax'] as num?)?.toDouble() ?? 0;
    final creditNoteCount = (item['creditNoteCount'] as num?)?.toInt() ?? 0;
    final creditNoteSales =
        (item['creditNoteSales'] as num?)?.toDouble() ?? 0;
    final creditNoteSalesWithTax =
        (item['creditNoteSalesWithTax'] as num?)?.toDouble() ?? 0;
    final totalSales = (item['totalSales'] as num?)?.toDouble() ?? 0;
    final totalSalesWithTax =
        (item['totalSalesWithTax'] as num?)?.toDouble() ?? 0;
    final openOverview = widget.onOpenOverview == null
        ? null
        : () => widget.onOpenOverview!(item);

    return _SalesBySalespersonComparisonMetricsRow(
      invoiceCount: invoiceCount,
      invoiceSales: invoiceSales,
      invoiceSalesWithTax: invoiceSalesWithTax,
      creditNoteCount: creditNoteCount,
      creditNoteSales: creditNoteSales,
      creditNoteSalesWithTax: creditNoteSalesWithTax,
      totalSales: totalSales,
      totalSalesWithTax: totalSalesWithTax,
      periods: widget.comparisonPeriods,
      onOpenOverview: openOverview,
      metricWidths: _metricWidths,
      periodWidth: _periodWidth,
      currencyFormat: widget.currencyFormat,
    );
  }

  Widget _buildStandardTable() {
    final totalInvoiceCount = widget.items.fold<int>(
      0,
      (sum, item) => sum + ((item['invoiceCount'] as num?)?.toInt() ?? 0),
    );
    final totalInvoiceSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['invoiceSales'] as num?)?.toDouble() ?? 0),
    );
    final totalInvoiceSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['invoiceSalesWithTax'] as num?)?.toDouble() ?? 0),
    );
    final totalCreditNoteCount = widget.items.fold<int>(
      0,
      (sum, item) => sum + ((item['creditNoteCount'] as num?)?.toInt() ?? 0),
    );
    final totalCreditNoteSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['creditNoteSales'] as num?)?.toDouble() ?? 0),
    );
    final totalCreditNoteSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['creditNoteSalesWithTax'] as num?)?.toDouble() ?? 0),
    );
    final totalSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['totalSales'] as num?)?.toDouble() ?? 0),
    );
    final totalSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['totalSalesWithTax'] as num?)?.toDouble() ?? 0),
    );

    return ReportStickyHeaderScrollTable(
      header: _buildHeader(),
      emptyBody: const ReportTableEmptyBody(),
      isEmpty: widget.items.isEmpty,
      children: [
        ...widget.items.map((item) {
          final salespersonName = item['salespersonName']?.toString() ?? '-';
          final invoiceCount = (item['invoiceCount'] as num?)?.toInt() ?? 0;
          final invoiceSales = (item['invoiceSales'] as num?)?.toDouble() ?? 0;
          final invoiceSalesWithTax =
              (item['invoiceSalesWithTax'] as num?)?.toDouble() ?? 0;
          final creditNoteCount =
              (item['creditNoteCount'] as num?)?.toInt() ?? 0;
          final creditNoteSales =
              (item['creditNoteSales'] as num?)?.toDouble() ?? 0;
          final creditNoteSalesWithTax =
              (item['creditNoteSalesWithTax'] as num?)?.toDouble() ?? 0;
          final totalSales = (item['totalSales'] as num?)?.toDouble() ?? 0;
          final totalSalesWithTax =
              (item['totalSalesWithTax'] as num?)?.toDouble() ?? 0;
          final openOverview = widget.onOpenOverview == null
              ? null
              : () => widget.onOpenOverview!(item);

          return _SalesBySalespersonDataRow(
            salespersonName: salespersonName,
            invoiceCount: invoiceCount,
            invoiceSalesText: widget.currencyFormat.format(invoiceSales),
            invoiceSalesWithTaxText: widget.currencyFormat.format(invoiceSalesWithTax),
            creditNoteCount: creditNoteCount,
            creditNoteSalesText: widget.currencyFormat.format(creditNoteSales),
            creditNoteSalesWithTaxText: widget.currencyFormat.format(
              creditNoteSalesWithTax,
            ),
            totalSalesText: widget.currencyFormat.format(totalSales),
            totalSalesWithTaxText: widget.currencyFormat.format(totalSalesWithTax),
            onOpenOverview: openOverview,
            rowBuilder: _buildTableRow,
          );
        }),
        if (widget.items.isNotEmpty)
          _buildTotalRow(
            totalInvoiceCount: totalInvoiceCount,
            totalInvoiceSales: totalInvoiceSales,
            totalInvoiceSalesWithTax: totalInvoiceSalesWithTax,
            totalCreditNoteCount: totalCreditNoteCount,
            totalCreditNoteSales: totalCreditNoteSales,
            totalCreditNoteSalesWithTax: totalCreditNoteSalesWithTax,
            totalSales: totalSales,
            totalSalesWithTax: totalSalesWithTax,
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
        invoiceSales: Text(
          'INVOICE SALES',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        invoiceSalesWithTax: Text(
          'INVOICE SALES WITH TAX',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        creditNoteCount: Text(
          'CREDIT NOTE COUNT',
          textAlign: TextAlign.center,
          style: ReportTableTypography.header,
        ),
        creditNoteSales: Text(
          'CREDIT NOTE SALES',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        creditNoteSalesWithTax: Text(
          'CREDIT NOTE SALES WITH TAX',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        totalSales: Text(
          'TOTAL SALES',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
        totalSalesWithTax: Text(
          'TOTAL SALES WITH TAX',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
      ),
    );
  }


  Widget _comparisonPeriodHeader(String label) {
    return SizedBox(
      width: _periodWidth,
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
                _comparisonMetricHeader('INVOICE COUNT', _metricWidths[0], TextAlign.center),
                _comparisonMetricHeader('INVOICE SALES', _metricWidths[1], TextAlign.right),
                _comparisonMetricHeader('INVOICE SALES WITH TAX', _metricWidths[2], TextAlign.right),
                _comparisonMetricHeader('CREDIT NOTE COUNT', _metricWidths[3], TextAlign.center),
                _comparisonMetricHeader('CREDIT NOTE SALES', _metricWidths[4], TextAlign.right),
                _comparisonMetricHeader('CREDIT NOTE SALES WITH TAX', _metricWidths[5], TextAlign.right),
                _comparisonMetricHeader('TOTAL SALES', _metricWidths[6], TextAlign.right),
                _comparisonMetricHeader('TOTAL SALES WITH TAX', _metricWidths[7], TextAlign.right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonMetricHeader(String text, double width, TextAlign textAlign) {
    return Container(
      width: width,
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
    );
  }

  Widget _buildTotalRow({
    required int totalInvoiceCount,
    required double totalInvoiceSales,
    required double totalInvoiceSalesWithTax,
    required int totalCreditNoteCount,
    required double totalCreditNoteSales,
    required double totalCreditNoteSalesWithTax,
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
        invoiceSales: Text(
          widget.currencyFormat.format(totalInvoiceSales),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        invoiceSalesWithTax: Text(
          widget.currencyFormat.format(totalInvoiceSalesWithTax),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        creditNoteCount: Text(
          '$totalCreditNoteCount',
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        creditNoteSales: Text(
          widget.currencyFormat.format(totalCreditNoteSales),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        creditNoteSalesWithTax: Text(
          widget.currencyFormat.format(totalCreditNoteSalesWithTax),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        totalSales: Text(
          widget.currencyFormat.format(totalSales),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        totalSalesWithTax: Text(
          widget.currencyFormat.format(totalSalesWithTax),
          textAlign: TextAlign.right,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTotalRow() {
    final totalInvoiceCount = widget.items.fold<int>(
      0,
      (sum, item) => sum + ((item['invoiceCount'] as num?)?.toInt() ?? 0),
    );
    final totalInvoiceSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['invoiceSales'] as num?)?.toDouble() ?? 0),
    );
    final totalInvoiceSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['invoiceSalesWithTax'] as num?)?.toDouble() ?? 0),
    );
    final totalCreditNoteCount = widget.items.fold<int>(
      0,
      (sum, item) => sum + ((item['creditNoteCount'] as num?)?.toInt() ?? 0),
    );
    final totalCreditNoteSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['creditNoteSales'] as num?)?.toDouble() ?? 0),
    );
    final totalCreditNoteSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['creditNoteSalesWithTax'] as num?)?.toDouble() ?? 0),
    );
    final totalSales = widget.items.fold<double>(
      0,
      (sum, item) => sum + ((item['totalSales'] as num?)?.toDouble() ?? 0),
    );
    final totalSalesWithTax = widget.items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['totalSalesWithTax'] as num?)?.toDouble() ?? 0),
    );

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: widget.comparisonPeriods.map((period) {
          final invCount = period.isCurrent ? totalInvoiceCount : 0;
          final invSales = period.isCurrent ? totalInvoiceSales : 0.0;
          final invSalesTax =
              period.isCurrent ? totalInvoiceSalesWithTax : 0.0;
          final cnCount = period.isCurrent ? totalCreditNoteCount : 0;
          final cnSales = period.isCurrent ? totalCreditNoteSales : 0.0;
          final cnSalesTax =
              period.isCurrent ? totalCreditNoteSalesWithTax : 0.0;
          final tSales = period.isCurrent ? totalSales : 0.0;
          final tSalesTax = period.isCurrent ? totalSalesWithTax : 0.0;

          return SizedBox(
            width: _periodWidth,
            child: Row(
              children: [
                _totalCell(_metricWidths[0], invCount.toString(),
                    TextAlign.center, isBold: false),
                _totalCell(_metricWidths[1],
                    widget.currencyFormat.format(invSales), TextAlign.right),
                _totalCell(_metricWidths[2],
                    widget.currencyFormat.format(invSalesTax), TextAlign.right),
                _totalCell(_metricWidths[3], cnCount.toString(),
                    TextAlign.center, isBold: false),
                _totalCell(_metricWidths[4],
                    widget.currencyFormat.format(cnSales), TextAlign.right),
                _totalCell(_metricWidths[5],
                    widget.currencyFormat.format(cnSalesTax), TextAlign.right),
                _totalCell(_metricWidths[6],
                    widget.currencyFormat.format(tSales), TextAlign.right),
                _totalCell(_metricWidths[7],
                    widget.currencyFormat.format(tSalesTax), TextAlign.right),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }


  Widget _totalCell(double width, String text, TextAlign align, {bool isBold = true}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : (align == TextAlign.center ? Alignment.center : Alignment.centerLeft),
      child: Text(
        text,
        textAlign: align,
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }


  Widget _buildTableRow({
    required Widget name,
    required Widget invoiceCount,
    required Widget invoiceSales,
    required Widget invoiceSalesWithTax,
    required Widget creditNoteCount,
    required Widget creditNoteSales,
    required Widget creditNoteSalesWithTax,
    required Widget totalSales,
    required Widget totalSalesWithTax,
  }) {
    return Row(
      children: [
        Expanded(flex: 17, child: name),
        Expanded(flex: 11, child: invoiceCount),
        Expanded(flex: 13, child: invoiceSales),
        Expanded(flex: 18, child: invoiceSalesWithTax),
        Expanded(flex: 13, child: creditNoteCount),
        Expanded(flex: 14, child: creditNoteSales),
        Expanded(flex: 20, child: creditNoteSalesWithTax),
        Expanded(flex: 12, child: totalSales),
        Expanded(flex: 17, child: totalSalesWithTax),
      ],
    );
  }
}

class _SalesBySalespersonDataRow extends StatefulWidget {
  final String salespersonName;
  final int invoiceCount;
  final String invoiceSalesText;
  final String invoiceSalesWithTaxText;
  final int creditNoteCount;
  final String creditNoteSalesText;
  final String creditNoteSalesWithTaxText;
  final String totalSalesText;
  final String totalSalesWithTaxText;
  final VoidCallback? onOpenOverview;
  final Widget Function({
    required Widget name,
    required Widget invoiceCount,
    required Widget invoiceSales,
    required Widget invoiceSalesWithTax,
    required Widget creditNoteCount,
    required Widget creditNoteSales,
    required Widget creditNoteSalesWithTax,
    required Widget totalSales,
    required Widget totalSalesWithTax,
  })
  rowBuilder;

  const _SalesBySalespersonDataRow({
    required this.salespersonName,
    required this.invoiceCount,
    required this.invoiceSalesText,
    required this.invoiceSalesWithTaxText,
    required this.creditNoteCount,
    required this.creditNoteSalesText,
    required this.creditNoteSalesWithTaxText,
    required this.totalSalesText,
    required this.totalSalesWithTaxText,
    required this.rowBuilder,
    this.onOpenOverview,
  });

  @override
  State<_SalesBySalespersonDataRow> createState() =>
      _SalesBySalespersonDataRowState();
}

class _SalesBySalespersonDataRowState
    extends State<_SalesBySalespersonDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenOverview == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpenOverview,
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
            name: _SalesBySalespersonLinkText(
              text: widget.salespersonName,
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.left,
              isUnderlined: _isHovered,
            ),
            invoiceCount: _SalesBySalespersonLinkText(
              text: '${widget.invoiceCount}',
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.center,
              isUnderlined: _isHovered,
            ),
            invoiceSales: _SalesBySalespersonLinkText(
              text: widget.invoiceSalesText,
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.right,
              isUnderlined: _isHovered,
            ),
            invoiceSalesWithTax: _SalesBySalespersonLinkText(
              text: widget.invoiceSalesWithTaxText,
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.right,
              isUnderlined: _isHovered,
            ),
            creditNoteCount: _SalesBySalespersonLinkText(
              text: '${widget.creditNoteCount}',
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.center,
              isUnderlined: _isHovered,
            ),
            creditNoteSales: _SalesBySalespersonLinkText(
              text: widget.creditNoteSalesText,
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.right,
              isUnderlined: _isHovered,
            ),
            creditNoteSalesWithTax: _SalesBySalespersonLinkText(
              text: widget.creditNoteSalesWithTaxText,
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.right,
              isUnderlined: _isHovered,
            ),
            totalSales: _SalesBySalespersonLinkText(
              text: widget.totalSalesText,
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.right,
              isUnderlined: _isHovered,
            ),
            totalSalesWithTax: _SalesBySalespersonLinkText(
              text: widget.totalSalesWithTaxText,
              onTap: widget.onOpenOverview,
              textAlign: TextAlign.right,
              isUnderlined: _isHovered,
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesBySalespersonLinkText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final bool isUnderlined;

  const _SalesBySalespersonLinkText({
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

/// Frozen left-column name cell for comparison mode (salesperson table).
class _SalesBySalespersonFrozenNameRow extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _SalesBySalespersonFrozenNameRow({
    required this.label,
    this.onTap,
  });

  @override
  State<_SalesBySalespersonFrozenNameRow> createState() =>
      _SalesBySalespersonFrozenNameRowState();
}

class _SalesBySalespersonFrozenNameRowState
    extends State<_SalesBySalespersonFrozenNameRow> {
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderColor),
              right: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: _SalesBySalespersonLinkText(
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

/// Right-side metrics-only row for the comparison frozen-column layout (salesperson table).
class _SalesBySalespersonComparisonMetricsRow extends StatefulWidget {
  final int invoiceCount;
  final double invoiceSales;
  final double invoiceSalesWithTax;
  final int creditNoteCount;
  final double creditNoteSales;
  final double creditNoteSalesWithTax;
  final double totalSales;
  final double totalSalesWithTax;
  final List<SalesByCustomerComparisonPeriod> periods;
  final VoidCallback? onOpenOverview;
  final List<double> metricWidths;
  final double periodWidth;
  final NumberFormat currencyFormat;

  const _SalesBySalespersonComparisonMetricsRow({
    required this.invoiceCount,
    required this.invoiceSales,
    required this.invoiceSalesWithTax,
    required this.creditNoteCount,
    required this.creditNoteSales,
    required this.creditNoteSalesWithTax,
    required this.totalSales,
    required this.totalSalesWithTax,
    required this.periods,
    required this.metricWidths,
    required this.periodWidth,
    required this.currencyFormat,
    this.onOpenOverview,
  });

  @override
  State<_SalesBySalespersonComparisonMetricsRow> createState() =>
      _SalesBySalespersonComparisonMetricsRowState();
}

class _SalesBySalespersonComparisonMetricsRowState
    extends State<_SalesBySalespersonComparisonMetricsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenOverview == null
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
            final invCount = period.isCurrent ? widget.invoiceCount : 0;
            final invSales = period.isCurrent ? widget.invoiceSales : 0.0;
            final invSalesTax =
                period.isCurrent ? widget.invoiceSalesWithTax : 0.0;
            final cnCount = period.isCurrent ? widget.creditNoteCount : 0;
            final cnSales = period.isCurrent ? widget.creditNoteSales : 0.0;
            final cnSalesTax =
                period.isCurrent ? widget.creditNoteSalesWithTax : 0.0;
            final tSales = period.isCurrent ? widget.totalSales : 0.0;
            final tSalesTax = period.isCurrent ? widget.totalSalesWithTax : 0.0;

            return SizedBox(
              width: widget.periodWidth,
              child: Row(
                children: [
                  _cell(widget.metricWidths[0], invCount.toString(),
                      TextAlign.center, widget.onOpenOverview),
                  _cell(
                      widget.metricWidths[1],
                      widget.currencyFormat.format(invSales),
                      TextAlign.right,
                      widget.onOpenOverview),
                  _cell(
                      widget.metricWidths[2],
                      widget.currencyFormat.format(invSalesTax),
                      TextAlign.right,
                      widget.onOpenOverview),
                  _cell(widget.metricWidths[3], cnCount.toString(),
                      TextAlign.center, widget.onOpenOverview),
                  _cell(
                      widget.metricWidths[4],
                      widget.currencyFormat.format(cnSales),
                      TextAlign.right,
                      widget.onOpenOverview),
                  _cell(
                      widget.metricWidths[5],
                      widget.currencyFormat.format(cnSalesTax),
                      TextAlign.right,
                      widget.onOpenOverview),
                  _cell(
                      widget.metricWidths[6],
                      widget.currencyFormat.format(tSales),
                      TextAlign.right,
                      widget.onOpenOverview),
                  _cell(
                      widget.metricWidths[7],
                      widget.currencyFormat.format(tSalesTax),
                      TextAlign.right,
                      widget.onOpenOverview),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _cell(
      double width, String text, TextAlign align, VoidCallback? onTap) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : (align == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft),
      child: _SalesBySalespersonLinkText(
        text: text,
        onTap: onTap,
        textAlign: align,
        isUnderlined: _isHovered,
      ),
    );
  }
}

