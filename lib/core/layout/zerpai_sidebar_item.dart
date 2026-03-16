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

  static const Color _hoverBg = Color(0xFF3A3F4F);
  static const Color _activeParentBg = Color(0xFF2A3A55); // Subtle blue for active parents
  static const Color _green = Color(0xFF10B981); // Green for active destinations

  @override
  Widget build(BuildContext context) {
    final bool collapsed = ZerpaiSidebarItem.isCollapsed;

    final Color bgColor = widget.isActive
        ? (widget.hasChildren ? _activeParentBg : _green)
        : _hover
            ? _hoverBg
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

    return Row(
      children: [
        if (widget.showIcon)
          Icon(widget.icon, size: widget.iconSize, color: Colors.white),
        const SizedBox(width: 12),

        Expanded(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
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
              color: Colors.white70,
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
                  color: const Color(0xFF10B981), // Green as per screenshot
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ICON
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? const Color(0xFF2E344A)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 18, color: Colors.white),
          ),

          const SizedBox(height: 4),

          // LABEL
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
                color: widget.isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 95 / 255), // 0.75 * 255
              ),
            ),
          ),

          // CORNER INDICATOR (BOTTOM-RIGHT FEEL)
          if (widget.hasChildren) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha:
                          (widget.isActive ? 115 : 71) /
                          255, // 0.45*255 , 0.28*255
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
