import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// "Clone" dialog — lets the user pick the contact type (Customer or Vendor)
/// for the new cloned contact. Pops the chosen type ('Customer' | 'Vendor').
class CloneVendorDialog extends StatefulWidget {
  const CloneVendorDialog({super.key});

  @override
  State<CloneVendorDialog> createState() => _CloneVendorDialogState();
}

class _CloneVendorDialogState extends State<CloneVendorDialog> {
  String _type = 'Customer';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Text(
                    'Select the contact type under which you want to create the '
                    'new cloned contact.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_radioRow('Customer'), _radioRow('Vendor')],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_type),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Proceed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _radioRow(String value) {
    return InkWell(
      onTap: () => setState(() => _type = value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // Blue + white radio styling per global interaction rule.
            Radio<String>(
              value: value,
              groupValue: _type,
              onChanged: (v) => setState(() => _type = v ?? _type),
              activeColor: const Color(0xFF2563EB),
              fillColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF9CA3AF),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }
}
