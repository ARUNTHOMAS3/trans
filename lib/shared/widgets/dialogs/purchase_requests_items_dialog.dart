import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../z_button.dart';

class PurchaseRequestItemSelection {
  final String productId;
  final String productName;
  final double quantity;
  final double rate;
  final String requestNumber;
  final String sourceKey;

  const PurchaseRequestItemSelection({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.rate,
    this.requestNumber = '',
    this.sourceKey = '',
  });
}

class PurchaseRequestsItemsDialog extends StatelessWidget {
  final String? initialVendorId;
  final Set<String>? excludeSourceKeys;
  final ValueChanged<List<PurchaseRequestItemSelection>> onItemsSelected;

  const PurchaseRequestsItemsDialog({
    super.key,
    this.initialVendorId,
    this.excludeSourceKeys,
    required this.onItemsSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text('Purchase Request Items'),
      content: const SizedBox(
        width: 520,
        child: Text(
          'Purchase request item sourcing is not wired in this repo slice yet. '
          'This merge keeps the entry point safe without blocking purchase order create.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
      ),
      actions: [
        ZButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Close',
        ),
      ],
    );
  }
}
