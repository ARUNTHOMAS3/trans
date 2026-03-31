import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleCreationState {
  final String roleName;
  final String description;
  final int activeTabIndex;
  final Map<String, Set<String>> permissions; // moduleKey -> {view, create, etc}
  final Map<String, Map<String, bool>> advancedOverrides; // moduleKey -> {permissionName: bool}
  final bool fullAccessReports;
  final Map<String, Set<String>> reportPermissions; // category -> {view, export, schedule, share}
  final String searchQuery;

  RoleCreationState({
    this.roleName = '',
    this.description = '',
    this.activeTabIndex = 0,
    this.permissions = const {},
    this.advancedOverrides = const {},
    this.fullAccessReports = false,
    this.reportPermissions = const {},
    this.searchQuery = '',
  });

  RoleCreationState copyWith({
    String? roleName,
    String? description,
    int? activeTabIndex,
    Map<String, Set<String>>? permissions,
    Map<String, Map<String, bool>>? advancedOverrides,
    bool? fullAccessReports,
    Map<String, Set<String>>? reportPermissions,
    String? searchQuery,
  }) {
    return RoleCreationState(
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      permissions: permissions ?? this.permissions,
      advancedOverrides: advancedOverrides ?? this.advancedOverrides,
      fullAccessReports: fullAccessReports ?? this.fullAccessReports,
      reportPermissions: reportPermissions ?? this.reportPermissions,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class RoleCreationNotifier extends StateNotifier<RoleCreationState> {
  RoleCreationNotifier() : super(RoleCreationState());

  void setRoleName(String val) => state = state.copyWith(roleName: val);
  void setDescription(String val) => state = state.copyWith(description: val);
  void setTabIndex(int index) => state = state.copyWith(activeTabIndex: index);
  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  /// -------------------------------------------------------------------------
  /// MATRIX LOGIC (DEPENDENCY ENGINE)
  /// -------------------------------------------------------------------------

  void togglePermission(String moduleKey, String action, List<String> availableActions) {
    final current = Map<String, Set<String>>.from(state.permissions);
    final rowSet = Set<String>.from(current[moduleKey] ?? {});

    if (action == 'full') {
      if (rowSet.contains('full')) {
        rowSet.clear();
      } else {
        // Checking Full auto-checks all available actions
        rowSet.addAll(['full', ...availableActions]);
      }
    } else {
      if (rowSet.contains(action)) {
        rowSet.remove(action);
        rowSet.remove('full');
        
        // Dependency: Unchecking View forces all others to false
        if (action == 'view') {
          rowSet.clear();
        }
      } else {
        rowSet.add(action);
        // Dependency: Checking any action auto-checks View
        rowSet.add('view');
        
        // Auto-check 'full' if all available actions are now selected
        final realActions = availableActions.where((a) => a != 'full').toList();
        if (realActions.every((a) => rowSet.contains(a))) {
          rowSet.add('full');
        }
      }
    }

    current[moduleKey] = rowSet;
    state = state.copyWith(permissions: current);
  }

  void toggleCategoryColumn(List<String> moduleKeys, String action, bool select, Map<String, List<String>> moduleActionMap) {
    final current = Map<String, Set<String>>.from(state.permissions);
    
    for (final key in moduleKeys) {
      final available = moduleActionMap[key] ?? [];
      if (!available.contains(action) && action != 'full') continue;
      
      final rowSet = Set<String>.from(current[key] ?? {});
      
      if (select) {
        if (action == 'full') {
          rowSet.addAll(['full', ...available]);
        } else {
          rowSet.add(action);
          rowSet.add('view');
          // Check if full should be enabled
          if (available.every((a) => rowSet.contains(a))) rowSet.add('full');
        }
      } else {
        if (action == 'full') {
          rowSet.clear();
        } else {
          rowSet.remove(action);
          rowSet.remove('full');
          if (action == 'view') rowSet.clear();
        }
      }
      current[key] = rowSet;
    }
    
    state = state.copyWith(permissions: current);
  }

  /// -------------------------------------------------------------------------
  /// ADVANCED OVERRIDES
  /// -------------------------------------------------------------------------

  void toggleAdvancedOverride(String moduleKey, String overrideKey, bool val) {
    final current = Map<String, Map<String, bool>>.from(state.advancedOverrides);
    final moduleOverrides = Map<String, bool>.from(current[moduleKey] ?? {});
    moduleOverrides[overrideKey] = val;
    current[moduleKey] = moduleOverrides;
    state = state.copyWith(advancedOverrides: current);
  }

  /// -------------------------------------------------------------------------
  /// REPORTS LOGIC
  /// -------------------------------------------------------------------------

  void toggleFullAccessReports(bool val) {
    state = state.copyWith(fullAccessReports: val);
  }

  void toggleReportPermission(String cat, String action) {
    final current = Map<String, Set<String>>.from(state.reportPermissions);
    final catSet = Set<String>.from(current[cat] ?? {});

    if (action == 'full_access') {
      if (catSet.contains('full_access')) {
        catSet.clear();
      } else {
        catSet.addAll(['full_access', 'view', 'export', 'schedule', 'share']);
      }
    } else {
      if (catSet.contains(action)) {
        catSet.remove(action);
        catSet.remove('full_access');
      } else {
        catSet.add(action);
        if (['view', 'export', 'schedule', 'share'].every((a) => catSet.contains(a))) {
          catSet.add('full_access');
        }
      }
    }

    current[cat] = catSet;
    state = state.copyWith(reportPermissions: current);
  }

  void selectAllReportsColumn(String action, List<String> categories, bool select) {
    final current = Map<String, Set<String>>.from(state.reportPermissions);
    for (final cat in categories) {
      final catSet = Set<String>.from(current[cat] ?? {});
      if (select) {
        if (action == 'full_access') {
          catSet.addAll(['full_access', 'view', 'export', 'schedule', 'share']);
        } else {
          catSet.add(action);
          if (['view', 'export', 'schedule', 'share'].every((a) => catSet.contains(a))) {
            catSet.add('full_access');
          }
        }
      } else {
        if (action == 'full_access') {
          catSet.clear();
        } else {
          catSet.remove(action);
          catSet.remove('full_access');
        }
      }
      current[cat] = catSet;
    }
    state = state.copyWith(reportPermissions: current);
  }
}

final roleCreationProvider =
    StateNotifierProvider.autoDispose<RoleCreationNotifier, RoleCreationState>(
        (ref) => RoleCreationNotifier());
