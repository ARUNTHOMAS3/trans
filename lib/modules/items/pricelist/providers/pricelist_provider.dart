import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../modules/auth/controller/auth_controller.dart';
import '../repositories/pricelist_repository.dart';
import '../services/pricelist_service.dart';
import '../controllers/pricelist_controller.dart';
export '../controllers/pricelist_controller.dart';
import '../models/pricelist_model.dart';
import '../models/pricelist_pagination.dart';

/// Service Provider for Price Lists
final priceListServiceProvider = Provider<PriceListService>((ref) {
  final api = ref.watch(apiClientProvider);
  // Backend controller is at /api/v1/price-lists, so we don't need an extra prefix
  final repository = PriceListRepositoryImpl(api.dio, '');
  return PriceListService(repository);
});

/// Notifier Provider for Price List State
final priceListNotifierProvider =
    StateNotifierProvider<PriceListNotifier, AsyncValue<List<PriceList>>>(
      (ref) => PriceListNotifier(
        ref.watch(priceListServiceProvider),
        isAuthenticated: ref.watch(isAuthenticatedProvider),
      ),
    );

/// Provider for Active Price Lists only
final activePriceListsProvider = Provider<List<PriceList>>((ref) {
  return ref
      .watch(priceListNotifierProvider)
      .when(
        data: (priceLists) =>
            priceLists.where((pl) => pl.status == 'active').toList(),
        loading: () => [],
        error: (error, stack) => [],
      );
});

/// Provider for a specific Price List by ID
final priceListByIdProvider = Provider.family<PriceList?, String>((ref, id) {
  return ref
      .watch(priceListNotifierProvider)
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

/// Shared pagination + filter state (used by the new overview experience)
final priceListLimitProvider = StateProvider<int>((ref) => 25);
final priceListPageProvider = StateProvider<int>((ref) => 1);

final priceListFilterProvider =
    StateNotifierProvider<PriceListFilterNotifier, PriceListFilters>(
  (ref) => PriceListFilterNotifier(ref),
);

final priceListColumnProvider =
    StateNotifierProvider<PriceListColumnNotifier, Map<String, bool>>(
  (ref) => PriceListColumnNotifier(),
);

final priceListSortProvider =
    StateNotifierProvider<PriceListSortNotifier, SortState>(
  (ref) => PriceListSortNotifier(),
);

final filteredPriceListsProvider =
    Provider<AsyncValue<List<PriceList>>>((ref) {
  final priceListsAsync = ref.watch(priceListNotifierProvider);
  final filters = ref.watch(priceListFilterProvider);

  return priceListsAsync.whenData(
    (priceLists) => _applyFilters(priceLists, filters),
  );
});

final filteredPriceListPaginationProvider =
    Provider<AsyncValue<PriceListPagination>>((ref) {
  final listAsync = ref.watch(filteredPriceListsProvider);
  final limit = ref.watch(priceListLimitProvider);
  final page = ref.watch(priceListPageProvider);

  return listAsync.whenData(
    (priceLists) => _paginatePriceLists(priceLists, limit, page),
  );
});

class PriceListFilters {
  final String status;
  final String transactionType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;

  const PriceListFilters({
    this.status = 'all',
    this.transactionType = 'all',
    this.startDate,
    this.endDate,
    this.searchQuery = '',
  });

  PriceListFilters copyWith({
    String? status,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return PriceListFilters(
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class PriceListFilterNotifier extends StateNotifier<PriceListFilters> {
  PriceListFilterNotifier(this._ref) : super(const PriceListFilters());

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
    state = const PriceListFilters();
    _resetPage();
  }

  void _resetPage() {
    _ref.read(priceListPageProvider.notifier).state = 1;
  }
}

class PriceListColumnNotifier extends StateNotifier<Map<String, bool>> {
  PriceListColumnNotifier()
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

class SortState {
  final String column;
  final bool ascending;

  const SortState({
    required this.column,
    this.ascending = true,
  });

  SortState copyWith({
    String? column,
    bool? ascending,
  }) {
    return SortState(
      column: column ?? this.column,
      ascending: ascending ?? this.ascending,
    );
  }
}

class PriceListSortNotifier extends StateNotifier<SortState> {
  PriceListSortNotifier() : super(const SortState(column: 'name'));

  void sort(String column) {
    if (state.column == column) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      state = SortState(column: column, ascending: true);
    }
  }
}

List<PriceList> _applyFilters(
  List<PriceList> priceLists,
  PriceListFilters filters,
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

PriceListPagination _paginatePriceLists(
  List<PriceList> priceLists,
  int limit,
  int page,
) {
  final safeLimit = limit > 0 ? limit : 25;
  final totalCount = priceLists.length;
  final totalPages =
      totalCount == 0 ? 1 : ((totalCount + safeLimit - 1) ~/ safeLimit);
  int currentPage = page;
  if (currentPage < 1) currentPage = 1;
  if (currentPage > totalPages) currentPage = totalPages;

  final startIndex = (currentPage - 1) * safeLimit;
  final endIndex = min(totalCount, startIndex + safeLimit);
  final pageItems =
      startIndex >= totalCount ? <PriceList>[] : priceLists.sublist(startIndex, endIndex);

  return PriceListPagination(
    items: pageItems,
    totalCount: totalCount,
    page: currentPage,
    limit: safeLimit,
  );
}
