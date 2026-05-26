import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/inventory/adjustments/providers/inventory_adjustments_provider.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import '../inventory_adjustments_list.dart';
import '../widgets/inventory_adjustments_detail_panel.dart';

class InventoryAdjustmentsOverviewScreen extends ConsumerStatefulWidget {
  final String? initialAdjustmentId;

  const InventoryAdjustmentsOverviewScreen({
    super.key,
    this.initialAdjustmentId,
  });

  @override
  ConsumerState<InventoryAdjustmentsOverviewScreen> createState() =>
      _InventoryAdjustmentsOverviewScreenState();
}

class _InventoryAdjustmentsOverviewScreenState
    extends ConsumerState<InventoryAdjustmentsOverviewScreen> {
  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';

  void _selectAdjustment(String id) {
    context.go('/$_orgId/inventory/adjustments?adjustmentId=$id');
  }

  void _closeDetail() {
    context.go('/$_orgId/inventory/adjustments');
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.initialAdjustmentId;
    final selectedAsync = selectedId == null
        ? null
        : ref.watch(inventoryAdjustmentDetailProvider(selectedId));

    final screenWidth = MediaQuery.of(context).size.width;
    final bool canSplit = screenWidth >= 1000;
    final bool showSplit = canSplit && selectedId != null;

    final listPanel = InventoryAdjustmentsListPanel(
      compact: showSplit,
      selectedAdjustmentId: selectedId,
      onSelectAdjustment: _selectAdjustment,
    );

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      actions: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: !showSplit
                ? listPanel
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 350, child: listPanel),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.borderColor,
                      ),
                      Expanded(
                        child: selectedAsync == null
                            ? _emptyDetail('Select an adjustment to view details.')
                            : selectedAsync.when(
                                data: (adj) => adj == null
                                    ? _emptyDetail('Adjustment not found.')
                                    : InventoryAdjustmentsDetailPanel(
                                        adjustment: adj,
                                        onClose: _closeDetail,
                                      ),
                                loading: () => _detailLoadingSkeleton(),
                                error: (e, _) =>
                                    _emptyDetail(e.toString()),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDetail(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _detailLoadingSkeleton() {
    return Skeletonizer(
      enabled: true,
      ignoreContainers: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Inventory Adjustment #ADJ-00001',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.close, size: 20),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason: Stock Correction'),
                  SizedBox(height: 10),
                  Text('Type: Quantity'),
                  SizedBox(height: 10),
                  Text('Date: 02-05-2026'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.borderLight),
                itemBuilder: (_, __) => const ListTile(
                  title: Text('Item Name Placeholder'),
                  subtitle: Text('Qty: 0  |  UOM: Unit'),
                  trailing: Text('0.00'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
