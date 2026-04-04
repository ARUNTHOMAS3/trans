import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

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
  final ApiClient _apiClient;

  UserAccessNotifier(this._apiClient) : super(UserAccessState());

  bool get isValid {
    final hasSelectedOutlets = state.selectedOutletIds.isNotEmpty;
    final hasDefaultBranch = state.defaultBranchId != null;
    final hasDefaultWarehouse = state.defaultWarehouseId != null;
    return hasSelectedOutlets && hasDefaultBranch && hasDefaultWarehouse;
  }

  Future<void> init(String orgId) async {
    state = state.copyWith(isLoading: true);
    try {
      final responses = await Future.wait([
        _apiClient.dio.get('/outlets', queryParameters: {'org_id': orgId}),
        _apiClient.dio.get('/users/roles/catalog', queryParameters: {'org_id': orgId}),
      ]);

      // Handle both {data: [...]} and raw array response formats
      final outletsData = responses[0].data is Map 
          ? List<Map<String, dynamic>>.from(responses[0].data['data'] ?? [])
          : List<Map<String, dynamic>>.from(responses[0].data ?? []);
          
      final rolesData = responses[1].data is Map 
          ? List<Map<String, dynamic>>.from(responses[1].data['data'] ?? [])
          : List<Map<String, dynamic>>.from(responses[1].data ?? []);

      final apiOutlets = outletsData.map((o) => SettingsLocationRecord.fromJson(o)).toList();
      
      var apiBranches = apiOutlets.where((o) => o.isBusiness).toList();
      var apiWarehouses = apiOutlets.where((o) => o.isWarehouse).toList();

      // ── MOCK DATA INJECTION (Matching Image Reference) ────────────────────────
      if (apiBranches.isEmpty && apiWarehouses.isEmpty) {
        apiBranches = [
          SettingsLocationRecord(
            id: 'mock-branch-1',
            name: 'Head Office',
            locationType: 'business',
            isPrimary: false,
          ),
          SettingsLocationRecord(
            id: 'mock-branch-2',
            name: 'ZABNIX PRIVATE LIMITED',
            locationType: 'business',
            isPrimary: true,
          ),
        ];

        apiWarehouses = [
          SettingsLocationRecord(
            id: 'mock-warehouse-1',
            name: 'DEMO WAREHOUSE 1',
            locationType: 'warehouse',
            parentOutletId: 'mock-branch-2', // Nest under ZABNIX
          ),
        ];
      }
      // ─────────────────────────────────────────────────────────────────────────────

      final apiRoles = rolesData.map((r) => SettingsRoleRecord(
        id: r['id']?.toString() ?? '',
        label: r['name'] ?? 'Unknown Role',
        description: r['description'] ?? '',
        userCount: r['user_count'] ?? 0,
      )).toList();

      state = state.copyWith(
        isLoading: false,
        branches: apiBranches,
        warehouses: apiWarehouses,
        roles: apiRoles,
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
  final apiClient = ref.watch(apiClientProvider);
  return UserAccessNotifier(apiClient);
});
