// FILE: lib/modules/accountant/repositories/accountant_repository.dart
// Accountant repository. Tenant-scoped business data remains server-owned.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import '../models/account_transaction_model.dart';
import '../models/accountant_lookup_models.dart';
import '../models/accountant_metadata_model.dart';

class AccountTransactionSearchPage {
  const AccountTransactionSearchPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<AccountTransaction> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}

class AccountantRepository {
  final ApiClient _apiClient;

  AccountantRepository(this._apiClient);

  /// Fetch the current entity's account tree from the server.
  Future<List<AccountNode>> getAccounts({bool forceRefresh = false}) async {
    final response = await _apiClient.get('accountant', useCache: false);
    final rawAccounts = (response.data as List)
        .map((e) => AccountNode.fromJson(e))
        .toList();
    return _ensureTree(rawAccounts);
  }

  /// Get single account by ID
  Future<AccountNode?> getAccount(String id) async {
    try {
      final response = await _apiClient.get('accountant/$id');
      return AccountNode.fromJson(response.data);
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
      return AccountNode.fromJson(response.data);
    } catch (e) {
      AppLogger.error(
        'Failed to create account',
        error: e,
        module: 'accountant',
      );
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
      return AccountNode.fromJson(response.data);
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
      rethrow;
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
      final metadata = AccountMetadata.fromJson(response.data);
      if (metadata.groupToTypes.isEmpty) {
        throw StateError('Account metadata response is empty');
      }
      return metadata;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch account metadata, using defaults',
        error: e,
        module: 'accountant',
      );
      rethrow;
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
      rethrow;
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
      rethrow;
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
        useCache: false,
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
      rethrow;
    }
  }

  /// Get closing balance for a specific account
  Future<Map<String, dynamic>> getAccountClosingBalance(
    String accountId,
  ) async {
    try {
      final response = await _apiClient.get(
        'accountant/$accountId/closing-balance',
        useCache: false,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch account closing balance',
        error: e,
        module: 'accountant',
        data: {'accountId': accountId},
      );
      rethrow;
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
    final page = await searchTransactionsPage(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
      pageSize: limit,
    );
    return page.items;
  }

  Future<AccountTransactionSearchPage> searchTransactionsPage({
    String? accountId,
    String? contactId,
    String? contactType,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
      if (accountId != null) queryParams['accountId'] = accountId;
      if (contactId != null) queryParams['contactId'] = contactId;
      if (contactType != null) queryParams['contactType'] = contactType;
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

      final payload = response.data;
      if (payload is List) {
        final items = payload
            .whereType<Map>()
            .map(
              (e) => AccountTransaction.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
        return AccountTransactionSearchPage(
          items: items,
          page: page,
          pageSize: pageSize,
          total: items.length,
          totalPages: items.isEmpty ? 0 : 1,
        );
      }
      final map = Map<String, dynamic>.from(payload as Map);
      final rawItems = (map['items'] as List? ?? const []);
      final pagination = Map<String, dynamic>.from(
        map['pagination'] as Map? ?? const {},
      );
      return AccountTransactionSearchPage(
        items: rawItems
            .whereType<Map>()
            .map(
              (e) => AccountTransaction.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
        page: (pagination['page'] as num?)?.toInt() ?? page,
        pageSize: (pagination['pageSize'] as num?)?.toInt() ?? pageSize,
        total: (pagination['total'] as num?)?.toInt() ?? rawItems.length,
        totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to search transactions',
        error: e,
        module: 'accountant',
      );
      rethrow;
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
    } catch (e) {
      AppLogger.error(
        'Failed to save opening balances',
        error: e,
        module: 'accountant',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOpeningBalances() async {
    try {
      final response = await _apiClient.get(
        'accountant/opening-balances',
        useCache: false,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      AppLogger.error(
        'Failed to load opening balances',
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

  // Offline cache intentionally omitted until keys include active entity.

  // ==================== PRIVATE HELPER METHODS ====================

  /// Ensure API data is returned as a hierarchy.
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
  return AccountantRepository(ref.watch(apiClientProvider));
});
