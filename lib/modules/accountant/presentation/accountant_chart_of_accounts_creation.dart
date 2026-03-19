import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/text_input.dart';
import '../models/accountant_lookup_models.dart';
import '../models/accountant_chart_of_accounts_account_model.dart';
import '../models/accountant_metadata_model.dart';
import '../providers/accountant_chart_of_accounts_provider.dart';
import '../../../core/routing/app_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/utils/zerpai_toast.dart';
import '../../../../shared/widgets/shortcut_handler.dart';
import '../../../../core/api/dio_client.dart';

class ChartOfAccountsCreationPage extends ConsumerStatefulWidget {
  final bool isIntegrationContext;
  const ChartOfAccountsCreationPage({
    super.key,
    this.isIntegrationContext =
        true, // Defaulting to true for now since user sees green
  });

  @override
  ConsumerState<ChartOfAccountsCreationPage> createState() =>
      _ChartOfAccountsCreationPageState();
}

class _ChartOfAccountsCreationPageState
    extends ConsumerState<ChartOfAccountsCreationPage> {
  // Form State
  String? _selectedGroup;
  String? _selectedType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _closingBalanceController = TextEditingController(
    text: '0',
  );
  String _closingBalanceType = 'Dr';
  String _currency = 'INR';
  bool _isSubAccount = false;
  bool _showInZerpaiExpense = false;
  bool _addToWatchlist = false;
  bool _isDirty = false;
  String? _parentAccountId; // ID of the parent
  AccountNode? _editingAccount;
  bool _didInitFromExtra = false;
  bool? _hasJournalEntries; // null = loading, true/false = fetched

  // Validation State
  bool _showErrors = false;
  String? _nameErrorText;
  String? _codeErrorText;
  String? _formErrorMessage; // inline top-of-form error banner

  // Constants
  String _getGroupForType(String type, AccountMetadata metadata) {
    for (var entry in metadata.groupToTypes.entries) {
      if (entry.value.contains(type)) {
        return entry.key;
      }
    }
    return 'Assets';
  }

  List<String> _buildAccountTypeDropdownItems(
    AccountMetadata metadata, {
    required bool isEditMode,
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final items = <String>[];

    bool isAllowedType(String type) {
      return (type != 'Accounts Payable' &&
              type != 'Accounts Receivable' &&
              type != 'Construction Loans' &&
              type != 'Mortgages' &&
              type != 'Home Equity Loans') ||
          (isEditMode && _selectedType == type);
    }

    for (final group in metadata.groupToTypes.keys) {
      final allowedTypes = metadata.groupToTypes[group]!
          .where(isAllowedType)
          .where(
            (type) =>
                normalizedQuery.isEmpty ||
                type.toLowerCase().contains(normalizedQuery) ||
                group.toLowerCase().contains(normalizedQuery),
          )
          .toList();

      if (allowedTypes.isEmpty) continue;

      items.add('HEADER:$group');
      items.addAll(allowedTypes);
    }

    return items;
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _codeController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _accountNumberController.addListener(_onFieldChanged);
    _ifscController.addListener(_onFieldChanged);
    _closingBalanceController.addListener(_onFieldChanged);

    // Default selection
    _selectedGroup = 'Assets';
    _selectedType = 'Other Asset';
    // Clear name/code error on change
    _nameController.addListener(() {
      if (_nameErrorText != null) setState(() => _nameErrorText = null);
    });
    _codeController.addListener(() {
      if (_codeErrorText != null) setState(() => _codeErrorText = null);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _closingBalanceController.dispose();
    super.dispose();
  }

  // --- Logic for Eligible Parents ---

  List<Map<String, dynamic>> _getEligibleParents(
    List<AccountNode> roots,
    String? targetType,
    AccountMetadata metadata, {
    String? excludeId,
    int level = 0,
    int maxDepth = 5, // Safety limit
  }) {
    if (targetType == null || targetType.isEmpty || level > maxDepth) return [];
    List<Map<String, dynamic>> results = [];

    // Use parentTypeRelationships from metadata; fall back to same-type nesting.
    final allowedParentTypes =
        metadata.parentTypeRelationships.containsKey(targetType)
        ? metadata.parentTypeRelationships[targetType]!
        : [targetType];

    void search(List<AccountNode> currentNodes, int currentLevel) {
      if (currentLevel > maxDepth) return;
      for (var node in currentNodes) {
        if (node.id == excludeId) continue;

        // 🔐 Security/Hierarchy Filter: Exclude specialized tax clearing accounts from being selectable as parents
        final bool isExcludedTaxAccount =
            node.name == 'Reverse Charge Tax Input but not due' ||
            node.name == 'Opening Balance Adjustments' ||
            node.name == 'Tax Payable' ||
            node.name == 'Unearned Revenue' ||
            node.name == 'Exchange Gain or Loss' ||
            node.name == 'Dimension Adjustments' ||
            node.name == 'Inventory Asset' ||
            node.name == 'Retained Earnings' ||
            node.name == 'Bad Debt' ||
            node.name == 'Bank Fees and Charges' ||
            node.name == 'Purchase Discounts' ||
            node.name == 'Salaries and Employee Wages' ||
            node.name == 'Uncategorized' ||
            node.name == 'Discount' ||
            node.name == 'Late Fee Income' ||
            node.name == 'Other Charges' ||
            node.name == 'Shipping Charge';

        if (!isExcludedTaxAccount &&
            allowedParentTypes.contains(node.accountType) &&
            !metadata.restrictedParentTypes.contains(node.accountType)) {
          results.add({'node': node, 'level': currentLevel});
        }
        if (node.children.isNotEmpty) {
          search(node.children, currentLevel + 1);
        }
      }
    }

    search(roots, level);
    return results;
  }

  // --- Flatten the entire account tree into a list ---
  List<AccountNode> _flattenAccounts(List<AccountNode> nodes) {
    final result = <AccountNode>[];
    for (final node in nodes) {
      result.add(node);
      result.addAll(_flattenAccounts(node.children));
    }
    return result;
  }

  Future<void> _checkJournalUsage(String accountId) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('accountant/$accountId/journal-usage');
      if (mounted) {
        setState(() {
          _hasJournalEntries = response.data['hasJournalEntries'] == true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasJournalEntries = false);
    }
  }

  void _onFieldChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  void _onCancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.accountsChartOfAccounts);
    }
  }

  bool _onSaveInProgress = false;
  void _onSave() async {
    setState(() {
      _showErrors = true;
      _nameErrorText = null;
      _codeErrorText = null;
    });

    final metadata = ref.read(chartOfAccountsProvider).accountMetadata;
    final String name = _nameController.text.trim();

    // Validation Rules
    final bool isNameEmpty = name.isEmpty;
    final bool isCodeEmpty = _codeController.text.trim().isEmpty;
    final bool isSubAccountInvalid = _isSubAccount && _parentAccountId == null;

    // Code is mandatory on both Create and Edit
    final bool isCodeMissing = isCodeEmpty;

    if (_selectedGroup == null || _selectedType == null) {
      ZerpaiToast.error(context, 'Please select an Account Type.');
      return;
    }
    if (isNameEmpty) {
      ZerpaiToast.error(context, 'Enter the Account Name');
      return;
    }
    if (isCodeMissing) {
      ZerpaiToast.error(context, 'Enter the Account Code');
      return;
    }

    // Flatten all accounts once for duplicate checks.
    final allAccounts = _flattenAccounts(
      ref.read(chartOfAccountsProvider).roots,
    );

    // Normalise a string: lowercase + strip all non-alphanumeric chars.
    // This makes "My Account", "my_account", "MY ACCOUNT", "myaccount" equal.
    String _norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    // Duplicate name check (case-insensitive, ignores spaces/underscores/etc).
    final enteredNameNorm = _norm(name);
    final isDuplicateName =
        enteredNameNorm.isNotEmpty &&
        allAccounts.any((a) {
          if (_editingAccount != null && a.id == _editingAccount!.id) {
            return false;
          }
          return _norm(a.name) == enteredNameNorm;
        });

    if (isDuplicateName) {
      setState(
        () => _nameErrorText =
            'An account with this name already exists. Please use a unique account name.',
      );
      return;
    }

    // Duplicate code check — runs against the already-loaded local tree.
    final enteredCode = _codeController.text.trim().toUpperCase();
    final isDuplicateCode = allAccounts.any((a) {
      // Skip the account being edited so its own code doesn't trigger the error.
      if (_editingAccount != null && a.id == _editingAccount!.id) return false;
      return (a.code?.toUpperCase() ?? '') == enteredCode;
    });

    if (isDuplicateCode) {
      setState(() {
        _codeErrorText =
            'This account code has been associated with another account already. '
            'Please enter a unique account code.';
      });
      ZerpaiToast.error(
        context,
        'This account code has been associated with another account already. '
        'Please enter a unique account code.',
      );
      return;
    }

    if (isSubAccountInvalid) {
      ZerpaiToast.error(context, 'Please select a Parent Account.');
      return;
    }

    // Guard: certain parent accounts do not support sub-accounts (CREATE only).
    if (_editingAccount == null && _isSubAccount && _parentAccountId != null) {
      const restrictedParentNames = [
        'GST Payable',
        'Input Tax Credits',
        'Input CGST',
        'Input IGST',
        'Input SGST',
        'Output CGST',
        'Output IGST',
        'Output SGST',
        'Retained Earnings',
        'Bad Debt',
        'Bank Fees and Charges',
        'Purchase Discounts',
        'Salaries and Employee Wages',
        'Uncategorized',
        'Discount',
        'Late Fee Income',
        'Other Charges',
        'Shipping Charge',
      ];
      final accountsState = ref.read(chartOfAccountsProvider);
      final eligibleParents = _getEligibleParents(
        accountsState.roots,
        _selectedType ?? '',
        accountsState.accountMetadata,
      );
      final parentMatch = eligibleParents
          .where((e) => (e['node'] as AccountNode).id == _parentAccountId)
          .firstOrNull;
      final parentName = parentMatch != null
          ? (parentMatch['node'] as AccountNode).name
          : null;
      if (parentName != null && restrictedParentNames.contains(parentName)) {
        setState(
          () => _formErrorMessage =
              'Creation of sub account is not supported for this account.',
        );
        return;
      }
    }

    if (_onSaveInProgress) return;

    setState(() => _onSaveInProgress = true);

    final String accountGroup =
        _selectedGroup ?? _getGroupForType(_selectedType!, metadata);
    final String accountType = _selectedType!;
    final String? code = _codeController.text.trim().isEmpty
        ? null
        : _codeController.text.trim();
    // Safety guard (CREATE only): Bank and Credit Card must never be sub-accounts,
    // even if the UI state was somehow left in a stale _isSubAccount = true condition.
    final bool _createForcesNoParent =
        _editingAccount == null &&
        (accountType == 'Bank' ||
            accountType == 'Credit Card' ||
            accountType == 'Other Income' ||
            accountType == 'Accounts Receivable');
    final String? parentId = (_isSubAccount && !_createForcesNoParent)
        ? _parentAccountId
        : null;

    try {
      if (_editingAccount == null) {
        await ref.read(chartOfAccountsProvider.notifier).addAccount({
          'user_account_name': name,
          'account_group': accountGroup,
          'account_type': accountType,
          'account_code': code,
          'description': _descriptionController.text.trim(),
          'account_number': _accountNumberController.text.trim(),
          'ifsc': _ifscController.text.trim(),
          'currency': _currency,
          'show_in_zerpai_expense': _showInZerpaiExpense,
          'add_to_watchlist': _addToWatchlist,
          'parent_id': parentId,
          'opening_balance':
              double.tryParse(_closingBalanceController.text) ?? 0,
          'opening_balance_type': _closingBalanceType,
        });
      } else {
        await ref
            .read(chartOfAccountsProvider.notifier)
            .updateAccount(_editingAccount!.id, {
              'user_account_name': name,
              'account_group': accountGroup,
              'account_type': accountType,
              'account_code': code,
              'description': _descriptionController.text.trim(),
              'account_number': _accountNumberController.text.trim(),
              'ifsc': _ifscController.text.trim(),
              'currency': _currency,
              'show_in_zerpai_expense': _showInZerpaiExpense,
              'add_to_watchlist': _addToWatchlist,
              'parent_id': parentId,
              'opening_balance':
                  double.tryParse(_closingBalanceController.text) ?? 0,
              'opening_balance_type': _closingBalanceType,
            });
      }

      if (!mounted) return;

      // Success
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.accountsChartOfAccounts);
      }
    } catch (e) {
      if (!mounted) return;

      String displayMessage = e.toString();

      // Standardize error message extraction from our ApiClient
      if (e is DioException) {
        final errorData = e.error;
        if (errorData is Map<String, dynamic>) {
          displayMessage = errorData['message']?.toString() ?? displayMessage;
        } else if (e.message != null) {
          displayMessage = e.message!;
        }
      }

      // Enhanced Toast feedback for accounting duplicates
      final lowercaseMsg = displayMessage.toLowerCase();
      if (lowercaseMsg.contains('already exists') ||
          lowercaseMsg.contains('unique') ||
          lowercaseMsg.contains('associated with another account')) {
        if (lowercaseMsg.contains('code')) {
          setState(
            () => _codeErrorText =
                'This account code is associated with another account.',
          );
        }
        ZerpaiToast.error(context, displayMessage);
      } else {
        ZerpaiToast.error(context, displayMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _onSaveInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShortcutHandler(
      onSave: _onSave,
      onCancel: _onCancel,
      isDirty: _isDirty,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    if (!_didInitFromExtra && extra is Map<String, dynamic>) {
      final account = extra['account'];
      if (account is AccountNode) {
        _editingAccount = account;
        _selectedGroup = account.accountGroup;
        _selectedType = account.accountType;
        _nameController.text = account.name;
        _codeController.text = account.code ?? '';
        _descriptionController.text = account.description ?? '';
        _accountNumberController.text = account.accountNumber ?? '';
        _ifscController.text = account.ifsc ?? '';
        _currency = account.currency;
        _showInZerpaiExpense = account.showInZerpaiExpense;
        _addToWatchlist = account.addToWatchlist;

        if (account.parentId != null) {
          _isSubAccount = true;
          _parentAccountId = account.parentId;
        }

        // Fetch journal usage asynchronously so we know if type should be locked
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _checkJournalUsage(account.id),
        );
      }
      _didInitFromExtra = true;
    }
    // 1. Get All Accounts and Metadata from Provider
    final accountsState = ref.watch(chartOfAccountsProvider);
    final metadata = accountsState.accountMetadata;

    final bool hasTransactions = (_editingAccount?.transactionCount ?? 0) > 0;

    // 🚔 Strict logic based on Zoho Books analysis (Strictly for Edit Mode)
    final String? sysName = _editingAccount?.systemAccountName;
    final String? accType = _editingAccount?.accountType ?? _selectedType;
    final bool isEditMode = _editingAccount != null;

    // 1. Account Name: Always editable (renaming is allowed for both system and user accounts)
    final bool isNameLocked = false;

    // 2. Account Type: Locked if the account has transactions, is a system/non-deletable account,
    //    OR is used in any active (non-cancelled) manual journal.
    final bool isTypeLocked =
        isEditMode &&
        (hasTransactions ||
            _editingAccount?.isDeletable == false ||
            _hasJournalEntries == true);

    // 3. Sub-account toggle visibility.
    //    CREATE mode: driven entirely by metadata.nonSubAccountableTypes so the
    //                 backend rule table is the single source of truth.
    //    EDIT mode:   original logic preserved exactly — sysName list + Bank type
    //                 check — to avoid any unintended side-effects on existing accounts.
    // Sub-account toggle visibility.
    // CREATE mode : driven by metadata.nonSubAccountableTypes (backend rule table).
    // EDIT mode   : mirrors the backend rule table for system-name-based restrictions.
    //   • 'Accounts Payable' and 'Accounts Receivable' are intentionally ABSENT —
    //     the table marks them as "Possible", so the checkbox must remain visible.
    //   • GST components (Output/Input CGST/IGST/SGST) are also absent here;
    //     their parent is locked via isParentLocked, not by hiding the toggle.
    final bool subAccountOptionAvailable = isEditMode
        ? !([
                'Retained Earnings',
                'Inventory Asset',
                'Opening Balance Adjustments',
                'GST Payable',
                'Unearned Revenue',
                'Tax Payable',
              ].contains(sysName) ||
              [
                'Bank',
                'Credit Card',
                'Payment Clearing Account',
                'Deferred Tax Asset',
                'Deferred Tax Liability',
                'Overseas Tax Payable',
                'Other Income',
                'Accounts Receivable',
              ].contains(accType) ||
              ['Shipping Charge'].contains(sysName))
        : !metadata.nonSubAccountableTypes.contains(_selectedType) ||
              _selectedType == 'Other Liability' ||
              _selectedType == 'Accounts Receivable';

    // 4. Parent Lock: Certain system accounts (Tax components) cannot have their parents moved.
    final bool isParentLocked =
        isEditMode &&
        [
          'Output CGST',
          'Output IGST',
          'Output SGST',
          'Input CGST',
          'Input IGST',
          'Input SGST',
        ].contains(sysName);

    final bool isOpeningBalanceLocked = isEditMode && hasTransactions;

    // Certain system accounts with a fixed parent should have the entire
    // sub-account section (toggle + parent row) hidden in edit mode.
    final bool hideSubAccountSection =
        isEditMode &&
        [
          'Reverse Charge Tax Input but not due',
          'Bad Debt',
          'Bank Fees and Charges',
          'Purchase Discounts',
          'Salaries and Employee Wages',
          'Discount',
          'Late Fee Income',
        ].contains(sysName);

    // 2. Calculate Eligible Parents
    final eligibleParents = _getEligibleParents(
      accountsState.roots,
      _selectedType ?? '',
      metadata,
      excludeId: _editingAccount?.id,
    );

    return Material(
      color:
          Colors.black38, // Semi-transparent backdrop to see the table behind
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 850,
          margin: const EdgeInsets.only(top: 20, bottom: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                blurRadius: 40,
                color: Color.fromARGB(66, 113, 190, 235),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space24,
                  vertical: AppTheme.space16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingAccount == null
                          ? 'Create Account'
                          : 'Edit Account',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppTheme.errorRed,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.accountsChartOfAccounts);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // SCROLLABLE CONTENT
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space24,
                    vertical: AppTheme.space16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN (FORM)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Inline form error banner (e.g. restricted sub-account)
                            if (_formErrorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed.withValues(
                                    alpha: 0.08,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.errorRed.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      LucideIcons.alertCircle,
                                      size: 14,
                                      color: AppTheme.errorRed,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formErrorMessage!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.errorRed,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _formErrorMessage = null,
                                      ),
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 14,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // 1. Unified Account Type dropdown (Nested Group/Type)
                            _buildFormRow(
                              'Account Type',
                              tooltip:
                                  'Select the category that best describes this account. This determines where it appears in your financial reports.',
                              isLocked: isTypeLocked,
                              lockedTooltip: _hasJournalEntries == true
                                  ? 'This account is used in a journal entry. To change the account type, remove it from all journals first.'
                                  : hasTransactions
                                  ? 'This account has existing transactions and its type cannot be changed.'
                                  : metadata.typeDefinitions[_selectedType] ??
                                        'This is a system account and its type cannot be modified.',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FormDropdown<String>(
                                    value: _selectedType,
                                    showSearch: true,
                                    enabled: !isTypeLocked,
                                    items: _buildAccountTypeDropdownItems(
                                      metadata,
                                      isEditMode: isEditMode,
                                    ),
                                    onSearch: (query) async =>
                                        _buildAccountTypeDropdownItems(
                                          metadata,
                                          isEditMode: isEditMode,
                                          query: query,
                                        ),
                                    hint: 'Select Account Type',
                                    isItemEnabled: (item) =>
                                        !item.startsWith('HEADER:'),
                                    displayStringForValue: (val) => val,
                                    itemBuilder: (item, isSelected, isHovered) {
                                      if (item.startsWith('HEADER:')) {
                                        return Container(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            top: 12,
                                            bottom: 8,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.bgLight,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppTheme.bgDisabled,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            item.substring(7).toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        );
                                      }
                                      return Container(
                                        height: 38,
                                        padding: const EdgeInsets.only(
                                          left: 28, // Indent sub-items
                                          right: 12,
                                        ),
                                        color: isSelected
                                            ? AppTheme.infoBg
                                            : isHovered
                                            ? AppTheme.bgLight
                                            : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isSelected
                                                      ? AppTheme.primaryBlueDark
                                                      : AppTheme.textBody,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                LucideIcons.check,
                                                size: 16,
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedType = val;
                                          _selectedGroup = _getGroupForType(
                                            val,
                                            metadata,
                                          );
                                          _parentAccountId = null;
                                          _isDirty = true;
                                          // CREATE mode: if the new type is non-sub-accountable
                                          // or has no eligible parents, clear the toggle.
                                          if (!isEditMode &&
                                              metadata.nonSubAccountableTypes
                                                  .contains(val)) {
                                            _isSubAccount = false;
                                          } else if (_getEligibleParents(
                                            accountsState.roots,
                                            val,
                                            metadata,
                                            excludeId: _editingAccount?.id,
                                          ).isEmpty) {
                                            _isSubAccount = false;
                                          }
                                        });
                                      }
                                    },
                                    errorText:
                                        _showErrors && _selectedType == null
                                        ? 'Required'
                                        : null,
                                  ),
                                  if (_showErrors && _selectedType == null)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Required',
                                        style: TextStyle(
                                          color: AppTheme.errorRed,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              isRequired: true,
                            ),

                            // 3. Account Name Row
                            _buildFormRow(
                              _selectedType == 'Credit Card'
                                  ? 'Credit Card Name'
                                  : 'Account Name',
                              tooltip:
                                  'A unique name to identify the account across the system.',
                              isLocked: isNameLocked,
                              lockedTooltip:
                                  metadata.typeDefinitions['Account Name'] ??
                                  'This is a system account and its name cannot be modified.',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FormTextInput(
                                    controller: _nameController,
                                    hint: 'Enter account name',
                                    maxLines: 1,
                                    enabled: !isNameLocked,
                                  ),
                                  if (_showErrors &&
                                      (_nameController.text.trim().isEmpty ||
                                          _nameErrorText != null))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _nameErrorText ??
                                            'Enter the Account Name',
                                        style: const TextStyle(
                                          color: AppTheme.errorRed,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              isRequired: true,
                            ),
                            // 4. SUB-ACCOUNT TOGGLE (hidden for locked-parent/fixed-parent system accounts)
                            if (_selectedType != null &&
                                !isParentLocked &&
                                !hideSubAccountSection &&
                                subAccountOptionAvailable &&
                                eligibleParents.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left:
                                      162, // Align with input start (150 label + 12 spacing)
                                  bottom: 24,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildCheckbox(
                                      label: 'Make this a sub-account',
                                      value: _isSubAccount,
                                      onChanged: (val) => setState(() {
                                        _isSubAccount = val ?? false;
                                        _isDirty = true;
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    const Tooltip(
                                      message:
                                          'Select this option if you want to make this a sub-account of another account.',
                                      child: Icon(
                                        LucideIcons.helpCircle,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // 5. PARENT ACCOUNT (Shown if Toggle is ON OR if Parent is locked/fixed)
                            if (_selectedType != null &&
                                !hideSubAccountSection &&
                                (_isSubAccount || isParentLocked))
                              _buildFormRow(
                                'Parent Account',
                                tooltip: isParentLocked
                                    ? 'Parent account cannot be modified for this system account.'
                                    : 'Select the primary account under which this sub-account will reside.',
                                isLocked: isParentLocked,
                                lockedTooltip:
                                    'Parent account cannot be modified',
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FormDropdown<String>(
                                      value: _parentAccountId,
                                      showSearch: true,
                                      enabled: !isParentLocked,
                                      items: eligibleParents
                                          .map(
                                            (e) =>
                                                (e['node'] as AccountNode).id,
                                          )
                                          .toList(),
                                      displayStringForValue: (id) {
                                        if (eligibleParents.isEmpty) {
                                          return '';
                                        }
                                        final item = eligibleParents.firstWhere(
                                          (e) =>
                                              (e['node'] as AccountNode).id ==
                                              id,
                                          orElse: () => {},
                                        );
                                        if (item.isEmpty) return '';
                                        final node =
                                            item['node'] as AccountNode;
                                        final level = item['level'] as int;
                                        if (level == 0) return node.name;
                                        return '${'    ' * level}• ${node.name}';
                                      },
                                      hint: 'Select parent account',
                                      onChanged: (val) {
                                        setState(() {
                                          _parentAccountId = val;
                                          _isDirty = true;
                                          _formErrorMessage = null;
                                        });
                                      },
                                      errorText:
                                          _showErrors &&
                                              _isSubAccount &&
                                              _parentAccountId == null
                                          ? 'Required'
                                          : null,
                                    ),
                                    if (_showErrors &&
                                        _isSubAccount &&
                                        _parentAccountId == null)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Required',
                                          style: TextStyle(
                                            color: AppTheme.errorRed,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    // Warning: selected parent does not allow sub-accounts
                                    if (!isEditMode && _parentAccountId != null)
                                      Builder(
                                        builder: (context) {
                                          const restrictedParentNames = [
                                            'GST Payable',
                                            'Input Tax Credits',
                                            'Input CGST',
                                            'Input IGST',
                                            'Input SGST',
                                            'Output CGST',
                                            'Output IGST',
                                            'Output SGST',
                                            'Retained Earnings',
                                            'Bad Debt',
                                            'Bank Fees and Charges',
                                            'Purchase Discounts',
                                            'Salaries and Employee Wages',
                                            'Uncategorized',
                                            'Discount',
                                            'Late Fee Income',
                                            'Other Charges',
                                            'Shipping Charge',
                                          ];
                                          final match = eligibleParents
                                              .where(
                                                (e) =>
                                                    (e['node'] as AccountNode)
                                                        .id ==
                                                    _parentAccountId,
                                              )
                                              .firstOrNull;
                                          final parentName = match != null
                                              ? (match['node'] as AccountNode)
                                                    .name
                                              : null;
                                          if (parentName == null ||
                                              !restrictedParentNames.contains(
                                                parentName,
                                              )) {
                                            return const SizedBox.shrink();
                                          }
                                          return const Padding(
                                            padding: EdgeInsets.only(top: 6),
                                            child: Text(
                                              'NOTE: This account cannot have sub-accounts. '
                                              'Select another account or create a new account.',
                                              style: TextStyle(
                                                color: AppTheme.errorRed,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                isRequired: true,
                              ),

                            // 3. BANK SPECIFIC FIELDS (Not for Credit Card per user request)
                            if (_selectedType == 'Bank') ...[
                              _buildFormRow(
                                'Account Number',
                                tooltip:
                                    'The official bank account number. Keep it secure.',
                                FormTextInput(
                                  controller: _accountNumberController,
                                  hint: 'Account Number',
                                ),
                              ),
                              _buildFormRow(
                                'IFSC',
                                FormTextInput(
                                  controller: _ifscController,
                                  hint: 'IFSC',
                                ),
                                tooltip:
                                    'Indian Financial System Code (IFSC) for bank branch identification.',
                              ),
                            ],

                            if (_selectedType == 'Bank' ||
                                _selectedType == 'Credit Card') ...[
                              _buildFormRow(
                                'Currency',
                                tooltip:
                                    'The default currency this account will transact in.',
                                _buildCurrencyDropdown(accountsState),
                                maxWidth: 150,
                              ),
                            ],

                            _buildFormRow(
                              'Account Code',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FormTextInput(
                                    controller: _codeController,
                                    hint: 'Account Code',
                                    maxLines: 1,
                                  ),
                                  if (_showErrors &&
                                      (_codeController.text.trim().isEmpty ||
                                          _codeErrorText != null))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _codeErrorText ??
                                            'Enter the Account Code',
                                        style: const TextStyle(
                                          color: AppTheme.errorRed,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              isRequired: true,
                              tooltip:
                                  'A unique identification number for this account.',
                            ),

                            // 6. DESCRIPTION
                            _buildFormRow(
                              'Description',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FormTextInput(
                                    controller: _descriptionController,
                                    hint: 'Max. 500 characters',
                                    maxLines: 3,
                                  ),
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _descriptionController,
                                    builder: (context, value, _) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${value.text.length} / 500',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              maxWidth: 450,
                            ),

                            // 7. OPENING BALANCE (Edit only)
                            if (_editingAccount != null) ...[
                              _buildFormRow(
                                'Opening Balance',
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      child: FormTextInput(
                                        controller: _closingBalanceController,
                                        hint: '0.00',
                                        maxLines: 1,
                                        enabled: !isOpeningBalanceLocked,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 80,
                                      child: Opacity(
                                        opacity: isOpeningBalanceLocked
                                            ? 0.6
                                            : 1.0,
                                        child: IgnorePointer(
                                          ignoring: isOpeningBalanceLocked,
                                          child: _buildBalanceTypeDropdown(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                tooltip: isOpeningBalanceLocked
                                    ? 'Opening balance cannot be modified once transactions have been recorded.'
                                    : 'Enter the balance of this account as of your opening balance date.',
                              ),

                              if (!_isSubAccount &&
                                  _selectedType != 'Credit Card')
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 162, // Align with input start
                                    bottom: 24,
                                  ),
                                  child: _buildCheckbox(
                                    label:
                                        'Add to the watchlist on my dashboard',
                                    value: _addToWatchlist,
                                    onChanged: (val) => setState(
                                      () => _addToWatchlist = val ?? false,
                                    ),
                                  ),
                                ),

                              // Watchlist if it IS a sub-account
                              if (_isSubAccount &&
                                  _selectedType != 'Credit Card')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _buildCheckbox(
                                    label:
                                        'Add to the watchlist on my dashboard',
                                    value: _addToWatchlist,
                                    onChanged: (val) => setState(
                                      () => _addToWatchlist = val ?? false,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      // RIGHT COLUMN (HELP PANEL)
                      if (_selectedType != null) ...[
                        const SizedBox(width: AppTheme.space24),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B), // Dark Navy/Grey
                              borderRadius: BorderRadius.circular(
                                AppTheme.space4,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedGroup ??
                                      _getGroupForType(
                                        _selectedType!,
                                        metadata,
                                      ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space12),
                                Text(
                                  metadata.typeDefinitions[_selectedType!] ??
                                      metadata
                                          .categoryDefinitions[_selectedGroup ??
                                          _getGroupForType(
                                            _selectedType!,
                                            metadata,
                                          )] ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.borderLight,
                                    height: 1.5,
                                  ),
                                ),
                                if (!metadata.typeDefinitions.containsKey(
                                      _selectedType!,
                                    ) &&
                                    metadata.typeExamples.containsKey(
                                      _selectedType!,
                                    )) ...[
                                  const SizedBox(height: 16),
                                  ...metadata.typeExamples[_selectedType!]!.map(
                                    (example) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4,
                                        left: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "• ",
                                            style: TextStyle(
                                              color: AppTheme.borderLight,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              example,
                                              style: const TextStyle(
                                                color: AppTheme.borderLight,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // FOOTER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space24,
                  vertical: AppTheme.space16,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderColor)),
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Save (Ctrl+S)',
                      child: ElevatedButton(
                        onPressed: _onSaveInProgress ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _onSaveInProgress
                              ? AppTheme.textSecondary
                              : (widget.isIntegrationContext
                                    ? const Color(0xFF2FB37F) // Seafoam Green
                                    : AppTheme.primaryBlue), // Bright Blue
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space24,
                            vertical: AppTheme.space12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.space4,
                            ),
                          ),
                        ),
                        child: Text(_onSaveInProgress ? 'Saving...' : 'Save'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Tooltip(
                      message: 'Cancel (Esc)',
                      child: ElevatedButton(
                        onPressed: _onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bgDisabled,
                          foregroundColor: AppTheme.textBody,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space24,
                            vertical: AppTheme.space12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.space4,
                            ),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(ChartOfAccountsState state) {
    // Prepare items
    final items = state.currencies.isEmpty
        ? [const Currency(id: 'inr', code: 'INR', name: 'Indian Rupee')]
        : state.currencies;

    return FormDropdown<Currency>(
      value: items.where((c) => c.code == _currency).firstOrNull ?? items.first,
      items: items,
      onChanged: (val) {
        if (val != null) {
          setState(() => _currency = val.code);
        }
      },
      displayStringForValue: (val) => val.code,
      searchStringForValue: (val) => '${val.code} ${val.name}'.toLowerCase(),
      itemBuilder: (item, isSelected, isHovered) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isHovered ? AppTheme.bgLight : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.code,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: AppTheme.textBody,
                      ),
                    ),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  LucideIcons.check,
                  size: 16,
                  color: AppTheme.primaryBlueDark,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceTypeDropdown() {
    return FormDropdown<String>(
      value: _closingBalanceType,
      items: const ['Dr', 'Cr'],
      onChanged: (val) {
        if (val != null) {
          setState(() => _closingBalanceType = val);
        }
      },
      displayStringForValue: (val) => val,
      itemBuilder: (item, isSelected, isHovered) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isHovered ? AppTheme.bgLight : Colors.transparent,
          child: Text(
            item,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textBody,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormRow(
    String label,
    Widget field, {
    bool isRequired = false,
    bool isDashedStyle = false,
    double? maxWidth,
    String? tooltip,
    bool isLocked = false,
    String? lockedTooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Row(
              children: [
                Flexible(
                  child: _buildLabel(
                    label,
                    isRequired: isRequired,
                    tooltip: tooltip,
                  ),
                ),
                if (isDashedStyle) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: _DottedLeader()),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth ?? 350),
                child: isLocked
                    ? Tooltip(
                        message: lockedTooltip ?? 'Field is locked',
                        preferBelow: false,
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary, // Zoho black
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        child: AbsorbPointer(child: field),
                      )
                    : field,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false, String? tooltip}) {
    Widget labelWidget = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 13,
              color: isRequired
                  ? AppTheme.errorRed
                  : AppTheme.textBody,
              fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isRequired)
            const TextSpan(
              text: '*',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );

    if (tooltip != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Tooltip(
          message: tooltip,
          preferBelow: false,
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 11),
          child: labelWidget,
        ),
      );
    }

    return Padding(padding: const EdgeInsets.only(top: 10), child: labelWidget);
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

class _DottedLeader extends StatelessWidget {
  const _DottedLeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 2.0;
        const dashSpace = 2.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
        );
      },
    );
  }
}
