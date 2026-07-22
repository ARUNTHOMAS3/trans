import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/modules/auth/services/permission_service.dart';

import 'platform_admin_override.dart';
import 'permission_registry.dart';
import 'permission_resolver.dart';

class CapabilityService {
  final User user;

  const CapabilityService(this.user);

  static bool _failsBranchGuard(User user, String? branchId) {
    final normalizedBranchId = branchId?.trim() ?? '';
    if (normalizedBranchId.isEmpty) return false;
    if (isPlatformAdminOverride(user)) return false;
    if (user.role.trim().toLowerCase() == 'admin') return false;
    if (user.accessibleBranchIds.isEmpty) return false;
    return !user.accessibleBranchIds.contains(normalizedBranchId);
  }

  Set<String> effectivePermissions({
    String? branchId,
    String? warehouseId,
    Set<String> grantOverrides = const {},
    Set<String> denyOverrides = const {},
  }) {
    return PermissionResolver.resolve(
      PermissionResolutionInput(
        user: user,
        branchId: branchId,
        warehouseId: warehouseId,
        grantOverrides: grantOverrides,
        denyOverrides: denyOverrides,
      ),
    );
  }

  bool can(String permissionKey, {String? branchId, String? warehouseId}) {
    return PermissionResolver.hasPermission(
      PermissionResolutionInput(
        user: user,
        branchId: branchId,
        warehouseId: warehouseId,
      ),
      permissionKey,
    );
  }

  static bool canUser(
    User? user,
    String permissionKey, {
    String? branchId,
    String? warehouseId,
  }) {
    if (user == null) return false;
    if (_failsBranchGuard(user, branchId)) return false;
    final capability = CapabilityService(user);
    if (capability.can(
      permissionKey,
      branchId: branchId,
      warehouseId: warehouseId,
    )) {
      return true;
    }

    // Phase-safe fallback for legacy module keys while migration is in progress.
    return PermissionService.hasModuleAction(
      user,
      permissionKey,
      action: 'view',
    );
  }

  static bool canUserAction(
    User? user,
    String legacyOrCanonicalKey, {
    required String action,
    String? branchId,
    String? warehouseId,
  }) {
    if (user == null) return false;
    if (_failsBranchGuard(user, branchId)) return false;
    final normalizedAction = action.trim().toLowerCase();
    final capability = CapabilityService(user);
    if (legacyOrCanonicalKey.contains('.') &&
        capability.can(
          legacyOrCanonicalKey,
          branchId: branchId,
          warehouseId: warehouseId,
        )) {
      return true;
    }

    final prefixes = legacyPermissionPrefixesByKey[legacyOrCanonicalKey];
    if (prefixes != null && prefixes.isNotEmpty) {
      for (final prefix in prefixes) {
        final canonicalKey = '$prefix.$normalizedAction';
        if (capability.can(
          canonicalKey,
          branchId: branchId,
          warehouseId: warehouseId,
        )) {
          return true;
        }
      }
    }

    // Legacy fallback by action.
    return PermissionService.hasModuleAction(
      user,
      legacyOrCanonicalKey,
      action: normalizedAction,
    );
  }
}

final capabilityServiceProvider = Provider<CapabilityService?>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return null;
  return CapabilityService(user);
});
