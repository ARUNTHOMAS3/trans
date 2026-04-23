import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/shared/widgets/reports/zerpai_report_shell.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';

typedef PnlParams = ({String startDate, String endDate, String basis});

final pnlProvider = FutureProvider.family<Map<String, dynamic>, PnlParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getProfitAndLoss(params.startDate, params.endDate);
});

class ProfitAndLossScreen extends ConsumerWidget {
  const ProfitAndLossScreen({super.key});

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

    final reportAsync = ref.watch(pnlProvider(queryParams));
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencySymbol = currencyAsync.valueOrNull?.symbol ?? '₹';
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return ZerpaiReportShell(
      reportTitle: 'Profit and Loss',
      startDate: startDate,
      endDate: endDate,
      basis: basis,
      child: reportAsync.when(
        loading: () => Skeletonizer(
          enabled: true,
          ignoreContainers: true,
          child: _buildPnlScrollView(context, currencyFormat,
            report: {
              'operatingIncome': [
                {'accountName': '—————————————', 'netAmount': 0},
                {'accountName': '———————————', 'netAmount': 0},
              ],
              'costOfGoodsSold': [
                {'accountName': '—————————————', 'netAmount': 0},
              ],
              'operatingExpenses': [
                {'accountName': '—————————————', 'netAmount': 0},
                {'accountName': '———————', 'netAmount': 0},
              ],
            },
            summary: {
              'totalIncome': 0,
              'totalCogs': 0,
              'grossProfit': 0,
              'totalExpenses': 0,
              'netProfit': 0,
            },
          ),
        ),
        error: (err, stack) => _buildPnlScrollView(
          context,
          currencyFormat,
          report: const {
            'operatingIncome': <Map<String, dynamic>>[],
            'costOfGoodsSold': <Map<String, dynamic>>[],
            'operatingExpenses': <Map<String, dynamic>>[],
          },
          summary: const {
            'totalIncome': 0,
            'totalCogs': 0,
            'grossProfit': 0,
            'totalExpenses': 0,
            'netProfit': 0,
          },
        ),
        data: (data) => _buildPnlScrollView(
          context,
          currencyFormat,
          report: data['report'] as Map<String, dynamic>,
          summary: data['summary'] as Map<String, dynamic>,
        ),
      ),
    );
  }

  Widget _buildPnlScrollView(
    BuildContext context,
    NumberFormat currencyFormat, {
    required Map<String, dynamic> report,
    required Map<String, dynamic> summary,
  }) {
    final operatingIncome = List<Map<String, dynamic>>.from(
      report['operatingIncome'] ?? [],
    );
    final costOfGoodsSold = List<Map<String, dynamic>>.from(
      report['costOfGoodsSold'] ?? [],
    );
    final operatingExpenses = List<Map<String, dynamic>>.from(
      report['operatingExpenses'] ?? [],
    );

    // Flatten all P&L content into a single list for SliverList.
    final contentRows = <Widget>[
      _buildSectionHeader('Operating Income'),
      ...operatingIncome.map(
        (item) => _buildAccountRow(context, item, currencyFormat),
      ),
      _buildTotalRow(
        context,
        'Total Operating Income',
        summary['totalIncome'],
        currencyFormat,
        isGroupTotal: true,
        groupName: 'Operating Income',
      ),
      _buildSectionHeader('Cost of Goods Sold'),
      ...costOfGoodsSold.map(
        (item) => _buildAccountRow(context, item, currencyFormat),
      ),
      _buildTotalRow(
        context,
        'Total Cost of Goods Sold',
        summary['totalCogs'],
        currencyFormat,
        isGroupTotal: true,
        groupName: 'Cost of Goods Sold',
      ),
      _buildTotalRow(
        context,
        'Gross Profit',
        summary['grossProfit'],
        currencyFormat,
        isMainTotal: true,
      ),
      _buildSectionHeader('Operating Expenses'),
      ...operatingExpenses.map(
        (item) => _buildAccountRow(context, item, currencyFormat),
      ),
      _buildTotalRow(
        context,
        'Total Operating Expenses',
        summary['totalExpenses'],
        currencyFormat,
        isGroupTotal: true,
        groupName: 'Operating Expenses',
      ),
      _buildTotalRow(
        context,
        'Net Profit/(Loss)',
        summary['netProfit'],
        currencyFormat,
        isMainTotal: true,
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            // Sticky column-header row (ACCOUNT | TOTAL)
            SliverPersistentHeader(
              pinned: true,
              delegate: _PnlTableHeaderDelegate(),
            ),
            SliverList(
              delegate: SliverChildListDelegate(contentRows),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppTheme.textBody, // Zoho Slate
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildAccountRow(
    BuildContext context,
    Map<String, dynamic> item,
    NumberFormat currencyFormat,
  ) {
    final amount = (item['netAmount'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              item['accountName'] ?? 'Unknown Account',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    dynamic amountDyn,
    NumberFormat currencyFormat, {
    bool isGroupTotal = false,
    bool isMainTotal = false,
    String? groupName,
  }) {
    final amount = (amountDyn as num?)?.toDouble() ?? 0.0;

    Widget labelWidget;
    if (isGroupTotal && groupName != null) {
      labelWidget = ZerpaiLinkText(
        text: label,
        onTap: () {
          final state = GoRouterState.of(context);
          final params = ReportUtils.parseReportParams(context, state);
          final start = ReportUtils.formatApiDate(
            params['startDate'] as DateTime,
          );
          final end = ReportUtils.formatApiDate(params['endDate'] as DateTime);

          context.goNamed(
            '/reports/general-ledger',
            queryParameters: {
              'group': groupName,
              'startDate': start,
              'endDate': end,
              'basis': params['basis'],
            },
          );
        },
        style: TextStyle(
          fontWeight: isMainTotal ? FontWeight.bold : FontWeight.w600,
          fontSize: isMainTotal ? 16 : 14,
        ),
      );
    } else {
      labelWidget = Text(
        label,
        style: TextStyle(
          fontWeight: isMainTotal ? FontWeight.bold : FontWeight.w600,
          fontSize: isMainTotal ? 16 : 14,
          color: AppTheme.textBody,
          fontFamily: 'Inter',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isMainTotal ? AppTheme.bgLight : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor,
            width: isMainTotal ? 2 : 1,
          ),
          bottom: isMainTotal
              ? const BorderSide(color: AppTheme.borderColor, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          labelWidget,
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: isMainTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isMainTotal ? 16 : 14,
              color: AppTheme.textBody,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate for the sticky P&L column headers.
class _PnlTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 48.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_PnlTableHeaderDelegate _) => false;

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
        color: AppTheme.bgLight,
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
          Text(
            'ACCOUNT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'TOTAL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
