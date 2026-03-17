import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accountant_chart_of_accounts_account_model.dart';
import '../models/account_transaction_model.dart';
import '../models/accountant_lookup_models.dart';
import '../models/accountant_metadata_model.dart';
import '../repositories/accountant_repository.dart';

class ChartOfAccountsState {
  final List<AccountNode> roots;
  final Set<String> expandedIds;
  final Set<String> savedExpandedIds;
  final String searchQuery;
  final String selectedView;
  final bool isLoading;
  final String? selectedAccountId;
  final String sortColumn;
  final bool isAscending;
  final Set<String> selectedIds;
  final List<AccountTransaction> recentTransactions;
  final List<Currency> currencies;
  final List<CountryCode> countryCodes;
  final double closingBalance;
  final String closingBalanceType;
  final String advancedSearchName;
  final String advancedSearchCode;
  final bool showDocuments;
  final bool showParentName;
  final bool isTextWrapped;
  final List<String> columnOrder;
  final bool isBackendSearch;
  final List<AccountNode> backendSearchResults;
  final AccountMetadata accountMetadata;

  const ChartOfAccountsState({
    this.roots = const [],
    this.expandedIds = const {},
    this.savedExpandedIds = const {},
    this.searchQuery = '',
    this.selectedView = 'All Accounts',
    this.isLoading = false,
    this.selectedAccountId,
    this.sortColumn = 'name',
    this.isAscending = true,
    this.selectedIds = const {},
    this.recentTransactions = const [],
    this.currencies = const [],
    this.countryCodes = const [],
    this.closingBalance = 0.0,
    this.closingBalanceType = 'Dr',
    this.advancedSearchName = '',
    this.advancedSearchCode = '',
    this.showDocuments = true,
    this.showParentName = true,
    this.isTextWrapped = false,
    this.columnOrder = const [
      'name',
      'code',
      'type',
      'documents',
      'parent',
      'balance',
    ],
    this.isBackendSearch = false,
    this.backendSearchResults = const [],
    this.accountMetadata = const AccountMetadata(),
  });

  ChartOfAccountsState copyWith({
    List<AccountNode>? roots,
    Set<String>? expandedIds,
    Set<String>? savedExpandedIds,
    String? searchQuery,
    String? selectedView,
    bool? isLoading,
    String? selectedAccountId,
    String? sortColumn,
    bool? isAscending,
    Set<String>? selectedIds,
    List<AccountTransaction>? recentTransactions,
    List<Currency>? currencies,

    List<CountryCode>? countryCodes,
    double? closingBalance,
    String? closingBalanceType,
    String? advancedSearchName,
    String? advancedSearchCode,
    bool? showDocuments,
    bool? showParentName,
    bool? isTextWrapped,
    List<String>? columnOrder,
    bool? isBackendSearch,
    List<AccountNode>? backendSearchResults,
    AccountMetadata? accountMetadata,
  }) {
    return ChartOfAccountsState(
      roots: roots ?? this.roots,
      expandedIds: expandedIds ?? this.expandedIds,
      savedExpandedIds: savedExpandedIds ?? this.savedExpandedIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedView: selectedView ?? this.selectedView,
      isLoading: isLoading ?? this.isLoading,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      sortColumn: sortColumn ?? this.sortColumn,
      isAscending: isAscending ?? this.isAscending,
      selectedIds: selectedIds ?? this.selectedIds,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      currencies: currencies ?? this.currencies,
      countryCodes: countryCodes ?? this.countryCodes,
      closingBalance: closingBalance ?? this.closingBalance,
      closingBalanceType: closingBalanceType ?? this.closingBalanceType,
      advancedSearchName: advancedSearchName ?? this.advancedSearchName,
      advancedSearchCode: advancedSearchCode ?? this.advancedSearchCode,
      showDocuments: showDocuments ?? this.showDocuments,
      showParentName: showParentName ?? this.showParentName,
      isTextWrapped: isTextWrapped ?? this.isTextWrapped,
      columnOrder: columnOrder ?? this.columnOrder,
      isBackendSearch: isBackendSearch ?? this.isBackendSearch,
      backendSearchResults: backendSearchResults ?? this.backendSearchResults,
      accountMetadata: accountMetadata ?? this.accountMetadata,
    );
  }

