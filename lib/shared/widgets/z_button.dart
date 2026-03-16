import 'package:flutter/material.dart';

class ZButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool primary;

  const ZButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  }) : primary = true;

  const ZButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
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
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B8EF1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildSecondary() {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}
