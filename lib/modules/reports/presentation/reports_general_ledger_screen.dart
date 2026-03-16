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

typedef GlParams = ({String startDate, String endDate, String basis});

final glProvider = FutureProvider.family<Map<String, dynamic>, GlParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getGeneralLedger(params.startDate, params.endDate);
});

class GeneralLedgerScreen extends ConsumerWidget {
  const GeneralLedgerScreen({super.key});

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

    final reportAsync = ref.watch(glProvider(queryParams));
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencySymbol = currencyAsync.valueOrNull?.symbol ?? '₹';
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return ZerpaiReportShell(
      reportTitle: 'General Ledger',
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
                onPressed: () => ref.invalidate(glProvider(queryParams)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final accounts = List<Map<String, dynamic>>.from(
            data['Accountant'] ?? [],
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  // Sticky column-header row
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _GlTableHeaderDelegate(),
                  ),
                  // Data rows
                  if (accounts.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No transactions found for the selected period.',
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) =>
                            _buildRow(ctx, accounts[i], currencyFormat),
                        childCount: accounts.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          );
        },
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
            flex: 3,
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
              item['accountCode']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
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
}

/// SliverPersistentHeaderDelegate for the sticky GL column headers.
class _GlTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 48.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_GlTableHeaderDelegate _) => false;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor, width: 2),
        ),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ACCOUNT CODE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
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
                fontSize: 12,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
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
                fontSize: 12,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
