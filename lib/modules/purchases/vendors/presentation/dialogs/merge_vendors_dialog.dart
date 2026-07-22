import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class MergeVendorsDialog extends ConsumerStatefulWidget {
  final Vendor currentVendor;

  const MergeVendorsDialog({super.key, required this.currentVendor});

  @override
  ConsumerState<MergeVendorsDialog> createState() => _MergeVendorsDialogState();
}

class _MergeVendorsDialogState extends ConsumerState<MergeVendorsDialog> {
  Vendor? _selectedVendor;

  void _onMerge() {
    if (_selectedVendor == null) {
      ZerpaiToast.error(
        context,
        'Please select a vendor profile to merge with',
      );
      return;
    }
    Navigator.of(context).pop(_selectedVendor);
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorProvider);
    final mergeableVendors = vendorsState.vendors
        .where((v) => v.id != widget.currentVendor.id)
        .toList();

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
            width: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Merge Vendors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // ── Body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF4B5563),
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  "Select a vendor profile with whom you'd like to merge ",
                            ),
                            TextSpan(
                              text: widget.currentVendor.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const TextSpan(
                              text: ". Once merged, the transactions of ",
                            ),
                            TextSpan(
                              text: widget.currentVendor.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  " will be transferred, and this vendor record will be marked as inactive.",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FormDropdown<Vendor>(
                        value: _selectedVendor,
                        items: mergeableVendors,
                        hint: 'Select Vendor',
                        isLoading: vendorsState.isLoading,
                        onChanged: (vendor) =>
                            setState(() => _selectedVendor = vendor),
                        displayStringForValue: (v) => v.displayName,
                        height: 42,
                      ),
                    ],
                  ),
                ),
                // ── Footer ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _selectedVendor != null ? _onMerge : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD1D5DB),
                          disabledForegroundColor: Colors.white,
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
                          'Continue',
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
}
