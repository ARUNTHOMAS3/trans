import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';

class RecurringExpenseHoverPopupMenuItem extends StatelessWidget {
  final Widget? leading;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? textColor;
  final bool isSelected;
  final String value;
  final ValueNotifier<String?> hoveredNotifier;

  const RecurringExpenseHoverPopupMenuItem({
    super.key,
    required this.label,
    required this.onTap,
    required this.value,
    required this.hoveredNotifier,
    this.leading,
    this.trailing,
    this.textColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: hoveredNotifier,
      builder: (context, hoveredValue, child) {
        final isHighlighted = hoveredValue == value;
        final bg = isHighlighted ? AppTheme.infoBlue : Colors.transparent;
        final fg = isHighlighted
            ? AppTheme.backgroundColor
            : (textColor ?? AppTheme.textPrimary);
        final resolvedLeadingColor = isHighlighted
            ? AppTheme.backgroundColor
            : (textColor ?? AppTheme.textSecondary);
        final resolvedTrailingColor = isHighlighted
            ? AppTheme.backgroundColor
            : (textColor ?? AppTheme.borderColorDark);

        return MouseRegion(
          onEnter: (_) => hoveredNotifier.value = value,
          onExit: (_) {
            if (hoveredNotifier.value == value) {
              hoveredNotifier.value = null;
            }
          },
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (leading != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        color: resolvedLeadingColor,
                        size: 16,
                      ),
                      child: leading!,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    IconTheme(
                      data: IconThemeData(
                        color: resolvedTrailingColor,
                        size: 16,
                      ),
                      child: trailing!,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
