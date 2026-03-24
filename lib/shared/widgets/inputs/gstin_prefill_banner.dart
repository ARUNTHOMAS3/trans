import 'package:flutter/material.dart';

/// A banner prompting the user to prefill entity details from the GST portal.
///
/// Used on both the Vendor and Customer create/edit forms.
///
/// ```dart
/// GstinPrefillBanner(
///   entityLabel: 'Vendor',   // or 'Customer'
///   onPrefill: _openGstinPrefillDialog,
/// )
/// ```
class GstinPrefillBanner extends StatelessWidget {
  /// The entity name shown in the message, e.g. `'Vendor'` or `'Customer'`.
  final String entityLabel;

  /// Called when the user taps "Prefill >".
  final VoidCallback onPrefill;

  const GstinPrefillBanner({
    super.key,
    required this.entityLabel,
    required this.onPrefill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Prefill $entityLabel details from the GST portal using the $entityLabel\'s GSTIN.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
            ),
          ),
          InkWell(
            onTap: onPrefill,
            child: const Text(
              'Prefill >',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
