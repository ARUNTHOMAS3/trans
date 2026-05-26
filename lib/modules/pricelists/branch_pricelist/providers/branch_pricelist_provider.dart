import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/branch_pricelist_repository.dart';
import '../services/branch_pricelist_service.dart';
import '../controllers/branch_pricelist_controller.dart';
export '../controllers/branch_pricelist_controller.dart';
import '../models/branch_pricelist_model.dart';
import '../models/branch_pricelist_pagination.dart';

/// Service Provider for Branch Price Lists
final branchPriceListServiceProvider = Provider<BranchPriceListService>((ref) {
  final repository = BranchPriceListRepositoryImpl();
  return BranchPriceListService(repository);
});

/// Notifier Provider for Branch Price List State
final branchPriceListNotifierProvider =
    StateNotifierProvider<
      BranchPriceListNotifier,
      AsyncValue<List<BranchPriceList>>
    >(
      (ref) => BranchPriceListNotifier(
        ref.watch(branchPriceListServiceProvider),
        isAuthenticated: true,
      ),
    );

/// Provider for Active Branch Price Lists only
final activeBranchPriceListsProvider = Provider<List<BranchPriceList>>((ref) {
  return ref
      .watch(branchPriceListNotifierProvider)
      .when(
        data: (priceLists) =>
            priceLists.where((pl) => pl.status == 'active').toList(),
        loading: () => [],
        error: (error, stack) => [],
      );
});

/// Provider for a specific Branch Price List by ID
final branchPriceListByIdProvider = Provider.family<BranchPriceList?, String>((
  ref,
  id,
) {
  return ref
      .watch(branchPriceListNotifierProvider)
      .when(
        data: (priceLists) {
          try {
            return priceLists.firstWhere((pl) => pl.id == id);
          } catch (e) {
            return null;
          }
        },
        loading: () => null,
        error: (error, stack) => null,
      );
});

/// Shared pagination + filter state
final branchPriceListLimitProvider = StateProvider<int>((ref) => 25);
final branchPriceListPageProvider = StateProvider<int>((ref) => 1);

final branchPriceListFilterProvider =
    StateNotifierProvider<
      BranchPriceListFilterNotifier,
      BranchPriceListFilters
    >((ref) => BranchPriceListFilterNotifier(ref));

final branchPriceListColumnProvider =
    StateNotifierProvider<BranchPriceListColumnNotifier, Map<String, bool>>(
      (ref) => BranchPriceListColumnNotifier(),
    );

final branchPriceListSortProvider =
    StateNotifierProvider<BranchPriceListSortNotifier, BranchSortState>(
      (ref) => BranchPriceListSortNotifier(),
    );

final filteredBranchPriceListsProvider =
    Provider<AsyncValue<List<BranchPriceList>>>((ref) {
      final priceListsAsync = ref.watch(branchPriceListNotifierProvider);
      final filters = ref.watch(branchPriceListFilterProvider);

      return priceListsAsync.whenData(
        (priceLists) => _applyFilters(priceLists, filters),
      );
    });

final filteredBranchPriceListPaginationProvider =
    Provider<AsyncValue<BranchPriceListPagination>>((ref) {
      final listAsync = ref.watch(filteredBranchPriceListsProvider);
      final limit = ref.watch(branchPriceListLimitProvider);
      final page = ref.watch(branchPriceListPageProvider);

      return listAsync.whenData(
        (priceLists) => _paginatePriceLists(priceLists, limit, page),
      );
    });

class BranchPriceListFilters {
  final String status;
  final String transactionType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;

  const BranchPriceListFilters({
    this.status = 'all',
    this.transactionType = 'all',
    this.startDate,
    this.endDate,
    this.searchQuery = '',
  });

  BranchPriceListFilters copyWith({
    String? status,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return BranchPriceListFilters(
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BranchPriceListFilterNotifier
    extends StateNotifier<BranchPriceListFilters> {
  BranchPriceListFilterNotifier(this._ref)
    : super(const BranchPriceListFilters());

  final Ref _ref;

  void setStatus(String status) {
    state = state.copyWith(status: status);
    _resetPage();
  }

  void setTransactionType(String type) {
    state = state.copyWith(transactionType: type);
    _resetPage();
  }

  void setDateRange(DateTime start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    _resetPage();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
    _resetPage();
  }

  void clearFilters() {
    state = const BranchPriceListFilters();
    _resetPage();
  }

  void _resetPage() {
    _ref.read(branchPriceListPageProvider.notifier).state = 1;
  }
}

class BranchPriceListColumnNotifier extends StateNotifier<Map<String, bool>> {
  BranchPriceListColumnNotifier()
    : super({
        'name': true,
        'itemsCovered': true,
        'currency': true,
        'details': true,
        'pricingScheme': true,
        'roundOffPreference': true,
      });

  void toggleColumn(String key) {
    final current = state[key] ?? false;
    state = {...state, key: !current};
  }
}

class BranchSortState {
  final String column;
  final bool ascending;

  const BranchSortState({required this.column, this.ascending = true});

  BranchSortState copyWith({String? column, bool? ascending}) {
    return BranchSortState(
      column: column ?? this.column,
      ascending: ascending ?? this.ascending,
    );
  }
}

class BranchPriceListSortNotifier extends StateNotifier<BranchSortState> {
  BranchPriceListSortNotifier() : super(const BranchSortState(column: 'name'));

  void sort(String column) {
    if (state.column == column) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      state = BranchSortState(column: column, ascending: true);
    }
  }
}

List<BranchPriceList> _applyFilters(
  List<BranchPriceList> priceLists,
  BranchPriceListFilters filters,
) {
  final query = filters.searchQuery.toLowerCase().trim();

  return priceLists.where((priceList) {
    if (filters.status != 'all' &&
        priceList.status.toLowerCase() != filters.status.toLowerCase()) {
      return false;
    }
    if (filters.transactionType != 'all' &&
        priceList.transactionType.toLowerCase() !=
            filters.transactionType.toLowerCase()) {
      return false;
    }

    if (filters.startDate != null) {
      final start = filters.startDate!;
      final end = filters.endDate ?? DateTime.now();
      final updatedAt = priceList.updatedAt;
      if (updatedAt.isBefore(start) || updatedAt.isAfter(end)) {
        return false;
      }
    }

    if (query.isNotEmpty) {
      final searchPayload = [
        priceList.name,
        priceList.description ?? '',
        priceList.pricingScheme,
        priceList.roundOffPreference ?? '',
        priceList.currency ?? '',
      ].join(' ').toLowerCase();

      if (!searchPayload.contains(query)) {
        return false;
      }
    }

    return true;
  }).toList();
}

BranchPriceListPagination _paginatePriceLists(
  List<BranchPriceList> priceLists,
  int limit,
  int page,
) {
  final safeLimit = limit > 0 ? limit : 25;
  final totalCount = priceLists.length;
  final totalPages = totalCount == 0
      ? 1
      : ((totalCount + safeLimit - 1) ~/ safeLimit);
  int currentPage = page;
  if (currentPage < 1) currentPage = 1;
  if (currentPage > totalPages) currentPage = totalPages;

  final startIndex = (currentPage - 1) * safeLimit;
  final endIndex = min(totalCount, startIndex + safeLimit);
  final pageItems = startIndex >= totalCount
      ? <BranchPriceList>[]
      : priceLists.sublist(startIndex, endIndex);

  return BranchPriceListPagination(
    items: pageItems,
    totalCount: totalCount,
    page: currentPage,
    limit: safeLimit,
  );
}
