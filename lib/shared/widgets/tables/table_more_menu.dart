import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';

/// A reusable 'More' menu (horizontal ellipsis) for tables.
class ZTableMoreMenu extends StatelessWidget {
  final List<Widget> menuChildren;
  final Offset alignmentOffset;
  final double height;
  final double width;
  final double iconSize;

  const ZTableMoreMenu({
    super.key,
    required this.menuChildren,
    this.alignmentOffset = const Offset(0, 4),
    this.height = 36,
    this.width = 36,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MenuAnchor(
        alignmentOffset: alignmentOffset,
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
          elevation: WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            icon: Icon(LucideIcons.moreHorizontal, size: iconSize, color: AppTheme.primaryBlue),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: width, minHeight: height),
          );
        },
        menuChildren: menuChildren,
      ),
    );
  }

  /// Standard style for menu items (MenuItemButton, SubmenuButton) with blue hover effect.
  static ButtonStyle menuItemButtonStyle({bool isActive = false, bool isHeader = false}) {
    return ButtonStyle(
      animationDuration: Duration.zero,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive) return AppTheme.primaryBlue;
        if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
        return isHeader ? Colors.transparent : Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) return Colors.white;
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) return Colors.white;
        return AppTheme.primaryBlue;
      }),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      minimumSize: const WidgetStatePropertyAll(Size(220, 40)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
    );
  }

  static MenuStyle submenuMenuStyle() {
    return const MenuStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: WidgetStatePropertyAll(Colors.white),
      padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
      elevation: WidgetStatePropertyAll(8),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
