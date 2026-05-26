import 'package:flutter/material.dart';

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.listRoute,
    required this.createRoute,
    this.permissionKey,
    this.showAdd = true,
  });

  final String label;
  final String listRoute;
  final String createRoute;
  final String? permissionKey;
  final bool showAdd;
}

class AppModule {
  const AppModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<AppNavItem> items;
}

