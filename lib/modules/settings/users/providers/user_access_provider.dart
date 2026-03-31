import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';

class UserAccessState {
  final bool isLoading;
  final String? error;
  final List<SettingsRoleRecord> roles;
  final List<SettingsLocationRecord> branches;
  final List<SettingsLocationRecord> warehouses;
  final Set<String> selectedOutletIds;
  final String? defaultBranchId;
  final String? defaultWarehouseId;

  UserAccessState({
    this.isLoading = false,
    this.error,
    this.roles = const [],
    this.branches = const [],
    this.warehouses = const [],
    this.selectedOutletIds = const {},
    this.defaultBranchId,
    this.defaultWarehouseId,
  });

  UserAccessState copyWith({
    bool? isLoading,
    String? error,
    List<SettingsRoleRecord>? roles,
    List<SettingsLocationRecord>? branches,
    List<SettingsLocationRecord>? warehouses,
    Set<String>? selectedOutletIds,
    String? defaultBranchId,
    String? defaultWarehouseId,
  }) {
    return UserAccessState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      roles: roles ?? this.roles,
      branches: branches ?? this.branches,
      warehouses: warehouses ?? this.warehouses,
      selectedOutletIds: selectedOutletIds ?? this.selectedOutletIds,
      defaultBranchId: defaultBranchId ?? this.defaultBranchId,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
    );
  }
}

class UserAccessNotifier extends StateNotifier<UserAccessState> {
  UserAccessNotifier() : super(UserAccessState());

  bool get isValid {
    final hasSelectedOutlets = state.selectedOutletIds.isNotEmpty;
    final hasDefaultBranch = state.defaultBranchId != null;
    final hasDefaultWarehouse = state.defaultWarehouseId != null;
    return hasSelectedOutlets && hasDefaultBranch && hasDefaultWarehouse;
  }

  Future<void> init(String orgId) async {
    state = state.copyWith(isLoading: true);
    try {
      // Mock data for consistency
      await Future.delayed(const Duration(milliseconds: 300));
      
      final mockBranches = [
        SettingsLocationRecord(id: 'br1', name: 'New York Branch', locationType: 'business', isPrimary: true),
        SettingsLocationRecord(id: 'br2', name: 'California Branch', locationType: 'business'),
      ];
      
      final mockWarehouses = [
        SettingsLocationRecord(id: 'wh1', name: 'NY Warehouse', locationType: 'warehouse'),
        SettingsLocationRecord(id: 'wh2', name: 'SF Warehouse', locationType: 'warehouse'),
      ];

      final mockRoles = [
        const SettingsRoleRecord(id: 'admin', label: 'Admin', description: 'Full access', userCount: 5),
        const SettingsRoleRecord(id: 'manager', label: 'Manager', description: 'Limited manage access', userCount: 12),
      ];

      state = state.copyWith(
        isLoading: false,
        branches: mockBranches,
        warehouses: mockWarehouses,
        roles: mockRoles,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleOutlet(String id) {
    final next = Set<String>.from(state.selectedOutletIds);
    if (next.contains(id)) {
      next.remove(id);
      if (state.defaultBranchId == id) state = state.copyWith(defaultBranchId: null);
      if (state.defaultWarehouseId == id) state = state.copyWith(defaultWarehouseId: null);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedOutletIds: next);
  }

  void toggleAll(bool select) {
    if (!select) {
      // Deselect all
      state = state.copyWith(
        selectedOutletIds: const {},
        defaultBranchId: null,
        defaultWarehouseId: null,
      );
    } else {
      // Select all (though UI calls selectVisible for selective select all)
      final all = {...state.branches, ...state.warehouses}.map((e) => e.id).toSet();
      state = state.copyWith(selectedOutletIds: all);
    }
  }

  void selectVisible(List<String> ids) {
    final next = Set<String>.from(state.selectedOutletIds);
    next.addAll(ids);
    state = state.copyWith(selectedOutletIds: next);
  }

  void setDefaultBranch(String? id) {
    state = state.copyWith(defaultBranchId: id);
  }

  void setDefaultWarehouse(String? id) {
    state = state.copyWith(defaultWarehouseId: id);
  }
}

enum RoleGroupType {
  financial,
  hr,
  operation,
  admin,
}

final userAccessProvider = StateNotifierProvider<UserAccessNotifier, UserAccessState>((ref) {
  return UserAccessNotifier();
});
