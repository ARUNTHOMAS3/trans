// PATH: lib/modules/auth/services/permission_service.dart

import '../models/user_model.dart';

class PermissionService {
  static const Map<String, List<String>> _moduleAliases = {
    'shipments': ['sales_shipments'],
    'sales_shipments': ['shipments'],
    'ewaybill_perms': ['ewaybill_settings'],
    'ewaybill_settings': ['ewaybill_perms'],
  };

  /// Check exact module/action permission from the backend-delivered auth payload.
  static bool hasModuleAction(
    User user,
    String moduleKey, {
    String? action,
  }) {
    return _resolveModuleAction(
      user,
      moduleKey,
      action: action,
    );
  }

  /// Check that all exact module/action permissions are granted.
  static bool hasAllModuleActions(
    User user,
    List<ModulePermissionCheck> checks,
  ) {
    return checks.every(
      (check) => _resolveModuleAction(
        user,
        check.moduleKey,
        action: check.action,
      ),
    );
  }

  /// Check that at least one exact module/action permission is granted.
  static bool hasAnyModuleAction(
    User user,
    List<ModulePermissionCheck> checks,
  ) {
    return checks.any(
      (check) => _resolveModuleAction(
        user,
        check.moduleKey,
        action: check.action,
      ),
    );
  }

  static bool _resolveModuleAction(
    User user,
    String moduleKey, {
    String? action,
    String? reportCategory,
  }) {
    final permissions = user.permissions;

    // Admin remains the single hardcoded full-access role.
    if (user.role.trim().toLowerCase() == 'admin') {
      return true;
    }

    if (permissions == null || permissions.isEmpty) {
      return false;
    }

    final globalFullAccess = permissions['full_access'] == true;
    if (globalFullAccess) {
      return true;
    }

    final sectionValue = _resolveSectionValue(permissions, moduleKey);
    if (sectionValue is List) {
      final actions = sectionValue.map((value) => value.toString()).toSet();
      if (actions.contains('full')) {
        return true;
      }
      if (action == null) {
        return actions.isNotEmpty;
      }
      return actions.contains(action);
    }

    if (sectionValue is Map && reportCategory != null) {
      final fullAccessReports = sectionValue['full_access'] == true;
      if (fullAccessReports) {
        return true;
      }

      final categories = sectionValue['categories'];
      if (categories is Map) {
        final reportActions = categories[reportCategory];
        if (reportActions is List) {
          final values =
              reportActions.map((value) => value.toString()).toSet();
          if (values.contains('full_access')) {
            return true;
          }
          if (action == null) {
            return values.isNotEmpty;
          }
          return values.contains(action);
        }
      }
    }

    return false;
  }

  static dynamic _resolveSectionValue(
    Map<String, dynamic> permissions,
    String moduleKey,
  ) {
    final direct = permissions[moduleKey];
    if (direct != null) return direct;

    final aliases = _moduleAliases[moduleKey];
    if (aliases == null || aliases.isEmpty) return null;

    for (final alias in aliases) {
      final value = permissions[alias];
      if (value != null) return value;
    }
    return null;
  }

}

class ModulePermissionCheck {
  const ModulePermissionCheck({
    required this.moduleKey,
    this.action,
  });

  final String moduleKey;
  final String? action;
}
