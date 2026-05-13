import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

class UserAccessState {
  final bool isLoading;
  final String? error;
  final List<SettingsRoleRecord> roles;
  final List<SettingsLocationRecord> branches;
  final List<SettingsLocationRecord> warehouses;
  final Set<String> selectedBranchIds;
  final String? defaultBranchId;
  final String? defaultWarehouseId;

  UserAccessState({
    this.isLoading = false,
    this.error,
    this.roles = const [],
    this.branches = const [],
    this.warehouses = const [],
    this.selectedBranchIds = const {},
    this.defaultBranchId,
    this.defaultWarehouseId,
  });

  UserAccessState copyWith({
    bool? isLoading,
    String? error,
    List<SettingsRoleRecord>? roles,
    List<SettingsLocationRecord>? branches,
    List<SettingsLocationRecord>? warehouses,
    Set<String>? selectedBranchIds,
    String? defaultBranchId,
    String? defaultWarehouseId,
  }) {
    return UserAccessState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      roles: roles ?? this.roles,
      branches: branches ?? this.branches,
      warehouses: warehouses ?? this.warehouses,
      selectedBranchIds: selectedBranchIds ?? this.selectedBranchIds,
      defaultBranchId: defaultBranchId ?? this.defaultBranchId,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
    );
  }
}

class UserAccessNotifier extends StateNotifier<UserAccessState> {
  final ApiClient _apiClient;

  UserAccessNotifier(this._apiClient) : super(UserAccessState());

  bool get isValid {
    final hasSelectedBranches = state.selectedBranchIds.isNotEmpty;
    final hasDefaultBranch = state.defaultBranchId != null;
    final hasDefaultWarehouse = state.defaultWarehouseId != null;
    return hasSelectedBranches && hasDefaultBranch && hasDefaultWarehouse;
  }

  Future<Map<String, dynamic>?> init(String orgId, {String? userId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final requests = <Future>[
        _apiClient.dio.get('/branches', queryParameters: {'org_id': orgId}),
        _apiClient.dio.get('/users/roles/catalog', queryParameters: {'org_id': orgId}),
        _apiClient.dio.get('/warehouses-settings', queryParameters: {'org_id': orgId}),
      ];

      if (userId != null && userId.isNotEmpty) {
        requests.add(
          _apiClient.dio.get('/users/$userId', queryParameters: {'org_id': orgId}),
        );
      }

      final responses = await Future.wait(requests);

      List<Map<String, dynamic>> asList(dynamic raw) {
        if (raw is Map) return List<Map<String, dynamic>>.from(raw['data'] ?? []);
        return List<Map<String, dynamic>>.from(raw ?? []);
      }

      final branchesData = asList(responses[0].data);
      final rolesData = asList(responses[1].data);
      final warehousesData = asList(responses[2].data);

      final apiBranches = branchesData.map((o) {
        final map = Map<String, dynamic>.from(o);
        if (map['display_name'] != null) map['name'] = map['display_name'];

        // User location-access APIs store branch access against the canonical
        // organisation_branch_master.id, not the branches table row id.
        final entityId = map['entity_id']?.toString().trim();
        if (entityId != null && entityId.isNotEmpty) {
          map['id'] = entityId;
        }

        return SettingsLocationRecord.fromJson(map);
      }).where((o) => o.isBusiness).toList();

      final apiWarehouses = warehousesData.map((o) {
        final map = Map<String, dynamic>.from(o);
        map['location_type'] = 'warehouse';
        return SettingsLocationRecord.fromJson(map);
      }).toList();

      final apiRoles = rolesData
          .map((r) => SettingsRoleRecord.fromJson(r))
          .toList();

      Map<String, dynamic>? userData;
      if (userId != null && userId.isNotEmpty && responses.length > 3) {
        final rawUser = responses[3].data;
        userData = rawUser is Map<String, dynamic>
            ? rawUser
            : Map<String, dynamic>.from(rawUser as Map);
      }

      Set<String> selectedBranchIds = const {};
      String? defaultBranchId;
      String? defaultWarehouseId;

      if (userData != null) {
        final userRecord = SettingsUserRecord.fromJson(userData);
        selectedBranchIds = userRecord.accessibleLocations
            .map((location) => location.id)
            .toSet();
        defaultBranchId = userRecord.defaultBusinessBranchId;
        defaultWarehouseId = userRecord.defaultWarehouseBranchId;
      }

      // Auto-select and set default when only one option exists
      if (apiBranches.length == 1 && selectedBranchIds.isEmpty) {
        selectedBranchIds = {apiBranches.first.id};
        defaultBranchId ??= apiBranches.first.id;
      }
      if (apiWarehouses.length == 1 && defaultWarehouseId == null) {
        selectedBranchIds = {...selectedBranchIds, apiWarehouses.first.id};
        defaultWarehouseId = apiWarehouses.first.id;
      }

      state = state.copyWith(
        isLoading: false,
        branches: apiBranches,
        warehouses: apiWarehouses,
        roles: apiRoles,
        selectedBranchIds: selectedBranchIds,
        defaultBranchId: defaultBranchId,
        defaultWarehouseId: defaultWarehouseId,
      );
      return userData;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void toggleBranch(String id) {
    final next = Set<String>.from(state.selectedBranchIds);
    if (next.contains(id)) {
      next.remove(id);
      if (state.defaultBranchId == id) state = state.copyWith(defaultBranchId: null);
      if (state.defaultWarehouseId == id) state = state.copyWith(defaultWarehouseId: null);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedBranchIds: next);
  }

  void toggleAll(bool select) {
    if (!select) {
      // Deselect all
      state = state.copyWith(
        selectedBranchIds: const {},
        defaultBranchId: null,
        defaultWarehouseId: null,
      );
    } else {
      // Select all (though UI calls selectVisible for selective select all)
      final all = {...state.branches, ...state.warehouses}.map((e) => e.id).toSet();
      state = state.copyWith(selectedBranchIds: all);
    }
  }

  void selectVisible(List<String> ids) {
    final next = Set<String>.from(state.selectedBranchIds);
    next.addAll(ids);
    state = state.copyWith(selectedBranchIds: next);
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
