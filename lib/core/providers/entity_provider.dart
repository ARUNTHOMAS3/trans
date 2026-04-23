import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EntityState {
  final String? entityId;
  final String? name;
  final String? type;
  final String? orgId;
  final String? branchId;

  EntityState({
    this.entityId,
    this.name,
    this.type,
    this.orgId,
    this.branchId,
  });

  factory EntityState.empty() => EntityState();

  bool get isEmpty => entityId == null;
}

class EntityNotifier extends StateNotifier<EntityState> {
  EntityNotifier() : super(EntityState.empty()) {
    _init();
  }

  void _init() {
    try {
      final box = Hive.box('config');
      final entityId = box.get('selected_entity_id') as String?;
      final name = box.get('selected_entity_name') as String?;
      final type = box.get('selected_entity_type') as String?;
      final orgId = box.get('selected_org_id') as String?;
      final branchId = box.get('selected_branch_id') as String?;

      if (entityId != null) {
        state = EntityState(
          entityId: entityId,
          name: name,
          type: type,
          orgId: orgId,
          branchId: branchId,
        );
      }
    } catch (_) {
      // Box might not be open yet
    }
  }

  Future<void> selectEntity({
    required String entityId,
    required String name,
    required String type,
    String? orgId,
    String? branchId,
  }) async {
    final box = Hive.box('config');
    await box.put('selected_entity_id', entityId);
    await box.put('selected_entity_name', name);
    await box.put('selected_entity_type', type);
    if (orgId != null) await box.put('selected_org_id', orgId);
    if (branchId != null) await box.put('selected_branch_id', branchId);

    state = EntityState(
      entityId: entityId,
      name: name,
      type: type,
      orgId: orgId,
      branchId: branchId,
    );
  }

  Future<void> clear() async {
    final box = Hive.box('config');
    await box.delete('selected_entity_id');
    await box.delete('selected_entity_name');
    await box.delete('selected_entity_type');
    await box.delete('selected_org_id');
    await box.delete('selected_branch_id');
    state = EntityState.empty();
  }
}

final entityProvider = StateNotifierProvider<EntityNotifier, EntityState>((ref) {
  return EntityNotifier();
});
