import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool primary;
  final IconData? icon;
  final double? height;
  final double? fontSize;
  final EdgeInsets? padding;
  final Widget? suffixWidget;

  const ZButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height,
    this.fontSize,
    this.padding,
    this.suffixWidget,
  }) : primary = true;

  const ZButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height,
    this.fontSize,
    this.padding,
    this.suffixWidget,
  }) : loading = false,
       primary = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 38,
      child: primary ? _buildPrimary(context) : _buildSecondary(),
    );
  }

  Widget _buildPrimary(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : _labelRow(AppTheme.buttonText);

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: icon != null ? 16 : 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: child,
    );
  }

  Widget _buildSecondary() {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: icon != null ? 14 : 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: _labelRow(
        AppTheme.bodyText.copyWith(
          fontWeight: FontWeight.w500,
          color: AppTheme.textBody,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _labelRow(TextStyle textStyle) {
    final labelWidget = Text(
      label,
      style: fontSize == null
          ? textStyle
          : textStyle.copyWith(fontSize: fontSize),
    );
    if (icon == null && suffixWidget == null) return labelWidget;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: textStyle.color),
          const SizedBox(width: 6),
        ],
        labelWidget,
        if (suffixWidget != null) ...[const SizedBox(width: 6), suffixWidget!],
      ],
    );
  }
}
