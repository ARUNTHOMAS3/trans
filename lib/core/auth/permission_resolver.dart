import 'package:zerpai_erp/modules/auth/models/user_model.dart';

import 'platform_admin_override.dart';
import 'permission_registry.dart';

class PermissionResolutionInput {
  final User user;
  final String? branchId;
  final String? warehouseId;
  final Set<String> grantOverrides;
  final Set<String> denyOverrides;

  const PermissionResolutionInput({
    required this.user,
    this.branchId,
    this.warehouseId,
    this.grantOverrides = const {},
    this.denyOverrides = const {},
  });
}

class PermissionResolver {
  const PermissionResolver._();
  static final Map<String, Set<String>> _effectivePermissionCache =
      <String, Set<String>>{};

  static Set<String> resolve(PermissionResolutionInput input) {
    final cacheKey = _cacheKey(input);
    final cached = _effectivePermissionCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final user = input.user;
    final permissions = user.permissions ?? const <String, dynamic>{};

    // Branch guard: if branch scope is requested and user lacks access, deny all.
    if (input.branchId != null &&
        input.branchId!.trim().isNotEmpty &&
        !isPlatformAdminOverride(user) &&
        user.role.trim().toLowerCase() != 'admin' &&
        user.accessibleBranchIds.isNotEmpty &&
        !user.accessibleBranchIds.contains(input.branchId!.trim())) {
      return const <String>{};
    }

    // Full-access users receive whole registry.
    final isAdmin = user.role.trim().toLowerCase() == 'admin';
    final hasGlobalFullAccess = permissions['full_access'] == true;
    final effective = <String>{};
    if (isPlatformAdminOverride(user) || isAdmin || hasGlobalFullAccess) {
      effective.addAll(permissionRegistryByKey.keys);
      effective.addAll(input.grantOverrides);
      effective.removeAll(input.denyOverrides);
      _effectivePermissionCache[cacheKey] = Set<String>.from(effective);
      return effective;
    }

    for (final entry in permissions.entries) {
      final legacyKey = entry.key;
      final rawValue = entry.value;
      if (rawValue is! List) continue;
      final actions = rawValue.map((value) => value.toString()).toSet();
      final prefixes = legacyPermissionPrefixesByKey[legacyKey];
      if (prefixes == null || prefixes.isEmpty) continue;

      for (final prefix in prefixes) {
        final relevant = permissionsRegistry.where(
          (permission) => permission.key.startsWith('$prefix.'),
        );
        for (final permission in relevant) {
          if (actions.contains('full') || actions.contains(permission.action)) {
            effective.add(permission.key);
          }
        }
      }
    }

    effective.addAll(input.grantOverrides);
    effective.removeAll(input.denyOverrides);
    _effectivePermissionCache[cacheKey] = Set<String>.from(effective);
    return effective;
  }

  static bool hasPermission(
    PermissionResolutionInput input,
    String permissionKey,
  ) {
    final effective = resolve(input);
    return effective.contains(permissionKey);
  }

  static void invalidateCache() {
    _effectivePermissionCache.clear();
  }

  static String _cacheKey(PermissionResolutionInput input) {
    final grantList = input.grantOverrides.toList()..sort();
    final denyList = input.denyOverrides.toList()..sort();
    return [
      input.user.id,
      input.user.role.trim().toLowerCase(),
      input.user.activeTenantId ?? '',
      input.user.activeTenantType ?? '',
      input.user.activeEntityId ?? '',
      input.user.activeTenantRouteSystemId ?? '',
      _signature(input.user.permissions),
      input.branchId?.trim() ?? '',
      input.warehouseId?.trim() ?? '',
      grantList.join(','),
      denyList.join(','),
    ].join('|');
  }

  static String _signature(dynamic value) {
    if (value == null) return 'null';
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      final parts = <String>[];
      for (final key in keys) {
        parts.add('$key:${_signature(value[key])}');
      }
      return '{${parts.join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_signature).join(',')}]';
    }
    return value.toString();
  }
}
