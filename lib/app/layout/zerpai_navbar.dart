import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/app/navigation/search_registry.dart';
import 'package:zerpai_erp/app/navigation/sidebar_builder.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/shared/services/recent_history_service.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/core/auth/platform_admin_override.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

import 'package:zerpai_erp/core/providers/entity_provider.dart';

@JS()
external void showInstallPrompt();

class _LocationOption {
  final String value;
  final String tenantId;
  final String tenantType;
  final String routeSystemId;
  final String entityId;
  final String label;

  const _LocationOption({
    required this.value,
    required this.tenantId,
    required this.tenantType,
    required this.routeSystemId,
    required this.entityId,
    required this.label,
  });
}

bool _isBranchScopedSettingsUser(User? user) {
  if (user == null) return false;
  final role = user.role.trim().toLowerCase();
  final activeTenantType = (user.activeTenantType ?? '').trim().toUpperCase();
  return role == 'branch_admin' ||
      role == 'data_entry' ||
      activeTenantType == 'BRANCH' ||
      user.accessibleBranchIds.isNotEmpty;
}

String? _resolveBranchProfileRoute(User? user) {
  if (!_isBranchScopedSettingsUser(user)) return null;
  final branchId =
      ((user?.activeTenantType ?? '').trim().toUpperCase() == 'BRANCH'
          ? user?.activeTenantId?.trim()
          : null) ??
      user?.defaultBusinessBranchId?.trim() ??
      ((user?.accessibleBranchIds.isNotEmpty ?? false)
          ? user!.accessibleBranchIds.first.trim()
          : '');
  if (branchId.isEmpty) return null;
  return '/settings/branches/$branchId/profile';
}

class ZerpaiNavbar extends ConsumerStatefulWidget {
  static final FocusNode globalSearchFocusNode = FocusNode(
    debugLabel: 'zerpai-navbar-search',
  );

  static void focusGlobalSearch() {
    if (globalSearchFocusNode.canRequestFocus) {
      globalSearchFocusNode.requestFocus();
    }
  }

  const ZerpaiNavbar({super.key});

  @override
  ConsumerState<ZerpaiNavbar> createState() => _ZerpaiNavbarState();
}

class _ZerpaiNavbarState extends ConsumerState<ZerpaiNavbar> {
  String _searchPlaceholder = 'Search in ... ( / )';
  String _selectedCategory = 'Items';
  bool _canInstall = false;
  String _lastSearchContextKey = '';
  bool _locationLoading = false;
  String _locationSeedUserId = '';
  String? _selectedLocationValue;
  List<_LocationOption> _locationOptions = const <_LocationOption>[];
  static final List<NavSearchEntry> _navEntries = SearchRegistry.all();

  static String _moduleKey(String module) => module.trim().toLowerCase();

  static final List<NavSearchEntry> _inventoryEntries = _navEntries
      .where(
        (entry) =>
            _moduleKey(entry.module) == 'items' ||
            _moduleKey(entry.module) == 'price lists' ||
            _moduleKey(entry.module) == 'inventory',
      )
      .toList(growable: false);

  static final List<NavSearchEntry> _salesEntries = _navEntries
      .where((entry) => _moduleKey(entry.module) == 'sales')
      .toList(growable: false);

  static final List<NavSearchEntry> _purchasesEntries = _navEntries
      .where((entry) => _moduleKey(entry.module) == 'purchases')
      .toList(growable: false);

  static List<String> _labelsFromEntries(List<NavSearchEntry> entries) {
    final seen = <String>{};
    final labels = <String>[];
    for (final entry in entries) {
      if (seen.add(entry.label)) {
        labels.add(entry.label);
      }
    }
    return labels;
  }

  static final List<String> _inventorySearchCategories = [
    ..._labelsFromEntries(_inventoryEntries),
    'Documents',
  ];

  static final List<String> _salesSearchCategories = [
    ..._labelsFromEntries(_salesEntries),
    'Documents',
  ];

