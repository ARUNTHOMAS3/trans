import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';

class VendorState {
  final List<Vendor> vendors;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final String? searchQuery;

  VendorState({
    this.vendors = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.searchQuery,
  });

  VendorState copyWith({
    List<Vendor>? vendors,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
  }) {
    return VendorState(
      vendors: vendors ?? this.vendors,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class VendorNotifier extends StateNotifier<VendorState> {
  final VendorRepository _repository;

  VendorNotifier(this._repository) : super(VendorState());

  Future<void> loadVendors({int page = 1, String? search}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final vendors = await _repository.getAllVendors(
        page: page,
        search: search,
      );

      state = state.copyWith(
        vendors: vendors,
        isLoading: false,
        currentPage: page,
        searchQuery: search,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Vendor> createVendor(Vendor vendor) async {
    try {
      final createdVendor = await _repository.createVendor(vendor);
      state = state.copyWith(vendors: [...state.vendors, createdVendor]);
      return createdVendor;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateVendor(String id, Vendor vendor) async {
    try {
      final updatedVendor = await _repository.updateVendor(id, vendor);
      state = state.copyWith(
        vendors: state.vendors
            .map((v) => v.id == id ? updatedVendor : v)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteVendor(String id) async {
    try {
      await _repository.deleteVendor(id);
      state = state.copyWith(
        vendors: state.vendors.where((v) => v.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final vendorProvider = StateNotifierProvider<VendorNotifier, VendorState>((
  ref,
) {
  final repository = ref.read(vendorRepositoryProvider);
  return VendorNotifier(repository);
});