  List<AccountNode> get filteredRoots {
    if (isBackendSearch) {
      return backendSearchResults;
    }
    List<AccountNode> results = roots;

    // 1. Filter by View
    if (selectedView != 'All Accounts') {
      results = _filterByView(results, selectedView);
    }

    // 2. Global Search
    if (searchQuery.isNotEmpty) {
      results = _filterBySearch(results, searchQuery.toLowerCase());
    }

    // 3. Advanced Search: Name
    if (advancedSearchName.isNotEmpty) {
      results = _filterByAdvancedName(
        results,
        advancedSearchName.toLowerCase(),
      );
    }

    // 4. Advanced Search: Code
    if (advancedSearchCode.isNotEmpty) {
      results = _filterByAdvancedCode(
        results,
        advancedSearchCode.toLowerCase(),
      );
    }

    // 5. Apply Sorting
    results = _sortNodes(results);

    return results;
  }

  List<AccountNode> _sortNodes(List<AccountNode> nodes) {
    var sorted = nodes.map((n) {
      if (n.children.isNotEmpty) {
        return n.copyWith(children: _sortNodes(n.children));
      }
      return n;
    }).toList();

    sorted.sort((a, b) {
      dynamic valA;
      dynamic valB;

      switch (sortColumn) {
        case 'name':
          valA = a.name.toLowerCase();
          valB = b.name.toLowerCase();
          break;
        case 'code':
          valA = (a.code ?? '').toLowerCase();
          valB = (b.code ?? '').toLowerCase();
          break;
        case 'type':
          valA = '${a.accountGroup} ${a.accountType}'.toLowerCase();
          valB = '${b.accountGroup} ${b.accountType}'.toLowerCase();
          break;
        case 'documents':
          valA = ''; // Placeholder
          valB = '';
          break;
        case 'parent':
          valA = (a.parentName ?? '').toLowerCase();
          valB = (b.parentName ?? '').toLowerCase();
          break;
        default:
          valA = a.name.toLowerCase();
          valB = b.name.toLowerCase();
      }

      int cmp = valA.compareTo(valB);
      return isAscending ? cmp : -cmp;
    });

    return sorted;
  }

  List<AccountNode> _filterByView(
    List<AccountNode> nodes,
    String view, {
    bool forceInclude = false,
  }) {
    return nodes
        .map((node) {
          bool matches = forceInclude;
          if (!matches) {
            switch (view) {
              case 'Active Accounts':
                matches = node.isActive;
                break;
              case 'Inactive Accounts':
                matches = !node.isActive;
                break;
              case 'Asset Accounts':
                matches = node.accountGroup.toLowerCase().contains('asset');
                break;
              case 'Liability Accounts':
                matches = node.accountGroup.toLowerCase().contains('liabil');
                break;
              case 'Equity Accounts':
                matches = node.accountGroup.toLowerCase().contains('equity');
                break;
              case 'Income Accounts':
                matches =
                    node.accountGroup.toLowerCase().contains('income') ||
                    node.accountGroup.toLowerCase().contains('revenue');
                break;
              case 'Expense Accounts':
                matches = node.accountGroup.toLowerCase().contains('expense');
                break;
              default:
                matches = true;
            }
          }

          final filteredChildren = _filterByView(
            node.children,
            view,
            forceInclude: matches,
          );

          if (matches || filteredChildren.isNotEmpty) {
            return node.copyWith(children: filteredChildren);
          }
          return null;
        })
        .whereType<AccountNode>()
        .toList();
  }

  List<AccountNode> _filterBySearch(List<AccountNode> nodes, String query) {
    return nodes
        .map((node) {
          final filteredChildren = _filterBySearch(node.children, query);

          bool matches =
              node.name.toLowerCase().contains(query) ||
              (node.code ?? '').toLowerCase().contains(query) ||
              node.accountGroup.toLowerCase().contains(query) ||
              node.accountType.toLowerCase().contains(query);

          if (matches || filteredChildren.isNotEmpty) {
            return node.copyWith(children: filteredChildren);
          }
          return null;
        })
        .whereType<AccountNode>()
        .toList();
  }

  List<AccountNode> _filterByAdvancedName(
    List<AccountNode> nodes,
    String nameQuery,
  ) {
    return nodes
        .map((node) {
          final filteredChildren = _filterByAdvancedName(
            node.children,
            nameQuery,
          );
          bool matches = node.name.toLowerCase().contains(nameQuery);
          if (matches || filteredChildren.isNotEmpty) {
            return node.copyWith(children: filteredChildren);
          }
          return null;
        })
        .whereType<AccountNode>()
        .toList();
  }

