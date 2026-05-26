import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class WarehouseChangeConfirmDialog extends StatelessWidget {
  const WarehouseChangeConfirmDialog({
    super.key,
    required this.warehouseName,
    this.title = 'Changing the Warehouse will update prices and quantities',
    this.primaryLabel = 'Proceed with the selected Warehouse',
  });

  final String warehouseName;
  final String title;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 600,
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    LucideIcons.alertTriangle,
                    color: AppTheme.warningOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.pageTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFE4C4)),
              ),
              child: const Column(
                children: [
                  _WarningRow(
                    text:
                        'Changing the Warehouse will update the cost price of the items based on the last transaction on the selected Warehouse.',
                  ),
                  SizedBox(height: 12),
                  _WarningRow(
                    text:
                        'It will also reset any adjusted Quantity you have entered.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Selected Warehouse: $warehouseName',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: If you want to change the cost price manually, You can edit and update the cost price of the items individually.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Theme(
                  data: AppTheme.themedWith(AppTheme.successGreen),
                  child: ZButton.primary(
                    label: primaryLabel,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 7),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppTheme.textPrimary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
