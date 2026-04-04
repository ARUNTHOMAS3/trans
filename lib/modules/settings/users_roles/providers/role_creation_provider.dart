import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/role_permission_models.dart';
import 'role_permission_scheme.dart';

class RoleCreationState {
  final String roleName;
  final String description;
  final Map<String, Set<String>>
  permissions; // moduleKey -> {view, create, etc}
  final Map<String, Map<String, bool>>
  advancedOverrides; // moduleKey -> {permissionName: bool}
  final bool fullAccessReports;
  final Map<String, Set<String>>
  reportPermissions; // category -> {view, export, schedule, share}
  final Set<String> expandedSections;

  RoleCreationState({
    this.roleName = '',
    this.description = '',
    this.permissions = const {},
    this.advancedOverrides = const {},
    this.fullAccessReports = false,
    this.reportPermissions = const {},
    this.expandedSections = const {},
  });

  RoleCreationState copyWith({
    String? roleName,
    String? description,
    Map<String, Set<String>>? permissions,
    Map<String, Map<String, bool>>? advancedOverrides,
    bool? fullAccessReports,
    Map<String, Set<String>>? reportPermissions,
    Set<String>? expandedSections,
  }) {
    return RoleCreationState(
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      advancedOverrides: advancedOverrides ?? this.advancedOverrides,
      fullAccessReports: fullAccessReports ?? this.fullAccessReports,
      reportPermissions: reportPermissions ?? this.reportPermissions,
      expandedSections: expandedSections ?? this.expandedSections,
    );
  }
}

class RoleCreationNotifier extends StateNotifier<RoleCreationState> {
  RoleCreationNotifier()
    : super(
        RoleCreationState(
          permissions: RolePermissionScheme.getDefaultPermissions(),
          reportPermissions: RolePermissionScheme.getDefaultReportPermissions(),
          expandedSections: RolePermissionScheme.getMetadata()
              .map((e) => e.title)
              .toSet(),
        ),
      );

  void setRoleName(String val) => state = state.copyWith(roleName: val);
  void setDescription(String val) => state = state.copyWith(description: val);

  void toggleSection(String title) {
    final current = Set<String>.from(state.expandedSections);
    if (current.contains(title)) {
      current.remove(title);
    } else {
      current.add(title);
    }
    state = state.copyWith(expandedSections: current);
  }

  /// -------------------------------------------------------------------------
  /// MATRIX LOGIC (DEPENDENCY ENGINE)
  /// -------------------------------------------------------------------------

  void togglePermission(
    String moduleKey,
    String action,
    List<String> availableActions, {
    List<PermissionRowMeta>? subRows,
  }) {
    final current = Map<String, Set<String>>.from(state.permissions);
    final rowSet = Set<String>.from(current[moduleKey] ?? {});

    if (action == 'full') {
      if (rowSet.contains('full')) {
        rowSet.clear();
        // Clear sub-rows if any
        if (subRows != null) {
          for (final sub in subRows) {
            current[sub.key] = {};
          }
        }
      } else {
        // Checking Full auto-checks all available actions
        rowSet.addAll(['full', ...availableActions]);
        // Set full for sub-rows if any
        if (subRows != null) {
          for (final sub in subRows) {
            current[sub.key] = {'full', ...sub.actions};
          }
        }
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

  void toggleCategoryColumn(
    List<String> moduleKeys,
    String action,
    bool select,
    Map<String, List<String>> moduleActionMap,
  ) {
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
    final current = Map<String, Map<String, bool>>.from(
      state.advancedOverrides,
    );
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
        if (action == 'view') {
          catSet.clear();
        }
      } else {
        catSet.add(action);
        catSet.add('view'); // Dependency
        if ([
          'view',
          'export',
          'schedule',
          'share',
        ].every((a) => catSet.contains(a))) {
          catSet.add('full_access');
        }
      }
    }

    current[cat] = catSet;
    state = state.copyWith(reportPermissions: current);
  }

  void selectAllReportsColumn(
    String action,
    List<String> categories,
    bool select,
  ) {
    final current = Map<String, Set<String>>.from(state.reportPermissions);
    for (final cat in categories) {
      final catSet = Set<String>.from(current[cat] ?? {});
      if (select) {
        if (action == 'full_access') {
          catSet.addAll(['full_access', 'view', 'export', 'schedule', 'share']);
        } else {
          catSet.add(action);
          catSet.add('view'); // Dependency
          if ([
            'view',
            'export',
            'schedule',
            'share',
          ].every((a) => catSet.contains(a))) {
            catSet.add('full_access');
          }
        }
      } else {
        if (action == 'full_access') {
          catSet.clear();
        } else {
          catSet.remove(action);
          catSet.remove('full_access');
          if (action == 'view') catSet.clear();
        }
      }
      current[cat] = catSet;
    }
    state = state.copyWith(reportPermissions: current);
  }
}

final roleCreationProvider =
    StateNotifierProvider.autoDispose<RoleCreationNotifier, RoleCreationState>(
      (ref) => RoleCreationNotifier(),
    );
