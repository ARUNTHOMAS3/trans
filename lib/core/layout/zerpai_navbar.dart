import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/shared/services/recent_history_service.dart';
import 'package:zerpai_erp/modules/items/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
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

  static const List<String> _inventorySearchCategories = [
    'Items',
    'Composite Items',
    'Assemblies',
    'Price Lists',
    'Inventory Adjustments',
    'Transfer Orders',
    'Picklists',
    'Packages',
    'Shipments',
    'Delivery Challans',
    'Documents',
  ];

  static const List<String> _salesSearchCategories = [
    'Customers',
    'Retainer Invoices',
    'Sales Orders',
    'Invoices',
    'Sales Returns',
    'Credit Notes',
    'Delivery Challans',
    'Documents',
  ];

  static const List<String> _purchasesSearchCategories = [
    'Vendors',
    'Purchase Orders',
    'Purchase Receives',
    'Bills',
    'Payments Made',
    'Vendor Credits',
    'Documents',
  ];

  final Map<String, String> _categoryRoutes = {
    'Customers': AppRoutes.salesCustomers,
    'Items': AppRoutes.itemsReport,
    'Composite Items': AppRoutes.compositeItems,
    'Assemblies': AppRoutes.assemblies,
    'Price Lists': AppRoutes.priceLists,
    'Inventory Adjustments': AppRoutes.inventoryAdjustments,
    'Transfer Orders': AppRoutes.transferOrders,
    'Retainer Invoices': AppRoutes.salesRetainerInvoices,
    'Sales Orders': AppRoutes.salesOrders,
    'Invoices': AppRoutes.salesInvoices,
    'Sales Returns': AppRoutes.salesReturns,
    'Credit Notes': AppRoutes.salesCreditNotes,
    'Vendors': AppRoutes.vendors,
    'Purchase Orders': AppRoutes.purchaseOrders,
    'Purchase Receives': AppRoutes.purchaseReceives,
    'Bills': AppRoutes.bills,
    'Payments Made': AppRoutes.paymentsMade,
    'Vendor Credits': AppRoutes.vendorCredits,
    'Documents': AppRoutes.documents,
    'Picklists': AppRoutes.picklists,
    'Packages': AppRoutes.packages,
    'Shipments': AppRoutes.shipments,
    'Delivery Challans': AppRoutes.salesDeliveryChallans,
  };

  final List<String> _searchCategories = [
    'Customers',
    'Items',
    'Composite Items',
    'Assemblies',
    'Price Lists',
    'Inventory Adjustments',
    'Transfer Orders',
    'Retainer Invoices',
    'Sales Orders',
    'Invoices',
    'Sales Returns',
    'Credit Notes',
    'Vendors',
    'Purchase Orders',
    'Purchase Receives',
    'Bills',
    'Payments Made',
    'Vendor Credits',
    'Documents',
    'Picklists',
    'Packages',
    'Shipments',
    'Delivery Challans',
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

    final options = <_LocationOption>[
      _LocationOption(
        value: 'ORG:${user.orgId}',
        tenantId: user.orgId,
        tenantType: 'ORG',
        routeSystemId: user.orgSystemId,
        entityId: user.orgEntityId ?? '',
        label: user.orgName.isNotEmpty ? user.orgName : 'Organization',
      ),
    ];

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

        if (user.role != 'admin' &&
            user.accessibleBranchIds.isNotEmpty &&
            !user.accessibleBranchIds.contains(branchId)) {
          continue;
        }

        final branchSystemId = (branch['system_id'] ?? '').toString().trim();
        final displayName = (branch['display_name'] ?? branch['name'] ?? '').toString().trim();
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
    } catch (_) {
      // Fallback to org-only option.
    }

    if (!mounted) {
      return;
    }

    final savedValue =
        user.activeTenantId != null && user.activeTenantType != null
        ? '${user.activeTenantType}:${user.activeTenantId}'
        : null;
    final hasSaved =
        savedValue != null &&
        options.any((option) => option.value == savedValue);

    setState(() {
      _locationOptions = options;
      _selectedLocationValue = hasSaved
          ? savedValue
          : (options.isNotEmpty ? options.first.value : null);
      _locationLoading = false;
    });
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
    if (option.entityId.isNotEmpty) {
      final user = ref.read(authUserProvider);
      if (user != null) {
        final apiClient = ref.read(apiClientProvider);
        unawaited(apiClient.patch(
          '/users/${user.id}/default-branch',
          data: {'entity_id': option.entityId},
        ));
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
      await ref.read(entityProvider.notifier).selectEntity(
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

  Future<void> _handleSignOut(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go(AppRoutes.authLogin);
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
    final categoryMatchers = <MapEntry<String, List<String>>>[
      const MapEntry('Customers', [AppRoutes.salesCustomers]),
      const MapEntry('Sales Orders', [AppRoutes.salesOrders]),
      const MapEntry('Retainer Invoices', [AppRoutes.salesRetainerInvoices]),
      const MapEntry('Invoices', [AppRoutes.salesInvoices]),
      const MapEntry('Sales Returns', [AppRoutes.salesReturns]),
      const MapEntry('Credit Notes', [AppRoutes.salesCreditNotes]),
      const MapEntry('Delivery Challans', [AppRoutes.salesDeliveryChallans]),
      const MapEntry('Items', [
        AppRoutes.itemsReport,
        '/items/detail',
        '/items/create',
        '/items/edit',
      ]),
      const MapEntry('Composite Items', [AppRoutes.compositeItems]),
      const MapEntry('Assemblies', [AppRoutes.assemblies]),
      const MapEntry('Price Lists', [AppRoutes.priceLists]),
      const MapEntry('Inventory Adjustments', [AppRoutes.inventoryAdjustments]),
      const MapEntry('Transfer Orders', [AppRoutes.transferOrders]),
      const MapEntry('Picklists', [AppRoutes.picklists]),
      const MapEntry('Packages', [AppRoutes.packages]),
      const MapEntry('Shipments', [AppRoutes.shipments]),
      const MapEntry('Vendors', [AppRoutes.vendors]),
      const MapEntry('Purchase Orders', [AppRoutes.purchaseOrders]),
      const MapEntry('Purchase Receives', [AppRoutes.purchaseReceives]),
      const MapEntry('Bills', [AppRoutes.bills]),
      const MapEntry('Payments Made', [AppRoutes.paymentsMade]),
      const MapEntry('Vendor Credits', [AppRoutes.vendorCredits]),
      const MapEntry('Documents', [AppRoutes.documents]),
    ];

    for (final matcher in categoryMatchers) {
      if (matcher.value.any(
        (prefix) => currentPath == prefix || currentPath.startsWith('$prefix/'),
      )) {
        return matcher.key;
      }
    }

    if (currentPath.startsWith('/sales/')) {
      return 'Customers';
    }
    if (currentPath.startsWith('/purchases/')) {
      return 'Vendors';
    }
    if (currentPath.startsWith('/inventory/')) {
      return 'Assemblies';
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
    final currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
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
      child: Row(
        children: [
          if (!isSettingsRoute) ...[
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
                constraints: const BoxConstraints(maxWidth: 280, minWidth: 120),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  _selectedCategory == category
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (_selectedCategory == category)
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
                                      borderRadius: BorderRadius.circular(4),
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
                                      borderRadius: BorderRadius.circular(4),
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
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        surfaceTintColor: WidgetStateProperty.all(Colors.white),
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
                                final route = _categoryRoutes[_selectedCategory];
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

          const Spacer(),

          // Right Actions Section - Fixed Layout
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PWA Install Button
              if (_canInstall)
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),

              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Org Switcher - Fixed width to prevent overflow
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
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

          const SizedBox(width: 16),

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
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
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
                onPressed: () => context.push(AppRoutes.salesInvoicesCreate),
                child: const Text('Invoice', style: TextStyle(fontSize: 13)),
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
                child: const Text('Package', style: TextStyle(fontSize: 13)),
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
                onPressed: () => context.push(AppRoutes.salesCreditNotesCreate),
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

          const SizedBox(width: 16),

          // User/Team Icon
          const Icon(Icons.people_outline, color: Colors.black54, size: 22),
          const SizedBox(width: 12),

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
          const SizedBox(width: 12),

          // Settings
          InkWell(
            onTap: () => context.go(AppRoutes.settings),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSettingsRoute ? AppTheme.bgLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSettingsRoute
                    ? Border.all(color: AppTheme.borderColor)
                    : null,
              ),
              child: Icon(
                Icons.settings_outlined,
                color: isSettingsRoute ? AppTheme.textPrimary : Colors.black54,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

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
              final displayName =
                  currentUser?.fullName.trim().isNotEmpty == true
                  ? currentUser!.fullName.trim()
                  : orgName;
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                onPressed: () =>
                                    MenuController.maybeOf(context)?.close(),
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
                            'Role: $roleLabel • System ID: ${currentUser?.routeSystemId.isNotEmpty == true ? currentUser?.routeSystemId : (currentUser?.orgSystemId ?? '-')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppTheme.borderLight),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  MenuController.maybeOf(context)?.close();
                                  context.go(AppRoutes.settingsOrgProfile);
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
          const SizedBox(width: 12),

          // App Grid
          const Icon(Icons.apps, color: Colors.black54, size: 22),
        ],
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
