import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/lookup_utils.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_currency_display.dart';
import 'package:zerpai_erp/shared/widgets/z_data_table_shell.dart';
import 'package:zerpai_erp/shared/widgets/z_row_actions.dart';

import '../../controllers/items_controller.dart';
import '../../controllers/items_state.dart';
import '../../models/item_model.dart';

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  String _resolveOrgSystemId(BuildContext context) {
    return GoRouterState.of(context).pathParameters['orgSystemId']?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgSystemId = _resolveOrgSystemId(context);
    final itemsState = ref.watch(itemsControllerProvider);
    final notifier = ref.read(itemsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Items', style: AppTheme.pageTitle),
        actions: [
          ZSearchField(
            hintText: 'Search by name, SKU, category...',
            onChanged: (q) => notifier.performSearch(q),
          ),
          const SizedBox(width: AppTheme.space12),
          ZButton.primary(
            label: 'New Item',
            icon: LucideIcons.plus,
            onPressed: () => context.goNamed(
              AppRoutes.itemsCreate,
              pathParameters: {'orgSystemId': orgSystemId},
            ),
          ),
          const SizedBox(width: AppTheme.space20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: _ItemsTable(
          orgSystemId: orgSystemId,
          state: itemsState,
          onDeleteItem: (item) => _confirmDelete(context, ref, item),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Item',
      message: 'Delete "${item.productName}"? This cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed) return;

    try {
      await ref
          .read(itemsControllerProvider.notifier)
          .deleteItem(item.id ?? '');
    } catch (e) {
      AppLogger.error('Delete item failed', module: 'items', error: e);
    }
  }
}

// ---------------------------------------------------------------------------
// TABLE IMPLEMENTATION
// ---------------------------------------------------------------------------

class _ItemsTable extends StatelessWidget {
  final String orgSystemId;
  final ItemsState state;
  final Future<void> Function(Item) onDeleteItem;

  const _ItemsTable({
    required this.orgSystemId,
    required this.state,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return ZDataTableShell(
      header: const ZTableHeader(
        children: [
          ZTableCell(flex: 4, child: Text('Item Name')),
          ZTableCell(flex: 2, child: Text('SKU')),
          ZTableCell(flex: 2, child: Text('Category')),
          ZTableCell(flex: 2, child: Text('MRP')),
          SizedBox(width: 40),
        ],
      ),
      rows: state.items
          .map(
            (item) => _ItemRow(
              item: item,
              categories: state.categories,
              onTap: () => context.pushNamed(
                AppRoutes.itemsDetail,
                pathParameters: {
                  'orgSystemId': orgSystemId,
                  'id': item.id ?? '',
                },
              ),
              orgSystemId: orgSystemId,
              onDelete: () => onDeleteItem(item),
            ),
          )
          .toList(),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Item item;
  final String orgSystemId;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.item,
    required this.orgSystemId,
    required this.categories,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ZTableRowLayout(
      onTap: onTap,
      children: [
        ZTableCell(
          flex: 4,
          child: Text(item.productName, style: AppTheme.tableCell),
        ),
        ZTableCell(
          flex: 2,
          child: Text(item.sku ?? '-', style: AppTheme.tableCell),
        ),
        ZTableCell(
          flex: 2,
          child: Text(
            LookupUtils.getNameById(categories, item.categoryId),
            style: AppTheme.tableCell,
          ),
        ),
        ZTableCell(
          flex: 2,
          child: ZCurrencyDisplay(
            amount: item.mrp ?? 0,
            style: AppTheme.tableCell,
          ),
        ),
        ZRowActions(
          onEdit: () => context.pushNamed(
            AppRoutes.itemsEdit,
            pathParameters: {
              'orgSystemId': orgSystemId,
              'id': item.id ?? '',
            },
          ),
          onDelete: onDelete,
          // onDuplicate: () => ... (backlog)
        ),
      ],
    );
  }
}
