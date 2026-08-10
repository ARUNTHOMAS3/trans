import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportCustomizationNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const ReportCustomizationNavItem({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.selectionActiveBg : AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppTheme.bgHover,
        splashColor: AppTheme.selectionActiveBg,
        highlightColor: AppTheme.selectionActiveBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space14,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                color: selected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