  List<AccountNode> _filterByAdvancedCode(
    List<AccountNode> nodes,
    String codeQuery,
  ) {
    return nodes
        .map((node) {
          final filteredChildren = _filterByAdvancedCode(
            node.children,
            codeQuery,
          );
          bool matches = (node.code ?? '').toLowerCase().contains(codeQuery);
          if (matches || filteredChildren.isNotEmpty) {
            return node.copyWith(children: filteredChildren);
          }
          return null;
        })
        .whereType<AccountNode>()
        .toList();
  }

  AccountNode? get selectedAccount {
    if (selectedAccountId == null) return null;
    return _findAccountById(roots, selectedAccountId!);
  }

  AccountNode? _findAccountById(List<AccountNode> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final found = _findAccountById(node.children, id);
      if (found != null) return found;
    }
    return null;
  }
}

class ChartOfAccountsNotifier extends StateNotifier<ChartOfAccountsState> {
  final AccountantRepository _repository;
  Timer? _syncTimer;

  ChartOfAccountsNotifier(this._repository)
    : super(const ChartOfAccountsState()) {
    _loadData();
    _startBackgroundSync();
  }

  void _startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true);
    }
    try {
      // Fetch data in parallel for initial load, but skip lookups if already present
      final List<dynamic> results = await Future.wait([
        _repository.getAccounts(forceRefresh: forceRefresh),
        state.currencies.isEmpty
            ? _repository.getCurrencies()
            : Future.value(state.currencies),
        state.countryCodes.isEmpty
            ? _repository.getCountryCodes()
            : Future.value(state.countryCodes),
        state.accountMetadata.groupToTypes.isEmpty
            ? _repository.getAccountMetadata()
            : Future.value(state.accountMetadata),
      ]);

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        roots: results[0] as List<AccountNode>,
        currencies: results[1] as List<Currency>,
        countryCodes: results[2] as List<CountryCode>,
        accountMetadata: results[3] as AccountMetadata,
      );
    } catch (e) {
      if (!mounted) return;
      if (showLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setAdvancedSearch({String? name, String? code, String? view}) {
    state = state.copyWith(
      advancedSearchName: name ?? state.advancedSearchName,
      advancedSearchCode: code ?? state.advancedSearchCode,
      selectedView: view ?? state.selectedView,
    );
    // If we have a query and it's long enough, trigger backend search
    if ((name?.length ?? 0) > 2 || (code?.length ?? 0) > 2) {
      performBackendSearch(name ?? code ?? '');
    }
  }

  Future<void> performBackendSearch(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        isBackendSearch: false,
        backendSearchResults: [],
      );
      return;
    }

    state = state.copyWith(isLoading: true, isBackendSearch: true);
    try {
      final results = await _repository.searchAccounts(query);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        backendSearchResults: results,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  void clearAdvancedSearch() {
    state = state.copyWith(
      advancedSearchName: '',
      advancedSearchCode: '',
      selectedView: 'All Accounts',
      isBackendSearch: false,
      backendSearchResults: [],
    );
  }

  void setView(String view) {
    state = state.copyWith(selectedView: view);
  }

  void toggleExpanded(String id) {
    final newExpanded = Set<String>.from(state.expandedIds);
    if (newExpanded.contains(id)) {
      newExpanded.remove(id);
    } else {
      newExpanded.add(id);
    }
    state = state.copyWith(expandedIds: newExpanded);
  }

  void setExpanded(Set<String> ids) {
    state = state.copyWith(expandedIds: ids);
  }

  void selectAccount(String? id) async {
    if (id == null) {
      state = state.copyWith(selectedAccountId: null, recentTransactions: []);
      return;
    }
    state = state.copyWith(selectedAccountId: id);
    // Load recent transactions and stats
    try {
      final results = await Future.wait([
        _repository.getAccountTransactions(id),
        _repository.getAccountClosingBalance(id),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        recentTransactions: results[0] as List<AccountTransaction>,
        closingBalance:
            (results[1] as Map<String, dynamic>)['balance'] as double,
        closingBalanceType:
            (results[1] as Map<String, dynamic>)['type'] as String,
      );
    } catch (e) {
      // Handle error
    }
  }

  void setSort(String column) {
    if (state.sortColumn == column) {
      state = state.copyWith(isAscending: !state.isAscending);
    } else {
      state = state.copyWith(sortColumn: column, isAscending: true);
    }
  }

  void toggleSelectAll() {
    final visibleSelectableIds = <String>{};
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        if (node.isDeletable) {
          visibleSelectableIds.add(node.id);
        }
        collect(node.children);
      }
    }

    collect(state.filteredRoots);

    // If we have already selected exactly the set of visible selectable IDs (or more),
    // then the logical next step for 'toggle' is to clear.
    // Otherwise, 'select all' means selecting the entire visible selectable set.
    bool allVisibleSelected =
        visibleSelectableIds.isNotEmpty &&
        visibleSelectableIds.every((id) => state.selectedIds.contains(id));

    if (allVisibleSelected) {
      state = state.copyWith(selectedIds: {});
    } else {
      state = state.copyWith(selectedIds: visibleSelectableIds);
    }
  }

  void toggleSelect(String id) {
    final newSelected = Set<String>.from(state.selectedIds);
    if (newSelected.contains(id)) {
      newSelected.remove(id);
    } else {
      newSelected.add(id);
    }
    state = state.copyWith(selectedIds: newSelected);
  }

  Future<void> createAccount(Map<String, dynamic> data) async {
    try {
      await _repository.createAccount(data);
      await _loadData(showLoading: false, forceRefresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addAccount(Map<String, dynamic> data) => createAccount(data);

  Future<void> updateAccount(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateAccount(id, data);
      await _loadData(showLoading: false, forceRefresh: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(String id) => deleteAccounts([id]);

  Future<void> deleteAccounts(List<String> ids) async {
    // Optimistic Update: Remove from tree immediately
    final originalRoots = state.roots;
    var newRoots = state.roots;
    for (final id in ids) {
      newRoots = _removeNodeFromTree(newRoots, id);
    }
    state = state.copyWith(roots: newRoots);

    try {
      // Execute all deletions (for now one-by-one, but only refresh once)
      for (final id in ids) {
        await _repository.deleteAccount(id);
      }
      if (!mounted) return;
      // Force refresh ONCE to ensure sync with server
      await _loadData(showLoading: false, forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      // Revert on failure
      state = state.copyWith(roots: originalRoots);
      rethrow;
    }
  }

  List<AccountNode> _removeNodeFromTree(List<AccountNode> nodes, String id) {
    return nodes.where((node) => node.id != id).map((node) {
      if (node.children.isNotEmpty) {
        return node.copyWith(children: _removeNodeFromTree(node.children, id));
      }
      return node;
    }).toList();
  }

  void toggleExpand(String id) => toggleExpanded(id);
  void toggleSelectAccount(String id) => toggleSelect(id);
  void clearSelection() => state = state.copyWith(selectedIds: {});

  Future<void> updateAccountStatus(String id, bool isActive) async {
    final originalRoots = state.roots;
    // Optimistic Update
    state = state.copyWith(
      roots: _updateNodeStatusInTree(state.roots, id, isActive),
    );

    try {
      await _repository.updateAccount(id, {'isActive': isActive});
      if (!mounted) return;
      // Force-refresh so cache does not serve stale status
      await _loadData(showLoading: false, forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      // Revert on failure
      state = state.copyWith(roots: originalRoots);
      rethrow;
    }
  }

  List<AccountNode> _updateNodeStatusInTree(
    List<AccountNode> nodes,
    String id,
    bool isActive,
  ) {
    return nodes.map((node) {
      if (node.id == id) {
        return node.copyWith(isActive: isActive);
      } else if (node.children.isNotEmpty) {
        return node.copyWith(
          children: _updateNodeStatusInTree(node.children, id, isActive),
        );
      }
      return node;
    }).toList();
  }

  Future<void> refresh() async {
    await _loadData(forceRefresh: true, showLoading: false);
  }

  void toggleColumn(String column) {
    if (column == 'documents') {
      state = state.copyWith(showDocuments: !state.showDocuments);
    } else if (column == 'parent') {
      state = state.copyWith(showParentName: !state.showParentName);
    }
  }

  void toggleTextWrapping() {
    state = state.copyWith(isTextWrapped: !state.isTextWrapped);
  }

  void setColumnOrder(List<String> order) {
    state = state.copyWith(columnOrder: List.unmodifiable(order));
  }
}

final chartOfAccountsProvider =
    StateNotifierProvider<ChartOfAccountsNotifier, ChartOfAccountsState>((ref) {
      final repository = ref.watch(accountantRepositoryProvider);
      return ChartOfAccountsNotifier(repository);
    });
