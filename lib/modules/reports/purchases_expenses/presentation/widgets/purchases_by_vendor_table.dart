import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_horizontal_scroll_overlay.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/sales/presentation/widgets/sales_by_customer_table.dart';
import 'package:zerpai_erp/modules/reports/purchases_expenses/presentation/widgets/purchase_details_for_vendor_table.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  symbol: '\u20B9',
  decimalDigits: 2,
);

class PurchasesByVendorRow {
  final String? vendorId;
  final String vendorName;
  final int expenseCountValue;
  final int billCountValue;
  final int vendorCreditCountValue;
  final int journalCountValue;
  final double amountValue;
  final double amountWithTaxValue;
  final List<PurchaseDetailsForVendorRow> details;

  const PurchasesByVendorRow({
    this.vendorId,
    required this.vendorName,
    required this.expenseCountValue,
    required this.billCountValue,
    required this.vendorCreditCountValue,
    required this.journalCountValue,
    required this.amountValue,
    required this.amountWithTaxValue,
    this.details = const <PurchaseDetailsForVendorRow>[],
  });

  factory PurchasesByVendorRow.fromJson(Map<String, dynamic> item) {
    double numberValue(String key) {
      final value = item[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String textValue(String key, [String fallback = '-']) {
      final value = item[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    final detailValues = item['details'];
    final detailRows = detailValues is List
        ? detailValues
              .whereType<Map>()
              .map(
                (detail) => PurchaseDetailsForVendorRow.fromJson(
                  Map<String, dynamic>.from(detail),
                ),
              )
              .toList(growable: false)
        : const <PurchaseDetailsForVendorRow>[];

    return PurchasesByVendorRow(
      vendorId: item['vendorId']?.toString(),
      vendorName: textValue('vendorName', 'Others'),
      expenseCountValue: numberValue('expenseCount').round(),
      billCountValue: numberValue('billCount').round(),
      vendorCreditCountValue: numberValue('vendorCreditCount').round(),
      journalCountValue: numberValue('journalCount').round(),
      amountValue: numberValue('amount'),
      amountWithTaxValue: numberValue('amountWithTax'),
      details: detailRows,
    );
  }

  String get expenseCount => expenseCountValue.toString();
  String get billCount => billCountValue.toString();
  String get vendorCreditCount => vendorCreditCountValue.toString();
  String get journalCount => journalCountValue.toString();
  String get amount => _currencyFormat.format(amountValue);
  String get amountWithTax => _currencyFormat.format(amountWithTaxValue);
}

class PurchasesByVendorTable extends StatefulWidget {
  final List<PurchasesByVendorRow> rows;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PurchasesByVendorRow>? onVendorSelected;
  final List<SalesByCustomerComparisonPeriod> comparisonPeriods;

  const PurchasesByVendorTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    this.onVendorSelected,
    this.comparisonPeriods = const <SalesByCustomerComparisonPeriod>[],
  });

  @override
  State<PurchasesByVendorTable> createState() => _PurchasesByVendorTableState();
}

class _PurchasesByVendorTableState extends State<PurchasesByVendorTable>
    with ReportHorizontalScrollMixin<PurchasesByVendorTable> {
  static const double _nameWidth = 240;
  static const double _periodWidth = 800;

  static const List<double> _metricWidths = [
    110, // Expense Count
    100, // Bill Count
    160, // Vendor Credit Count
    130, // Journal Count
    140, // Amount
    160, // Amount With Tax
  ];

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  bool _isSyncingVertical = false;

  @override
  ScrollController get horizontalScrollController => _horizontalController;

  bool get _isComparisonMode => widget.comparisonPeriods.isNotEmpty;

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

  List<PurchasesByVendorRow> get _pageRows {
    final start = (widget.page - 1) * widget.pageSize;
    if (start >= widget.rows.length) {
      return const <PurchasesByVendorRow>[];
    }
    final end = (start + widget.pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  int get _totalExpenseCount =>
      widget.rows.fold<int>(0, (total, row) => total + row.expenseCountValue);

  int get _totalBillCount =>
      widget.rows.fold<int>(0, (total, row) => total + row.billCountValue);

  int get _totalVendorCreditCount => widget.rows.fold<int>(
    0,
    (total, row) => total + row.vendorCreditCountValue,
  );

  int get _totalJournalCount =>
      widget.rows.fold<int>(0, (total, row) => total + row.journalCountValue);

  double get _totalAmount =>
      widget.rows.fold<double>(0, (total, row) => total + row.amountValue);

  double get _totalAmountWithTax => widget.rows.fold<double>(
    0,
    (total, row) => total + row.amountWithTaxValue,
  );

  @override
  Widget build(BuildContext context) {
    return _isComparisonMode ? _buildComparisonTable() : _buildStandardTable();
  }

  Widget _buildStandardTable() {
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1380,
          child: ReportStickyHeaderScrollTable(
            header: _buildHeader(),
            emptyBody: const SizedBox.shrink(),
            children: [
              SizedBox(
                height: 260,
                child: widget.rows.isEmpty
                    ? const ReportTableEmptyBody(
                        minHeight: 260,
                        message: 'No data to display',
                      )
                    : Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: _pageRows.length > 6,
                        child: ListView.separated(
                          controller: _verticalController,
                          itemCount: _pageRows.length + 1,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.borderLight,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _pageRows.length) {
                              return _buildTotalRow();
                            }
                            return _PurchasesByVendorDataRow(
                              row: _pageRows[index],
                              onVendorSelected: widget.onVendorSelected,
                            );
                          },
                        ),
                      ),
              ),
              ReportPaginationFooter(
                totalCount: widget.rows.length,
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

  Widget _buildComparisonTable() {
    final frozenColumn = _buildFrozenNameColumn();

    final scrollableSection = ReportHorizontalScrollOverlay(
      canScrollLeft: canScrollLeft,
      canScrollRight: canScrollRight,
      onScrollLeft: scrollLeft,
      onScrollRight: scrollRight,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: widget.rows.isNotEmpty,
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
                    thumbVisibility: widget.rows.isNotEmpty,
                    child: widget.rows.isEmpty
                        ? const ReportTableEmptyBody(message: 'No data to display')
                        : ListView(
                            controller: _rightVerticalController,
                            primary: false,
                            padding: EdgeInsets.zero,
                            children: [
                              ..._pageRows.map(
                                (row) => _buildComparisonMetricsRow(row),
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

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              frozenColumn,
              Expanded(child: scrollableSection),
            ],
          ),
        ),
        ReportPaginationFooter(
          totalCount: widget.rows.length,
          page: widget.page,
          pageSize: widget.pageSize,
          onPageChanged: widget.onPageChanged,
        ),
        const SizedBox(height: AppTheme.space28),
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
                Text('VENDOR NAME', style: ReportTableTypography.header),
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
            child: widget.rows.isEmpty
                ? const SizedBox.shrink()
                : ListView(
                    controller: _leftVerticalController,
                    primary: false,
                    padding: EdgeInsets.zero,
                    children: [
                      ..._pageRows.map(_buildFrozenNameCell),
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

  Widget _buildFrozenNameCell(PurchasesByVendorRow row) {
    return _PurchasesByVendorFrozenNameRow(
      row: row,
      onTap: widget.onVendorSelected == null
          ? null
          : () => widget.onVendorSelected!(row),
    );
  }

  Widget _buildFrozenTotalNameCell() {
    return Container(
      height: 48,
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
          fontWeight: FontWeight.w700,
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
        children: widget.comparisonPeriods.map(
          (period) => _comparisonPeriodHeader(period.label),
        ).toList(),
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
                _comparisonMetricHeader('EXPENSE COUNT', _metricWidths[0], TextAlign.right),
                _comparisonMetricHeader('BILL COUNT', _metricWidths[1], TextAlign.right),
                _comparisonMetricHeader('VENDOR CREDIT COUNT', _metricWidths[2], TextAlign.right),
                _comparisonMetricHeader('JOURNAL COUNT', _metricWidths[3], TextAlign.right),
                _comparisonMetricHeader('AMOUNT', _metricWidths[4], TextAlign.right),
                _comparisonMetricHeader('AMOUNT WITH TAX', _metricWidths[5], TextAlign.right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonMetricHeader(String label, double width, TextAlign align) {
    return Container(
      width: width,
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

  Widget _buildComparisonMetricsRow(PurchasesByVendorRow row) {
    final currentMetrics = _comparisonMetricsFor(row, isCurrent: true);
    final previousMetrics = const _PurchasesByVendorComparisonMetrics.empty();

    return _PurchasesByVendorComparisonMetricsRow(
      periods: widget.comparisonPeriods,
      currentMetrics: currentMetrics,
      previousMetrics: previousMetrics,
      currencyFormat: _currencyFormat,
      metricWidths: _metricWidths,
      periodWidth: _periodWidth,
      onOpenDetails: widget.onVendorSelected == null
          ? null
          : () => widget.onVendorSelected!(row),
    );
  }

  Widget _buildComparisonTotalMetricsRow() {
    final currentMetrics = _PurchasesByVendorComparisonMetrics(
      expenseCount: _totalExpenseCount,
      billCount: _totalBillCount,
      vendorCreditCount: _totalVendorCreditCount,
      journalCount: _totalJournalCount,
      amount: _totalAmount,
      amountWithTax: _totalAmountWithTax,
    );
    final previousMetrics = const _PurchasesByVendorComparisonMetrics.empty();

    return _PurchasesByVendorComparisonMetricsRow(
      periods: widget.comparisonPeriods,
      currentMetrics: currentMetrics,
      previousMetrics: previousMetrics,
      currencyFormat: _currencyFormat,
      metricWidths: _metricWidths,
      periodWidth: _periodWidth,
      isTotalRow: true,
    );
  }

  _PurchasesByVendorComparisonMetrics _comparisonMetricsFor(
    PurchasesByVendorRow row, {
    required bool isCurrent,
  }) {
    if (!isCurrent) return const _PurchasesByVendorComparisonMetrics.empty();
    return _PurchasesByVendorComparisonMetrics(
      expenseCount: row.expenseCountValue,
      billCount: row.billCountValue,
      vendorCreditCount: row.vendorCreditCountValue,
      journalCount: row.journalCountValue,
      amount: row.amountValue,
      amountWithTax: row.amountWithTaxValue,
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
        vendorName: Row(
          children: [
            Text('VENDOR NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        expenseCount: _headerText('EXPENSE COUNT', alignRight: true),
        billCount: _headerText('BILL COUNT', alignRight: true),
        vendorCreditCount: _headerText('VENDOR CREDIT COUNT', alignRight: true),
        journalCount: _headerText('JOURNAL COUNT', alignRight: true),
        amount: _headerText('AMOUNT', alignRight: true),
        amountWithTax: _headerText('AMOUNT WITH TAX', alignRight: true),
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

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        vendorName: Text('Total', style: _totalStyle),
        expenseCount: Text(
          _totalExpenseCount.toString(),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        billCount: Text(
          _totalBillCount.toString(),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        vendorCreditCount: Text(
          _totalVendorCreditCount.toString(),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        journalCount: Text(
          _totalJournalCount.toString(),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amount: Text(
          _currencyFormat.format(_totalAmount),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
        amountWithTax: Text(
          _currencyFormat.format(_totalAmountWithTax),
          textAlign: TextAlign.right,
          style: _totalStyle,
        ),
      ),
    );
  }

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );
}

class _PurchasesByVendorDataRow extends StatefulWidget {
  final PurchasesByVendorRow row;
  final ValueChanged<PurchasesByVendorRow>? onVendorSelected;

  const _PurchasesByVendorDataRow({
    required this.row,
    required this.onVendorSelected,
  });

  @override
  State<_PurchasesByVendorDataRow> createState() =>
      _PurchasesByVendorDataRowState();
}

class _PurchasesByVendorDataRowState extends State<_PurchasesByVendorDataRow> {
  bool _isHovered = false;

  bool get _isClickable => widget.onVendorSelected != null;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _handlePressed() {
    widget.onVendorSelected?.call(widget.row);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        vendorName: _linkText(
          row.vendorName,
          isOthers: row.vendorName == 'Others',
        ),
        expenseCount: _plainText(row.expenseCount, alignRight: true),
        billCount: _plainText(row.billCount, alignRight: true),
        vendorCreditCount: _plainText(row.vendorCreditCount, alignRight: true),
        journalCount: _plainText(row.journalCount, alignRight: true),
        amount: _amountText(row.amount),
        amountWithTax: _amountText(row.amountWithTax),
      ),
    );

    if (!_isClickable) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handlePressed,
        child: content,
      ),
    );
  }

  Widget _plainText(String value, {bool alignRight = false}) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: AppTheme.tableCell.copyWith(color: AppTheme.textPrimary),
    );
  }

  Widget _linkText(String value, {bool isOthers = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppTheme.tableCell.copyWith(
          color: isOthers ? AppTheme.textPrimary : AppTheme.primaryBlue,
          fontWeight: isOthers ? FontWeight.w400 : FontWeight.w600,
          decoration: !isOthers && _isHovered
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _amountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(
        color: AppTheme.primaryBlue,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

Widget _buildTableRow({
  required Widget vendorName,
  required Widget expenseCount,
  required Widget billCount,
  required Widget vendorCreditCount,
  required Widget journalCount,
  required Widget amount,
  required Widget amountWithTax,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 5, child: vendorName),
      Expanded(flex: 3, child: expenseCount),
      Expanded(flex: 3, child: billCount),
      Expanded(flex: 4, child: vendorCreditCount),
      Expanded(flex: 4, child: journalCount),
      Expanded(flex: 3, child: amount),
      Expanded(flex: 4, child: amountWithTax),
    ],
  );
}

class _PurchasesByVendorComparisonMetrics {
  final int expenseCount;
  final int billCount;
  final int vendorCreditCount;
  final int journalCount;
  final double amount;
  final double amountWithTax;

  const _PurchasesByVendorComparisonMetrics({
    required this.expenseCount,
    required this.billCount,
    required this.vendorCreditCount,
    required this.journalCount,
    required this.amount,
    required this.amountWithTax,
  });

  const _PurchasesByVendorComparisonMetrics.empty()
      : expenseCount = 0,
        billCount = 0,
        vendorCreditCount = 0,
        journalCount = 0,
        amount = 0.0,
        amountWithTax = 0.0;
}

class _PurchasesByVendorFrozenNameRow extends StatefulWidget {
  final PurchasesByVendorRow row;
  final VoidCallback? onTap;

  const _PurchasesByVendorFrozenNameRow({
    required this.row,
    this.onTap,
  });

  @override
  State<_PurchasesByVendorFrozenNameRow> createState() =>
      _PurchasesByVendorFrozenNameRowState();
}

class _PurchasesByVendorFrozenNameRowState
    extends State<_PurchasesByVendorFrozenNameRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isOthers = widget.row.vendorName == 'Others';
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
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
          child: Text(
            widget.row.vendorName,
            style: AppTheme.tableCell.copyWith(
              color: isOthers ? AppTheme.textPrimary : AppTheme.primaryBlue,
              fontWeight: isOthers ? FontWeight.w400 : FontWeight.w600,
              decoration: !isOthers && _isHovered
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _PurchasesByVendorComparisonMetricsRow extends StatefulWidget {
  final List<SalesByCustomerComparisonPeriod> periods;
  final _PurchasesByVendorComparisonMetrics currentMetrics;
  final _PurchasesByVendorComparisonMetrics previousMetrics;
  final List<double> metricWidths;
  final double periodWidth;
  final NumberFormat currencyFormat;
  final VoidCallback? onOpenDetails;
  final bool isTotalRow;

  const _PurchasesByVendorComparisonMetricsRow({
    required this.periods,
    required this.currentMetrics,
    required this.previousMetrics,
    required this.metricWidths,
    required this.periodWidth,
    required this.currencyFormat,
    this.onOpenDetails,
    this.isTotalRow = false,
  });

  @override
  State<_PurchasesByVendorComparisonMetricsRow> createState() =>
      _PurchasesByVendorComparisonMetricsRowState();
}

class _PurchasesByVendorComparisonMetricsRowState
    extends State<_PurchasesByVendorComparisonMetricsRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onOpenDetails == null || widget.isTotalRow
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isTotalRow ? null : widget.onOpenDetails,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.isTotalRow
                ? AppTheme.backgroundColor
                : (_isHovered ? AppTheme.bgHover : AppTheme.backgroundColor),
            border: Border(
              bottom: BorderSide(
                color: widget.isTotalRow ? AppTheme.borderColor : AppTheme.borderColor,
                width: widget.isTotalRow ? 1.0 : 1.0,
              ),
            ),
          ),
          child: Row(
            children: widget.periods.map((period) {
              final metrics = period.isCurrent
                  ? widget.currentMetrics
                  : widget.previousMetrics;

              return SizedBox(
                width: widget.periodWidth,
                child: Row(
                  children: [
                    _cell(
                      widget.metricWidths[0],
                      metrics.expenseCount.toString(),
                      TextAlign.right,
                    ),
                    _cell(
                      widget.metricWidths[1],
                      metrics.billCount.toString(),
                      TextAlign.right,
                    ),
                    _cell(
                      widget.metricWidths[2],
                      metrics.vendorCreditCount.toString(),
                      TextAlign.right,
                    ),
                    _cell(
                      widget.metricWidths[3],
                      metrics.journalCount.toString(),
                      TextAlign.right,
                    ),
                    _cell(
                      widget.metricWidths[4],
                      widget.currencyFormat.format(metrics.amount),
                      TextAlign.right,
                      isAmount: true,
                    ),
                    _cell(
                      widget.metricWidths[5],
                      widget.currencyFormat.format(metrics.amountWithTax),
                      TextAlign.right,
                      isAmount: true,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _cell(double width, String text, TextAlign align, {bool isAmount = false}) {
    final cellStyle = widget.isTotalRow
        ? AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          )
        : AppTheme.tableCell.copyWith(
            color: isAmount && !widget.isTotalRow ? AppTheme.primaryBlue : AppTheme.textPrimary,
            decoration: isAmount && !widget.isTotalRow && _isHovered
                ? TextDecoration.underline
                : TextDecoration.none,
          );

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : (align == TextAlign.center ? Alignment.center : Alignment.centerLeft),
      child: Text(
        text,
        textAlign: align,
        style: cellStyle,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
