import 'package:flutter/material.dart';
import 'package:zerpai_erp/app/navigation/navigation_registry.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';

class SidebarLeaf {
  const SidebarLeaf({
    required this.label,
    required this.route,
    required this.icon,
    required this.permissionKey,
  });

  final String label;
  final String route;
  final IconData icon;
  final String permissionKey;
}

class SidebarChild {
  const SidebarChild({
    required this.label,
    required this.listRoute,
    required this.createRoute,
    required this.permissionKey,
    required this.showAdd,
  });

  final String label;
  final String listRoute;
  final String createRoute;
  final String? permissionKey;
  final bool showAdd;
}

class SidebarBuilder {
  SidebarBuilder._();

  static const List<SidebarLeaf> topLeaves = [
    SidebarLeaf(
      label: 'Home',
      route: AppRoutes.home,
      icon: Icons.home_outlined,
      permissionKey: 'dashboard_charts',
    ),
    SidebarLeaf(
      label: 'Reports',
      route: AppRoutes.reports,
      icon: Icons.bar_chart_outlined,
      permissionKey: 'reports',
    ),
    SidebarLeaf(
      label: 'Documents',
      route: AppRoutes.documents,
      icon: Icons.description_outlined,
      permissionKey: 'documents',
    ),
    SidebarLeaf(
      label: 'Audit Logs',
      route: AppRoutes.auditLogs,
      icon: Icons.history,
      permissionKey: 'audit_logs',
    ),
  ];

  static Map<String, List<SidebarChild>> menuByParent() {
    final result = <String, List<SidebarChild>>{};
    for (final module in NavigationRegistry.modules) {
      result[module.label] = module.items
          .map(
            (item) => SidebarChild(
              label: item.label,
              listRoute: item.listRoute,
              createRoute: item.createRoute,
              permissionKey: item.permissionKey,
              showAdd: item.showAdd,
            ),
          )
          .toList(growable: false);
    }
    return result;
  }

  static Map<String, IconData> iconByParent() {
    return {
      for (final module in NavigationRegistry.modules)
        module.label: module.icon,
      for (final leaf in topLeaves) leaf.label: leaf.icon,
    };
  }

  static Map<String, String> leafPermissionKeys() => {
    for (final leaf in topLeaves) leaf.label: leaf.permissionKey,
  };

  static SidebarLeaf? topLeafForRoute(String route) {
    for (final leaf in topLeaves) {
      if (route == leaf.route || route.startsWith('${leaf.route}/')) {
        return leaf;
      }
    }
    return null;
  }

  static String? parentForRoute(String route) {
    final menu = menuByParent();
    for (final entry in menu.entries) {
      final parent = entry.key;
      for (final child in entry.value) {
        if (child.listRoute != '/' &&
            (route == child.listRoute ||
                route.startsWith('${child.listRoute}/'))) {
          return parent;
        }
      }
    }
    // Fallback for detail/edit/deep routes that do not share exact listRoute
    // but still clearly belong to a module parent in sidebar.
    if (route.startsWith('/items/')) return 'Items';
    if (route.startsWith('/inventory/')) return 'Inventory';
    if (route.startsWith('/sales/')) return 'Sales';
    if (route.startsWith('/purchases/')) return 'Purchases';
    if (route.startsWith('/accountant/')) return 'Accountant';
    if (route.startsWith('/accounts/')) return 'Accounts';
    return null;
  }

  static bool isTopLeaf(String route) {
    return topLeafForRoute(route) != null;
  }
}
