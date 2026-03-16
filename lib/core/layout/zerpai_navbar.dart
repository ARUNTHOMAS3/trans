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

@JS()
external void showInstallPrompt();

class ZerpaiNavbar extends ConsumerStatefulWidget {
  const ZerpaiNavbar({super.key});

  @override
  ConsumerState<ZerpaiNavbar> createState() => _ZerpaiNavbarState();
}

class _ZerpaiNavbarState extends ConsumerState<ZerpaiNavbar> {
  // Default placeholder
  String _searchPlaceholder = 'Search in ... ( / )';

  // Currently selected search category
  String _selectedCategory = 'Items';

  // PWA State
  bool _canInstall = false;

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

  @override
  Widget build(BuildContext context) {
    final recentItems = ref.watch(recentHistoryProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // History Icon (Left)
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

          // Search Bar
          Expanded(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(maxWidth: 280, minWidth: 120),
              decoration: BoxDecoration(
                color: AppTheme
                    .bgLight, // Light greyish blue - migrated from 0xFFF1F3F9
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ), // Subtle blue border like in image
              ),
              child: Row(
                children: [
                  // Search Icon & Dropdown Trigger
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                      // Scrollable list of items
                      SizedBox(
                        height: 300,
                        width: 220,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._searchCategories.map(
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
                                  onPressed: () => _updatePlaceholder(category),
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

                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.only(right: 8),
                  ),

                  // Actual Text Input
                  Expanded(
                    child: TextField(
                      onSubmitted: (value) {
                        // swallowing Enter to prevent layout break on Web
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
              ),
            ),
          ),

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
                      foregroundColor:
                          AppTheme.primaryBlue, // Migrated from 0xFF2563EB
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
                  value: 'ZABNIX',
                  items: const ['ZABNIX'],
                  displayStringForValue: (v) => 'ZABNIX PRIVATE LIMITED',
                  onChanged: (_) {},
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
                  color:
                      AppTheme.successGreen, // Green - migrated from 0xFF22C55E
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
                    color: Color(0xFF9CA3AF),
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
          const Icon(Icons.settings_outlined, color: Colors.black54, size: 22),
          const SizedBox(width: 12),

          // Profile Avatar
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 20),
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
