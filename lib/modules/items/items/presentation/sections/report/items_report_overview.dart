// ignore_for_file: deprecated_member_use
// FILE: lib/modules/items/items/presentation/sections/report/items_items_report_overview.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/services/permission_service.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';

import 'item_row.dart';
import 'items_filters.dart';
import 'items_report_body.dart';

class ItemsReportScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  final String? initialSearchQuery;

  const ItemsReportScreen({
    super.key,
    this.initialFilter,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<ItemsReportScreen> createState() => _ItemsReportScreenState();
}

class _ItemsReportScreenState extends ConsumerState<ItemsReportScreen> {
  ItemsFilter _currentFilter = ItemsFilter.all;

  ItemsFilter _parseFilter(String? value) {
    if (value == null || value.isEmpty) {
      return ItemsFilter.all;
    }
    return ItemsFilter.values
            .where((filter) => filter.name == value)
            .firstOrNull ??
        ItemsFilter.all;
  }

  String? _filterToQueryValue(ItemsFilter filter) {
    return filter == ItemsFilter.all ? null : filter.name;
  }

  void _setCurrentFilter(ItemsFilter filter) {
    setState(() => _currentFilter = filter);
    final queryParameters = <String, String>{};
    final filterValue = _filterToQueryValue(filter);
    if (filterValue != null) {
      queryParameters['filter'] = filterValue;
    }
    context.goNamed(AppRoutes.itemsReport, queryParameters: queryParameters);
  }

  @override
  void initState() {
    super.initState();
    _currentFilter = _parseFilter(widget.initialFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(itemsControllerProvider.notifier);
      final initialQuery = widget.initialSearchQuery?.trim() ?? '';
      if (initialQuery.isNotEmpty) {
        controller.performSearch(initialQuery);
      } else {
        controller.loadItems();
      }
    });
  }

  // Map Item (Domain) to ItemRow (UI) using pre-computed maps for O(1) lookups
  ItemRow _mapToRow(
    Item item, {
    required Map<String, String> brandsMap,
    required Map<String, String> categoriesMap,
    required Map<String, String> manufacturersMap,
    required Map<String, String> vendorsMap,
    required Map<String, String> storageMap,
    required Map<String, String> accountsMap,
    required Map<String, String> reorderTermsMap,
    required Map<String, String> buyingRulesMap,
    required Map<String, String> drugSchedulesMap,
  }) {
    // Look up names from IDs using the maps
    String? brandName = item.brandId != null ? brandsMap[item.brandId] : null;
    String? categoryName = item.categoryId != null
        ? categoriesMap[item.categoryId]
        : null;
    String? manufacturerName = item.manufacturerId != null
        ? manufacturersMap[item.manufacturerId]
        : null;
    String? vendorName = item.preferredVendorId != null
        ? vendorsMap[item.preferredVendorId]
        : null;
    String? storageName = item.storageId != null
        ? storageMap[item.storageId]
        : null;
    String? salesAccountName = item.salesAccountId != null
        ? accountsMap[item.salesAccountId]
        : null;
    String? purchaseAccountName = item.purchaseAccountId != null
        ? accountsMap[item.purchaseAccountId]
        : null;
    String? reorderTermName = item.reorderTermId != null
        ? reorderTermsMap[item.reorderTermId]
        : null;
    String? buyingRuleName = item.buyingRuleId != null
        ? buyingRulesMap[item.buyingRuleId]
        : null;
    String? scheduleName = item.scheduleOfDrugId != null
        ? drugSchedulesMap[item.scheduleOfDrugId]
        : null;

    // Format tax preference for display
    String? taxPrefDisplay;
    if (item.taxPreference != null) {
      switch (item.taxPreference!.toLowerCase()) {
        case 'taxable':
          taxPrefDisplay = 'Taxable';
          break;
        case 'non-taxable':
          taxPrefDisplay = 'Non-Taxable';
          break;
        case 'exempt':
          taxPrefDisplay = 'Exempt';
          break;
        default:
          taxPrefDisplay = item.taxPreference;
      }
    }

    return ItemRow(
      id: item.id ?? item.itemCode,
      // Core
      name: item.productName,
      accountName:
          salesAccountName ?? 'Sales', // Use actual sales account or fallback
      // Basic Information
      billingName: item.billingName,
      itemCode: item.itemCode,
      typeDisplay: item.type == 'goods' ? 'Goods' : 'Service',
      taxPreference: taxPrefDisplay,
      hsn: item.hsnCode,
      sku: item.sku ?? item.itemCode,
      ean: item.ean,
      brand: brandName,
      category: categoryName,

      // Sales Information
      sellingPrice: item.sellingPrice?.toStringAsFixed(2),
      mrp: item.mrp?.toStringAsFixed(2),
      ptr: item.ptr?.toStringAsFixed(2),
      salesAccount: salesAccountName,
      salesDescription: item.salesDescription,

      // Purchase Information
      costPrice: item.costPrice?.toStringAsFixed(2),
      purchaseAccount: purchaseAccountName,
      preferredVendor: vendorName,
      purchaseDescription: item.purchaseDescription,

      // Formulation
      length: item.length?.toString(),
      width: item.width?.toString(),
      height: item.height?.toString(),
      weight: item.weight?.toString(),
      manufacturer: manufacturerName,
      mpn: item.mpn,
      upc: item.upc,
      isbn: item.isbn,

      // Inventory
      stockOnHand: (item.stockOnHand ?? 0).toStringAsFixed(2),
      reorderLevel: item.reorderPoint > 0 ? item.reorderPoint.toString() : null,
      inventoryValuationMethod: item.inventoryValuationMethod,
      storageLocation: storageName,
      reorderTerm: reorderTermName,

      // Composition
      buyingRule: buyingRuleName,
      scheduleOfDrug: scheduleName,

      // Legacy
      description: item.salesDescription,
      itemType: item.type,
      imageUrl: item.primaryImageUrl,

      // Flags
      isActive: item.isActive,
      isLock: item.isLock,
      isReturnable: item.isReturnable,
      pushToEcommerce: item.pushToEcommerce,
      isInventoryItem: item.isTrackInventory,
      isTemperatureControlled: item.isTemperatureControlled,
      isSalesItem: item.isSalesItem,
      isPurchaseItem: item.isPurchaseItem,
      isRackItem: item.rackId != null && item.rackId!.isNotEmpty,
      hasSku: (item.sku ?? item.itemCode).isNotEmpty,
      trackActiveIngredients: item.trackAssocIngredients,
      usesBatch: item.trackBatches,
      hasReorderPoint: item.reorderPoint > 0,
      hasCategory: item.categoryId != null,
      isScheduledDrug: item.scheduleOfDrugId != null,
      isTaxable: item.taxPreference?.toLowerCase() == 'taxable',
    );
  }

  List<ItemRow> get _filteredItems {
    final state = ref.watch(itemsControllerProvider);
    final allItems = state.items;

    // Pre-compute maps for O(1) lookups during mapping with safety checks
    final brandsMap = <String, String>{};
    for (var b in state.brands) {
      if (b['id'] != null && (b['name'] != null || b['brand_name'] != null)) {
        brandsMap[b['id'].toString()] = (b['name'] ?? b['brand_name'])
            .toString();
      }
    }

    final categoriesMap = <String, String>{};
    for (var c in state.categories) {
      if (c['id'] != null &&
          (c['name'] != null || c['category_name'] != null)) {
        categoriesMap[c['id'].toString()] =
            (c['name'] != null ? c['name'] : c['category_name']).toString();
      }
    }

    final manufacturersMap = <String, String>{};
    for (var m in state.manufacturers) {
      if (m['id'] != null &&
          (m['name'] != null || m['manufacturer_name'] != null)) {
        manufacturersMap[m['id'].toString()] =
            (m['name'] != null ? m['name'] : m['manufacturer_name']).toString();
      }
    }

    final vendorsMap = <String, String>{};
    for (var v in state.vendors) {
      if (v['id'] != null &&
          (v['name'] != null ||
              v['vendor_name'] != null ||
              v['display_name'] != null)) {
        final name = v['name'] != null
            ? v['name']
            : (v['vendor_name'] != null ? v['vendor_name'] : v['display_name']);
        vendorsMap[v['id'].toString()] = name.toString();
      }
    }

    final storageMap = <String, String>{};
    for (var s in state.storageLocations) {
      if (s['id'] != null &&
          (s['name'] != null ||
              s['display_text'] != null ||
              s['location_name'] != null)) {
        storageMap[s['id'].toString()] =
            (s['name'] ?? s['display_text'] ?? s['location_name']).toString();
      }
    }

    final accountsMap = <String, String>{};
    for (var a in state.accounts) {
      if (a['id'] != null &&
          (a['name'] != null || a['system_account_name'] != null)) {
        accountsMap[a['id'].toString()] =
            (a['name'] ?? a['system_account_name']).toString();
      }
    }

    final reorderTermsMap = <String, String>{};
    for (var t in state.reorderTerms) {
      if (t['id'] != null && (t['name'] != null || t['term_name'] != null)) {
        reorderTermsMap[t['id'].toString()] = (t['name'] ?? t['term_name'])
            .toString();
      }
    }

    final buyingRulesMap = <String, String>{};
    for (var r in state.buyingRules) {
      if (r['id'] != null &&
          (r['name'] != null ||
              r['rule_name'] != null ||
              r['buying_rule'] != null)) {
        buyingRulesMap[r['id'].toString()] =
            (r['name'] ?? r['rule_name'] ?? r['buying_rule']).toString();
      }
    }

    final drugSchedulesMap = <String, String>{};
    for (var s in state.drugSchedules) {
      if (s['id'] != null &&
          (s['name'] != null ||
              s['schedule_name'] != null ||
              s['shedule_name'] != null)) {
        drugSchedulesMap[s['id'].toString()] =
            (s['name'] ?? s['schedule_name'] ?? s['shedule_name']).toString();
      }
    }

    debugPrint(
      '📊 ItemsReportScreen: Mapping ${allItems.length} items to rows...',
    );

    // Convert all to ItemRow first
    final List<ItemRow> rows = [];
    for (final item in allItems) {
      try {
        rows.add(
          _mapToRow(
            item,
            brandsMap: brandsMap,
            categoriesMap: categoriesMap,
            manufacturersMap: manufacturersMap,
            vendorsMap: vendorsMap,
            storageMap: storageMap,
            accountsMap: accountsMap,
            reorderTermsMap: reorderTermsMap,
            buyingRulesMap: buyingRulesMap,
            drugSchedulesMap: drugSchedulesMap,
          ),
        );
      } catch (e) {
        debugPrint(
          '❌ Error mapping item ${item.productName} (ID: ${item.id}): $e',
        );
      }
    }

    debugPrint(
      '✅ ItemsReportScreen: Successfully mapped ${rows.length} / ${allItems.length} items',
    );

    double parseNumber(String? s) {
      if (s == null || s.trim().isEmpty) return 0;
      return double.tryParse(s.trim()) ?? 0;
    }

    switch (_currentFilter) {
      case ItemsFilter.all:
        return rows;

      case ItemsFilter.service:
        return rows
            .where((e) => e.itemType.toLowerCase() == 'service')
            .toList();

      case ItemsFilter.composite:
        return rows
            .where(
              (e) =>
                  e.itemType.toLowerCase() == 'goods' &&
                  e.trackActiveIngredients,
            )
            .toList();

      case ItemsFilter.active:
        return rows.where((e) => e.isActive).toList();

      case ItemsFilter.inactive:
        return rows.where((e) => !e.isActive).toList();

      case ItemsFilter.returnable:
        return rows.where((e) => e.isReturnable).toList();

      case ItemsFilter.nonreturnable:
        return rows.where((e) => !e.isReturnable).toList();

      case ItemsFilter.temperature:
        return rows.where((e) => e.isTemperatureControlled).toList();

      case ItemsFilter.nontemperature:
        return rows.where((e) => !e.isTemperatureControlled).toList();

      case ItemsFilter.sales:
        return rows.where((e) => e.isSalesItem).toList();

      case ItemsFilter.purchase:
        return rows.where((e) => e.isPurchaseItem).toList();

      case ItemsFilter.inventory:
        return rows.where((e) => e.isInventoryItem).toList();

      case ItemsFilter.noninventory:
        return rows.where((e) => !e.isInventoryItem).toList();

      case ItemsFilter.batch:
        return rows.where((e) => e.usesBatch).toList();

      case ItemsFilter.nonbatch:
        return rows.where((e) => !e.usesBatch).toList();

      case ItemsFilter.lowstock:
        return rows.where((e) {
          final stock = parseNumber(e.stockOnHand);
          final rop = parseNumber(e.reorderLevel);
          return stock > 0 && rop > 0 && stock <= rop;
        }).toList();

      case ItemsFilter.belowreorderpoint:
        return rows.where((e) {
          final stock = parseNumber(e.stockOnHand);
          final rop = parseNumber(e.reorderLevel);
          return rop > 0 && stock < rop;
        }).toList();

      case ItemsFilter.abovereorderpoint:
        return rows.where((e) {
          final stock = parseNumber(e.stockOnHand);
          final rop = parseNumber(e.reorderLevel);
          return rop > 0 && stock > rop;
        }).toList();

      case ItemsFilter.nonrackgoods:
        return rows.where((e) => !e.isRackItem).toList();

      case ItemsFilter.nonreorderpointgoods:
        return rows.where((e) => !e.hasReorderPoint).toList();

      case ItemsFilter.scheduledrugs:
        return rows.where((e) => e.isScheduledDrug).toList();

      case ItemsFilter.nontaxable:
        return rows.where((e) => !e.isTaxable).toList();

      case ItemsFilter.noncategory:
        return rows.where((e) => !e.hasCategory).toList();

      case ItemsFilter.nonsku:
        return rows.where((e) => !e.hasSku).toList();
    }
  }

  void _openDetail(ItemRow row) {
    final user = ref.read(authUserProvider);
    final canViewItems =
        user != null &&
        PermissionService.hasModuleAction(user, 'item', action: 'view');
    if (!canViewItems) {
      return;
    }

    final state = ref.read(itemsControllerProvider);
    Item? item = state.items.firstWhere(
      (it) =>
          (row.id != null && it.id == row.id) ||
          it.productName.toLowerCase() == row.name.toLowerCase(),
      orElse: () => Item(
        id: null,
        type: row.itemType,
        productName: row.name,
        itemCode: row.itemCode ?? '',
        unitId: '',
        isReturnable: row.isReturnable,
        pushToEcommerce: row.pushToEcommerce,
        isTrackInventory: row.isInventoryItem,
        trackBinLocation: false,
        trackBatches: row.usesBatch,
        reorderPoint: row.hasReorderPoint
            ? int.tryParse(row.reorderLevel ?? '') ?? 0
            : 0,
      ),
    );

    if (item.id != null) {
      context.go('/items/detail/${item.id!}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemsControllerProvider);
    final user = ref.watch(authUserProvider);
    final canViewItems =
        user != null &&
        PermissionService.hasModuleAction(user, 'item', action: 'view');

    if (!canViewItems) {
      return ZerpaiLayout(
        pageTitle: 'Items',
        enableBodyScroll: false,
        child: const Center(
          child: Text('You do not have permission to view items.'),
        ),
      );
    }

    return ZerpaiLayout(
      pageTitle: 'Items',
      enableBodyScroll: false,
      child: ItemsReportBody(
        isLoading: state.isLoadingList,
        filter: _currentFilter,
        initialSearchQuery: widget.initialSearchQuery,
        items: _filteredItems, // Uses the computed property
        onFilterChanged: _setCurrentFilter,
        onItemTap: _openDetail,
        onBulkSetActive: _bulkSetActive,
        onBulkSetLock: _bulkSetLock,
        onBulkDelete: _bulkDelete,
      ),
    );
  }

  Future<int> _bulkSetActive(Set<String> ids, bool isActive) async {
    final user = ref.read(authUserProvider);
    final canEditItems =
        user != null &&
        PermissionService.hasModuleAction(user, 'item', action: 'edit');
    if (!canEditItems) {
      return 0;
    }

    final controller = ref.read(itemsControllerProvider.notifier);
    final items = ref.read(itemsControllerProvider).items;
    final idsToUpdate = <String>{};

    for (final item in items) {
      final selectionId = item.id ?? item.itemCode;
      if (ids.contains(selectionId) && item.id != null) {
        idsToUpdate.add(item.id!);
      }
    }

    return controller.updateItemsBulk(idsToUpdate, {'is_active': isActive});
  }

  Future<int> _bulkSetLock(Set<String> ids, bool isLock) async {
    final user = ref.read(authUserProvider);
    final canEditItems =
        user != null &&
        PermissionService.hasModuleAction(user, 'item', action: 'edit');
    if (!canEditItems) {
      return 0;
    }

    final controller = ref.read(itemsControllerProvider.notifier);
    final items = ref.read(itemsControllerProvider).items;
    final idsToUpdate = <String>{};

    for (final item in items) {
      final selectionId = item.id ?? item.itemCode;
      if (ids.contains(selectionId) && item.id != null) {
        idsToUpdate.add(item.id!);
      }
    }

    return controller.updateItemsBulk(idsToUpdate, {'is_lock': isLock});
  }

  Future<int> _bulkDelete(Set<String> ids) async {
    final user = ref.read(authUserProvider);
    final canDeleteItems =
        user != null &&
        PermissionService.hasModuleAction(user, 'item', action: 'delete');
    if (!canDeleteItems) return 0;

    final controller = ref.read(itemsControllerProvider.notifier);
    final items = ref.read(itemsControllerProvider).items;
    final idsToDelete = <String>{};

    for (final item in items) {
      final selectionId = item.id ?? item.itemCode;
      if (ids.contains(selectionId) && item.id != null) {
        idsToDelete.add(item.id!);
      }
    }

    return controller.deleteItemsBulk(idsToDelete);
  }
}
