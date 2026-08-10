import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class ReportIconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final bool chromeless;
  final bool useLocalTooltip;

  const ReportIconActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.chromeless = false,
    this.useLocalTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final resolvedIconColor = isEnabled
        ? iconColor ?? AppTheme.textSecondary
        : AppTheme.textDisabled;
    final borderRadius = BorderRadius.circular(AppTheme.space8);

    final button = Material(
      color: chromeless ? AppTheme.transparent : AppTheme.bgLight,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        hoverColor: chromeless ? AppTheme.transparent : AppTheme.bgHover,
        splashColor: chromeless ? AppTheme.transparent : AppTheme.selectionActiveBg,
        highlightColor: chromeless ? AppTheme.transparent : AppTheme.selectionActiveBg,
        child: Container(
          width: chromeless ? null : AppTheme.buttonHeight,
          height: AppTheme.buttonHeight,
          padding: EdgeInsets.symmetric(
            horizontal: chromeless ? 0 : 0,
          ),
          decoration: chromeless
              ? null
              : BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: isEnabled ? AppTheme.borderLight : AppTheme.borderColor,
                  ),
                ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: AppTheme.space16,
            color: resolvedIconColor,
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return button;
    if (useLocalTooltip) {
      return ReportTooltip(message: tooltip!, child: button);
    }
    return ZTooltip(message: tooltip!, child: button);
  }
}

class ReportPrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const ReportPrimaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: AppTheme.space16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successGreen,
          foregroundColor: AppTheme.backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.space4),
          ),
          textStyle: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class ReportTextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailing;

  const ReportTextActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.space4),
        hoverColor: AppTheme.bgHover,
        splashColor: AppTheme.selectionActiveBg,
        highlightColor: AppTheme.selectionActiveBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppTheme.space16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.space6),
              ],
              Text(
                label,
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppTheme.space6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}


