import 'package:flutter/material.dart';
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
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:intl/intl.dart';

class OpeningBalancesUpdateScreen extends ConsumerStatefulWidget {
  const OpeningBalancesUpdateScreen({super.key});

  @override
  ConsumerState<OpeningBalancesUpdateScreen> createState() =>
      _OpeningBalancesUpdateScreenState();
}

class _OpeningBalancesUpdateScreenState
    extends ConsumerState<OpeningBalancesUpdateScreen> {
  DateTime _openingDate = DateTime(DateTime.now().year, 4, 1);
  final _openingDateKey = GlobalKey();
  final Map<String, TextEditingController> _debitControllers = {};
  final Map<String, TextEditingController> _creditControllers = {};
  double _totalDebit = 0.0;
  double _totalCredit = 0.0;
  double _difference = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final openingState = ref.read(openingBalanceProvider);
    _openingDate = openingState.openingDate;
  }

  void _initControllers(
    List<AccountNode> leafAccounts,
    OpeningBalanceState openingState,
  ) {
    for (var account in leafAccounts) {
      if (!_debitControllers.containsKey(account.id)) {
        final initialDebit = openingState.debitBalances[account.id] ?? 0.0;
        final initialCredit = openingState.creditBalances[account.id] ?? 0.0;

        _debitControllers[account.id] = TextEditingController(
          text: initialDebit > 0 ? initialDebit.toStringAsFixed(2) : '',
        )..addListener(_calculateTotals);

        _creditControllers[account.id] = TextEditingController(
          text: initialCredit > 0 ? initialCredit.toStringAsFixed(2) : '',
        )..addListener(_calculateTotals);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _debitControllers.values) {
      controller.dispose();
    }
    for (var controller in _creditControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateTotals() {
    double debitSum = 0.0;
    double creditSum = 0.0;
    for (var controller in _debitControllers.values) {
      debitSum += double.tryParse(controller.text) ?? 0.0;
    }
    for (var controller in _creditControllers.values) {
      creditSum += double.tryParse(controller.text) ?? 0.0;
    }
    if (mounted) {
      setState(() {
        _totalDebit = debitSum;
        _totalCredit = creditSum;
        _difference = (debitSum - creditSum).abs();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(chartOfAccountsProvider);
    final openingState = ref.watch(openingBalanceProvider);
    final leafAccounts = _getLeafAccounts(accountsState.roots);

    // Initialize controllers with existing balances safely
    _initControllers(leafAccounts, openingState);

    // Refresh totals on first build after controller init
    if (_totalDebit == 0 && _totalCredit == 0 && leafAccounts.isNotEmpty) {
      Future.microtask(() => _calculateTotals());
    }

    return ZerpaiLayout(
      pageTitle: 'Update Opening Balances',
      enableBodyScroll: false,
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: leafAccounts.isEmpty
                ? accountsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
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
                              'Ensure you have leaf accounts in your Chart of Accounts.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                : _buildEditTable(leafAccounts),
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

  Widget _buildToolbar() {
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
          InkWell(
            key: _openingDateKey,
            onTap: () async {
              final picked = await ZerpaiDatePicker.show(
                context,
                initialDate: _openingDate,
                targetKey: _openingDateKey,
              );
              if (picked != null) {
                setState(() => _openingDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(_openingDate),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTable(List<AccountNode> accounts) {
    return Container(
      margin: const EdgeInsets.all(24),
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
              itemBuilder: (context, index) => _buildEditRow(accounts[index]),
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

  Widget _buildEditRow(AccountNode account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CustomTextField(
                controller: _debitControllers[account.id]!,
                textAlign: TextAlign.right,
                hintText: '0.00',
                keyboardType: TextInputType.number,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CustomTextField(
                controller: _creditControllers[account.id]!,
                textAlign: TextAlign.right,
                hintText: '0.00',
                keyboardType: TextInputType.number,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Difference: ₹ ${NumberFormat('#,##,##0.00').format(_difference)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _difference == 0
                      ? AppTheme.accentGreen
                      : AppTheme.errorRed,
                ),
              ),
              Text(
                'Total Debit: ₹ ${NumberFormat('#,##,##0.00').format(_totalDebit)} | Total Credit: ₹ ${NumberFormat('#,##,##0.00').format(_totalCredit)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () => context.go(AppRoutes.accountantOpeningBalances),
          ),
          const SizedBox(width: 12),
          ZButton.primary(
            label: 'Save Opening Balances',
            loading: _isSaving,
            onPressed: _handleSave,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_difference != 0) {
      ZerpaiToast.error(context, 'Total Debits and Credits must be equal.');
      return;
    }

    setState(() => _isSaving = true);

    // Create maps to save
    final Map<String, double> debits = {};
    final Map<String, double> credits = {};
    _debitControllers.forEach(
      (id, ctrl) => debits[id] = double.tryParse(ctrl.text) ?? 0.0,
    );
    _creditControllers.forEach(
      (id, ctrl) => credits[id] = double.tryParse(ctrl.text) ?? 0.0,
    );

    // Save to provider and sync to backend
    try {
      final notifier = ref.read(openingBalanceProvider.notifier);
      notifier.updateBalances(
        debitBalances: debits,
        creditBalances: credits,
        openingDate: _openingDate,
      );

      await notifier.saveBalances();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ZerpaiToast.error(context, 'Failed to save opening balances: $e');
      }
      return;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ZerpaiToast.saved(context, 'Opening balances');
      context.go(AppRoutes.accountantOpeningBalances);
    }
  }
}
