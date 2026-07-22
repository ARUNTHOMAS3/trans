import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class InventoryMappingMappingCreateScreen extends StatelessWidget {
  const InventoryMappingMappingCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'New Item Mapping',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 420,
              child: CustomTextField(
                label: 'Source Item Code',
                hintText: 'Enter source code',
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 420,
              child: CustomTextField(
                label: 'Target Item Code',
                hintText: 'Enter target code',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ZButton.primary(
                  label: 'Save',
                  onPressed: () => context.go(AppRoutes.itemMapping),
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => context.go(AppRoutes.itemMapping),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
