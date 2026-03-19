import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/shared/widgets/reports/zerpai_report_shell.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';

typedef TrialBalanceParams = ({String startDate, String endDate, String basis});

final trialBalanceProvider =
    FutureProvider.family<Map<String, dynamic>, TrialBalanceParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return repo.getTrialBalance(params.startDate, params.endDate);
    });

class TrialBalanceScreen extends ConsumerWidget {
  const TrialBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);

    final startDate = parsedParams['startDate'] as DateTime;
    final endDate = parsedParams['endDate'] as DateTime;
    final basis = parsedParams['basis'] as String;

    final queryParams = (
      startDate: ReportUtils.formatApiDate(startDate),
      endDate: ReportUtils.formatApiDate(endDate),
      basis: basis,
    );

    final reportAsync = ref.watch(trialBalanceProvider(queryParams));
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencySymbol = currencyAsync.valueOrNull?.symbol ?? '₹';
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return ZerpaiReportShell(
      reportTitle: 'Trial Balance',
      startDate: startDate,
      endDate: endDate,
      basis: basis,
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
                    ref.invalidate(trialBalanceProvider(queryParams)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final accounts = List<Map<String, dynamic>>.from(
            data['Accountant'] ?? [],
          );
          final totalDebit = (data['totalDebit'] as num?)?.toDouble() ?? 0.0;
          final totalCredit = (data['totalCredit'] as num?)?.toDouble() ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _buildReportTable(
                context,
                currencyFormat,
                accounts,
                totalDebit,
                totalCredit,
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
    List<Map<String, dynamic>> accounts,
    double totalDebit,
    double totalCredit,
  ) {
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
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No accounts found with a balance for the selected period.',
                ),
              ),
            ),
          ...accounts.map((item) => _buildRow(context, item, currencyFormat)),
          if (accounts.isNotEmpty)
            _buildTotalRow(currencyFormat, totalDebit, totalCredit),
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
        color: AppTheme.bgLight,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'NET DEBIT',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'NET CREDIT',
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
    final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
    final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: ZerpaiLinkText(
              text: item['accountName'] ?? 'Unknown',
              onTap: () {
                final state = GoRouterState.of(context);
                final params = ReportUtils.parseReportParams(context, state);
                final start = ReportUtils.formatApiDate(
                  params['startDate'] as DateTime,
                );
                final end = ReportUtils.formatApiDate(
                  params['endDate'] as DateTime,
                );

                context.goNamed(
                  '/reports/account-transactions',
                  queryParameters: {
                    'accountId': item['accountId']?.toString(),
                    'accountName': item['accountName']?.toString(),
                    'startDate': start,
                    'endDate': end,
                    'basis': params['basis'],
                  },
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              debit > 0 ? currencyFormat.format(debit) : '-',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              credit > 0 ? currencyFormat.format(credit) : '-',
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
    NumberFormat currencyFormat,
    double totalDebit,
    double totalCredit,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            flex: 4,
            child: Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textBody,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(totalDebit),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textBody,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(totalCredit),
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
