// FILE: lib/modules/accountant/repositories/accountant_repository.dart
// Enhanced repository for Chart of Accounts with offline support (PRD Section 12.2)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import '../models/accountant_chart_of_accounts_account_model.dart';
import '../models/account_transaction_model.dart';
import '../models/accountant_lookup_models.dart';
import '../models/accountant_metadata_model.dart';

class AccountantRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  AccountantRepository(this._apiClient, this._hiveService);

  /// Fetch accounts tree - Online-first with offline fallback
  Future<List<AccountNode>> getAccounts({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get(
        'accountant',
        useCache: !forceRefresh,
      );
      final List<AccountNode> accounts = (response.data as List)
          .map((e) => AccountNode.fromJson(e))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.saveAccounts(accounts);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('accountant');

      return accounts;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached accounts',
        error: e,
        module: 'accountant',
      );

      final cachedAccounts = _hiveService.getAccounts();

      if (cachedAccounts.isEmpty) {
        rethrow;
      }

      return _ensureTree(cachedAccounts);
    }
  }

  /// Get single account by ID
  Future<AccountNode?> getAccount(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getAccount(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('accountant/$id');
      final account = AccountNode.fromJson(response.data);

      await _hiveService.saveAccount(account);
      return account;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch account',
        error: e,
        module: 'accountant',
        data: {'accountId': id},
      );
      return null;
    }
  }

  /// Create new account
  Future<AccountNode> createAccount(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('accountant', data: data);
      final createdAccount = AccountNode.fromJson(response.data);

      // Cache locally
      await _hiveService.saveAccount(createdAccount);

      return createdAccount;
    } catch (e) {
      AppLogger.error('Failed to create account', error: e, module: 'accountant');
      rethrow;
    }
  }

  /// Update existing account
  Future<AccountNode> updateAccount(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put('accountant/$id', data: data);
      final updatedAccount = AccountNode.fromJson(response.data);

      // Update cache
      await _hiveService.saveAccount(updatedAccount);

      return updatedAccount;
    } catch (e) {
      AppLogger.error(
        'Failed to update account',
        error: e,
        module: 'accountant',
        data: {'accountId': id},
      );
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount(String id) async {
    try {
      await _apiClient.delete('accountant/$id');

      // Remove from cache
      await _hiveService.accountsBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete account',
        error: e,
        module: 'accountant',
        data: {'accountId': id},
      );
      rethrow;
    }
  }

  /// Fetch all active currencies
  Future<List<Currency>> getCurrencies() async {
    try {
      final response = await _apiClient.get('lookups/currencies');
      return (response.data as List).map((e) => Currency.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error(
        'Failed to fetch currencies',
        error: e,
        module: 'accountant',
      );
      return [];
    }
  }

  /// Fetch all active country codes
  Future<List<CountryCode>> getCountryCodes() async {
    try {
      final response = await _apiClient.get('lookups/countries');
      return (response.data as List)
          .map((e) => CountryCode.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error(
        'Failed to fetch country codes',
        error: e,
        module: 'accountant',
      );
      return [];
    }
  }

  /// Fetch account metadata (groups, types, definitions)
  Future<AccountMetadata> getAccountMetadata() async {
    try {
      final response = await _apiClient.get('accountant/metadata');
      return AccountMetadata.fromJson(response.data);
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch account metadata, using defaults',
        error: e,
        module: 'accountant',
      );
      // Centralized fallback - moving this OUT of the UI
      return const AccountMetadata(
        groupToTypes: {
          'Assets': [
            'Bank',
            'Cash',
            'Accounts Receivable',
            'Stock',
            'Payment Clearing Account',
            'Other Current Asset',
            'Fixed Asset',
            'Non Current Asset',
            'Intangible Asset',
            'Deferred Tax Asset',
            'Other Asset',
          ],
          'Liabilities': [
            'Credit Card',
            'Accounts Payable',
            'Other Current Liability',
            'Overseas Tax Payable',
            'Non Current Liability',
            'Deferred Tax Liability',
            'Other Liability',
          ],
          'Expenses': [
            'Cost Of Goods Sold',
            'Expense',
            'Other Expense',
            'Contract Assets',
          ],
          'Income': ['Income', 'Other Income'],
          'Equity': ['Equity'],
        },
        categoryDefinitions: {
          'Assets':
              'Any short term/long term asset that can be converted into cash easily.',
          'Liabilities':
              'Obligations arising from past transactions or future tax payments.',
          'Expenses':
              'Direct costs attributable to production or costs for running normal business operations.',
          'Income':
              'Revenue earned from normal business activities or secondary activities like interest.',
          'Equity':
              "Owners or stakeholders interest on the assets of the business after deducting all the liabilities.",
        },
        typeDefinitions: {
          'Credit Card':
              'Create a trail of all your credit card transactions by creating a credit card account',
        },
        typeExamples: {
          'Stock': ['Inventory assets'],
          'Accounts Receivable': ['Unpaid Invoices'],
          'Fixed Asset': [
            'Land and Buildings',
            'Plant, Machinery and Equipment',
            'Computers',
            'Furniture',
          ],
          'Bank': ['Savings', 'Checking', 'Money Market accounts'],
          'Cash': ['Petty cash', 'Undeposited funds'],
          'Other Current Asset': [
            'Prepaid expenses',
            'Stocks and Mutual Funds',
          ],
          'Other Asset': ['Goodwill', 'Other intangible assets'],
          'Other Expense': ['Insurance', 'Contribution towards charity'],
          'Cost Of Goods Sold': [
            'Material and Labor costs',
            'Cost of obtaining raw materials',
          ],
          'Expense': [
            'Advertisements and Marketing',
            'Business Travel Expenses',
            'License Fees',
            'Utility Expenses',
          ],
          'Other Income': ['Interest Earned', 'Dividend Earned'],
          'Income': ['Sale of goods', 'Services to customers'],
          'Equity': ['Owner\'s Capital', 'Shareholder investment'],
          'Deferred Tax Liability': [
            'Accelerated depreciation',
            'Revenue received in advance',
          ],
          'Overseas Tax Payable': [
            'Taxes for digital services to foreign customers',
          ],
          'Accounts Payable': ['Money owed to suppliers'],
          'Other Liability': ['Tax to be paid', 'Loan to be Repaid'],
          'Non Current Liability': [
            'Notes Payable',
            'Debentures',
            'Long Term Loans',
          ],
          'Credit Card': ['Credit card transactions'],
          'Other Current Liability': ['Customer Deposits', 'Tax Payable'],
          'Deferred Tax Asset': [
            'Warranty expenses',
            'Bad debt provisions',
            'Tax loss carry-forwards',
          ],
          'Payment Clearing Account': ['Stripe', 'PayPal'],
          'Intangible Asset': [
            'Goodwill',
            'Patents',
            'Copyrights',
            'Trademarks',
          ],
          'Non Current Asset': ['Long term investments'],
        },
        zerpaiExpenseSupportedTypes: [
          'Stock',
          'Fixed Asset',
          'Bank',
          'Cash',
          'Other Current Asset',
          'Other Asset',
          'Other Expense',
          'Cost Of Goods Sold',
          'Expense',
          'Other Liability',
          'Non Current Liability',
          'Credit Card',
          'Other Current Liability',
          'Intangible Asset',
        ],
      );
    }
  }

  /// Get accounts by type (Asset, Liability, Income, Expense, Equity)
  Future<List<AccountNode>> getAccountsByGroup(String group) async {
    try {
      final response = await _apiClient.get('accountant/group/$group');
      return (response.data as List)
          .map((e) => AccountNode.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch accounts by group',
        error: e,
        module: 'accountant',
        data: {'group': group},
      );
      // Fallback: Filter cached accounts
      final allAccounts = _flattenAccountTree(_hiveService.getAccounts());
      return allAccounts.where((acc) => acc.accountGroup == group).toList();
    }
  }

  /// Search accounts by name or code
  Future<List<AccountNode>> searchAccounts(String query) async {
    try {
      final response = await _apiClient.get('accountant/search?q=$query');
      return (response.data as List)
          .map((e) => AccountNode.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to search accounts',
        error: e,
        module: 'accountant',
        data: {'query': query},
      );
      // Fallback: Filter cached accounts
      final allAccounts = _flattenAccountTree(_hiveService.getAccounts());
      final lowercaseQuery = query.toLowerCase();
      return allAccounts
          .where(
            (acc) =>
                acc.name.toLowerCase().contains(lowercaseQuery) ||
                (acc.code?.toLowerCase().contains(lowercaseQuery) ?? false),
          )
          .toList();
    }
  }

  /// Get transactions for a specific account
  Future<List<AccountTransaction>> getAccountTransactions(
    String accountId, {
    int limit = 100,
  }) async {
    try {
      final response = await _apiClient.get(
        'accountant/$accountId/transactions',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((e) => AccountTransaction.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error(
        'Failed to fetch account transactions',
        error: e,
        module: 'accountant',
        data: {'accountId': accountId},
      );
      return [];
    }
  }

  /// Get closing balance for a specific account
  Future<Map<String, dynamic>> getAccountClosingBalance(
    String accountId,
  ) async {
    try {
      final response = await _apiClient.get(
        'accountant/$accountId/closing-balance',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch account closing balance',
        error: e,
        module: 'accountant',
        data: {'accountId': accountId},
      );
      return {'balance': 0.0, 'type': 'Dr'};
    }
  }

  /// Search transactions with filters
  Future<List<AccountTransaction>> searchTransactions({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (accountId != null) queryParams['accountId'] = accountId;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (minAmount != null) queryParams['minAmount'] = minAmount;
      if (maxAmount != null) queryParams['maxAmount'] = maxAmount;

      final response = await _apiClient.get(
        'accountant/transactions/search',
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((e) => AccountTransaction.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.error(
        'Failed to search transactions',
        error: e,
        module: 'accountant',
      );
      return [];
    }
  }

  /// Bulk update transaction accounts
  Future<void> bulkUpdateTransactions({
    required List<String> transactionIds,
    required String targetAccountId,
  }) async {
    try {
      await _apiClient.post(
        'accountant/transactions/bulk-update',
        data: {
          'transactionIds': transactionIds,
          'targetAccountId': targetAccountId,
        },
      );
    } catch (e) {
      AppLogger.error(
        'Failed to bulk update transactions',
        error: e,
        module: 'accountant',
      );
      rethrow;
    }
  }

  /// Save opening balances for multiple accounts
  Future<void> saveOpeningBalances({
    required Map<String, double> debits,
    required Map<String, double> credits,
    required DateTime openingDate,
  }) async {
    try {
      await _apiClient.post(
        'accountant/opening-balances',
        data: {
          'debits': debits,
          'credits': credits,
          'openingDate': openingDate.toIso8601String(),
        },
      );
      // Clear cache as balances will change
      await _hiveService.accountsBox.clear();
    } catch (e) {
      AppLogger.error(
        'Failed to save opening balances',
        error: e,
        module: 'accountant',
      );
      rethrow;
    }
  }

  /// Get only leaf accounts (accounts without children)
  Future<List<AccountNode>> getLeafAccounts() async {
    final allAccounts = await getAccounts();
    return _getLeafAccounts(allAccounts);
  }

  /// Get account hierarchy path for breadcrumb navigation
  Future<List<AccountNode>> getAccountPath(String accountId) async {
    final allAccounts = await getAccounts();
    return _findAccountPath(allAccounts, accountId);
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('Accountant');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('Accountant');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_accounts': stats['Accountant'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Ensure cached data is returned as a hierarchy.
  /// Hive currently stores accounts in flat form for offline fallback.
  List<AccountNode> _ensureTree(List<AccountNode> accounts) {
    if (accounts.any((account) => account.children.isNotEmpty)) {
      return accounts;
    }

    final byId = <String, AccountNode>{};
    final childrenByParent = <String, List<AccountNode>>{};

    for (final account in accounts) {
      byId[account.id] = account.copyWith(children: const []);
    }

    for (final account in byId.values) {
      final parentId = account.parentId;
      if (parentId != null && byId.containsKey(parentId)) {
        childrenByParent.putIfAbsent(parentId, () => []).add(account);
      }
    }

    AccountNode buildNode(AccountNode node) {
      final children = (childrenByParent[node.id] ?? const <AccountNode>[])
          .map(buildNode)
          .toList();
      return node.copyWith(children: children);
    }

    final roots = <AccountNode>[];
    for (final node in byId.values) {
      final parentId = node.parentId;
      if (parentId == null || !byId.containsKey(parentId)) {
        roots.add(buildNode(node));
      }
    }

    return roots;
  }

  /// Flatten account tree to list
  List<AccountNode> _flattenAccountTree(List<AccountNode> accounts) {
    final result = <AccountNode>[];

    void traverse(List<AccountNode> nodes) {
      for (final node in nodes) {
        result.add(node);
        if (node.children.isNotEmpty) {
          traverse(node.children);
        }
      }
    }

    traverse(accounts);
    return result;
  }

  /// Get leaf accounts (no children)
  List<AccountNode> _getLeafAccounts(List<AccountNode> accounts) {
    final leaves = <AccountNode>[];

    void collectLeaves(List<AccountNode> nodes) {
      for (final node in nodes) {
        if (node.children.isEmpty) {
          leaves.add(node);
        } else {
          collectLeaves(node.children);
        }
      }
    }

    collectLeaves(accounts);
    return leaves;
  }

  /// Find path to account for breadcrumbs
  List<AccountNode> _findAccountPath(
    List<AccountNode> accounts,
    String targetId,
  ) {
    List<AccountNode>? path;

    bool findPath(List<AccountNode> nodes, List<AccountNode> currentPath) {
      for (final node in nodes) {
        final newPath = [...currentPath, node];

        if (node.id == targetId) {
          path = newPath;
          return true;
        }

        if (node.children.isNotEmpty) {
          if (findPath(node.children, newPath)) {
            return true;
          }
        }
      }
      return false;
    }

    findPath(accounts, []);
    return path ?? [];
  }
}

final accountantRepositoryProvider = Provider<AccountantRepository>((ref) {
  return AccountantRepository(ref.watch(apiClientProvider), HiveService());
});
