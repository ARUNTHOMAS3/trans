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
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
          surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
          elevation: const WidgetStatePropertyAll(8),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                SizedBox(width: 12),
                const Text('Customize Columns', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          MenuItemButton(
            onPressed: () => onWrapChange(!wrapText),
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: Row(
              children: [
                const SizedBox(width: 4), // Small offset since icon is removed
                Text(wrapText ? 'Clip Text' : 'Wrap Text', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
