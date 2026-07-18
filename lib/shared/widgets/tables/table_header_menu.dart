import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'table_more_menu.dart';

/// A reusable menu button for table headers (sliders icon).
/// Features:
/// - Customize Columns (Order: 1st)
/// - Wrap Text (Order: 2nd)
/// - Standardized blue hover effect with white text
class ZTableHeaderMenu extends StatelessWidget {
  final bool wrapText;
  final ValueChanged<bool> onWrapChange;
  final VoidCallback onCustomize;
  final Offset alignmentOffset;

  const ZTableHeaderMenu({
    super.key,
    required this.wrapText,
    required this.onWrapChange,
    required this.onCustomize,
    this.alignmentOffset = const Offset(0, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      child: MenuAnchor(
        alignmentOffset: alignmentOffset,
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
          elevation: WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              side: BorderSide(color: AppTheme.borderLight),
            ),
          ),
        ),
        builder: (context, controller, child) => IconButton(
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(LucideIcons.sliders, size: 14, color: AppTheme.primaryBlue),
          padding: EdgeInsets.zero,
        ),
        menuChildren: [
          MenuItemButton(
            onPressed: onCustomize,
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: Row(
              children: const [
                Icon(LucideIcons.columns, size: 16),
                const SizedBox(width: 12),
                Text('Customize Columns', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          MenuItemButton(
            onPressed: () => onWrapChange(!wrapText),
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: Row(
              children: [
                Icon(
                  wrapText ? LucideIcons.list : LucideIcons.wrapText,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Text(wrapText ? 'Clip Text' : 'Wrap Text', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