  static final List<String> _purchasesSearchCategories = [
    ..._labelsFromEntries(_purchasesEntries),
    'Documents',
  ];

  static final Map<String, String> _categoryRoutes = {
    for (final entry in _navEntries) entry.label: entry.route,
    for (final leaf in SidebarBuilder.topLeaves)
      if (leaf.label != 'Home') leaf.label: leaf.route,
  };

  static final List<String> _searchCategories = [
    ..._labelsFromEntries(_navEntries),
    ...SidebarBuilder.topLeaves
        .where((leaf) => leaf.label != 'Home')
        .map((leaf) => leaf.label),
  ];

  @override
  void initState() {
    super.initState();
    _updatePlaceholder(_selectedCategory);
    if (kIsWeb) {
      _listenForPwaInstall();
    }
  }

  void _listenForPwaInstall() {
    // Listen for custom event dispatch from index.html
    web.window.addEventListener(
      'pwa-install-ready',
      (web.Event event) {
        setState(() {
          _canInstall = true;
        });
      }.toJS,
    );
  }

  void _installApp() {
    if (kIsWeb) {
      showInstallPrompt();
      setState(() {
        _canInstall = false;
      });
    }
  }

  void _updatePlaceholder(String category) {
    setState(() {
      _selectedCategory = category;
      _searchPlaceholder = 'Search in $category ( / )';
    });
  }

