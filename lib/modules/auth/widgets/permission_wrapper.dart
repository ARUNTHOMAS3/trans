// PATH: lib/modules/auth/widgets/permission_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/auth/capability_service.dart';
import '../controller/auth_controller.dart';
import '../models/user_model.dart';
import '../services/permission_service.dart';

/// Widget that conditionally displays content based on an exact module/action
/// permission from the backend auth payload.
class ModulePermissionWrapper extends ConsumerWidget {
  const ModulePermissionWrapper({
    super.key,
    required this.moduleKey,
    this.action,
    required this.child,
    this.fallback,
    this.hideInsteadOfDisable = false,
  });

  final String moduleKey;
  final String? action;
  final Widget child;
  final Widget? fallback;
  final bool hideInsteadOfDisable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authUserProvider);
    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final hasPermission = CapabilityService.canUserAction(
      user,
      moduleKey,
      action: action ?? 'view',
    );

    if (hideInsteadOfDisable) {
      return hasPermission ? child : (fallback ?? SizedBox.shrink());
    }

    return AbsorbPointer(
      absorbing: !hasPermission,
      child: Opacity(opacity: hasPermission ? 1.0 : 0.5, child: child),
    );
  }
}

/// Widget that requires all exact module/action permissions.
class ModulePermissionAllWrapper extends ConsumerWidget {
  const ModulePermissionAllWrapper({
    super.key,
    required this.checks,
    required this.child,
    this.fallback,
    this.hideInsteadOfDisable = false,
  });

  final List<ModulePermissionCheck> checks;
  final Widget child;
  final Widget? fallback;
  final bool hideInsteadOfDisable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authUserProvider);
    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final hasPermission = checks.every(
      (check) => CapabilityService.canUserAction(
        user,
        check.moduleKey,
        action: check.action ?? 'view',
      ),
    );

    if (hideInsteadOfDisable) {
      return hasPermission ? child : (fallback ?? SizedBox.shrink());
    }

    return AbsorbPointer(
      absorbing: !hasPermission,
      child: Opacity(opacity: hasPermission ? 1.0 : 0.5, child: child),
    );
  }
}

/// Widget that requires any exact module/action permission.
class ModulePermissionAnyWrapper extends ConsumerWidget {
  const ModulePermissionAnyWrapper({
    super.key,
    required this.checks,
    required this.child,
    this.fallback,
    this.hideInsteadOfDisable = false,
  });

  final List<ModulePermissionCheck> checks;
  final Widget child;
  final Widget? fallback;
  final bool hideInsteadOfDisable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authUserProvider);
    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final hasPermission = checks.any(
      (check) => CapabilityService.canUserAction(
        user,
        check.moduleKey,
        action: check.action ?? 'view',
      ),
    );

    if (hideInsteadOfDisable) {
      return hasPermission ? child : (fallback ?? SizedBox.shrink());
    }

    return AbsorbPointer(
      absorbing: !hasPermission,
      child: Opacity(opacity: hasPermission ? 1.0 : 0.5, child: child),
    );
  }
}

/// Extension on Widget to add permission checking methods
extension PermissionExtensions on Widget {
  /// Wrap widget with a direct module/action permission check.
  Widget withModulePermission(
    String moduleKey, {
    String? action,
    Widget? fallback,
    bool hideInsteadOfDisable = false,
  }) {
    return ModulePermissionWrapper(
      moduleKey: moduleKey,
      action: action,
      fallback: fallback,
      hideInsteadOfDisable: hideInsteadOfDisable,
      child: this,
    );
  }

  /// Wrap widget with multiple direct module/action checks (ALL required).
  Widget withAllModulePermissions(
    List<ModulePermissionCheck> checks, {
    Widget? fallback,
    bool hideInsteadOfDisable = false,
  }) {
    return ModulePermissionAllWrapper(
      checks: checks,
      fallback: fallback,
      hideInsteadOfDisable: hideInsteadOfDisable,
      child: this,
    );
  }

  /// Wrap widget with multiple direct module/action checks (ANY required).
  Widget withAnyModulePermission(
    List<ModulePermissionCheck> checks, {
    Widget? fallback,
    bool hideInsteadOfDisable = false,
  }) {
    return ModulePermissionAnyWrapper(
      checks: checks,
      fallback: fallback,
      hideInsteadOfDisable: hideInsteadOfDisable,
      child: this,
    );
  }
}
