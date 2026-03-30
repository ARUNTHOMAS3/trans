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

  Future<void> createPicklist(Picklist picklist) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      await repository.createPicklist(picklist);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncError(e, st);
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
