import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportNavigationItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final double leadingInset;
  final EdgeInsetsGeometry? padding;

  const ReportNavigationItem({
    super.key,
    required this.label,
    this.onTap,
    this.leading,
    this.trailing,
    this.selected = false,
    this.leadingInset = 0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );

    return Material(
      color: selected ? AppTheme.selectionActiveBg : AppTheme.transparent,
      borderRadius: BorderRadius.circular(AppTheme.space8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        hoverColor: AppTheme.bgHover,
        splashColor: AppTheme.selectionActiveBg,
        highlightColor: AppTheme.selectionActiveBg,
        child: Padding(
          padding: padding ??
              EdgeInsets.fromLTRB(
                AppTheme.space12 + leadingInset,
                AppTheme.space10,
                AppTheme.space12,
                AppTheme.space10,
              ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppTheme.space8),
              ],
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppTheme.space8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
