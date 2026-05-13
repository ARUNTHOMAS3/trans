import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';

/// Provider that returns the list of composite items.
final compositeItemsProvider = Provider<AsyncValue<List<CompositeItem>>>((ref) {
  final itemsState = ref.watch(itemsControllerProvider);

  if (itemsState.isLoading) {
    return const AsyncValue.loading();
  }

  if (itemsState.error != null) {
    return AsyncValue.error(itemsState.error!, StackTrace.current);
  }

  return AsyncValue.data(itemsState.compositeItems.cast<CompositeItem>());
});
