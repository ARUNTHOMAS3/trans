part of '../items_item_detail.dart';

extension _ItemDetailActions on _ItemDetailScreenState {
  Future<void> _handleMoreAction(
    BuildContext context,
    _ItemsMoreAction action,
  ) async {
    String msg = '';
    switch (action) {
      case _ItemsMoreAction.importItems:
        final result = await showImportItemsDialog(context);
        if (result != null && context.mounted) {
          ZerpaiToast.info(context, 'Import option: $result');
        }
        return;
      case _ItemsMoreAction.importItemImages:
        msg = 'TODO: Import Items Images';
        break;
      case _ItemsMoreAction.exportItems:
        await showExportItemsDialog(context);
        return;
      case _ItemsMoreAction.exportCurrentItem:
        msg = 'TODO: Export Current Item';
        break;
      case _ItemsMoreAction.preferences:
        msg = 'TODO: Open Preferences';
        break;
      case _ItemsMoreAction.refreshList:
        ref.read(itemsControllerProvider.notifier).loadItems();
        msg = 'Items list refreshed';
        break;
    }

    if (msg.isNotEmpty && context.mounted) {
      ZerpaiToast.info(context, msg);
    }
  }
}
