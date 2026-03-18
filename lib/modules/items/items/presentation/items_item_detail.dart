import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'sections/components/items_stock_find_panels.dart';
import 'sections/components/items_batch_dialogs.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/items_filter_dropdown.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/items_filters.dart';
import 'package:zerpai_erp/core/layout/zerpai_sidebar.dart';
import 'sections/report/dialogs/import_items_dialog.dart';
import 'sections/report/dialogs/export_items_dialog.dart';
import 'sections/report/dialogs/bulk_update_dialog.dart';
import 'sections/items_stock_providers.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

part 'sections/items_item_detail_overview.dart';
part 'sections/items_item_detail_stock.dart';
part 'sections/items_item_detail_price_lists.dart';
part 'sections/items_item_detail_menus.dart';
part 'sections/items_item_detail_actions.dart';
part 'sections/items_item_detail_charts.dart';
part 'sections/items_item_detail_components.dart';
part 'sections/items_opening_stock_dialog.dart';

enum _ItemsMoreAction {
  importItems,
  importItemImages,
  exportItems,
  exportCurrentItem,
  preferences,
  refreshList,
}

enum _ItemsSortField {
  name,
  reorderLevel,
  sku,
  stockOnHand,
  hsnSacRate,
  createdTime,
  lastModifiedTime,
}

enum _StockView { accounting, physical }

