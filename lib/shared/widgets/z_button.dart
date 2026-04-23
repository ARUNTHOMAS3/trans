import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool primary;
  final IconData? icon;

  const ZButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  }) : primary = true;

  const ZButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : loading = false,
       primary = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: primary ? _buildPrimary() : _buildSecondary(),
    );
  }

  Widget _buildPrimary() {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : _labelRow(Colors.white, FontWeight.w600);

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: icon != null ? 16 : 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: child,
    );
  }

  Widget _buildSecondary() {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: icon != null ? 14 : 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: _labelRow(AppTheme.textBody, FontWeight.w500),
    );
  }

  Widget _labelRow(Color textColor, FontWeight weight) {
    if (icon == null) {
      return Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: weight, color: textColor),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: weight, color: textColor),
        ),
      ],
    );
  }
}
