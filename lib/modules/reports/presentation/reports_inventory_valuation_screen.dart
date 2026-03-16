import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/shared/widgets/reports/zerpai_report_shell.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';

final inventoryValuationProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getInventoryValuation();
});

class InventoryValuationScreen extends ConsumerWidget {
  const InventoryValuationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);

    // Inventory valuation doesn't strictly need a date range in this simple form,
    // but we use the shell which expects them. We'll pass them along.
    final startDate = parsedParams['startDate'] as DateTime;
    final endDate = parsedParams['endDate'] as DateTime;

    final reportAsync = ref.watch(inventoryValuationProvider);
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencySymbol = currencyAsync.valueOrNull?.symbol ?? '₹';
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return ZerpaiReportShell(
      reportTitle: 'Inventory Valuation Summary',
      startDate: startDate,
      endDate: endDate,
      basis: 'N/A', // Doesn't apply neatly
      child: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading report: $err',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(inventoryValuationProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = List<Map<String, dynamic>>.from(data['data'] ?? []);

          if (items.isEmpty) {
            return const Center(child: Text("No inventory data found."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildReportTable(context, currencyFormat, items)],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportTable(
    BuildContext context,
    NumberFormat currencyFormat,
    List<Map<String, dynamic>> items,
  ) {
    double totalValue = 0.0;
    int totalQty = 0;

    for (final item in items) {
      totalValue += (item['assetValue'] as num?)?.toDouble() ?? 0.0;
      totalQty += (item['stockOnHand'] as num?)?.toInt() ?? 0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeader(),
          ...items.map((item) => _buildRow(context, item, currencyFormat)),
          _buildTotalRow(
            context,
            'Total',
            totalValue,
            totalQty,
            currencyFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 2),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'ITEM NAME',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'SKU',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'WAREHOUSE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STOCK ON HAND',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'ASSET VALUE',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    Map<String, dynamic> item,
    NumberFormat currencyFormat,
  ) {
    final value = (item['assetValue'] as num?)?.toDouble() ?? 0.0;
    final qty = (item['stockOnHand'] as num?)?.toInt() ?? 0;
    final itemName = item['itemName'] ?? 'Unknown Item';
    final sku = item['sku'] ?? '--';
    final warehouse = item['warehouse'] ?? 'Default';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                itemName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              sku,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              warehouse,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              qty.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currencyFormat.format(value),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    double totalValue,
    int totalQty,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 2),
          bottom: BorderSide(color: AppTheme.borderColor, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4, // 2 (name) + 1 (sku) + 1 (warehouse)
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF374151),
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              totalQty.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF374151),
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currencyFormat.format(totalValue),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF374151),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
