import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/shared/widgets/reports/zerpai_report_shell.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';

typedef AccountTransactionsParams = ({
  String accountId,
  String startDate,
  String endDate,
  String basis,
  String? contactId,
  String? contactType,
});

final accountTransactionsProvider =
    FutureProvider.family<Map<String, dynamic>, AccountTransactionsParams>((
      ref,
      params,
    ) async {
      if (params.accountId.isEmpty) return {};

      final repo = ref.watch(reportsRepositoryProvider);
      return repo.getAccountTransactions(
        params.accountId,
        params.startDate,
        params.endDate,
        contactId: params.contactId,
        contactType: params.contactType,
      );
    });

class AccountTransactionsReportPage extends ConsumerWidget {
  final String? accountId;
  final String? accountName;

  const AccountTransactionsReportPage({
    super.key,
    this.accountId,
    this.accountName,
  });

  String _formatTransactionType(String? rawType) {
    final value = (rawType ?? '').trim();
    if (value.isEmpty) return '--';
    final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);

    final startDate = parsedParams['startDate'] as DateTime;
    final endDate = parsedParams['endDate'] as DateTime;
    final basis = parsedParams['basis'] as String;

    final queryParams = (
      accountId: accountId ?? '',
      startDate: ReportUtils.formatApiDate(startDate),
      endDate: ReportUtils.formatApiDate(endDate),
      basis: basis,
      contactId: routerState.uri.queryParameters['contactId'],
      contactType: routerState.uri.queryParameters['contactType'],
    );

    final reportAsync = ref.watch(accountTransactionsProvider(queryParams));
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencySymbol = currencyAsync.valueOrNull?.symbol ?? '₹';
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    final orgDatePattern = ref.watch(orgDateFormatProvider);
    final dateFormat = DateFormat(orgDatePattern);

    final title = accountName != null && accountName!.isNotEmpty
        ? 'Account Transactions ($accountName)'
        : 'Account Transactions';

