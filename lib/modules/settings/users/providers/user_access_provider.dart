import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';

class UserAccessState {
  final List<SettingsRoleRecord> roles;
  final List<SettingsLocationRecord> branches;
  final List<SettingsLocationRecord> warehouses;
  final Set<String> selectedOutletIds;
  final String? defaultBranchId;
  final String? defaultWarehouseId;
  final bool isLoading;
  final String? error;

  UserAccessState({
    this.roles = const [],
    this.branches = const [],
    this.warehouses = const [],
    this.selectedOutletIds = const {},
    this.defaultBranchId,
    this.defaultWarehouseId,
    this.isLoading = false,
    this.error,
  });

  UserAccessState copyWith({
    List<SettingsRoleRecord>? roles,
    List<SettingsLocationRecord>? branches,
    List<SettingsLocationRecord>? warehouses,
    Set<String>? selectedOutletIds,
    String? defaultBranchId,
    String? defaultWarehouseId,
    bool? isLoading,
    String? error,
  }) {
    return UserAccessState(
      roles: roles ?? this.roles,
      branches: branches ?? this.branches,
      warehouses: warehouses ?? this.warehouses,
      selectedOutletIds: selectedOutletIds ?? this.selectedOutletIds,
      defaultBranchId: defaultBranchId ?? this.defaultBranchId,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserAccessNotifier extends StateNotifier<UserAccessState> {
  UserAccessNotifier(this._apiClient) : super(UserAccessState());

  final ApiClient _apiClient;

  Future<void> init(String orgId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rolesRes = await _apiClient.get('users/roles/catalog', queryParameters: {'org_id': orgId});
      final locationsRes = await _apiClient.get('outlets', queryParameters: {'org_id': orgId});

      final roles = (rolesRes.data as List).map((e) => SettingsRoleRecord.fromJson(e)).toList();
      final allLocations = (locationsRes.data as List).map((e) => SettingsLocationRecord.fromJson(e)).toList();

      final branches = allLocations.where((l) => l.isBusiness).toList();
      final warehouses = allLocations.where((l) => l.isWarehouse).toList();

      state = state.copyWith(
        roles: roles,
        branches: branches,
        warehouses: warehouses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleOutlet(String id) {
    final selected = Set<String>.from(state.selectedOutletIds);
    if (selected.contains(id)) {
      selected.remove(id);
      // Clear defaults if removed
      if (state.defaultBranchId == id) state = state.copyWith(defaultBranchId: null);
      if (state.defaultWarehouseId == id) state = state.copyWith(defaultWarehouseId: null);
    } else {
      selected.add(id);
    }
    state = state.copyWith(selectedOutletIds: selected);
  }

  void selectAllWarehousesForBranch(String branchId) {
    final selected = Set<String>.from(state.selectedOutletIds);
    final relatedWarehouses = state.warehouses.where((w) => w.parentOutletId == branchId);
    
    selected.add(branchId);
    for (final w in relatedWarehouses) {
      selected.add(w.id);
    }
    state = state.copyWith(selectedOutletIds: selected);
  }

  void selectVisible(List<String> ids) {
    final selected = Set<String>.from(state.selectedOutletIds);
    selected.addAll(ids);
    state = state.copyWith(selectedOutletIds: selected);
  }

  void toggleAll(bool selectAll) {
    if (selectAll) {
      final all = <String>{};
      for (final b in state.branches) {
        all.add(b.id);
      }
      for (final w in state.warehouses) {
        all.add(w.id);
      }
      state = state.copyWith(selectedOutletIds: all);
    } else {
      state = state.copyWith(
        selectedOutletIds: const {},
        defaultBranchId: null,
        defaultWarehouseId: null,
      );
    }
  }

  void setDefaultBranch(String? id) => state = state.copyWith(defaultBranchId: id);
  void setDefaultWarehouse(String? id) => state = state.copyWith(defaultWarehouseId: id);

  bool get isValid => state.defaultBranchId != null && state.defaultWarehouseId != null;
}

final userAccessProvider = StateNotifierProvider.autoDispose<UserAccessNotifier, UserAccessState>((ref) {
  return UserAccessNotifier(ApiClient());
});
