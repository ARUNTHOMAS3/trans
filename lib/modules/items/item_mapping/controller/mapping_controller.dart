import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/item_mapping/models/mapping_model.dart';

final itemMappingControllerProvider = Provider<ItemMappingController>((ref) {
  return const ItemMappingController();
});

class ItemMappingController {
  const ItemMappingController();

  // Transitional empty list until backend contract is wired.
  List<ItemMappingRecord> list() => const <ItemMappingRecord>[];
}
