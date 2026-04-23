import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accountant/providers/opening_balance_provider.dart';
import 'package:intl/intl.dart';

class OpeningBalancesScreen extends ConsumerStatefulWidget {
  const OpeningBalancesScreen({super.key});

  @override
  ConsumerState<OpeningBalancesScreen> createState() =>
      _OpeningBalancesScreenState();
}

class _OpeningBalancesScreenState extends ConsumerState<OpeningBalancesScreen> {
  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(chartOfAccountsProvider);
    final openingState = ref.watch(openingBalanceProvider);

    // Flatten and take only non-parent accounts (leaves)
    final leafAccounts = _getLeafAccounts(accountsState.roots);

    return ZerpaiLayout(
      pageTitle: 'Opening Balances',
      enableBodyScroll: false,
      child: Column(
        children: [
          _buildToolbar(openingState.openingDate),
          _buildInfoBanner(),
          Expanded(
            child: leafAccounts.isEmpty
                ? accountsState.isLoading
                      ? Skeletonizer(
                          enabled: true,
                          ignoreContainers: true,
                          child: ListView.builder(
                            itemCount: 10,
                            itemBuilder: (_, __) => const ListTile(
                              title: Text('Account name placeholder'),
                              trailing: SizedBox(width: 120, height: 36),
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.list,
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No leaf accounts found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Finalize your Chart of Accounts to see leaf accounts here.',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 24),
                              ZButton.secondary(
                                label: 'Go to Chart of Accounts',
                                onPressed: () => context.go(
                                  AppRoutes.accountsChartOfAccounts,
                                ),
                              ),
                            ],
                          ),
                        )
                : _buildBalancesTable(leafAccounts),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  List<AccountNode> _getLeafAccounts(List<AccountNode> nodes) {
    List<AccountNode> leaves = [];
    void traverse(List<AccountNode> children) {
      for (var node in children) {
        if (node.children.isEmpty) {
          leaves.add(node);
        } else {
          traverse(node.children);
        }
      }
    }

    traverse(nodes);
    return leaves;
  }

  Widget _buildToolbar(DateTime openingDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const Text(
            'Opening Balance Date:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('dd MMM yyyy').format(openingDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Spacer(),
          ZButton.primary(
            label: 'Update Opening Balances',
            onPressed: () =>
                context.go(AppRoutes.accountsOpeningBalancesUpdate),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Opening balances are the amounts your business has in its accounts before you start tracking with Zerpai ERP. These are typically the balances from the last day of your previous financial year.',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesTable(List<AccountNode> accounts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, index) {
                final account = accounts[index];
                final debit = ref
                    .read(openingBalanceProvider.notifier)
                    .getDebit(account.id);
                final credit = ref
                    .read(openingBalanceProvider.notifier)
                    .getCredit(account.id);
                return _buildTableRow(account, debit, credit);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'DEBIT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'CREDIT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(AccountNode account, double debit, double credit) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', locale: 'en_IN');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.userAccountName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  account.accountGroup,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currencyFormat.format(debit),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currencyFormat.format(credit),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final openingState = ref.watch(openingBalanceProvider);
    double totalDebit = 0;
    double totalCredit = 0;
    openingState.debitBalances.forEach((_, v) => totalDebit += v);
    openingState.creditBalances.forEach((_, v) => totalCredit += v);
    final diff = (totalDebit - totalCredit).abs();
    final currencyFormat = NumberFormat.currency(symbol: '₹', locale: 'en_IN');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Difference: ${currencyFormat.format(diff)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: diff == 0 ? AppTheme.accentGreen : AppTheme.errorRed,
                ),
              ),
              Text(
                'Total Debit: ${currencyFormat.format(totalDebit)} | Total Credit: ${currencyFormat.format(totalCredit)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