  Future<void> _loadLocationOptions(User? user) async {
    if (user == null || user.id.isEmpty || user.orgId.isEmpty) {
      return;
    }
    if (_locationLoading) {
      return;
    }

    setState(() {
      _locationLoading = true;
    });

    final role = user.role.trim().toLowerCase();
    final isPrivilegedUser =
        user.role.trim().toLowerCase() == 'admin' ||
        isPlatformAdminOverride(user);
    final isBranchScopedUser =
        role == 'branch_admin' ||
        ((user.activeTenantType ?? '').trim().toUpperCase() == 'BRANCH') ||
        user.accessibleBranchIds.isNotEmpty;
    final canShowOrgOption = isPrivilegedUser && !isBranchScopedUser;
    final options = <_LocationOption>[];

    if (canShowOrgOption) {
      options.add(
        _LocationOption(
          value: 'ORG:${user.orgId}',
          tenantId: user.orgId,
          tenantType: 'ORG',
          routeSystemId: user.orgSystemId,
          entityId: user.orgEntityId ?? '',
          label: user.orgName.isNotEmpty ? user.orgName : 'Organization',
        ),
      );
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .get(
            'branches',
            queryParameters: <String, dynamic>{'org_id': user.orgId},
          );

      final rows = response.data is List
          ? (response.data as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .toList()
          : const <Map<String, dynamic>>[];

      for (final raw in rows) {
        final branch = Map<String, dynamic>.from(raw);
        final branchId = (branch['id'] ?? '').toString().trim();
        if (branchId.isEmpty) {
          continue;
        }

        if (!isPrivilegedUser && !user.accessibleBranchIds.contains(branchId)) {
          continue;
        }

        final branchSystemId = (branch['system_id'] ?? '').toString().trim();
        final displayName = (branch['display_name'] ?? branch['name'] ?? '')
            .toString()
            .trim();
        final entityId = (branch['entity_id'] ?? '').toString().trim();

        if (branchSystemId.isEmpty) {
          continue;
        }

        options.add(
          _LocationOption(
            value: 'BRANCH:$branchId',
            tenantId: branchId,
            tenantType: 'BRANCH',
            routeSystemId: branchSystemId,
            entityId: entityId,
            label: displayName.isNotEmpty ? displayName : branchSystemId,
          ),
        );
      }

      // Fallback: branch-scoped users may have delayed/empty accessible list
      // from profile hydration. Keep active/default branch selectable to avoid
      // empty switcher and zero-context dashboard.
      if (!isPrivilegedUser && options.isEmpty) {
        final candidateBranchIds = <String>{
          if ((user.activeTenantType ?? '').trim().toUpperCase() == 'BRANCH' &&
              (user.activeTenantId ?? '').trim().isNotEmpty)
            user.activeTenantId!.trim(),
          if ((user.defaultBusinessBranchId ?? '').trim().isNotEmpty)
            user.defaultBusinessBranchId!.trim(),
        };

        for (final raw in rows) {
          final branch = Map<String, dynamic>.from(raw);
          final branchId = (branch['id'] ?? '').toString().trim();
          if (!candidateBranchIds.contains(branchId)) continue;
          final branchSystemId = (branch['system_id'] ?? '').toString().trim();
          final displayName = (branch['display_name'] ?? branch['name'] ?? '')
              .toString()
              .trim();
          final entityId = (branch['entity_id'] ?? '').toString().trim();
          if (branchSystemId.isEmpty) continue;
          options.add(
            _LocationOption(
              value: 'BRANCH:$branchId',
              tenantId: branchId,
              tenantType: 'BRANCH',
              routeSystemId: branchSystemId,
              entityId: entityId,
              label: displayName.isNotEmpty ? displayName : branchSystemId,
            ),
          );
        }
      }
    } catch (_) {
      // Fallback to org-only option.
    }

    if (!mounted) {
      return;
    }

    if (options.isEmpty) {
      final fallbackTenantType = (user.activeTenantType ?? '')
          .trim()
          .toUpperCase();
      final fallbackTenantId = (user.activeTenantId ?? '').trim();
      final fallbackRouteSystemId =
          (user.activeTenantRouteSystemId ?? '').trim().isNotEmpty
          ? user.activeTenantRouteSystemId!.trim()
          : (user.routeSystemId.trim().isNotEmpty
                ? user.routeSystemId.trim()
                : user.orgSystemId.trim());
      final fallbackEntityId = (user.activeEntityId ?? '').trim().isNotEmpty
          ? user.activeEntityId!.trim()
          : (user.orgEntityId ?? '').trim();

      final allowOrgFallback = fallbackTenantType == 'ORG'
          ? canShowOrgOption
          : true;
      if (allowOrgFallback &&
          (fallbackTenantType == 'ORG' || fallbackTenantType == 'BRANCH') &&
          fallbackTenantId.isNotEmpty &&
          fallbackRouteSystemId.isNotEmpty) {
        options.add(
          _LocationOption(
            value: '$fallbackTenantType:$fallbackTenantId',
            tenantId: fallbackTenantId,
            tenantType: fallbackTenantType,
            routeSystemId: fallbackRouteSystemId,
            entityId: fallbackEntityId,
            label: fallbackTenantType == 'BRANCH'
                ? (fallbackRouteSystemId)
                : (user.orgName.isNotEmpty
                      ? user.orgName
                      : fallbackRouteSystemId),
          ),
        );
      }
    }

    final savedValue =
        user.activeTenantId != null && user.activeTenantType != null
        ? '${user.activeTenantType}:${user.activeTenantId}'
        : null;
    final hasSaved =
        savedValue != null &&
        options.any((option) => option.value == savedValue);
    final selectedValue = hasSaved
        ? savedValue
        : (options.isNotEmpty ? options.first.value : null);
    _LocationOption? selectedOption;
    if (selectedValue != null) {
      for (final option in options) {
        if (option.value == selectedValue) {
          selectedOption = option;
          break;
        }
      }
    }

    setState(() {
      _locationOptions = options;
      _selectedLocationValue = selectedValue;
      _locationLoading = false;
    });

    // Self-heal stale route system ids after login/profile hydration.
    // This keeps URL/profile system id aligned with selected branch system id.
    if (selectedOption != null &&
        selectedOption.routeSystemId.trim().isNotEmpty &&
        (selectedOption.routeSystemId.trim() !=
                (user.activeTenantRouteSystemId ?? '').trim() ||
            selectedOption.entityId.trim().isNotEmpty &&
                selectedOption.entityId.trim() !=
                    (user.activeEntityId ?? '').trim())) {
      await ref
          .read(authControllerProvider.notifier)
          .setActiveTenant(
            id: selectedOption.tenantId,
            type: selectedOption.tenantType,
            routeSystemId: selectedOption.routeSystemId,
            entityId: selectedOption.entityId,
          );
    }
  }

  Future<void> _onLocationChanged(String? value, BuildContext context) async {
    if (value == null || value.isEmpty) {
      return;
    }

    final selected = _locationOptions.where((option) => option.value == value);
    if (selected.isEmpty) {
      return;
    }

    final option = selected.first;

    // Persist default branch to DB (fire-and-forget, non-blocking)
    if (option.tenantType == 'BRANCH' && option.tenantId.isNotEmpty) {
      final user = ref.read(authUserProvider);
      if (user != null) {
        unawaited(_persistDefaultBranch(user.id, option.tenantId));
      }
    }

    // Update Auth State
    await ref
        .read(authControllerProvider.notifier)
        .setActiveTenant(
          id: option.tenantId,
          type: option.tenantType,
          routeSystemId: option.routeSystemId,
          entityId: option.entityId,
        );

    // Update Global Entity Context
    if (option.entityId.isNotEmpty) {
      await ref
          .read(entityProvider.notifier)
          .selectEntity(
            entityId: option.entityId,
            name: option.label,
            type: option.tenantType,
            orgId: option.tenantType == 'ORG' ? option.tenantId : null,
            branchId: option.tenantType == 'BRANCH' ? option.tenantId : null,
          );
    }

    if (!mounted) {
      return;
    }

    ref.invalidate(orgSettingsProvider);

    // Clear API response cache so all providers fetch fresh data for new entity
    ref.read(apiClientProvider).clearCache();

    final currentUri = GoRouter.of(context).routeInformationProvider.value.uri;
    final currentPath = currentUri.path;
    final subPath = currentPath.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    final targetSubPath =
        option.tenantType == 'BRANCH' && subPath.startsWith('/settings')
        ? '/home'
        : (subPath.isEmpty ? '/home' : subPath);
    final query = currentUri.query.isNotEmpty ? '?${currentUri.query}' : '';
    final targetPath = '/${option.routeSystemId}$targetSubPath$query';

    // On web, set href directly so the URL and reload happen atomically.
    // context.go + reload() races: reload fires before pushState completes.
    if (kIsWeb) {
      web.window.location.href = targetPath;
    } else {
      context.go(targetPath);
    }
  }

  Future<void> _persistDefaultBranch(String userId, String entityId) async {
    if (userId.trim().isEmpty || entityId.trim().isEmpty) {
      return;
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch(
        '/users/$userId/default-branch',
        data: {'entity_id': entityId},
      );
    } on DioException catch (e) {
      // Best-effort persistence only: never break tenant switch UX.
      // Backend can return envelope-level errors with HTTP 200/4xx while auth
      // refresh is in-flight; swallow and retry naturally on later switches.
      if (kDebugMode) {
        final status = e.response?.statusCode;
        debugPrint(
          '⚠️ default-branch persist skipped '
          '(status=${status ?? 'n/a'}): ${e.message}',
        );
      }
      return;
    } catch (_) {
      // Keep switch flow resilient; persistence retries on next switch/session.
      return;
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go(AppRoutes.authLogin);
  }

  String _effectiveProfileSystemId(User? currentUser) {
    final selectedValue = _selectedLocationValue;
    if (selectedValue != null && selectedValue.isNotEmpty) {
      for (final option in _locationOptions) {
        if (option.value == selectedValue &&
            option.routeSystemId.trim().isNotEmpty) {
          return option.routeSystemId.trim();
        }
      }
    }

    final active = (currentUser?.activeTenantRouteSystemId ?? '').trim();
    if (active.isNotEmpty) return active;

    final route = (currentUser?.routeSystemId ?? '').trim();
    if (route.isNotEmpty) return route;

    final org = (currentUser?.orgSystemId ?? '').trim();
    if (org.isNotEmpty) return org;

    return '-';
  }

  void _syncSearchContext(String currentPath) {
    if (_lastSearchContextKey == currentPath) {
      return;
    }

    final inferredCategory = _inferCategoryFromPath(currentPath);
    _lastSearchContextKey = currentPath;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedCategory = inferredCategory;
        _searchPlaceholder = 'Search in $inferredCategory ( / )';
      });
    });
  }

  String _inferCategoryFromPath(String currentPath) {
    if (currentPath.startsWith('/items/detail') ||
        currentPath.startsWith('/items/create') ||
        currentPath.startsWith('/items/edit')) {
      return 'Items';
    }

    for (final entry in _navEntries) {
      if (currentPath == entry.route ||
          currentPath.startsWith('${entry.route}/')) {
        return entry.label;
      }
    }

    final topLeaf = SidebarBuilder.topLeafForRoute(currentPath);
    if (topLeaf != null && topLeaf.label != 'Home') {
      return topLeaf.label;
    }

    if (currentPath.startsWith('/sales/')) {
      return _salesSearchCategories.firstWhere(
        (label) => label != 'Documents',
        orElse: () => 'Items',
      );
    }
    if (currentPath.startsWith('/purchases/')) {
      return _purchasesSearchCategories.firstWhere(
        (label) => label != 'Documents',
        orElse: () => 'Items',
      );
    }
    if (currentPath.startsWith('/inventory/')) {
      return _inventorySearchCategories.firstWhere(
        (label) => label != 'Documents',
        orElse: () => 'Items',
      );
    }
    if (currentPath.startsWith('/items/')) {
      return 'Items';
    }
    return 'Items';
  }

  List<String> _visibleSearchCategoriesForPath(String currentPath) {
    if (currentPath.startsWith('/sales/')) {
      return _salesSearchCategories;
    }
    if (currentPath.startsWith('/purchases/')) {
      return _purchasesSearchCategories;
    }
    if (currentPath.startsWith('/inventory/') ||
        currentPath.startsWith('/items/')) {
      return _inventorySearchCategories;
    }
    return _searchCategories;
  }

  @override
  Widget build(BuildContext context) {
    final recentItems = ref.watch(recentHistoryProvider);
    final currentUser = ref.watch(authUserProvider);
    if (currentUser != null && _locationSeedUserId != currentUser.id) {
      _locationSeedUserId = currentUser.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadLocationOptions(currentUser);
        }
      });
    }
    final roleLabel = currentUser?.roleLabel?.trim().isNotEmpty == true
        ? currentUser!.roleLabel!.trim()
        : (currentUser?.role == 'ho_admin'
              ? 'HO Admin'
              : currentUser?.role == 'branch_admin'
              ? 'Branch Admin'
              : currentUser?.role == 'admin'
              ? 'Admin'
              : 'User');
    final profileSystemId = _effectiveProfileSystemId(currentUser);
    String pathStr = '';
    try {
      pathStr = GoRouterState.of(context).uri.path;
    } catch (_) {
      pathStr = GoRouter.of(context).routeInformationProvider.value.uri.path;
    }
    final currentPath = pathStr.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    final hideSearch =
        currentPath.startsWith('/purchases/bills') ||
        currentPath.startsWith('/purchases/purchase-orders');
    final isSettingsRoute =
        currentPath == AppRoutes.settings ||
        currentPath.startsWith('${AppRoutes.settings}/');
    if (!isSettingsRoute) {
      _syncSearchContext(currentPath);
    }
    final visibleSearchCategories = _visibleSearchCategoriesForPath(
      currentPath,
    );

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: LayoutBuilder(
        builder: (context, navbarConstraints) {
          final navbarWidth = navbarConstraints.maxWidth;
          final isCompactNavbar = navbarWidth < 900;
          final isVeryCompactNavbar = navbarWidth < 640;
          final isUltraCompactNavbar = navbarWidth < 520;
          final searchMaxWidth = isUltraCompactNavbar
              ? 140.0
              : isVeryCompactNavbar
              ? 180.0
              : isCompactNavbar
              ? 220.0
              : 280.0;
          final searchMinWidth = isUltraCompactNavbar ? 44.0 : 120.0;
          final sectionGap = isUltraCompactNavbar ? 8.0 : 16.0;
          final iconGap = isCompactNavbar ? 8.0 : 12.0;

          return Row(
            children: [
              if (!isSettingsRoute && !hideSearch) ...[
                MenuAnchor(
                  builder: (context, controller, child) {
                    return IconButton(
                      icon: const Icon(Icons.history, color: Colors.grey),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      tooltip: 'Recent Items',
                    );
                  },
                  menuChildren: [
                    if (recentItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No recent items',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    else
                      ...recentItems.map(
                        (item) => MenuItemButton(
                          onPressed: () {
                            if (item.extraData != null) {
                              if (item.type == 'Price List') {
                                context.push(
                                  item.route,
                                  extra: PriceList.fromJson(item.extraData),
                                );
                              } else {
                                context.push(item.route, extra: item.extraData);
                              }
                            } else {
                              context.push(item.route);
                            }
                          },
                          leadingIcon: Icon(
                            _getIconForType(item.type),
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.type,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  style: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    surfaceTintColor: WidgetStateProperty.all(Colors.white),
                    elevation: WidgetStateProperty.all(4),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: AppTheme.borderColor),
                    ),
                    maximumSize: WidgetStateProperty.all(const Size(400, 400)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 36,
                    constraints: BoxConstraints(
                      maxWidth: searchMaxWidth,
                      minWidth: searchMinWidth,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 40) {
                          return const SizedBox.shrink();
                        }
                        final isUltraCompact = constraints.maxWidth < 96;
                        return Row(
                          children: [
                            MenuAnchor(
                              builder: (context, controller, child) {
                                return InkWell(
                                  onTap: () {
                                    if (controller.isOpen) {
                                      controller.close();
                                    } else {
                                      controller.open();
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isUltraCompact ? 4.0 : 8.0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.search,
                                          size: 20,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          controller.isOpen
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              menuChildren: [
                                SizedBox(
                                  height: 300,
                                  width: 220,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ...visibleSearchCategories.map(
                                          (category) => MenuItemButton(
                                            style: MenuItemButton.styleFrom(
                                              backgroundColor:
                                                  _selectedCategory == category
                                                  ? AppTheme.primaryBlue
                                                  : null,
                                              foregroundColor:
                                                  _selectedCategory == category
                                                  ? Colors.white
                                                  : AppTheme.textPrimary,
                                            ),
                                            onPressed: () =>
                                                _updatePlaceholder(category),
                                            child: Container(
                                              width: 180,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    category,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          _selectedCategory ==
                                                              category
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                  if (_selectedCategory ==
                                                      category)
                                                    const Icon(
                                                      Icons.check,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Divider(),
                                        MenuItemButton(
                                          onPressed: () {},
                                          leadingIcon: const Icon(
                                            Icons.search,
                                            size: 16,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          trailingIcon: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bgLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Alt + /',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Advanced Search',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        MenuItemButton(
                                          onPressed: () {},
                                          leadingIcon: const Icon(
                                            Icons.search_outlined,
                                            size: 16,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          trailingIcon: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bgLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Ctrl + /',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Search across Zerpai',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              style: MenuStyle(
                                backgroundColor: WidgetStateProperty.all(
                                  Colors.white,
                                ),
                                surfaceTintColor: WidgetStateProperty.all(
                                  Colors.white,
                                ),
                                elevation: WidgetStateProperty.all(4),
                                side: WidgetStateProperty.all(
                                  const BorderSide(color: AppTheme.borderColor),
                                ),
                                maximumSize: WidgetStateProperty.all(
                                  const Size(400, 400),
                                ),
                              ),
                            ),
                            if (!isUltraCompact) ...[
                              Container(
                                width: 1,
                                height: 20,
                                color: Colors.grey.shade300,
                                margin: const EdgeInsets.only(right: 8),
                              ),
                              Expanded(
                                child: TextField(
                                  focusNode: ZerpaiNavbar.globalSearchFocusNode,
                                  onSubmitted: (value) {
                                    if (value.trim().isEmpty) return;
                                    final route =
                                        _categoryRoutes[_selectedCategory];
                                    if (route != null) {
                                      context.go(
                                        Uri(
                                          path: route,
                                          queryParameters: {'q': value.trim()},
                                        ).toString(),
                                      );
                                    }
                                    FocusScope.of(context).unfocus();
                                  },
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: _searchPlaceholder,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],

              if (!isUltraCompactNavbar) const Spacer(),
              if (isUltraCompactNavbar) const SizedBox(width: 8),

              // Right Actions Section - Fixed Layout
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PWA Install Button
                  if (_canInstall && !isCompactNavbar)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton.icon(
                        onPressed: _installApp,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Install App'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          backgroundColor:
                              AppTheme.infoBg, // Migrated from 0xFFEFF6FF
                        ),
                      ),
                    ),

                  // Upgrade Button
                  if (!isCompactNavbar)
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (!isCompactNavbar)
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),

                  // Org Switcher - Fixed width to prevent overflow
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isUltraCompactNavbar
                          ? 112
                          : isVeryCompactNavbar
                          ? 128
                          : 160,
                    ),
                    child: FormDropdown<String>(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      value: _selectedLocationValue,
                      items: _locationOptions
                          .map((option) => option.value)
                          .toList(),
                      displayStringForValue: (value) {
                        final option = _locationOptions.firstWhere(
                          (item) => item.value == value,
                          orElse: () => const _LocationOption(
                            value: '',
                            tenantId: '',
                            tenantType: '',
                            routeSystemId: '',
                            entityId: '',
                            label: '',
                          ),
                        );
                        if (option.value.isNotEmpty) {
                          return option.label;
                        }
                        return value;
                      },
                      hint: _locationLoading ? 'Loading...' : 'Select Location',
                      onChanged: (value) {
                        if (_locationLoading) {
                          return;
                        }
                        _onLocationChanged(value, context);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(width: sectionGap),

              // Quick Add Button (Green Plus)
              MenuAnchor(
                builder: (context, controller, child) {
                  return Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: ref.watch(appBrandingProvider).accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      tooltip: 'Quick Create',
                    ),
                  );
                },
                menuChildren: [
                  const MenuItemButton(
                    onPressed: null,
                    child: Text(
                      'SALES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        context.push(AppRoutes.salesInvoicesCreate),
                    child: const Text(
                      'Invoice',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () {},
                    child: const Text(
                      'Bill Of Supply',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        context.push(AppRoutes.salesPaymentsReceivedCreate),
                    child: const Text(
                      'Customer Payment',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        context.push(AppRoutes.salesRetainerInvoicesCreate),
                    child: const Text(
                      'Retainer Invoice',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () => context.push(AppRoutes.salesOrdersCreate),
                    child: const Text(
                      'Sales Order',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () {},
                    child: const Text(
                      'Package',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        context.push(AppRoutes.salesDeliveryChallansCreate),
                    child: const Text(
                      'Delivery Challan',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        context.push(AppRoutes.salesCreditNotesCreate),
                    child: const Text(
                      'Credit Note',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                style: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  surfaceTintColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(4),
                  side: WidgetStateProperty.all(
                    const BorderSide(color: AppTheme.borderColor),
                  ),
                  maximumSize: WidgetStateProperty.all(const Size(400, 400)),
                ),
              ),

              SizedBox(width: sectionGap),

              // User/Team Icon
              if (!isVeryCompactNavbar) ...[
                const Icon(
                  Icons.people_outline,
                  color: Colors.black54,
                  size: 22,
                ),
                SizedBox(width: iconGap),
              ],

              // Notification
              Stack(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: Colors.black54,
                    size: 22,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: iconGap),

              // Settings
              InkWell(
                onTap: () => context.go(AppRoutes.settings),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSettingsRoute
                        ? AppTheme.bgLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSettingsRoute
                        ? Border.all(color: AppTheme.borderColor)
                        : null,
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: isSettingsRoute
                        ? AppTheme.textPrimary
                        : Colors.black54,
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: iconGap),

              // Account Menu
              Builder(
                builder: (context) {
                  final orgSettingsAsync = ref.watch(orgSettingsProvider);
                  final logoUrl = orgSettingsAsync.whenOrNull(
                    data: (settings) => settings?.logoUrl,
                  );
                  final orgName =
                      orgSettingsAsync.whenOrNull(
                        data: (settings) => settings?.name,
                      ) ??
                      currentUser?.orgName ??
                      '';
                  final fallbackLabel = orgName.trim().isNotEmpty
                      ? orgName.trim().substring(0, 1).toUpperCase()
                      : 'O';
                  final selectedLocationLabel = (() {
                    final selectedValue = _selectedLocationValue;
                    if (selectedValue == null || selectedValue.isEmpty) {
                      return '';
                    }
                    final selected = _locationOptions.where(
                      (option) => option.value == selectedValue,
                    );
                    if (selected.isEmpty) {
                      return '';
                    }
                    return selected.first.label.trim();
                  })();
                  final normalizedRole = (currentUser?.role ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
                  final isBranchScopedIdentity =
                      normalizedRole == 'branch_admin' ||
                      normalizedRole == 'data_entry' ||
                      ((currentUser?.activeTenantType ?? '')
                              .trim()
                              .toUpperCase() ==
                          'BRANCH') ||
                      (currentUser?.accessibleBranchIds.isNotEmpty ?? false);
                  final firstOptionLabel = _locationOptions.isNotEmpty
                      ? _locationOptions.first.label.trim()
                      : '';
                  final fallbackDisplayName =
                      currentUser?.fullName.trim().isNotEmpty == true
                      ? currentUser!.fullName.trim()
                      : orgName;
                  final displayName = selectedLocationLabel.isNotEmpty
                      ? selectedLocationLabel
                      : (isBranchScopedIdentity
                            ? (firstOptionLabel.isNotEmpty
                                  ? firstOptionLabel
                                  : (currentUser?.activeTenantRouteSystemId ??
                                        ''))
                            : fallbackDisplayName);
                  final email = currentUser?.email ?? '';

                  return MenuAnchor(
                    builder: (context, controller, child) {
                      return InkWell(
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: logoUrl != null && logoUrl.isNotEmpty
                              ? Image.network(
                                  logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        fallbackLabel,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    fallbackLabel,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                    style: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.white),
                      surfaceTintColor: WidgetStateProperty.all(Colors.white),
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      elevation: WidgetStateProperty.all(8),
                      side: WidgetStateProperty.all(
                        const BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    menuChildren: [
                      SizedBox(
                        width: 300,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName.isEmpty
                                              ? 'My Account'
                                              : displayName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => MenuController.maybeOf(
                                      context,
                                    )?.close(),
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppTheme.errorRed,
                                      size: 18,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    splashRadius: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Role: $roleLabel • System ID: $profileSystemId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderLight,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      MenuController.maybeOf(context)?.close();
                                      context.go(
                                        _resolveBranchProfileRoute(
                                              currentUser,
                                            ) ??
                                            AppRoutes.settingsOrgProfile,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'My Account',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () {
                                      MenuController.maybeOf(context)?.close();
                                      _handleSignOut(context);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.errorRed,
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.logout, size: 16),
                                    label: const Text(
                                      'Sign Out',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(width: iconGap),

              // App Grid
              const Icon(Icons.apps, color: Colors.black54, size: 22),
            ],
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Price List':
        return Icons.receipt_long_outlined;
      case 'Item':
        return Icons.inventory_2_outlined;
      case 'Customer':
        return Icons.person_outline;
      case 'Sales Order':
        return Icons.shopping_cart_outlined;
      case 'Invoice':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
