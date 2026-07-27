// lib/modules/inventory/providers/warehouse_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/repositories/warehouse_repository.dart';

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  return WarehouseRepositoryImpl();
});

String? _readConfigValue(String key) {
  try {
    if (!Hive.isBoxOpen('config')) {
      return null;
    }
    final value = Hive.box('config').get(key)?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  } catch (_) {
    return null;
  }
}

final warehousesProvider = FutureProvider<List<Warehouse>>((ref) async {
  final repository = ref.watch(warehouseRepositoryProvider);
  final entityState = ref.watch(entityProvider);
  final authUser = ref.watch(authUserProvider);
  final resolvedEntityId = (entityState.entityId != null &&
          entityState.entityId!.trim().isNotEmpty)
      ? entityState.entityId!.trim()
      : (authUser?.orgEntityId?.trim().isNotEmpty == true
            ? authUser!.orgEntityId!.trim()
            : _readConfigValue('selected_entity_id'));
  final resolvedOrgId = (entityState.orgId != null &&
          entityState.orgId!.trim().isNotEmpty)
      ? entityState.orgId!.trim()
      : _readConfigValue('selected_org_id');
  final resolvedBranchId = (entityState.branchId != null &&
          entityState.branchId!.trim().isNotEmpty)
      ? entityState.branchId!.trim()
      : _readConfigValue('selected_branch_id');

  return repository.getWarehouses(
    forceRefresh: true,
    orgId: resolvedOrgId,
    outletId: resolvedBranchId,
    entityId: resolvedEntityId,
  );
});
