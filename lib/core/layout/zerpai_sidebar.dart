import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'zerpai_sidebar_item.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ZerpaiSidebar extends StatefulWidget {
  final ValueChanged<String>? onNavigate;

  const ZerpaiSidebar({super.key, this.onNavigate});

  @override
  State<ZerpaiSidebar> createState() => _ZerpaiSidebarState();
}

class _ZerpaiSidebarState extends State<ZerpaiSidebar> {
  // ---------------- MENU CONFIG ----------------

  final Map<String, List<_Child>> _menu = {
    'Items': [
      _Child('Items', AppRoutes.itemsReport, AppRoutes.itemsCreate),
      _Child(
        'Composite Items',
        AppRoutes.compositeItems,
        AppRoutes.compositeItemsCreate,
      ),
      _Child('Item Groups', AppRoutes.itemGroups, AppRoutes.itemGroupsCreate),
      _Child('Price Lists', AppRoutes.priceLists, AppRoutes.priceListsCreate),
      _Child(
        'Item Mapping',
        AppRoutes.itemMapping,
        AppRoutes.itemMappingCreate,
      ),
    ],
    'Inventory': [
      _Child('Assemblies', AppRoutes.assemblies, AppRoutes.assembliesCreate),
      _Child(
        'Inventory Adjustments',
        AppRoutes.inventoryAdjustments,
        AppRoutes.inventoryAdjustmentsCreate,
      ),
      _Child('Picklists', AppRoutes.picklists, AppRoutes.picklistsCreate),
      _Child('Packages', AppRoutes.packages, AppRoutes.packagesCreate),
      _Child('Shipments', AppRoutes.shipments, AppRoutes.shipmentsCreate),
      _Child(
        'Transfer Orders',
        AppRoutes.transferOrders,
        AppRoutes.transferOrdersCreate,
      ),
    ],
    'Sales': [
      _Child(
        'Customers',
        AppRoutes.salesCustomers,
        AppRoutes.salesCustomersCreate,
      ),
      _Child(
        'Retainer Invoices',
        AppRoutes.salesRetainerInvoices,
        AppRoutes.salesRetainerInvoicesCreate,
      ),
      _Child(
        'Sales Orders',
        AppRoutes.salesOrders,
        AppRoutes.salesOrdersCreate,
      ),
      _Child(
        'Invoices',
        AppRoutes.salesInvoices,
        AppRoutes.salesInvoicesCreate,
      ),
      _Child(
        'Delivery Challans',
        AppRoutes.salesDeliveryChallans,
        AppRoutes.salesDeliveryChallansCreate,
      ),
      _Child(
        'Payments Received',
        AppRoutes.salesPaymentsReceived,
        AppRoutes.salesPaymentsReceivedCreate,
      ),
      _Child('Sales Returns', AppRoutes.salesReturns, AppRoutes.salesReturns),
      _Child(
        'Credit Notes',
        AppRoutes.salesCreditNotes,
        AppRoutes.salesCreditNotesCreate,
      ),
      _Child(
        'e-Way Bills',
        AppRoutes.salesEWayBills,
        AppRoutes.salesEWayBillsCreate,
      ),
    ],
    'Purchases': [
      _Child('Vendors', AppRoutes.vendors, AppRoutes.vendorsCreate),
      _Child('Expenses', AppRoutes.expenses, AppRoutes.expensesCreate),
      _Child(
        'Recurring Expenses',
        AppRoutes.recurringExpenses,
        AppRoutes.recurringExpensesCreate,
      ),
      _Child(
        'Purchase Orders',
        AppRoutes.purchaseOrders,
        AppRoutes.purchaseOrdersCreate,
      ),
      _Child('Bills', AppRoutes.bills, AppRoutes.billsCreate),
      _Child(
        'Recurring Bills',
        AppRoutes.recurringBills,
        AppRoutes.recurringBillsCreate,
      ),
      _Child(
        'Payments Made',
        AppRoutes.paymentsMade,
        AppRoutes.paymentsMadeCreate,
      ),
      _Child(
        'Vendor Credits',
        AppRoutes.vendorCredits,
        AppRoutes.vendorCreditsCreate,
      ),
    ],
    'Accountant': [
      _Child(
        'Manual Journals',
        AppRoutes.accountantManualJournals,
        AppRoutes.accountantManualJournalsCreate,
      ),
      _Child(
        'Recurring Journals',
        AppRoutes.accountantRecurringJournals,
        AppRoutes.accountantRecurringJournalsCreate,
      ),
      _Child(
        'Bulk Update',
        AppRoutes.accountantBulkUpdate,
        '/placeholder',
        showAdd: false,
      ),
      _Child(
        'Transaction Locking',
        AppRoutes.accountantTransactionLocking,
        '/placeholder',
        showAdd: false,
      ),
      _Child(
        'Opening Balances',
        AppRoutes.accountantOpeningBalances,
        AppRoutes.accountantOpeningBalancesUpdate,
        showAdd: true,
      ),
    ],
    'Accounts': [
      _Child(
        'Chart of Accounts',
        AppRoutes.accountsChartOfAccounts,
        AppRoutes.accountsChartOfAccountsCreate,
        showAdd: false,
      ),
    ],
  };

