import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/accountant/models/account_transaction_model.dart';
import 'package:zerpai_erp/modules/accountant/repositories/accountant_repository.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart'
    as coa;
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/providers/manual_journal_provider.dart';

typedef TransactionFilterCallback =
    void Function({
      String? accountId,
      String? contactId,
      DateTime? startDate,
      DateTime? endDate,
      double? minAmount,
      double? maxAmount,
    });

class AccountantBulkUpdateScreen extends ConsumerStatefulWidget {
  const AccountantBulkUpdateScreen({super.key});

  @override
  ConsumerState<AccountantBulkUpdateScreen> createState() =>
      _AccountantBulkUpdateScreenState();
}

class _AccountantBulkUpdateScreenState
    extends ConsumerState<AccountantBulkUpdateScreen> {
  bool _hasSearched = false;
  bool _isLoading = false;
  List<AccountTransaction> _transactions = [];
  List<String> _selectedTransactions = [];
  String? _targetAccountId;

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterTransactionsDialog(onSearch: _performSearch),
    );
  }

  Future<void> _performSearch({
    String? accountId,
    String? contactId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(accountantRepositoryProvider);
      final results = await repository.searchTransactions(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );
      setState(() {
        _transactions = results;
        _hasSearched = true;
        _isLoading = false;
        _selectedTransactions = [];
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ZerpaiToast.error(context, 'Search failed: $e');
    }
  }

  Future<void> _updateTransactions() async {
    if (_targetAccountId == null || _selectedTransactions.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(accountantRepositoryProvider);
      await repository.bulkUpdateTransactions(
        transactionIds: _selectedTransactions,
        targetAccountId: _targetAccountId!,
      );

      if (mounted) {
        ZerpaiToast.success(
          context,
          'Updated ${_selectedTransactions.length} transactions successfully!',
        );
      }

      setState(() {
        _isLoading = false;
        // Remove updated transactions from local view
        _transactions.removeWhere((t) => _selectedTransactions.contains(t.id));
        _selectedTransactions = [];
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ZerpaiToast.error(context, 'Update failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Bulk Update',
      isDirty: _selectedTransactions.isNotEmpty,
      child: Stack(
        children: [
          _hasSearched ? _buildResultsView() : _buildEmptyState(),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Illustration ---
            Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F0FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      LucideIcons.folder,
                      size: 80,
                      color: Color(0xFF9333EA),
                    ),
                    Positioned(
                      top: 45,
                      child: Container(
                        width: 30,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              width: 18,
                              height: 2,
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Heading ---
            const Text(
              'Bulk Update Accounts in Transactions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // --- Sub-heading ---
            const Text(
              'Filter transactions (Invoices, Credit Notes, Purchase Orders, Expenses, Bills, Vendor Credits) and bulk-update its accounts with a new account',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // --- Warning Box ---
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFCD34D)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bulk-updating accounts in transactions will cause significant changes to the financial data of your business. We recommend that you do this with the assistance of an accountant.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.warningTextDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Action Button ---
            Tooltip(
              message: 'Open search filters to locate transactions',
              child: ZButton.primary(
                label: 'Filter and Bulk Update',
                onPressed: _showFilterDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final accountsState = ref.watch(chartOfAccountsProvider);

    return Column(
      children: [
        // --- Toolbar ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              Text(
                '${_transactions.length} Transactions Found',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Tooltip(
                message: 'Remove all current search results',
                child: ZButton.secondary(
                  label: 'Clear Results',
                  onPressed: () => setState(() {
                    _hasSearched = false;
                    _transactions = [];
                    _selectedTransactions.clear();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Refine transaction filter criteria',
                child: ZButton.primary(
                  label: 'New Search',
                  onPressed: _showFilterDialog,
                ),
              ),
            ],
          ),
        ),

        // --- Results Table ---
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Reference#')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Account')),
                  DataColumn(label: Text('Amount')),
                ],
                rows: _transactions.map((t) {
                  final isSelected = _selectedTransactions.contains(t.id);
                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedTransactions.add(t.id);
                        } else {
                          _selectedTransactions.remove(t.id);
                        }
                      });
                    },
                    cells: [
                      DataCell(
                        Text(
                          DateFormat('dd/MM/yyyy').format(t.transactionDate),
                        ),
                      ),
                      DataCell(
                        Text(
                          t.referenceNumber ?? '-',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(Text(t.transactionType ?? '-')),
                      DataCell(Text(t.accountName ?? '-')),
                      DataCell(
                        Text(
                          NumberFormat.currency(symbol: '₹').format(t.amount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // --- Bulk Action Footer ---
        if (_selectedTransactions.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '${_selectedTransactions.length} Items Selected',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Update to Account:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 300,
                  child: AccountTreeDropdown(
                    value: _targetAccountId,
                    nodes: _mapNodes(accountsState.roots),
                    hint: 'Select target account',
                    onSearch: (q) async {
                      final results = await ref
                          .read(accountantRepositoryProvider)
                          .searchAccounts(q);
                      return results
                          .map(
                            (e) => shared.AccountNode(
                              id: e.id,
                              name: e.name,
                              children: e.children
                                  .map(
                                    (c) => shared.AccountNode(
                                      id: c.id,
                                      name: c.name,
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                          .toList();
                    },
                    onChanged: (v) => setState(() => _targetAccountId = v),
                  ),
                ),
                const SizedBox(width: 16),
                Tooltip(
                  message:
                      'Permanently update all selected transactions to the target account',
                  child: ZButton.primary(
                    label: 'Update Transactions',
                    onPressed: _targetAccountId == null
                        ? null
                        : _updateTransactions,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<shared.AccountNode> _mapNodes(List<coa.AccountNode> roots) {
    if (roots.isEmpty) return [];

    shared.AccountNode mapWithChildren(coa.AccountNode n) {
      return shared.AccountNode(
        id: n.id,
        name: n.name,
        selectable: true,
        children: n.children.map((c) => mapWithChildren(c)).toList(),
      );
    }

    final Map<String, List<shared.AccountNode>> grouped = {};
    for (final root in roots) {
      final type = root.accountType;
      grouped.putIfAbsent(type, () => []).add(mapWithChildren(root));
    }

    final sortedTypes = grouped.keys.toList()..sort();
    return sortedTypes.map((type) {
      return shared.AccountNode(
        id: 'header_$type',
        name: type.toUpperCase(),
        selectable: false,
        children: grouped[type]!,
      );
    }).toList();
  }
}

class _FilterTransactionsDialog extends ConsumerStatefulWidget {
  final TransactionFilterCallback onSearch;
  const _FilterTransactionsDialog({required this.onSearch});

  @override
  ConsumerState<_FilterTransactionsDialog> createState() =>
      _FilterTransactionsDialogState();
}

class _FilterTransactionsDialogState
    extends ConsumerState<_FilterTransactionsDialog> {
  String? _selectedAccountId;
  String? _selectedContactId;
  final _startDateKey = GlobalKey();
  final _endDateKey = GlobalKey();
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDateController.text = 'dd/MM/yyyy';
    _endDateController.text = 'dd/MM/yyyy';
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await ZerpaiDatePicker.show(
      context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      targetKey: isStart ? _startDateKey : _endDateKey,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  List<shared.AccountNode> _mapNodes(List<coa.AccountNode> roots) {
    if (roots.isEmpty) return [];

    // 1. Helper for recursive mapping
    shared.AccountNode mapWithChildren(coa.AccountNode n) {
      return shared.AccountNode(
        id: n.id,
        name: n.name,
        selectable: true,
        children: n.children.map((c) => mapWithChildren(c)).toList(),
      );
    }

    // 2. Group roots by account type
    final Map<String, List<shared.AccountNode>> grouped = {};
    for (final root in roots) {
      final type = root.accountType;
      grouped.putIfAbsent(type, () => []).add(mapWithChildren(root));
    }

    // 3. Sort types and build final list
    final sortedTypes = grouped.keys.toList()..sort();
    return sortedTypes.map((type) {
      return shared.AccountNode(
        id: 'header_$type',
        name: type.toUpperCase(),
        selectable: false,
        children: grouped[type]!,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(chartOfAccountsProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // --- Form ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select an account and enter your ranges to filter your transaction',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSubtle),
                  ),
                  const SizedBox(height: 24),

                  // --- Account Dropdown ---
                  SharedFieldLayout(
                    label: 'Account',
                    required: true,
                    tooltip:
                        'Only transactions with this specific account will be filtered for bulk update',
                    child: AccountTreeDropdown(
                      value: _selectedAccountId,
                      nodes: _mapNodes(accountsState.roots),
                      hint: 'Select an account',
                      onSearch: (q) async {
                        final results = await ref
                            .read(accountantRepositoryProvider)
                            .searchAccounts(q);
                        return results
                            .map(
                              (e) => shared.AccountNode(
                                id: e.id,
                                name: e.name,
                                children: e.children
                                    .map(
                                      (c) => shared.AccountNode(
                                        id: c.id,
                                        name: c.name,
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                            .toList();
                      },
                      onChanged: (v) => setState(() => _selectedAccountId = v),
                    ),
                  ),

                  // --- Contact Dropdown ---
                  SharedFieldLayout(
                    label: 'Contact',
                    tooltip:
                        'Optionally filter transactions assigned to a specific customer or vendor',
                    child: FormDropdown<Map<String, dynamic>>(
                      value: _selectedContactId != null
                          ? {
                              'id': _selectedContactId,
                              'displayName': _selectedContactId,
                            }
                          : null,
                      items: const [],
                      hint: 'Select Contact',
                      showSearch: true,
                      displayStringForValue: (c) =>
                          (c['displayName'] ?? c['display_name'] ?? '')
                              .toString(),
                      onSearch: (q) async {
                        return await ref.read(searchContactsProvider(q).future);
                      },
                      onChanged: (v) =>
                          setState(() => _selectedContactId = v?['id']),
                    ),
                  ),

                  // --- Date Range ---
                  SharedFieldLayout(
                    label: 'Date Range',
                    tooltip:
                        'Restrict search to transactions that occurred within this date range',
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            key: _startDateKey,
                            onTap: () => _selectDate(context, true),
                            child: CustomTextField(
                              controller: _startDateController,
                              enabled: false,
                              hintText: 'dd/MM/yyyy',
                              suffixWidget: const Icon(
                                LucideIcons.calendar,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '-',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            key: _endDateKey,
                            onTap: () => _selectDate(context, false),
                            child: CustomTextField(
                              controller: _endDateController,
                              enabled: false,
                              hintText: 'dd/MM/yyyy',
                              suffixWidget: const Icon(
                                LucideIcons.calendar,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Amount Range ---
                  SharedFieldLayout(
                    label: 'Total Amount Range',
                    tooltip:
                        'Filter for transactions strictly falling between the minimum and maximum monetary values',
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '-',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // --- Buttons ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Search',
                    onPressed: () {
                      if (_selectedAccountId == null) {
                        ZerpaiToast.error(
                          context,
                          'Please select a mandatory Source Account to filter transactions.',
                        );
                        return;
                      }
                      widget.onSearch(
                        accountId: _selectedAccountId,
                        contactId: _selectedContactId,
                        startDate: _startDate,
                        endDate: _endDate,
                        minAmount: double.tryParse(_minAmountController.text),
                        maxAmount: double.tryParse(_maxAmountController.text),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: Opening Balances (P0) - Priority Implementation
// TODO: Advanced Reporting - Relocate to Reports module
