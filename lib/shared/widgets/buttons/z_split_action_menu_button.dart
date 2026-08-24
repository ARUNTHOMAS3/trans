import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZSplitActionMenuItem {
  const ZSplitActionMenuItem({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
}

class ZSplitActionMenuButton extends StatelessWidget {
  const ZSplitActionMenuButton({
    super.key,
    this.height = 34,
    this.menuWidth = 180,
    required this.triggerLabel,
    required this.menuItems,
    this.onPrimaryPressed,
    this.isDisabled = false,
    this.isPrimaryStyle = true,
    this.useFilledBlueHover = true,
    this.openUp = false,
    this.primaryColor,
  });

  final double height;
  final double menuWidth;
  final String triggerLabel;
  final List<ZSplitActionMenuItem> menuItems;
  final VoidCallback? onPrimaryPressed;
  final bool isDisabled;
  final bool isPrimaryStyle;
  final bool useFilledBlueHover;
  final bool openUp;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(4);
    final triggerForeground = isPrimaryStyle
        ? AppTheme.backgroundColor
        : (isDisabled ? AppTheme.textSecondary : AppTheme.textBody);
    final resolvedPrimaryColor = primaryColor ?? AppTheme.primaryBlue;
    final triggerBaseBackground = isPrimaryStyle
        ? resolvedPrimaryColor
        : AppTheme.backgroundColor;
    final triggerHoverBackground = useFilledBlueHover
        ? (primaryColor ?? AppTheme.primaryBlueDark)
        : AppTheme.primaryBlue.withValues(alpha: 0.12);
    final triggerSide = isPrimaryStyle
        ? BorderSide(color: resolvedPrimaryColor)
        : const BorderSide(color: AppTheme.borderColor);

    final triggerBaseStyle = ButtonStyle(
      elevation: const WidgetStatePropertyAll<double>(0),
      foregroundColor: WidgetStatePropertyAll<Color>(triggerForeground),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return triggerHoverBackground;
        }
        return triggerBaseBackground;
      }),
      side: WidgetStatePropertyAll<BorderSide>(triggerSide),
    );

    final triggerLabelWidget = Text(
      triggerLabel,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: triggerForeground,
      ),
    );

    return MenuAnchor(
      alignmentOffset: openUp
          ? Offset(0, -((menuItems.length * 40) + 16 + height))
          : const Offset(0, 4),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(4)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      ),
      menuChildren: menuItems
          .map((item) {
            return MenuItemButton(
              onPressed: isDisabled ? null : item.onPressed,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppTheme.primaryBlue;
                  }
                  return AppTheme.backgroundColor;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppTheme.backgroundColor;
                  }
                  return AppTheme.textPrimary;
                }),
                iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  return states.contains(WidgetState.hovered)
                      ? Colors.white
                      : AppTheme.primaryBlue;
                }),
                shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
              ),
              leadingIcon: item.icon == null ? null : Icon(item.icon, size: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: menuWidth - 32),
                child: Row(
                  children: [
                    Expanded(child: Text(item.label)),
                    if (item.isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
      builder: (context, controller, child) {
        final hasSplitPrimary = onPrimaryPressed != null;
        if (!hasSplitPrimary) {
          return SizedBox(
            height: height,
            child: ElevatedButton(
              onPressed: isDisabled
                  ? null
                  : () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
              style: triggerBaseStyle.copyWith(
                padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(horizontal: 14),
                ),
                shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  triggerLabelWidget,
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.chevronDown, size: 14),
                ],
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: ElevatedButton(
                onPressed: isDisabled ? null : onPrimaryPressed,
                style: triggerBaseStyle.copyWith(
                  padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(horizontal: 14),
                  ),
                  shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: radius,
                        bottomLeft: radius,
                      ),
                    ),
                  ),
                ),
                child: triggerLabelWidget,
              ),
            ),
            SizedBox(
              height: height,
              width: 34,
              child: ElevatedButton(
                onPressed: isDisabled
                    ? null
                    : () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                style: triggerBaseStyle.copyWith(
                  padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                    EdgeInsets.zero,
                  ),
                  shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: radius,
                        bottomRight: radius,
                      ),
                    ),
                  ),
                ),
                child: const Icon(LucideIcons.chevronDown, size: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}