  final Map<String, IconData> _icons = {
    'Home': LucideIcons.home,
    'Accountant': LucideIcons.landmark,
    'Accounts': LucideIcons.wallet,
    'Items': LucideIcons.shoppingBag,
    'Inventory': LucideIcons.package,
    'Sales': LucideIcons.shoppingCart,
    'Purchases': LucideIcons.truck,
    'Reports': LucideIcons.barChart2,
    'Documents': LucideIcons.fileText,
    'Audit Logs': LucideIcons.history,
  };

  // ---------------- STATE ----------------

  static String _activeMenu = 'Home';
  static final Set<String> _expandedParents = {'Items'};
  static bool _isCollapsed = false;

  OverlayEntry? _submenuOverlay;

  bool _hoverParent = false;
  bool _hoverSubmenu = false;
  Timer? _hideTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateActiveMenuFromRoute();
  }

  void _updateActiveMenuFromRoute() {
    final String location = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.last.matchedLocation;

    String? currentMatchedMenu;

    // Check top level leaves first
    if (location == AppRoutes.home) {
      currentMatchedMenu = 'Home';
    } else if (location.startsWith(AppRoutes.reports)) {
      currentMatchedMenu = 'Reports';
    } else if (location.startsWith(AppRoutes.documents)) {
      currentMatchedMenu = 'Documents';
    } else if (location.startsWith(AppRoutes.auditLogs)) {
      currentMatchedMenu = 'Audit Logs';
    } else {
      // Check Accountant and Accounts module sub-routes generically
      if (location.startsWith('/accountant/')) {
        if (!_isCollapsed) _expandedParents.add('Accountant');
      } else if (location.startsWith('/accounts/')) {
        if (!_isCollapsed) _expandedParents.add('Accounts');
      }

      // Find matching menu item in the deep menu structure
      for (var entry in _menu.entries) {
        final parent = entry.key;
        final children = entry.value;

        for (var child in children) {
          if (location.startsWith(child.listRoute) && child.listRoute != '/') {
            currentMatchedMenu = child.label;
            if (!_isCollapsed) {
              _expandedParents.add(parent);
            }
            break;
          }
        }
        if (currentMatchedMenu != null) break;
      }
    }

    if (_activeMenu != currentMatchedMenu) {
      setState(() => _activeMenu = currentMatchedMenu ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    ZerpaiSidebarItem.isCollapsed = _isCollapsed;

    return AnimatedContainer(
      width: _isCollapsed ? 72 : 230,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      color: const Color(0xFF1F2637), // ✅ Fixed to match backup
      padding: const EdgeInsets.only(top: 16, bottom: 12), // ✅ Fixed padding
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _buildBrand(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _leaf('Home', AppRoutes.home),

                ..._menu.entries.expand((entry) {
                  final parent = entry.key;
                  final children = entry.value;

                  return [
                    _parent(parent),
                    if (_expandedParents.contains(parent) && !_isCollapsed)
                      ...children.map(_child),
                  ];
                }),

                _leaf('Reports', AppRoutes.reports),
                _leaf('Documents', AppRoutes.documents),
                _leaf('Audit Logs', AppRoutes.auditLogs),
              ],
            ),
          ),
          _collapseToggle(),
        ],
      ),
    );
  }

  // ---------------- FLOATING SUBMENU ----------------

  void _showFloatingMenu({
    required BuildContext context,
    required RenderBox parentBox,
    required String parentLabel,
  }) {
    _removeFloatingMenu();

    final Offset position = parentBox.localToGlobal(Offset.zero);
    final Size size = parentBox.size;

    _submenuOverlay = OverlayEntry(
      builder: (_) {
        return Positioned(
          left: position.dx + size.width + 8,
          top: position.dy,
          child: MouseRegion(
            onEnter: (_) {
              _hoverSubmenu = true;
              _cancelHide();
            },
            onExit: (_) {
              _hoverSubmenu = false;
              _scheduleHide();
            },
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF2C3E50), // Sidebar background color
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // -------- PARENT HEADING --------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text(
                        parentLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.white70,
                        ),
                      ),
                    ),

                    ..._menu[parentLabel]!.map((c) {
                      final bool isActive = _activeMenu == c.label;

                      return _FloatingChildRow(
                        label: c.label,
                        isActive: isActive,
                        onOpen: () {
                          _removeFloatingMenu();
                          _select(c.label, c.listRoute);
                        },
                        onAdd: () {
                          _removeFloatingMenu();
                          _select(c.label, c.createRoute);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_submenuOverlay!);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 180), () {
      if (!_hoverParent && !_hoverSubmenu) {
        _removeFloatingMenu();
      }
    });
  }

  void _cancelHide() {
    _hideTimer?.cancel();
  }

  void _removeFloatingMenu() {
    _hideTimer?.cancel();
    _submenuOverlay?.remove();
    _submenuOverlay = null;
  }

  // ---------------- BUILDERS ----------------

  Widget _leaf(String label, String route) {
    return ZerpaiSidebarItem(
      icon: _icons[label]!,
      label: label,
      isActive: _activeMenu == label,
      onTap: () => _select(label, route),
    );
  }

  Widget _parent(String label) {
    final bool isExpanded = _expandedParents.contains(label);
    final bool isActive = _menu[label]!.any(
      (child) => child.label == _activeMenu,
    );

    return Builder(
      builder: (itemContext) {
        return MouseRegion(
          onEnter: (_) {
            if (_isCollapsed) {
              _hoverParent = true;
              _cancelHide();

              final box = itemContext.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                _showFloatingMenu(
                  context: context,
                  parentBox: box,
                  parentLabel: label,
                );
              }
            }
          },
          onExit: (_) {
            if (_isCollapsed) {
              _hoverParent = false;
              _scheduleHide();
            }
          },
          child: ZerpaiSidebarItem(
            icon: _icons[label]!,
            label: label,
            isActive: isActive,
            hasChildren: true,
            isExpanded: isExpanded,
            onTap: () {
              if (!_isCollapsed) {
                setState(() {
                  if (isExpanded) {
                    _expandedParents.remove(label);
                  } else {
                    _expandedParents.clear();
                    _expandedParents.add(label);
                  }
                });
              }
            },
          ),
        );
      },
    );
  }

  Widget _child(_Child c) {
    return ZerpaiSidebarItem(
      icon: Icons.circle,
      label: c.label,
      isSubItem: true,
      showIcon: false,
      showAddButton: c.showAdd,
      isActive: _activeMenu == c.label,
      onTap: () => _select(c.label, c.listRoute),
      onAdd: () => _select(c.label, c.createRoute, isAdd: true),
    );
  }

  // ---------------- COMMON ----------------

  Widget _collapseToggle() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10, bottom: 8, top: 4),
        child: Material(
          color: const Color(0xFF2B3040),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _removeFloatingMenu();
              setState(() => _isCollapsed = !_isCollapsed);
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(child: _CollapseIcon(isCollapsed: _isCollapsed)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisAlignment: _isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            const Icon(LucideIcons.receipt, color: Colors.white, size: 22),
            if (!_isCollapsed) ...[
              const SizedBox(width: 10),
              const Text(
                'Zerpai',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // void _select(String menu, String route) {
  //   setState(() => _activeMenu = menu);
  //   widget.onNavigate?.call(route);
  // }

  void _select(String menu, String route, {bool isAdd = false}) {
    if (isAdd) {
      context.go(route);
      return;
    }
    setState(() {
      _activeMenu = menu;

      // ✅ Find if this menu item belongs to a parent
      String? parentKey;
      for (var entry in _menu.entries) {
        if (entry.value.any((child) => child.label == menu)) {
          parentKey = entry.key;
          break;
        }
      }

      if (parentKey != null) {
        // Keep the parent expanded and collapse others (Accordion)
        _expandedParents.clear();
        _expandedParents.add(parentKey);
      } else if (!_menu.containsKey(menu)) {
        // Only clear if it's a top-level leaf (like Home, Sales, etc.)
        _expandedParents.clear();
      }
    });

    widget.onNavigate?.call(route);
  }
}

// ---------------- FLOATING SUBMENU CHILD ROW ----------------

class _FloatingChildRow extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  const _FloatingChildRow({
    required this.label,
    required this.isActive,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  State<_FloatingChildRow> createState() => _FloatingChildRowState();
}

class _FloatingChildRowState extends State<_FloatingChildRow> {
  bool _hovered = false;
  static const Color _activeGreen = Color(0xFF22A95E); // PRD 14.12.1
  static const Color _hoverBg = Color(0xFF3E4F63);

  @override
  Widget build(BuildContext context) {
    final bool showPlus = widget.isActive || _hovered;

    return InkWell(
      onTap: widget.onOpen,
      onHover: (v) => setState(() => _hovered = v),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isActive
              ? _activeGreen
              : (_hovered ? _hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
            // ➕ ADD BUTTON
            AnimatedOpacity(
              opacity: showPlus ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: GestureDetector(
                onTap: widget.onAdd,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  width: 28,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? Colors.white.withValues(alpha: 46 / 255)
                        : const Color(0xFF34495E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 14,
                    color: widget.isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapseIcon extends StatelessWidget {
  final bool isCollapsed;

  const _CollapseIcon({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    const Color color = Colors.white;
    final IconData arrow = isCollapsed
        ? LucideIcons.chevronRight
        : LucideIcons.chevronLeft;

    Widget line() {
      return Container(
        width: 10,
        height: 2,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }

    final Widget lines = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        const SizedBox(height: 3),
        line(),
        const SizedBox(height: 3),
        line(),
      ],
    );

    final Widget arrowIcon = Icon(arrow, size: 16, color: color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isCollapsed
          ? [lines, const SizedBox(width: 4), arrowIcon]
          : [arrowIcon, const SizedBox(width: 4), lines],
    );
  }
}

// ---------------- MODEL ----------------

class _Child {
  final String label;
  final String listRoute;
  final String createRoute;
  final bool showAdd;

  const _Child(
    this.label,
    this.listRoute,
    this.createRoute, {
    this.showAdd = true,
  });
}