    return ZerpaiReportShell(
      reportTitle: title,
      startDate: startDate,
      endDate: endDate,
      basis: basis,
      child: queryParams.accountId.isEmpty && queryParams.contactId == null
          ? const Center(
              child: Text(
                'No account or contact selected. Please select one from the General Ledger or Journal Detail.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : reportAsync.when(
              loading: () => Skeletonizer(
                enabled: true,
                ignoreContainers: true,
                child: _buildAccountTxContent(context, currencyFormat, dateFormat,
                  startDate: startDate,
                  endDate: endDate,
                  transactions: [
                    {'date': null, 'details': '—————————————', 'type': '————', 'reference': '——————', 'debit': 0, 'credit': 0, 'runningBalance': 0},
                    {'date': null, 'details': '———————————', 'type': '————', 'reference': '——————', 'debit': 0, 'credit': 0, 'runningBalance': 0},
                    {'date': null, 'details': '————————————', 'type': '————', 'reference': '——————', 'debit': 0, 'credit': 0, 'runningBalance': 0},
                    {'date': null, 'details': '——————————', 'type': '————', 'reference': '——————', 'debit': 0, 'credit': 0, 'runningBalance': 0},
                    {'date': null, 'details': '————————', 'type': '————', 'reference': '——————', 'debit': 0, 'credit': 0, 'runningBalance': 0},
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading report: $err',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                        accountTransactionsProvider(queryParams),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (data) => _buildAccountTxContent(
                context, currencyFormat, dateFormat,
                startDate: startDate,
                endDate: endDate,
                transactions: List<Map<String, dynamic>>.from(
                  data['transactions'] ?? [],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountTxContent(
    BuildContext context,
    NumberFormat currencyFormat,
    DateFormat dateFormat, {
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> transactions,
  }) {
    final totals = _computeTotals(transactions);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryStrip(
              currencyFormat: currencyFormat,
              transactionCount: transactions.length,
              totalDebit: totals.$1,
              totalCredit: totals.$2,
              closingBalance: totals.$3,
            ),
            const SizedBox(height: 16),
            _buildReportTable(
              context,
              currencyFormat,
              dateFormat,
              transactions,
              startDate: startDate,
              endDate: endDate,
            ),
          ],
        ),
      ),
    );
  }

  (double, double, double) _computeTotals(List<Map<String, dynamic>> transactions) {
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    double closingBalance = 0.0;

    for (final tx in transactions) {
      totalDebit += (tx['debit'] as num?)?.toDouble() ?? 0.0;
      totalCredit += (tx['credit'] as num?)?.toDouble() ?? 0.0;
    }
    if (transactions.isNotEmpty) {
      closingBalance =
          (transactions.first['runningBalance'] as num?)?.toDouble() ?? 0.0;
    }

    return (totalDebit, totalCredit, closingBalance);
  }

  Widget _buildSummaryStrip({
    required NumberFormat currencyFormat,
    required int transactionCount,
    required double totalDebit,
    required double totalCredit,
    required double closingBalance,
  }) {
    Widget statCard(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final closingLabel = closingBalance >= 0 ? 'Dr' : 'Cr';

    return Row(
      children: [
        statCard('Entries', transactionCount.toString()),
        const SizedBox(width: 12),
        statCard('Total Debit', currencyFormat.format(totalDebit)),
        const SizedBox(width: 12),
        statCard('Total Credit', currencyFormat.format(totalCredit)),
        const SizedBox(width: 12),
        statCard(
          'Closing Balance',
          '${currencyFormat.format(closingBalance.abs())} $closingLabel',
        ),
      ],
    );
  }

  Widget _buildReportTable(
    BuildContext context,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    List<Map<String, dynamic>> transactions,
    {
    required DateTime startDate,
    required DateTime endDate,
    }
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
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 34,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No transactions found for the selected period.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try widening the date range (currently ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}).',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...transactions.map(
            (t) => _buildRow(context, t, currencyFormat, dateFormat),
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
        color: AppTheme.bgLight,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: _Th('DATE')),
          Expanded(flex: 3, child: _Th('DETAILS')),
          Expanded(flex: 2, child: _Th('TYPE')),
          Expanded(flex: 2, child: _Th('REFERENCE')),
          Expanded(flex: 2, child: _Th('DEBIT', align: TextAlign.right)),
          Expanded(flex: 2, child: _Th('CREDIT', align: TextAlign.right)),
          Expanded(flex: 2, child: _Th('RUNNING BAL', align: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    Map<String, dynamic> item,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final dateStr = item['date']?.toString();
    final dateObj = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final formattedDate = dateObj != null ? dateFormat.format(dateObj) : '';

    final debit = (item['debit'] as num?)?.toDouble() ?? 0.0;
    final credit = (item['credit'] as num?)?.toDouble() ?? 0.0;
    final runningBalance = (item['runningBalance'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: _Td(formattedDate)),
          Expanded(flex: 3, child: _Td(item['details']?.toString() ?? '--')),
          Expanded(
            flex: 2,
            child: _Td(_formatTransactionType(item['type']?.toString())),
          ),
          Expanded(
            flex: 2,
            child: ZerpaiLinkText(
              text: item['reference']?.toString() ?? '--',
              onTap: () {
                // Future Implementation: Jump to source transaction based on item['sourceType'] and item['sourceId']
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: _Td(
              debit > 0 ? currencyFormat.format(debit) : '-',
              align: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: _Td(
              credit > 0 ? currencyFormat.format(credit) : '-',
              align: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: _Td(
              currencyFormat.format(runningBalance.abs()) +
                  (runningBalance >= 0 ? ' Dr' : ' Cr'),
              align: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _Th(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: AppTheme.textSecondary,
        fontFamily: 'Inter',
      ),
    );
  }
}

class _Td extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _Td(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textPrimary,
        fontFamily: 'Inter',
      ),
    );
  }
}
