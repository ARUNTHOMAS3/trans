import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'zerpai_sidebar_item.dart';

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
      _Child('Items', '/items/report', '/items/create'),
      _Child('Composite Items', '/composite-items', '/composite-items-create'),
      _Child('Item Groups', '/item-groups', '/item-groups-create'),
      _Child('Price Lists', '/price-lists', '/price-lists-create'),
      _Child('Item Mapping', '/item-mapping', '/item-mapping-create'),
    ],
    'Inventory': [
      _Child('Assemblies', '/assemblies', '/assemblies-create'),
      _Child(
        'Inventory Adjustments',
        '/inventory-adjustments',
        '/inventory-adjustments-create',
      ),
      _Child('Picklists', '/picklists', '/picklists-create'),
      _Child('Packages', '/packages', '/packages-create'),
      _Child('Shipments', '/shipments', '/shipments-create'),
      _Child('Transfer Orders', '/transfer-orders', '/transfer-orders-create'),
    ],
    'Purchases': [
      _Child('Vendors', '/vendors', '/vendors-create'),
      _Child('Expenses', '/expenses', '/expenses-create'),
      _Child(
        'Recurring Expenses',
        '/recurring-expenses',
        '/recurring-expenses-create',
      ),
      _Child('Purchase Orders', '/purchase-orders', '/purchase-orders-create'),
      _Child('Bills', '/bills', '/bills-create'),
      _Child('Recurring Bills', '/recurring-bills', '/recurring-bills-create'),
      _Child('Payments Made', '/payments-made', '/payments-made-create'),
      _Child('Vendor Credits', '/vendor-credits', '/vendor-credits-create'),
    ],
  };

  final Map<String, IconData> _icons = {
    'Home': Icons.home_outlined,
    'Items': Icons.shopping_bag_outlined,
    'Inventory': Icons.inventory_2_outlined,
    'Sales': Icons.point_of_sale_outlined,
    'Purchases': Icons.local_shipping_outlined,
    'Reports': Icons.bar_chart_outlined,
    'Documents': Icons.insert_drive_file_outlined,
  };

  // ---------------- STATE ----------------

  static String _activeMenu = 'Home';
  final Set<String> _expandedParents = {'Items'};
  static bool _isCollapsed = false;

  OverlayEntry? _submenuOverlay;

  bool _hoverParent = false;
  bool _hoverSubmenu = false;
  Timer? _hideTimer;

  @override
  Widget build(BuildContext context) {
    ZerpaiSidebarItem.isCollapsed = _isCollapsed;

    return AnimatedContainer(
      width: _isCollapsed ? 72 : 230,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      color: const Color(0xFF1F2637),
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _buildBrand(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _leaf('Home', '/home'),

                ..._menu.entries.expand((entry) {
                  final parent = entry.key;
                  final children = entry.value;

                  return [
                    _parent(parent),
                    if (_expandedParents.contains(parent) && !_isCollapsed)
                      ...children.map(_child),
                  ];
                }),

                _leaf('Sales', '/sales'),
                _leaf('Reports', '/reports'),
                _leaf('Documents', '/documents'),
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
              color: const Color(0xFF1F2637),
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
              if (box != null) {
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
                  isExpanded
                      ? _expandedParents.remove(label)
                      : _expandedParents.add(label);
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
      showAddButton: true,
      isActive: _activeMenu == c.label,
      onTap: () => _select(c.label, c.listRoute),
      onAdd: () => _select(c.label, c.createRoute),
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
      child: Row(
        mainAxisAlignment: _isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          const _BrandMark(),
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
    );
  }

  // void _select(String menu, String route) {
  //   setState(() => _activeMenu = menu);
  //   widget.onNavigate?.call(route);
  // }

  void _select(String menu, String route) {
    setState(() {
      _activeMenu = menu;

      // ✅ Collapse parent highlight when a leaf is selected
      if (!_menu.containsKey(menu)) {
        _expandedParents.clear();
      }
    });

    widget.onNavigate?.call(route);
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        '₹',
        style: AppTheme.bodyText.copyWith(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
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

  static const Color _activeBlue = AppTheme.primaryBlueDark; // blue (you can tweak)
  static const Color _hoverBg = Color(0xFF2B3040);

  @override
  Widget build(BuildContext context) {
    final bool showPlus = widget.isActive || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onOpen,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? _activeBlue
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
                    color: widget.isActive ? Colors.white : Colors.white,
                    fontSize: 13,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),

              // ➕ ADD BUTTON (active always shows, otherwise hover)
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
                          ? Colors.white.withValues(alpha: 46)
                          : const Color(0xFF3A4157),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: widget.isActive ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        ? Icons.chevron_right
        : Icons.chevron_left;

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

  const _Child(this.label, this.listRoute, this.createRoute);
}
