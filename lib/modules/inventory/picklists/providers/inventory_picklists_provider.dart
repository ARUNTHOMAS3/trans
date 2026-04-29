import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/inventory_picklist_model.dart';
import '../data/inventory_picklist_repository.dart';
import '../data/inventory_picklist_repository_impl.dart';

/// Provider for the Picklist repository.
final inventoryPicklistRepositoryProvider = Provider<InventoryPicklistRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryPicklistRepositoryImpl(apiClient);
});

/// Provider for managing the list of Picklists.
class PicklistsNotifier extends AsyncNotifier<List<Picklist>> {
  @override
  Future<List<Picklist>> build() async {
    final repository = ref.watch(inventoryPicklistRepositoryProvider);
    return repository.getPicklists();
  }

  Future<Picklist?> createPicklist(Map<String, dynamic> data) async {
    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      final result = await repository.createPicklist(data);
      ref.invalidateSelf();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Picklist?> updatePicklist(String id, Map<String, dynamic> data) async {
    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      final result = await repository.updatePicklist(id, data);
      ref.invalidateSelf();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePicklistStatus(String id, String status) async {
    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      await repository.updatePicklist(id, {'status': status});
      ref.invalidateSelf();
      ref.invalidate(picklistByIdProvider(id));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePicklist(String id) async {
    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      await repository.deletePicklist(id);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  void refresh() {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}

final picklistsProvider =
    AsyncNotifierProvider<PicklistsNotifier, List<Picklist>>(
  PicklistsNotifier.new,
);

/// Provider for a single Picklist by ID.
final picklistByIdProvider = FutureProvider.family<Picklist?, String>((ref, id) {
  final repository = ref.watch(inventoryPicklistRepositoryProvider);
  return repository.getPicklist(id);
});

/// Provider for next picklist number from DB.
final nextPicklistNumberProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(inventoryPicklistRepositoryProvider);
  return repository.getNextNumber();
});
