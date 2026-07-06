import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/app/navigation/sidebar_builder.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/auth/capability_service.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/core/layout/zerpai_sidebar_item.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ZerpaiSidebar extends ConsumerStatefulWidget {
  static const double expandedWidth = 230;
  static const double collapsedWidth = 72;
  static final ValueNotifier<bool> collapsedNotifier = ValueNotifier<bool>(
    false,
  );

  final ValueChanged<String>? onNavigate;

  const ZerpaiSidebar({super.key, this.onNavigate});

  @override
  ConsumerState<ZerpaiSidebar> createState() => _ZerpaiSidebarState();
}

/// Strips the leading /:orgSystemId segment from a path for comparison with AppRoutes constants.
String _stripOrgPrefix(String path) {
  return path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
}

class _ZerpaiSidebarState extends ConsumerState<ZerpaiSidebar> {
  String _safeCurrentPath() {
    try {
      final configuration = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration;
      if (configuration.isNotEmpty) {
        return configuration.last.matchedLocation;
      }
    } catch (_) {}

    try {
      return GoRouter.of(context).routeInformationProvider.value.uri.path;
    } catch (_) {
      return '';
    }
  }

  // ---------------- MENU CONFIG ----------------

  final Map<String, List<_Child>> _menu = SidebarBuilder.menuByParent().map(
    (key, value) => MapEntry(
      key,
      value
          .map(
            (item) => _Child(
              item.label,
              item.listRoute,
              item.createRoute,
              permissionKey: item.permissionKey,
              showAdd: item.showAdd,
            ),
          )
          .toList(growable: false),
    ),
  );

  final Map<String, IconData> _icons = SidebarBuilder.iconByParent();

  // ---------------- STATE ----------------

  static String _activeMenu = 'Home';
  static String _activeParent = '';
  static final Set<String> _expandedParents = {'Items'};
  static bool _isCollapsed = false;
  static bool _wasOnSettingsRoute = false;
  static String _lastSyncedLocation = '';
  // Stores the user's sidebar state before entering settings so it can be restored on exit.
  static bool? _preSettingsCollapsed;

  OverlayEntry? _submenuOverlay;

