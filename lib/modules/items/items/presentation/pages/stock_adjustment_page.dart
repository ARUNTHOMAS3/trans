import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Stock adjustment view for an item. Rendered embedded inside the item/composite
/// overview when adjusting stock. Kept as a focused entry point; the detailed
/// adjustment form is wired per item type.
class StockAdjustmentPage extends StatelessWidget {
  final String itemId;
  final bool isEmbedded;

  const StockAdjustmentPage({
    super.key,
    required this.itemId,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.packageOpen,
            size: 40,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Stock adjustment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adjust stock for item $itemId.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
