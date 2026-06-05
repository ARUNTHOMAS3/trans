import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../data/inventory_package_repository.dart';
import '../data/inventory_package_repository_impl.dart';
import '../models/inventory_package_model.dart';

final inventoryPackageRepositoryProvider = Provider<InventoryPackageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryPackageRepositoryImpl(apiClient);
});

class InventoryPackagesState {
  final bool isLoading;
  final List<InventoryPackage> packages;
  final String? error;

  InventoryPackagesState({
    this.isLoading = false,
    this.packages = const [],
    this.error,
  });

  InventoryPackagesState copyWith({
    bool? isLoading,
    List<InventoryPackage>? packages,
    String? error,
  }) {
    return InventoryPackagesState(
      isLoading: isLoading ?? this.isLoading,
      packages: packages ?? this.packages,
      error: error, // Can be null
    );
  }
}

class InventoryPackagesNotifier extends StateNotifier<InventoryPackagesState> {
  final InventoryPackageRepository _repository;

  InventoryPackagesNotifier(this._repository) : super(InventoryPackagesState());

  Future<void> fetchPackages({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final packages = await _repository.getPackages(
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
      state = state.copyWith(isLoading: false, packages: packages);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createPackage(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createPackage(data);
      await fetchPackages();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updatePackage(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updatePackage(id, data);
      await fetchPackages();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deletePackage(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deletePackage(id);
      await fetchPackages();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateNextNumberSettings({
    required String prefix,
    required int nextNumber,
  }) async {
    try {
      await _repository.updateNextNumberSettings(
        prefix: prefix,
        nextNumber: nextNumber,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final inventoryPackagesProvider =
    StateNotifierProvider<InventoryPackagesNotifier, InventoryPackagesState>((ref) {
  final repository = ref.watch(inventoryPackageRepositoryProvider);
  return InventoryPackagesNotifier(repository);
});

final nextPackageNumberProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(inventoryPackageRepositoryProvider);
  return repository.getNextNumber();
});

final packageByIdProvider = FutureProvider.family<InventoryPackage?, String>((ref, id) async {
  final repository = ref.watch(inventoryPackageRepositoryProvider);
  return repository.getPackage(id);
});
