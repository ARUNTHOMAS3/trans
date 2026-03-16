// PATH: lib/modules/auth/widgets/permission_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/permission_service.dart';

/// Widget that conditionally displays content based on user permissions
class PermissionWrapper extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;
  final bool hideInsteadOfDisable;

  const PermissionWrapper({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.hideInsteadOfDisable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real implementation, you'd get the user from auth state
    // For now, we'll simulate with a default user
    final user = User(
      id: 'demo-user',
      email: 'demo@example.com',
      fullName: 'Demo User',
      role: 'ho_admin', // Default role for demo
      orgId: 'demo-org',
      orgName: 'Demo Organization',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final hasPermission = PermissionService.hasPermission(user, permission);

    if (hideInsteadOfDisable) {
      return hasPermission ? child : (fallback ?? SizedBox.shrink());
    } else {
      return AbsorbPointer(
        absorbing: !hasPermission,
        child: Opacity(opacity: hasPermission ? 1.0 : 0.5, child: child),
      );
    }
  }
}

/// Widget that conditionally displays content based on multiple permissions (ALL required)
class PermissionAllWrapper extends ConsumerWidget {
  final List<Permission> permissions;
  final Widget child;
  final Widget? fallback;
  final bool hideInsteadOfDisable;

  const PermissionAllWrapper({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
    this.hideInsteadOfDisable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = User(
      id: 'demo-user',
      email: 'demo@example.com',
      fullName: 'Demo User',
      role: 'ho_admin',
      orgId: 'demo-org',
      orgName: 'Demo Organization',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final hasAllPermissions = PermissionService.hasAllPermissions(
      user,
      permissions,
    );

    if (hideInsteadOfDisable) {
      return hasAllPermissions ? child : (fallback ?? SizedBox.shrink());
    } else {
      return AbsorbPointer(
        absorbing: !hasAllPermissions,
        child: Opacity(opacity: hasAllPermissions ? 1.0 : 0.5, child: child),
      );
    }
  }
}

/// Widget that conditionally displays content based on multiple permissions (ANY required)
class PermissionAnyWrapper extends ConsumerWidget {
  final List<Permission> permissions;
  final Widget child;
  final Widget? fallback;
  final bool hideInsteadOfDisable;

  const PermissionAnyWrapper({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
    this.hideInsteadOfDisable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = User(
      id: 'demo-user',
      email: 'demo@example.com',
      fullName: 'Demo User',
      role: 'ho_admin',
      orgId: 'demo-org',
      orgName: 'Demo Organization',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final hasAnyPermission = PermissionService.hasAnyPermission(
      user,
      permissions,
    );

    if (hideInsteadOfDisable) {
      return hasAnyPermission ? child : (fallback ?? SizedBox.shrink());
    } else {
      return AbsorbPointer(
        absorbing: !hasAnyPermission,
        child: Opacity(opacity: hasAnyPermission ? 1.0 : 0.5, child: child),
      );
    }
  }
}

/// Extension on Widget to add permission checking methods
extension PermissionExtensions on Widget {
  /// Wrap widget with single permission check
  Widget withPermission(
    Permission permission, {
    Widget? fallback,
    bool hideInsteadOfDisable = false,
  }) {
    return PermissionWrapper(
      permission: permission,
      fallback: fallback,
      hideInsteadOfDisable: hideInsteadOfDisable,
      child: this,
    );
  }

  /// Wrap widget with multiple permission check (ALL required)
  Widget withAllPermissions(
    List<Permission> permissions, {
    Widget? fallback,
    bool hideInsteadOfDisable = false,
  }) {
    return PermissionAllWrapper(
      permissions: permissions,
      fallback: fallback,
      hideInsteadOfDisable: hideInsteadOfDisable,
      child: this,
    );
  }

  /// Wrap widget with multiple permission check (ANY required)
  Widget withAnyPermission(
    List<Permission> permissions, {
    Widget? fallback,
    bool hideInsteadOfDisable = false,
  }) {
    return PermissionAnyWrapper(
      permissions: permissions,
      fallback: fallback,
      hideInsteadOfDisable: hideInsteadOfDisable,
      child: this,
    );
  }
}
