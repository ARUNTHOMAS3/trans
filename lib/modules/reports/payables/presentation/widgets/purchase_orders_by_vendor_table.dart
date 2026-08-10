import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class PurchaseOrdersByVendorTable extends StatelessWidget {
  final List<PurchaseOrdersByVendorGroup> groups;
  final PurchaseOrdersByVendorTotals totals;
  final NumberFormat currencyFormat;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const PurchaseOrdersByVendorTable({
    super.key,
    required this.groups,
    required this.totals,
    required this.currencyFormat,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ReportStickyHeaderScrollTable(
      header: _buildHeader(),
      emptyBody: const SizedBox.shrink(),
      children: [
        if (groups.isEmpty)
          const ReportTableEmptyBody(
            minHeight: 300,
            message: 'No data to display',
          )
        else ...[
          for (final group in groups)
            _VendorSummaryRow(group: group, currencyFormat: currencyFormat),
          _TotalRow(totals: totals, currencyFormat: currencyFormat),
        ],
        if (totalCount > pageSize)
          ReportPaginationFooter(
            totalCount: totalCount,
            page: page,
            pageSize: pageSize,
            onPageChanged: onPageChanged,
          ),
        const SizedBox(height: AppTheme.space28),
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
        purchaseOrderCount: Text(
          'PURCHASE ORDER COUNT',
          textAlign: TextAlign.center,
          style: ReportTableTypography.header,
        ),
        amount: Text(
          'AMOUNT',
          textAlign: TextAlign.right,
          style: ReportTableTypography.header,
        ),
      ),
    );
  }
}

class _VendorSummaryRow extends StatefulWidget {
  final PurchaseOrdersByVendorGroup group;
  final NumberFormat currencyFormat;

  const _VendorSummaryRow({required this.group, required this.currencyFormat});

  @override
  State<_VendorSummaryRow> createState() => _VendorSummaryRowState();
}

class _VendorSummaryRowState extends State<_VendorSummaryRow> {
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: _buildTableRow(
          vendorName: _linkText(
            widget.group.vendorName,
            align: TextAlign.left,
            isUnderlined: _isHovered,
          ),
          purchaseOrderCount: _linkText(
            widget.group.purchaseOrderCount.toString(),
            align: TextAlign.center,
            isUnderlined: _isHovered,
          ),
          amount: _linkText(
            widget.currencyFormat.format(widget.group.grandTotal),
            align: TextAlign.right,
            isUnderlined: _isHovered,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final PurchaseOrdersByVendorTotals totals;
  final NumberFormat currencyFormat;

  const _TotalRow({required this.totals, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildTableRow(
        vendorName: _totalText('Total', align: TextAlign.left),
        purchaseOrderCount: _totalText(
          totals.purchaseOrderCount.toString(),
          align: TextAlign.center,
        ),
        amount: _totalText(
          currencyFormat.format(totals.grandTotal),
          align: TextAlign.right,
        ),
      ),
    );
  }
}

Widget _buildTableRow({
  required Widget vendorName,
  required Widget purchaseOrderCount,
  required Widget amount,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(flex: 5, child: vendorName),
      Expanded(flex: 3, child: purchaseOrderCount),
      Expanded(flex: 3, child: amount),
    ],
  );
}

Widget _linkText(
  String value, {
  required TextAlign align,
  required bool isUnderlined,
}) {
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
    ),
  );
}

Widget _totalText(String value, {required TextAlign align}) {
  return Text(
    value,
    overflow: TextOverflow.ellipsis,
    textAlign: align,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
    ),
  );
}

class PurchaseOrdersByVendorGroup {
  final String vendorId;
  final String vendorName;
  final int purchaseOrderCount;
  final double grandTotal;

  const PurchaseOrdersByVendorGroup({
    required this.vendorId,
    required this.vendorName,
    required this.purchaseOrderCount,
    required this.grandTotal,
  });

  static List<PurchaseOrdersByVendorGroup> fromResponse(
    Map<String, dynamic>? response,
  ) {
    final rawGroups = response?['groups'] ?? response?['rows'];
    if (rawGroups is! List) return const <PurchaseOrdersByVendorGroup>[];
    return rawGroups
        .whereType<Map>()
        .map(
          (raw) => PurchaseOrdersByVendorGroup.fromJson(
            Map<String, dynamic>.from(raw),
          ),
        )
        .toList(growable: false);
  }

  factory PurchaseOrdersByVendorGroup.fromJson(Map<String, dynamic> json) {
    final totals = Map<String, dynamic>.from(
      json['totals'] as Map? ?? const <String, dynamic>{},
    );
    return PurchaseOrdersByVendorGroup(
      vendorId: _stringValue(json['vendorId']),
      vendorName: _stringValue(json['vendorName'], fallback: 'Others'),
      purchaseOrderCount: _intValue(json['purchaseOrderCount']),
      grandTotal: _doubleValue(totals['grandTotal']),
    );
  }
}

class PurchaseOrdersByVendorTotals {
  final int purchaseOrderCount;
  final double grandTotal;

  const PurchaseOrdersByVendorTotals({
    required this.purchaseOrderCount,
    required this.grandTotal,
  });

  factory PurchaseOrdersByVendorTotals.fromResponse(
    Map<String, dynamic>? response,
  ) {
    final totals = Map<String, dynamic>.from(
      response?['totals'] as Map? ?? const <String, dynamic>{},
    );
    return PurchaseOrdersByVendorTotals(
      purchaseOrderCount: _intValue(totals['purchaseOrderCount']),
      grandTotal: _doubleValue(totals['grandTotal']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
