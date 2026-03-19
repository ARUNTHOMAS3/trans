import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/shared/widgets/reports/zerpai_report_shell.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';

typedef SalesByCustomerParams = ({String startDate, String endDate});

final salesByCustomerProvider =
    FutureProvider.family<Map<String, dynamic>, SalesByCustomerParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return repo.getSalesByCustomer(params.startDate, params.endDate);
    });

class SalesByCustomerScreen extends ConsumerWidget {
  const SalesByCustomerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);

    final startDate = parsedParams['startDate'] as DateTime;
    final endDate = parsedParams['endDate'] as DateTime;

    final queryParams = (
      startDate: ReportUtils.formatApiDate(startDate),
      endDate: ReportUtils.formatApiDate(endDate),
    );

    final reportAsync = ref.watch(salesByCustomerProvider(queryParams));
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencySymbol = currencyAsync.valueOrNull?.symbol ?? '₹';
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return ZerpaiReportShell(
      reportTitle: 'Sales by Customer',
      startDate: startDate,
      endDate: endDate,
      basis: 'Accrual', // or whatever makes sense
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
                onPressed: () =>
                    ref.invalidate(salesByCustomerProvider(queryParams)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final items = List<Map<String, dynamic>>.from(data['data'] ?? []);

          if (items.isEmpty) {
            return const Center(
              child: Text("No data found for the selected period."),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
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
    double totalSales = 0.0;
    int totalCount = 0;

    for (final item in items) {
      totalSales += (item['totalSales'] as num?)?.toDouble() ?? 0.0;
      totalCount += (item['invoiceCount'] as num?)?.toInt() ?? 0;
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
            totalSales,
            totalCount,
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
              'CUSTOMER NAME',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'INVOICE COUNT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'SALES',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textSecondary,
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
    final amount = (item['totalSales'] as num?)?.toDouble() ?? 0.0;
    final count = (item['invoiceCount'] as num?)?.toInt() ?? 0;
    final customerName = item['customerName'] ?? 'Unknown Customer';

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
                customerName,
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
              count.toString(),
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
            child: Align(
              alignment: Alignment.centerRight,
              child: ZerpaiLinkText(
                text: currencyFormat.format(amount),
                onTap: () {
                  // Currently backend requires accountId, so we pass it if available or customerId as a placeholder.
                  // Ideally, filter Account Transactions by customer/contact ID in the future.
                  final routerState = GoRouterState.of(context);
                  final parsedParams = ReportUtils.parseReportParams(
                    context,
                    routerState,
                  );
                  final startDate = parsedParams['startDate'] as DateTime;
                  final endDate = parsedParams['endDate'] as DateTime;

                  context.pushNamed(
                    AppRoutes.accountantTransactionsReport,
                    queryParameters: {
                      'accountId': item['customerId']?.toString() ?? '',
                      'accountName': customerName,
                      'startDate': ReportUtils.formatApiDate(startDate),
                      'endDate': ReportUtils.formatApiDate(endDate),
                    },
                  );
                },
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
    double totalSales,
    int totalCount,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 2),
          bottom: BorderSide(color: AppTheme.borderColor, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textBody,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              totalCount.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textBody,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currencyFormat.format(totalSales),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textBody,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