enum _ItemDetailTab {
  overview,
  warehouses,
  serialNumbers,
  batchNumbers,
  transactions,
  history,
}

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final Map<String, String> initialQueryParameters;

  const ItemDetailScreen({
    super.key,
    this.itemId,
    this.initialQueryParameters = const <String, String>{},
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  void updateState(VoidCallback fn) => setState(fn);

  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey _reorderPointKey = GlobalKey();
  final GlobalKey _reorderTermsKey = GlobalKey();

  OverlayEntry? _moreMenuEntry;
  OverlayEntry? _importMenuEntry;
  OverlayEntry? _exportMenuEntry;
  OverlayEntry? _sortMenuEntry;
  OverlayEntry? _reorderPointEntry;
  OverlayEntry? _reorderTermsEntry;

  _ItemsSortField _currentSortField = _ItemsSortField.name;
  bool _isAscending = true;

  int _selectedTabIndex = 0;
  final Set<String> _selectedItemIds = {};
  bool _isLoadingItem = false; // Guard against infinite ensureItemLoaded loop

  ItemsFilter _currentFilter = ItemsFilter.all;

  final List<dynamic> _itemImages = [];
  int _primaryImageIndex = 0;
  String? _lastEffectiveId;
  bool _isImageDragging = false;
  bool _isImageUploading = false;

  _StockView _stockView = _StockView.accounting;
  String _batchFilter = 'all';
  String _warehouseFilter = 'all';
  bool _showEmptyBatches = true;
  final Set<String> _selectedBatchRefs = {};
  int? _hoveredBatchIndex;
  final Set<String> _inactiveBatchRefs = {};
  String _serialWarehouseFilter = 'all';
  bool _showAllSerialNumbers = false;
  String _transactionTypeFilter = 'salesOrders';
  String _transactionStatusFilter = 'all';
  TransactionData? _selectedTransaction;

  // Menu hovers
  bool _isHoveringSortRow = false;
  bool _isHoveringSortMenu = false;
  bool _isHoveringImportRow = false;
  bool _isHoveringImportMenu = false;
  bool _isHoveringExportRow = false;
  bool _isHoveringExportMenu = false;
  Offset? _moreMenuTopLeft;
  OverlayEntry? _termsSearchEntry;

  // Price list states
  bool _isPriceListExpanded = false;
  int _selectedPriceListTab = 0;

  // Sales period states
  String _selectedPeriod = 'This Month';
  OverlayEntry? _periodDropdownEntry;
  String? _requestedInitialTabKey;

  @override
  void initState() {
    super.initState();
    _hydrateRouteState();
  }

  void _hydrateRouteState() {
    final params = widget.initialQueryParameters;
    _requestedInitialTabKey = params['tab'];
    _currentFilter = _parseItemsFilter(params['filter']);
    _stockView = _parseStockView(params['stockView']);
    _batchFilter = params['batchFilter'] ?? 'all';
    _warehouseFilter = params['warehouseFilter'] ?? 'all';
    _showEmptyBatches = params['showEmptyBatches'] != 'false';
    _serialWarehouseFilter = params['serialWarehouseFilter'] ?? 'all';
    _showAllSerialNumbers = params['showAllSerialNumbers'] == 'true';
    _transactionTypeFilter = params['transactionType'] ?? 'salesOrders';
    _transactionStatusFilter = params['transactionStatus'] ?? 'all';
    _selectedPriceListTab =
        int.tryParse(params['priceListTab'] ?? '')?.clamp(0, 1) ?? 0;
    _selectedPeriod = params['period'] ?? 'This Month';
  }

  ItemsFilter _parseItemsFilter(String? value) {
    if (value == null || value.isEmpty) {
      return ItemsFilter.all;
    }
    return ItemsFilter.values
            .where((filter) => filter.name == value)
            .firstOrNull ??
        ItemsFilter.all;
  }

  _StockView _parseStockView(String? value) {
    return value == 'physical' ? _StockView.physical : _StockView.accounting;
  }

  String _detailTabKey(_ItemDetailTab tab) {
    switch (tab) {
      case _ItemDetailTab.overview:
        return 'overview';
      case _ItemDetailTab.warehouses:
        return 'warehouses';
      case _ItemDetailTab.serialNumbers:
        return 'serial-numbers';
      case _ItemDetailTab.batchNumbers:
        return 'batch-details';
      case _ItemDetailTab.transactions:
        return 'transactions';
      case _ItemDetailTab.history:
        return 'history';
    }
  }

  _ItemDetailTab? _parseDetailTab(String? value) {
    switch (value) {
      case 'overview':
        return _ItemDetailTab.overview;
      case 'warehouses':
        return _ItemDetailTab.warehouses;
      case 'serial-numbers':
        return _ItemDetailTab.serialNumbers;
      case 'batch-details':
        return _ItemDetailTab.batchNumbers;
      case 'transactions':
        return _ItemDetailTab.transactions;
      case 'history':
        return _ItemDetailTab.history;
      default:
        return null;
    }
  }

  Map<String, String> _buildDetailQueryParameters(List<_ItemDetailTab> tabs) {
    final query = <String, String>{};
    final selectedTab = tabs[_resolveTabIndex(tabs)];
    if (selectedTab != _ItemDetailTab.overview) {
      query['tab'] = _detailTabKey(selectedTab);
    }
    if (_currentFilter != ItemsFilter.all) {
      query['filter'] = _currentFilter.name;
    }
    if (_stockView != _StockView.accounting) {
      query['stockView'] = 'physical';
    }
    if (_batchFilter != 'all') {
      query['batchFilter'] = _batchFilter;
    }
    if (_warehouseFilter != 'all') {
      query['warehouseFilter'] = _warehouseFilter;
    }
    if (!_showEmptyBatches) {
      query['showEmptyBatches'] = 'false';
    }
    if (_serialWarehouseFilter != 'all') {
      query['serialWarehouseFilter'] = _serialWarehouseFilter;
    }
    if (_showAllSerialNumbers) {
      query['showAllSerialNumbers'] = 'true';
    }
    if (_transactionTypeFilter != 'salesOrders') {
      query['transactionType'] = _transactionTypeFilter;
    }
    if (_transactionStatusFilter != 'all') {
      query['transactionStatus'] = _transactionStatusFilter;
    }
    if (_selectedPriceListTab != 0) {
      query['priceListTab'] = _selectedPriceListTab.toString();
    }
    if (_selectedPeriod != 'This Month') {
      query['period'] = _selectedPeriod;
    }
    return query;
  }

  void _syncDetailRoute(List<_ItemDetailTab> tabs) {
    if (!mounted || widget.itemId == null) return;
    context.goNamed(
      AppRoutes.itemsDetail,
      pathParameters: {'id': widget.itemId!},
      queryParameters: _buildDetailQueryParameters(tabs),
    );
  }

  void _setSelectedTabIndex(int index, List<_ItemDetailTab> tabs) {
    setState(() => _selectedTabIndex = index);
    _syncDetailRoute(tabs);
  }

  void _setCurrentFilter(ItemsFilter filter, List<_ItemDetailTab> tabs) {
    setState(() => _currentFilter = filter);
    _syncDetailRoute(tabs);
  }

  void _setStockView(_StockView view, List<_ItemDetailTab> tabs) {
    setState(() => _stockView = view);
    _syncDetailRoute(tabs);
  }

  void _setBatchFilter(String value, List<_ItemDetailTab> tabs) {
    setState(() => _batchFilter = value);
    _syncDetailRoute(tabs);
  }

  void _setWarehouseFilter(String value, List<_ItemDetailTab> tabs) {
    setState(() => _warehouseFilter = value);
    _syncDetailRoute(tabs);
  }

  void _setShowEmptyBatches(bool value, List<_ItemDetailTab> tabs) {
    setState(() => _showEmptyBatches = value);
    _syncDetailRoute(tabs);
  }

  void _setTransactionTypeFilter(String value, List<_ItemDetailTab> tabs) {
    setState(() => _transactionTypeFilter = value);
    _syncDetailRoute(tabs);
  }

  void _setTransactionStatusFilter(String value, List<_ItemDetailTab> tabs) {
    setState(() => _transactionStatusFilter = value);
    _syncDetailRoute(tabs);
  }

  void _setSelectedPriceListTab(int index, List<_ItemDetailTab> tabs) {
    setState(() => _selectedPriceListTab = index);
    _syncDetailRoute(tabs);
  }

  void _setSelectedPeriod(String period, List<_ItemDetailTab> tabs) {
    setState(() => _selectedPeriod = period);
    _syncDetailRoute(tabs);
  }

  @override
  void dispose() {
    _closeMenus();
    _reorderTermsEntry?.remove();
    _reorderTermsEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemsControllerProvider);

    final String? effectiveId =
        widget.itemId ??
        state.selectedItemId ??
        (state.items.isNotEmpty ? state.items.first.id : null);

    final Item? item = state.items.cast<Item?>().firstWhere(
      (i) => i?.id == effectiveId,
      orElse: () => null,
    );

    if (item != null &&
        (_lastEffectiveId != item.id ||
            (_itemImages.isEmpty &&
                item.imageUrls != null &&
                item.imageUrls!.isNotEmpty))) {
      _lastEffectiveId = item.id;
      _itemImages.clear();
      if (item.imageUrls != null) {
        _itemImages.addAll(item.imageUrls!);
      }
      if (item.primaryImageUrl != null) {
        final idx = _itemImages.indexOf(item.primaryImageUrl!);
        _primaryImageIndex = idx >= 0 ? idx : 0;
      } else {
        _primaryImageIndex = 0;
      }

      // Trigger quick stats fetch for the selected item to get real stock and status data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(itemsControllerProvider.notifier).fetchQuickStats(item.id!);
        ref
            .read(itemsControllerProvider.notifier)
            .fetchAssociatedPriceLists(item.id!);
      });
    }

    if (item == null) {
      if (effectiveId != null &&
          !state.isHydratingItem &&
          !_isLoadingItem &&
          state.error == null) {
        _isLoadingItem = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await ref
              .read(itemsControllerProvider.notifier)
              .ensureItemLoaded(effectiveId);
          if (mounted) setState(() => _isLoadingItem = false);
        });
      }
    }

    Widget contentArea;
    if ((state.isHydratingItem || _isLoadingItem) && item == null) {
      contentArea = const DetailContentSkeleton();
    } else if (state.error != null && item == null) {
      contentArea = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (effectiveId != null) {
                  ref
                      .read(itemsControllerProvider.notifier)
                      .ensureItemLoaded(effectiveId, forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (item == null) {
      contentArea = const Center(
        child: Text(
          'Item not found',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7281)),
        ),
      );
    } else {
      // Resolve IDs to Names
      final unitName =
          item.unitName ??
          state.units
              .firstWhere(
                (u) => u.id == item.unitId,
                orElse: () => Unit(id: '', unitName: 'N/A'),
              )
              .unitName;

      final categoryName =
          item.categoryName ??
          state.categories.firstWhere(
            (c) => c['id'] == item.categoryId,
            orElse: () => {'name': 'N/A'},
          )['name'];

      // Resolve names: prefer the joined name embedded in the item model (from API),
      // then fall back to the global lookup lists.
      final manufacturerName =
          item.manufacturerName ??
          state.manufacturers.firstWhere(
            (m) => m['id'] == item.manufacturerId,
            orElse: () => {'name': null},
          )['name'] ??
          'N/A';

      final brandName =
          item.brandName ??
          state.brands.firstWhere(
            (b) => b['id'] == item.brandId,
            orElse: () => {'name': null},
          )['name'] ??
          'N/A';

      final purchaseAccountName =
          item.purchaseAccountName ??
          state.accounts.firstWhere(
            (a) => a['id'] == item.purchaseAccountId,
            orElse: () => {'name': null},
          )['name'] ??
          'N/A';

      final inventoryAccountName =
          item.inventoryAccountName ??
          state.accounts.firstWhere(
            (a) => a['id'] == item.inventoryAccountId,
            orElse: () => {'name': null},
          )['name'] ??
          'N/A';

      final salesAccountName =
          item.salesAccountName ??
          state.accounts.firstWhere(
            (a) => a['id'] == item.salesAccountId,
            orElse: () => {'name': null},
          )['name'] ??
          'N/A';

      final intraStateTaxName =
          item.intraStateTaxName ??
          state.taxRates
              .firstWhere(
                (t) => t.id == item.intraStateTaxId,
                orElse: () => TaxRate(id: '', taxName: 'N/A', taxRate: 0),
              )
              .taxName;

      final interStateTaxName =
          item.interStateTaxName ??
          state.taxRates
              .firstWhere(
                (t) => t.id == item.interStateTaxId,
                orElse: () => TaxRate(id: '', taxName: 'N/A', taxRate: 0),
              )
              .taxName;

      final tabs = _tabsForItem(item);
      final selectedIndex = _resolveTabIndex(tabs);

      contentArea = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailHeader(item),
          // Tab Header
          Container(
            height: 48,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 0),
              child: Row(
                children: tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final label = _tabLabel(tab);
                  final isSelected = selectedIndex == index;

                  return InkWell(
                    onTap: () => _setSelectedTabIndex(index, tabs),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: Builder(
              builder: (_) {
                switch (tabs[selectedIndex]) {
                  case _ItemDetailTab.overview:
                    return _buildOverviewTab(
                      state,
                      item,
                      unitName,
                      categoryName,
                      manufacturerName,
                      brandName,
                      purchaseAccountName,
                      inventoryAccountName,
                      salesAccountName,
                      intraStateTaxName,
                      interStateTaxName,
                    );
                  case _ItemDetailTab.warehouses:
                    return _buildWarehousesTab(state, item);
                  case _ItemDetailTab.serialNumbers:
                    return _buildSerialNumbersTab(item);
                  case _ItemDetailTab.batchNumbers:
                    return _buildBatchNumbersTab(item);
                  case _ItemDetailTab.transactions:
                    return _buildTransactionsTab(item);
                  case _ItemDetailTab.history:
                    return _buildHistoryTab(item);
                }
              },
            ),
          ),
        ],
      );
    }

    return DropTarget(
      onDragDone: (_) {}, // Global intercept to prevent browser navigation
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Row(
              children: [
                _buildItemSidebar(state),
                Expanded(child: contentArea),
              ],
            ),
            if (_selectedTransaction != null)
              buildTransactionDetailDrawer(_selectedTransaction!),
          ],
        ),
      ),
    );
  }

  void _closeMenus() {
    _closeImportMenu();
    _closeExportMenu();
    _closeSortMenu();
    _sortMenuEntry?.remove();
    _sortMenuEntry = null;
    _moreMenuEntry?.remove();
    _moreMenuEntry = null;
    _moreMenuTopLeft = null;
    _reorderPointEntry?.remove();
    _reorderPointEntry = null;
    _reorderTermsEntry?.remove();
    _reorderTermsEntry = null;
    _termsSearchEntry?.remove();
    _termsSearchEntry = null;
    _periodDropdownEntry?.remove();
    _periodDropdownEntry = null;
  }

  String _formatQty(double qty) => qty.toStringAsFixed(2);
  String _formatMoney(double? value) => (value ?? 0).toStringAsFixed(2);

  List<Item> _getFilteredItems(List<Item> allItems) {
    switch (_currentFilter) {
      case ItemsFilter.all:
        return allItems;
      case ItemsFilter.service:
        return allItems
            .where((it) => it.type.toLowerCase() == 'service')
            .toList();
      case ItemsFilter.composite:
        return allItems.where((it) => it.trackAssocIngredients).toList();
      case ItemsFilter.active:
        return allItems.where((it) => it.isActive).toList();
      case ItemsFilter.inactive:
        return allItems.where((it) => !it.isActive).toList();
      case ItemsFilter.returnable:
        return allItems.where((it) => it.isReturnable).toList();
      case ItemsFilter.nonreturnable:
        return allItems.where((it) => !it.isReturnable).toList();
      case ItemsFilter.temperature:
        return allItems.where((it) => it.isTemperatureControlled).toList();
      case ItemsFilter.nontemperature:
        return allItems.where((it) => !it.isTemperatureControlled).toList();
      case ItemsFilter.sales:
        return allItems.where((it) => it.isSalesItem).toList();
      case ItemsFilter.purchase:
        return allItems.where((it) => it.isPurchaseItem).toList();
      case ItemsFilter.inventory:
        return allItems.where((it) => it.isTrackInventory).toList();
      case ItemsFilter.noninventory:
        return allItems.where((it) => !it.isTrackInventory).toList();
      case ItemsFilter.batch:
        return allItems.where((it) => it.trackBatches).toList();
      case ItemsFilter.nonbatch:
        return allItems.where((it) => !it.trackBatches).toList();
      case ItemsFilter.lowstock:
        return allItems
            .where(
              (it) =>
                  it.reorderPoint > 0 &&
                  (it.stockOnHand ?? 0) < it.reorderPoint,
            )
            .toList();
      case ItemsFilter.belowreorderpoint:
        return allItems
            .where(
              (it) =>
                  it.reorderPoint > 0 &&
                  (it.stockOnHand ?? 0) <= it.reorderPoint,
            )
            .toList();
      case ItemsFilter.abovereorderpoint:
        return allItems
            .where(
              (it) =>
                  it.reorderPoint > 0 &&
                  (it.stockOnHand ?? 0) > it.reorderPoint,
            )
            .toList();
      case ItemsFilter.nonrackgoods:
        return allItems
            .where((it) => it.rackId == null || it.rackId!.isEmpty)
            .toList();
      case ItemsFilter.nonreorderpointgoods:
        return allItems.where((it) => it.reorderPoint == 0).toList();
      case ItemsFilter.scheduledrugs:
        return allItems.where((it) => it.scheduleOfDrugId != null).toList();
      case ItemsFilter.nontaxable:
        return allItems
            .where((it) => it.taxPreference?.toLowerCase() != 'taxable')
            .toList();
      case ItemsFilter.noncategory:
        return allItems.where((it) => it.categoryId == null).toList();
      case ItemsFilter.nonsku:
        return allItems
            .where((it) => it.sku == null || it.sku!.isEmpty)
            .toList();
    }
  }

  List<_ItemDetailTab> _tabsForItem(Item item) {
    final tabs = <_ItemDetailTab>[
      _ItemDetailTab.overview,
      _ItemDetailTab.warehouses,
    ];

    if (item.trackSerialNumber) {
      tabs.add(_ItemDetailTab.serialNumbers);
    } else if (item.trackBatches) {
      tabs.add(_ItemDetailTab.batchNumbers);
    }

    tabs.addAll([_ItemDetailTab.transactions, _ItemDetailTab.history]);

    return tabs;
  }

  String _tabLabel(_ItemDetailTab tab) {
    switch (tab) {
      case _ItemDetailTab.overview:
        return 'Overview';
      case _ItemDetailTab.warehouses:
        return 'Warehouses';
      case _ItemDetailTab.serialNumbers:
        return 'Serial Numbers';
      case _ItemDetailTab.batchNumbers:
        return 'Batch Details';
      case _ItemDetailTab.transactions:
        return 'Transactions';
      case _ItemDetailTab.history:
        return 'History';
    }
  }

  int _resolveTabIndex(List<_ItemDetailTab> tabs) {
    final requestedTab = _parseDetailTab(_requestedInitialTabKey);
    if (requestedTab != null) {
      final requestedIndex = tabs.indexOf(requestedTab);
      if (requestedIndex >= 0) {
        _selectedTabIndex = requestedIndex;
        _requestedInitialTabKey = null;
      }
    }

    if (_selectedTabIndex < tabs.length) {
      return _selectedTabIndex;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _selectedTabIndex = 0);
      }
    });
    return 0;
  }

  void _showReorderPointDialog(String itemId, int current) {
    final bool wasOpen = _reorderPointEntry != null;
    _closeMenus();
    if (wasOpen) return;

    final RenderBox renderBox =
        _reorderPointKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final overlay = Overlay.of(context);
    final RenderBox overlayBox =
        overlay.context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    final TextEditingController controller = TextEditingController(
      text: current > 0 ? current.toString() : '',
    );

    _reorderPointEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _reorderPointEntry?.remove();
                _reorderPointEntry = null;
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx - 100,
            top: offset.dy + size.height + 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -6,
                    left: 110,
                    child: Transform.rotate(
                      angle: 0.785,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Reorder Point',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Set Reorder point*',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF111827),
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final newVal =
                                      int.tryParse(controller.text) ?? 0;
                                  await ref
                                      .read(itemsControllerProvider.notifier)
                                      .updateReorderPoint(itemId, newVal);
                                  _reorderPointEntry?.remove();
                                  _reorderPointEntry = null;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(80, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Update',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reorderPointEntry!);
  }

  void _showReorderTermsDialog(String itemId, String? currentId) {
    final bool wasOpen = _reorderTermsEntry != null;
    _closeMenus();
    if (wasOpen) return;

    final RenderBox renderBox =
        _reorderTermsKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final overlay = Overlay.of(context);
    final RenderBox overlayBox =
        overlay.context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    String? selectedId = currentId;

    _reorderTermsEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final state = ref.watch(itemsControllerProvider);

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _reorderTermsEntry?.remove();
                      _reorderTermsEntry = null;
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: offset.dx - 100,
                  top: offset.dy + size.height + 8,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -6,
                          left: 110,
                          child: Transform.rotate(
                            angle: 0.785,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Reorder Terms',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Set Reorder Terms',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        final GlobalKey dropdownKey =
                                            GlobalKey();
                                        return InkWell(
                                          key: dropdownKey,
                                          onTap: () => _openTermsSearchMenu(
                                            context,
                                            dropdownKey,
                                            selectedId,
                                            (newId) {
                                              setPopupState(() {
                                                selectedId = newId;
                                              });
                                            },
                                          ),
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              minHeight: 40,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFD1D5DB),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedId == null
                                                        ? 'Select Terms'
                                                        : (state.reorderTerms
                                                                  .followedBy(
                                                                    state
                                                                        .drugSchedules,
                                                                  )
                                                                  .firstWhere(
                                                                    (t) =>
                                                                        t['id'] ==
                                                                        selectedId,
                                                                    orElse: () => {
                                                                      'name':
                                                                          'Select Terms',
                                                                    },
                                                                  )['name'] ??
                                                              'Select Terms'),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Color(0xFF6B7280),
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              itemsControllerProvider.notifier,
                                            )
                                            .updateReorderTerm(
                                              itemId,
                                              selectedId,
                                            );
                                        _reorderTermsEntry?.remove();
                                        _reorderTermsEntry = null;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(80, 36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Update',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_reorderTermsEntry!);
  }

  void _openTermsSearchMenu(
    BuildContext context,
    GlobalKey dropdownKey,
    String? currentId,
    Function(String?) onSelected,
  ) {
    if (_termsSearchEntry != null) {
      _termsSearchEntry?.remove();
      _termsSearchEntry = null;
      return;
    }

    final RenderBox renderBox =
        dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final overlay = Overlay.of(context);
    final RenderBox overlayBox =
        overlay.context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    String searchQuery = '';

    _termsSearchEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSearchState) {
            final state = ref.watch(itemsControllerProvider);

            // Combine reorder terms and drug schedules as seen in image
            final List<Map<String, dynamic>> allOptions = [
              ...state.reorderTerms,
              ...state.drugSchedules,
            ];

            final filteredOptions = allOptions.where((opt) {
              final name = (opt['name'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _termsSearchEntry?.remove();
                      _termsSearchEntry = null;
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: offset.dx,
                  top: offset.dy + size.height + 4,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    child: Container(
                      width: size.width,
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                border: Border.all(
                                  color: const Color(0xFF2563EB),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: TextField(
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (val) {
                                  setSearchState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filteredOptions.length,
                              itemBuilder: (context, index) {
                                final opt = filteredOptions[index];
                                final isSelected = opt['id'] == currentId;
                                return InkWell(
                                  onTap: () {
                                    onSelected(opt['id']);
                                    _termsSearchEntry?.remove();
                                    _termsSearchEntry = null;
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      opt['name'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF374151),
                                        fontWeight: isSelected
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (filteredOptions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No matches found',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_termsSearchEntry!);
  }

  void _handleSortField(
    BuildContext context,
    _ItemsSortField field,
    bool ascending,
  ) {
    // Already handled by setState in menus/actions
  }

  Future<void> _onFilesDropped(DropDoneDetails details) async {
    final List<PlatformFile> newFiles = [];
    for (final file in details.files) {
      final bytes = await file.readAsBytes();
      newFiles.add(
        PlatformFile(name: file.name, size: bytes.length, bytes: bytes),
      );
    }

    if (newFiles.isNotEmpty) {
      updateState(() {
        _itemImages.addAll(newFiles);
      });
      _updateItemImages();
    }
  }

  Future<void> _pickItemImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    updateState(() {
      _itemImages.addAll(result.files);
    });
    _updateItemImages();
  }

  Future<void> _updateItemImages() async {
    final state = ref.read(itemsControllerProvider);
    final String? effectiveId =
        widget.itemId ??
        state.selectedItemId ??
        (state.items.isNotEmpty ? state.items.first.id : null);

    final Item? item = state.items.cast<Item?>().firstWhere(
      (i) => i?.id == effectiveId,
      orElse: () => null,
    );

    if (item == null) return;

    setState(() => _isImageUploading = true);
    try {
      final storage = StorageService();

      // Separate existing URLs and new local files
      final newLocalFiles = _itemImages.whereType<PlatformFile>().toList();

      List<String> newlyUploadedUrls = [];
      if (newLocalFiles.isNotEmpty) {
        newlyUploadedUrls = await storage.uploadProductImages(newLocalFiles);
      }

      // Reconstruct final ordered list - careful to match original intended order
      final List<String> finalUrls = [];
      int uploadedIdx = 0;
      for (var img in _itemImages) {
        if (img is String) {
          finalUrls.add(img);
        } else if (img is PlatformFile) {
          if (uploadedIdx < newlyUploadedUrls.length) {
            finalUrls.add(newlyUploadedUrls[uploadedIdx]);
            uploadedIdx++;
          }
        }
      }

      if (finalUrls.isEmpty && _itemImages.isNotEmpty) {
        // Fallback if upload failed but we had images
        return;
      }

      final updatedItem = item.copyWith(
        imageUrls: finalUrls,
        primaryImageUrl: finalUrls.isNotEmpty
            ? finalUrls[_primaryImageIndex.clamp(0, finalUrls.length - 1)]
            : null,
      );

      final success = await ref
          .read(itemsControllerProvider.notifier)
          .updateItem(updatedItem);

      if (success && mounted) {
        setState(() {
          _itemImages.clear();
          _itemImages.addAll(finalUrls);
          _primaryImageIndex = finalUrls
              .indexOf(updatedItem.primaryImageUrl ?? '')
              .clamp(0, finalUrls.length);
          if (_primaryImageIndex < 0) _primaryImageIndex = 0;
        });
      }
    } catch (e) {
      debugPrint('Failed to update item images: $e');
    } finally {
      if (mounted) setState(() => _isImageUploading = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'partiallyInvoiced':
        return 'Partially Invoiced';
      case 'invoiced':
        return 'Invoiced';
      case 'closed':
        return 'Closed';
      case 'void':
        return 'Void';
      case 'confirmed':
        return 'Confirmed';
      case 'partiallyShipped':
        return 'Partially shipped';
      case 'shipped':
        return 'Shipped';
      case 'dropshipped':
        return 'Dropshipped';
      case 'backordered':
        return 'Backordered';
      case 'onHold':
        return 'On Hold';
      default:
        return status;
    }
  }

  String _formatCurrency(double value) => '₹${value.toStringAsFixed(2)}';

  Widget buildTransactionDetailDrawer(TransactionData tx) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Material(
        elevation: 16,
        child: Container(
          width: 480,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.documentType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx.documentNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _selectedTransaction = null),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDrawerSection('TRANSACTION DETAILS', [
                        _buildDrawerRow('Date', tx.date),
                        _buildDrawerRow(
                          'Status',
                          _statusLabel(tx.status),
                          valueColor: tx.status == 'confirmed'
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildDrawerSection('PARTNER DETAILS', [
                        _buildDrawerRow('Customer/Vendor', tx.customerName),
                        _buildDrawerRow('Reference', tx.reference ?? 'N/A'),
                      ]),
                      const SizedBox(height: 32),
                      _buildDrawerSection('ITEM TOTALS', [
                        _buildDrawerRow(
                          'Quantity',
                          tx.quantitySold.toStringAsFixed(2),
                        ),
                        _buildDrawerRow('Rate', _formatCurrency(tx.price)),
                        const Divider(height: 32),
                        _buildDrawerRow(
                          'Total Amount',
                          _formatCurrency(tx.total),
                          isBold: true,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Download PDF',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'View Document',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDrawerRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