  bool _hoverParent = false;
  bool _hoverSubmenu = false;
  Timer? _hideTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoCollapseForSettings();
    _updateActiveMenuFromRoute();
    // Defer notifier update so it doesn't fire mid-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ZerpaiSidebar.collapsedNotifier.value = _isCollapsed;
      }
    });
  }

  void _autoCollapseForSettings() {
    final String location = _stripOrgPrefix(_safeCurrentPath());
    final bool isSettings =
        location == AppRoutes.settings ||
        location.startsWith('${AppRoutes.settings}/');

    if (isSettings && !_wasOnSettingsRoute) {
      // Entering settings — save current state then collapse
      _preSettingsCollapsed = _isCollapsed;
      _isCollapsed = true;
    } else if (!isSettings && _wasOnSettingsRoute) {
      // Leaving settings — restore what the user had before
      _isCollapsed = _preSettingsCollapsed ?? false;
      _preSettingsCollapsed = null;
    }
    _wasOnSettingsRoute = isSettings;
  }

  void _updateActiveMenuFromRoute() {
    final String location = _stripOrgPrefix(_safeCurrentPath());
    final bool routeChanged = location != _lastSyncedLocation;

    String? currentMatchedMenu;
    String? currentMatchedParent;

    final matchedTopLeaf = SidebarBuilder.topLeafForRoute(location);
    if (matchedTopLeaf != null) {
      currentMatchedMenu = matchedTopLeaf.label;
      currentMatchedParent = null;
    } else {
      // Find matching menu item in the deep menu structure
      for (var entry in _menu.entries) {
        final parent = entry.key;
        final children = entry.value;

        for (var child in children) {
          if (location.startsWith(child.listRoute) && child.listRoute != '/') {
            currentMatchedMenu = child.label;
            currentMatchedParent = parent;
            if (!_isCollapsed && routeChanged) {
              _expandedParents
                ..clear()
                ..add(parent);
            }
            break;
          }
        }
        if (currentMatchedMenu != null) break;
      }

      final matchedParent = SidebarBuilder.parentForRoute(location);
      if (matchedParent != null && !_isCollapsed && routeChanged) {
        _expandedParents
          ..clear()
          ..add(matchedParent);
      }
      currentMatchedParent ??= matchedParent;
    }

    if (_activeMenu != currentMatchedMenu) {
      _activeMenu = currentMatchedMenu ?? '';
    }
    if (_activeParent != (currentMatchedParent ?? '')) {
      _activeParent = currentMatchedParent ?? '';
    }

    _lastSyncedLocation = location;
  }

  @override
  Widget build(BuildContext context) {
    // Call on every build so route changes (driven by parent shell rebuild)
    // are always caught, not just when didChangeDependencies fires.
    _autoCollapseForSettings();
    _updateActiveMenuFromRoute();

    final branding = ref.watch(appBrandingProvider);
    final user = ref.watch(authUserProvider);
    final visibleMenu = _visibleMenuByPermission(user);

    // Sync statics so ZerpaiSidebarItem picks up live branding values.
    ZerpaiSidebarItem.isCollapsed = _isCollapsed;
    ZerpaiSidebarItem.accentColor = branding.accentColor;
    ZerpaiSidebarItem.hoverBg = branding.itemHoverBg;
    ZerpaiSidebarItem.activeParentBg = branding.activeParentBg;
    ZerpaiSidebarItem.collapseToggleBg = branding.collapseToggleBg;
    ZerpaiSidebarItem.itemFg = branding.itemFg;
    ZerpaiSidebarItem.itemFgMuted = branding.itemFgMuted;

    return AnimatedContainer(
      width: _isCollapsed
          ? ZerpaiSidebar.collapsedWidth
          : ZerpaiSidebar.expandedWidth,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      color: branding.sidebarBg,
      padding: const EdgeInsets.only(top: 16, bottom: 12), // ✅ Fixed padding
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _buildBrand(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ...SidebarBuilder.topLeaves
                    .where(
                      (leaf) =>
                          leaf.label == 'Home' &&
                          _isLeafVisible(user, leaf.label),
                    )
                    .map((leaf) => _leaf(leaf.label, leaf.route)),

                ...visibleMenu.entries.expand((entry) {
                  final parent = entry.key;
                  final children = entry.value;

                  return [
                    _parent(parent),
                    if (_expandedParents.contains(parent) && !_isCollapsed)
                      ...children.map(_child),
                  ];
                }),

                ...SidebarBuilder.topLeaves
                    .where(
                      (leaf) =>
                          leaf.label != 'Home' &&
                          _isLeafVisible(user, leaf.label),
                    )
                    .map((leaf) => _leaf(leaf.label, leaf.route)),
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

    final user = ref.read(authUserProvider);
    final children = _visibleChildrenForParent(user, parentLabel);
    if (children.isEmpty) {
      return;
    }

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

                    ...children.map((c) {
                      final bool isActive = _activeMenu == c.label;
                      final bool canAdd = _canCreateChild(user, c);

                      return _FloatingChildRow(
                        label: c.label,
                        isActive: isActive,
                        canAdd: canAdd,
                        accentColor: ZerpaiSidebarItem.accentColor,
                        onOpen: () {
                          _removeFloatingMenu();
                          _select(c.label, c.listRoute);
                        },
                        onAdd: canAdd
                            ? () {
                                _removeFloatingMenu();
                                _select(c.label, c.createRoute);
                              }
                            : null,
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

  String _resolveCurrentOrgSystemId() {
    final state = GoRouterState.of(context);
    final routeId = (state.pathParameters['orgSystemId'] ?? '').trim();
    if (routeId.isNotEmpty) return routeId;
    final currentPath = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.path;
    final match = RegExp(r'^/(\d{10,20})(?:/|$)').firstMatch(currentPath);
    return (match?.group(1) ?? '').trim();
  }

  String _withCurrentOrgPrefix(String route) {
    if (route.isEmpty) return route;
    if (RegExp(r'^/\d{10,20}(?:/|$)').hasMatch(route)) return route;
    final orgSystemId = _resolveCurrentOrgSystemId();
    if (orgSystemId.isEmpty) return route;
    return '/$orgSystemId$route';
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
    final user = ref.watch(authUserProvider);
    final visibleChildren = _visibleChildrenForParent(user, label);
    if (visibleChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isExpanded = _expandedParents.contains(label);
    final bool hasActiveChild = visibleChildren.any(
      (child) => child.label == _activeMenu,
    );
    // Parent highlight only when section is active but no specific child is active.
    final bool isActive = _activeParent == label && !hasActiveChild;

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
    final user = ref.watch(authUserProvider);
    final canAdd = _canCreateChild(user, c);
    return ZerpaiSidebarItem(
      icon: Icons.circle,
      label: c.label,
      isSubItem: true,
      showIcon: false,
      showAddButton: canAdd,
      isActive: _activeMenu == c.label,
      onTap: () => _select(c.label, c.listRoute),
      onAdd: canAdd ? () => _select(c.label, c.createRoute, isAdd: true) : null,
    );
  }

  // ---------------- COMMON ----------------

  Widget _collapseToggle() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10, bottom: 8, top: 4),
        child: Material(
          color: ZerpaiSidebarItem.collapseToggleBg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _removeFloatingMenu();
              setState(() {
                _isCollapsed = !_isCollapsed;
                ZerpaiSidebar.collapsedNotifier.value = _isCollapsed;
              });
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
            _BrandMark(accentColor: ZerpaiSidebarItem.accentColor),
            if (!_isCollapsed) ...[
              const SizedBox(width: 10),
              Text(
                'Zerpai',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ZerpaiSidebarItem.itemFg,
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

    final resolvedRoute = _withCurrentOrgPrefix(route);
    context.go(resolvedRoute);
    widget.onNavigate?.call(resolvedRoute);
  }

  bool _isLeafVisible(User? user, String label) {
    if (user == null) {
      return false;
    }
    final moduleKey = SidebarBuilder.leafPermissionKeys()[label];
    if (moduleKey == null) {
      return true;
    }
    return CapabilityService.canUserAction(user, moduleKey, action: 'view');
  }

  Map<String, List<_Child>> _visibleMenuByPermission(User? user) {
    if (user == null) {
      return const {};
    }
    final filtered = <String, List<_Child>>{};
    for (final entry in _menu.entries) {
      final visibleChildren = _visibleChildrenForParent(user, entry.key);
      if (visibleChildren.isNotEmpty) {
        filtered[entry.key] = visibleChildren;
      }
    }
    return filtered;
  }

  List<_Child> _visibleChildrenForParent(User? user, String parentLabel) {
    final children = _menu[parentLabel];
    if (children == null || children.isEmpty) {
      return const [];
    }
    if (user == null) {
      return const [];
    }

    return children
        .where((child) => _isChildVisible(user, child))
        .toList(growable: false);
  }

  bool _isChildVisible(User user, _Child child) {
    final key = child.permissionKey;
    if (key == null) {
      return true;
    }
    return CapabilityService.canUserAction(user, key, action: 'view');
  }

  bool _canCreateChild(User? user, _Child child) {
    if (user == null || !child.showAdd) {
      return false;
    }
    final isRestrictedBranchAdmin =
        user.role.trim().toLowerCase() == 'branch_admin' &&
        user.roleIsDefault == true;
    if (isRestrictedBranchAdmin &&
        child.listRoute == AppRoutes.branchPriceLists) {
      return false;
    }
    final key = child.permissionKey;
    if (key == null) {
      // Some modules are intentionally sidebar-visible without legacy
      // permission keys wired yet; keep their inline create affordance active.
      return true;
    }
    return CapabilityService.canUserAction(user, key, action: 'create');
  }
}

class _BrandMark extends StatelessWidget {
  final Color accentColor;
  const _BrandMark({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.2),
        border: Border.all(color: accentColor),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        '₹',
        style: AppTheme.bodyText.copyWith(
          color: accentColor,
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
  final bool canAdd;
  final Color accentColor;
  final VoidCallback onOpen;
  final VoidCallback? onAdd;

  const _FloatingChildRow({
    required this.label,
    required this.isActive,
    required this.canAdd,
    required this.accentColor,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  State<_FloatingChildRow> createState() => _FloatingChildRowState();
}

class _FloatingChildRowState extends State<_FloatingChildRow> {
  bool _hovered = false;
  static const Color _hoverBg = Color(0xFF3E4F63);

  @override
  Widget build(BuildContext context) {
    final bool showPlus = widget.canAdd && (widget.isActive || _hovered);

    return InkWell(
      onTap: widget.onOpen,
      onHover: (v) => setState(() => _hovered = v),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isActive
              ? widget.accentColor
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
            if (widget.canAdd)
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
  final String? permissionKey;
  final bool showAdd;

  const _Child(
    this.label,
    this.listRoute,
    this.createRoute, {
    this.permissionKey,
    this.showAdd = true,
  });
}
