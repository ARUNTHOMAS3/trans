import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ZerpaiSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isSubItem;
  final double iconSize;
  final VoidCallback onTap;
  final bool showIcon;

  /// ➕ Child add button
  final bool showAddButton;
  final VoidCallback? onAdd;

  /// ▶ Parent arrow
  final bool hasChildren;
  final bool isExpanded;

  static bool isCollapsed = false;

  /// Set by [ZerpaiSidebar] from [appBrandingProvider] before each build.
  static Color accentColor = const Color(0xFF22A95E);
  static Color hoverBg = const Color(0xFF3A3F4F);
  static Color activeParentBg = const Color(0xFF2A3A55);
  static Color collapseToggleBg = const Color(0xFF2B3040);

  /// Text/icon color — white on dark pane, near-black on light pane.
  static Color itemFg = Colors.white;
  /// Muted variant for inactive labels and arrows.
  static Color itemFgMuted = Colors.white70;

  const ZerpaiSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isSubItem = false,
    this.iconSize = 20,
    this.showIcon = true,
    this.showAddButton = false,
    this.onAdd,
    this.hasChildren = false,
    this.isExpanded = false,
  });

  @override
  State<ZerpaiSidebarItem> createState() => _ZerpaiSidebarItemState();
}

class _ZerpaiSidebarItemState extends State<ZerpaiSidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool collapsed = ZerpaiSidebarItem.isCollapsed;
    final Color hoverBg = ZerpaiSidebarItem.hoverBg;
    final Color activeParentBg = ZerpaiSidebarItem.activeParentBg;
    final Color accentColor = ZerpaiSidebarItem.accentColor;

    final Color bgColor = collapsed
        ? (_hover ? hoverBg.withValues(alpha: 0.35) : Colors.transparent)
        : widget.isActive
        ? (widget.hasChildren ? activeParentBg : accentColor)
        : _hover
        ? hoverBg
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Stack(
        children: [
          InkWell(
            onTap: widget.onTap,
            onHover: (v) => setState(() => _hover = v),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: collapsed ? 72 : 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: collapsed
                  ? _CollapsedView(widget: widget)
                  : _ExpandedView(widget: widget, isHovering: _hover),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedView extends StatelessWidget {
  final ZerpaiSidebarItem widget;
  final bool isHovering;

  const _ExpandedView({required this.widget, required this.isHovering});

  @override
  Widget build(BuildContext context) {
    final bool showPlus =
        widget.isSubItem &&
        widget.showAddButton &&
        (widget.isActive || isHovering);

    // On active items the bg is accent-colored so text is always white.
    // On inactive items use the theme foreground color.
    final Color fg = widget.isActive ? Colors.white : ZerpaiSidebarItem.itemFg;
    final Color fgMuted = widget.isActive ? Colors.white70 : ZerpaiSidebarItem.itemFgMuted;

    return Row(
      children: [
        if (widget.showIcon)
          Icon(widget.icon, size: widget.iconSize, color: fg),
        const SizedBox(width: 12),

        Expanded(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: fg,
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),

        // ▶ PARENT ARROW (Visual indicator only)
        if (widget.hasChildren)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              widget.isExpanded
                  ? LucideIcons.chevronUp
                  : LucideIcons.chevronDown,
              size: 18,
              color: fgMuted,
            ),
          ),

        // ➕ CHILD ADD BUTTON
        if (showPlus)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onAdd,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: ZerpaiSidebarItem.accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CollapsedView extends StatelessWidget {
  final ZerpaiSidebarItem widget;
  const _CollapsedView({required this.widget});

  @override
  Widget build(BuildContext context) {
    final bool showActiveIconHighlight = widget.isActive && !widget.hasChildren;
    final bool showActiveParentHighlight =
        widget.isActive && widget.hasChildren;

    final Color fg = widget.isActive ? Colors.white : ZerpaiSidebarItem.itemFg;
    final Color labelFg = widget.isActive
        ? Colors.white
        : ZerpaiSidebarItem.itemFgMuted;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: showActiveIconHighlight
                  ? ZerpaiSidebarItem.accentColor
                  : showActiveParentHighlight
                  ? ZerpaiSidebarItem.activeParentBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: showActiveParentHighlight
                  ? Border.all(color: ZerpaiSidebarItem.itemFg.withValues(alpha: 0.08))
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 18, color: fg),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            height: 14,
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                color: labelFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
