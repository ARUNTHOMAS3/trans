
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class InventoryMappingMappingListScreen extends StatelessWidget {
  const InventoryMappingMappingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Item Mapping',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ZButton.primary(
                label: 'New Item Mapping',
                onPressed: () => context.go(AppRoutes.itemMappingCreate),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No item mappings found.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
