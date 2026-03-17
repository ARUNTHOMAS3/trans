// FILE: lib/modules/items/controller/items_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository.dart';

import 'package:zerpai_erp/modules/items/items/repositories/items_repository_provider.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/errors/app_exceptions.dart';

import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/items/items/models/uqc_model.dart';
import 'package:zerpai_erp/shared/services/sync/sync_service.dart';
import 'items_state.dart';

class ItemsController extends StateNotifier<ItemsState> {
  final ItemRepository repo;
  final SyncService _syncService;
  final LookupsApiService _lookupsService = LookupsApiService();

  /// Tracks IDs that already failed a fetch so [ensureItemLoaded] doesn't
  /// loop when [loadItems] clears the global [state.error] in the background.
  final Set<String> _failedItemIds = {};

  /// Cache for item quick stats (stock and price) for search hover overlay
  final Map<String, Map<String, dynamic>> _statsCache = {};

  ItemsController(this.repo, this._syncService) : super(const ItemsState()) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      loadItems(),
      loadCompositeItems(),
      loadLookupData(),
      loadAllPriceLists(),
    ]);
  }

  Future<void> loadItems() async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('Loading items', module: 'items');
      state = state.copyWith(
        isLoading: true,
        hasReachedMax: false,
        // Using explicit null to clear previous cursor
        nextCursor: null,
      );

      final resultFuture = repo.getProductsCursor(limit: 50);
      final countFuture = repo.getItemsCount();

      final results = await Future.wait([resultFuture, countFuture]);
      final data = results[0] as Map<String, dynamic>;
      final items = data['items'] as List<Item>;
      final nextCursorStr = data['next_cursor'] as String?;
      final itemsCount = results[1] as int;

      stopwatch.stop();
      AppLogger.performance('loadItems', stopwatch.elapsed);
      AppLogger.info(
        'First chunk items loaded successfully',
        module: 'items',
        data: {'count': items.length},
      );

      // Important logic: Need to explicitly pass `null` for `nextCursor` to the state to reset it.
      // But `copyWith` treats `null` as "keep existing", so we must bypass it for explicit cancellation.
      // Wait, let's check ItemsState.copyWith if it has `String? nextCursor`. Usually copyWith has issues unsetting nulls.
      // For now, let's just use it and rely on it, or better yet, make an internal change to items_state.dart

      state = state.copyWith(
        items: items,
        totalItemsCount: itemsCount,
        nextCursor: nextCursorStr,
        hasReachedMax: nextCursorStr == null || items.length < 50,
        isLoading: false,
        isSearching: false,
        // We do NOT pass error: null here to avoid clearing error
        // from a concurrent ensureItemLoaded call.
      );

      for (final item in items) {
        _syncLookupCache(item);
      }
    } on NetworkException catch (e) {
      AppLogger.error('Network error loading items', error: e, module: 'items');
      state = state.copyWith(error: e.userMessage, isLoading: false);
    } on AppException catch (e) {
      AppLogger.error('Failed to load items', error: e, module: 'items');
      state = state.copyWith(error: e.userMessage, isLoading: false);
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading items',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to load items. Please try again.",
        isLoading: false,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.hasReachedMax || state.isSearching) return;

    try {
      state = state.copyWith(isLoading: true);

      final data = await repo.getProductsCursor(
        limit: 50,
        cursor: state.nextCursor,
      );

      final newItems = data['items'] as List<Item>;
      final nextCursorStr = data['next_cursor'] as String?;

      final allItems = [...state.items, ...newItems];

      state = state.copyWith(
        items: allItems,
        nextCursor: nextCursorStr,
        hasReachedMax: nextCursorStr == null || newItems.length < 50,
        isLoading: false,
      );

      for (final item in newItems) {
        _syncLookupCache(item);
      }
    } catch (e) {
      AppLogger.error('Failed to load next page', error: e, module: 'items');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      return loadItems();
    }

    try {
      AppLogger.info('Searching items: $query', module: 'items');
      state = state.copyWith(isSearching: true, isLoading: true, error: null);

      final items = await repo.searchProducts(query.trim(), limit: 30);

      state = state.copyWith(
        items: items,
        totalItemsCount: state.totalItemsCount,
        nextCursor: null,
        hasReachedMax: true,
        isLoading: false,
        isSearching: true,
        error: null, // Clear error specifically for search context
      );

      for (final item in items) {
        _syncLookupCache(item);
      }
    } catch (e) {
      AppLogger.error('Failed to search items', error: e, module: 'items');
      state = state.copyWith(
        error: "Search failed. Please try again.",
        isLoading: false,
      );
    }
  }

  void selectItem(String? id) {
    state = state.copyWith(selectedItemId: id);
    if (id != null) {
      final item = state.items.cast<Item?>().firstWhere(
        (i) => i?.id == id,
        orElse: () => null,
      );
      if (item != null) _syncLookupCache(item);
    }
  }

  /// Ensures a specific item is loaded into the state.
  /// Used for deep links where the item might not be in the initial background chunk.
  Future<Item?> ensureItemLoaded(String id, {bool forceRefresh = false}) async {
    // Guard 1: already loading — don't stack requests.
    if (state.isLoading) return null;

    // Guard 2: this item already failed a previous fetch.
    // [forceRefresh] (Retry button) clears the failure so we can try again.
    if (_failedItemIds.contains(id) && !forceRefresh) {
      AppLogger.debug(
        'ensureItemLoaded: skipping — previous fetch already failed for $id',
        module: 'items',
      );
      // Re-surface the error so the UI still shows the Retry button.
      if (state.error == null) {
        state = state.copyWith(
          error: "Failed to load item. Please check your connection.",
        );
      }
      return null;
    }

    // Guard 3: already in memory — no network call needed.
    if (!forceRefresh) {
      final existing = state.items.cast<Item?>().firstWhere(
        (i) => i?.id == id,
        orElse: () => null,
      );
      if (existing != null) {
        _syncLookupCache(existing);
        return existing;
      }
    }

    // Clear failure record when explicitly retrying.
    if (forceRefresh) _failedItemIds.remove(id);

    try {
      AppLogger.debug(
        'Fetching specific item for direct link',
        data: {'id': id, 'forceRefresh': forceRefresh},
        module: 'items',
      );

      state = state.copyWith(isLoading: true, error: null);

      final item = await repo.getItemById(id);
      if (item != null) {
        AppLogger.info(
          'Successfully hydrated item: ${item.productName}',
          module: 'items',
          data: {
            'compositions': item.compositions?.length ?? 0,
            'manufacturer': item.manufacturerName,
          },
        );

        final newCache = _getUpdatedCache(item);
        final updatedItems = state.items.any((i) => i.id == id)
            ? state.items.map((i) => i.id == id ? item : i).toList()
            : [...state.items, item];

        state = state.copyWith(
          items: updatedItems,
          lookupCache: newCache,
          isLoading: false,
          error: null,
        );
        return item;
      } else {
        AppLogger.warning(
          'Hydration failed: API returned null for ID $id',
          module: 'items',
        );
        _failedItemIds.add(id);
        state = state.copyWith(isLoading: false, error: "Item not found.");
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load item for direct link',
        error: e,
        module: 'items',
      );
      _failedItemIds.add(id); // ← loop breaker: future calls short-circuit
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load item. Please check your connection.",
      );
    }
    return null;
  }

  /// Fetches quick stats (current stock and last purchase price) for an item.
  /// Uses a local cache to prevent redundant API calls during rapid hover.
  Future<Map<String, dynamic>> fetchQuickStats(String itemId) async {
    if (_statsCache.containsKey(itemId)) {
      return _statsCache[itemId]!;
    }

    try {
      final stats = await repo.getQuickStats(itemId);
      _statsCache[itemId] = stats;

      // Update the item in the state if it exists
      final index = state.items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final currentItem = state.items[index];
        final updatedItem = currentItem.copyWith(
          stockOnHand: double.tryParse(stats['current_stock']?.toString() ?? '0'),
          committedStock:
              double.tryParse(stats['committed_stock']?.toString() ?? '0'),
          toBeShipped: stats['to_be_shipped'] != null
              ? double.tryParse(stats['to_be_shipped'].toString())
              : null,
          toBeReceived: stats['to_be_received'] != null
              ? double.tryParse(stats['to_be_received'].toString())
              : null,
          toBeInvoiced: stats['to_be_invoiced'] != null
              ? double.tryParse(stats['to_be_invoiced'].toString())
              : null,
          toBeBilled: stats['to_be_billed'] != null
              ? double.tryParse(stats['to_be_billed'].toString())
              : null,
        );

        final newItems = List<Item>.from(state.items);
        newItems[index] = updatedItem;
        state = state.copyWith(items: newItems);
      }

      return stats;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch item quick stats',
        error: e,
        module: 'items',
      );
      return {'current_stock': 0, 'last_purchase_price': 0.0};
    }
  }

  Future<void> loadLookupData({bool force = false}) async {
    // Avoid redundant calls if already loading or already have data
    if (!force && (state.isLoadingLookups || state.units.isNotEmpty)) {
      return;
    }

    try {
      state = state.copyWith(isLoadingLookups: true);
      AppLogger.debug('Loading lookup data', module: 'items');

      // Load all lookup data in parallel for significant performance improvement
      // Load lookup data in parallel.
      // NOTE: We EXCLUDE contents and strengths here because they can be very large
      // and are better handled via search-on-demand (Autocomplete).
      final futureResults = await Future.wait([
        _lookupsService.getUnits(),
        _lookupsService.getCategories(),
        _lookupsService.getTaxRates(),
        _lookupsService.getTaxGroups(),
        _lookupsService.getManufacturers(),
        _lookupsService.getBrands(),
        _lookupsService.getVendors(),
        _lookupsService.getStorageLocations(),
        _lookupsService.getRacks(),
        _lookupsService.getReorderTerms(),
        _lookupsService.getAccounts(),
        _lookupsService.getBuyingRules(),
        _lookupsService.getDrugSchedules(),
        _lookupsService.getUqc(),
      ]);

      final units = futureResults[0] as List<Unit>;
      final categories = futureResults[1] as List<Map<String, dynamic>>;
      final taxRates = futureResults[2] as List<TaxRate>;
      final taxGroups = futureResults[3] as List<TaxRate>;

      final manufacturers = (futureResults[4] as List<Map<String, dynamic>>)
          .map(
            (m) => {
              ...m,
              'name': m['name'] ?? m['manufacturer_name'] ?? 'Unknown',
            },
          )
          .toList();

      final brands = (futureResults[5] as List<Map<String, dynamic>>)
          .map((b) => {...b, 'name': b['name'] ?? b['brand_name'] ?? 'Unknown'})
          .toList();

      final vendors = (futureResults[6] as List<Map<String, dynamic>>)
          .map(
            (v) => {
              ...v,
              'name':
                  v['name'] ??
                  v['vendor_name'] ??
                  v['display_name'] ??
                  'Unknown',
            },
          )
          .toList();

      final storageLocations = (futureResults[7] as List<Map<String, dynamic>>)
          .map(
            (s) => {...s, 'name': s['name'] ?? s['location_name'] ?? 'Unknown'},
          )
          .toList();

      final racks = (futureResults[8] as List<Map<String, dynamic>>)
          .map((r) => {...r, 'name': r['name'] ?? r['rack_code'] ?? 'Unknown'})
          .toList();

      final reorderTerms = (futureResults[9] as List<Map<String, dynamic>>)
          .map(
            (rt) => {...rt, 'name': rt['name'] ?? rt['term_name'] ?? 'Unknown'},
          )
          .toList();

      final accounts = (futureResults[10] as List<Map<String, dynamic>>)
          .map(
            (a) => {
              ...a,
              'name': a['name'] ?? a['system_account_name'] ?? 'Unknown',
            },
          )
          .toList();

      final buyingRules = (futureResults[11] as List<Map<String, dynamic>>)
          .map(
            (br) => {
              ...br,
              'name':
                  br['name'] ??
                  br['rule_name'] ??
                  br['buying_rule'] ??
                  'Unknown',
            },
          )
          .toList();

      final drugSchedules = (futureResults[12] as List<Map<String, dynamic>>)
          .map(
            (ds) => {
              ...ds,
              'name':
                  ds['name'] ??
                  ds['schedule_name'] ??
                  ds['shedule_name'] ??
                  'Unknown',
            },
          )
          .toList();

      final uqcList = (futureResults.length > 13)
          ? (futureResults[13] as List<Uqc>)
          : <Uqc>[];

      state = state.copyWith(
        units: units,
        categories: categories,
        taxRates: taxRates,
        taxGroups: taxGroups,
        manufacturers: manufacturers,
        brands: brands,
        vendors: vendors,
        storageLocations: storageLocations,
        racks: racks,
        reorderTerms: reorderTerms,
        accounts: accounts,
        contents: [], // Handled by search-on-demand
        strengths: [], // Handled by search-on-demand
        buyingRules: buyingRules,
        drugSchedules: drugSchedules,
        uqcList: uqcList,
        isLoadingLookups: false,
      );
      
      // Load all price lists into state
      await loadAllPriceLists();

      AppLogger.debug(
        'State updated with lookup data',
        module: 'items',
        data: {
          'units': state.units.length,
          'categories': state.categories.length,
          'manufacturers': state.manufacturers.length,
          'brands': state.brands.length,
          'vendors': state.vendors.length,
          'contents': state.contents.length,
          'strengths': state.strengths.length,
          'buyingRules': state.buyingRules.length,
          'drugSchedules': state.drugSchedules.length,
          'uqcList': state.uqcList.length,
        },
      );
    } catch (e) {
      AppLogger.error('Error loading lookup data', error: e, module: 'items');
      state = state.copyWith(isLoadingLookups: false);
    }
  }

  Map<String, String> validateItem(Item item) {
    final errors = <String, String>{};

    // BACKEND REQUIRED FIELDS (from CreateProductDto)

    // 1. Type (required in backend)
    if (item.type.trim().isEmpty) {
      errors['type'] = 'Product type is required';
    }

    // 2. Product Name (required in backend)
    if (item.productName.trim().isEmpty) {
      errors['productName'] = 'Product name is required';
    }

    // 3. Item Code (required in backend)
    if (item.itemCode.trim().isEmpty) {
      errors['itemCode'] = 'Item code/SKU is required';
    }

    // 4. Unit ID (required for goods only)
    if (item.type.trim().toLowerCase() != 'service' &&
        item.unitId.trim().isEmpty) {
      errors['unitId'] = 'Unit is required';
    }

    // OPTIONAL VALIDATIONS (format checks only if field is filled)

    // Validate prices are positive if provided
    if (item.sellingPrice != null && item.sellingPrice! < 0) {
      errors['sellingPrice'] = 'Selling price must be positive';
    }

    if (item.isTrackInventory &&
        (item.inventoryValuationMethod == null ||
            item.inventoryValuationMethod!.isEmpty)) {
      errors['inventoryValuationMethod'] = 'Valuation method is required';
    }

    // 12. MRP - MRP must be positive if provided
    if (item.mrp != null && item.mrp! < 0) {
      errors['mrp'] = 'MRP must be positive';
    }

    return errors;
  }

  Future<bool> createItem(Item item) async {
    try {
      // Validate first
      final errors = validateItem(item);
      if (errors.isNotEmpty) {
        AppLogger.warning(
          'Item validation failed',
          module: 'items',
          data: {'errors': errors},
        );
        state = state.copyWith(validationErrors: errors);
        return false;
      }

      // Check for duplicate item code locally first
      final codeExists = state.items.any(
        (i) => i.itemCode.toLowerCase() == item.itemCode.toLowerCase(),
      );
      if (codeExists) {
        state = state.copyWith(
          validationErrors: {'itemCode': 'This item code is already in use.'},
        );
        return false;
      }

      // Check for duplicate SKU locally
      if (item.sku != null && item.sku!.isNotEmpty) {
        final skuExists = state.items.any(
          (i) => i.sku?.toLowerCase() == item.sku?.toLowerCase(),
        );
        if (skuExists) {
          state = state.copyWith(
            validationErrors: {'sku': 'This SKU is already in use.'},
          );
          return false;
        }
      }

      AppLogger.info(
        'Creating item',
        module: 'items',
        data: {'name': item.productName, 'code': item.itemCode},
      );

      state = state.copyWith(isSaving: true, validationErrors: {});
      final createdItem = await repo.createItem(item);

      AppLogger.info(
        'Item created successfully',
        module: 'items',
        data: {'name': item.productName},
      );

      // Fetch the fully hydrated item if possible to get joined names
      final hydratedItem =
          await repo.getItemById(createdItem.id!) ?? createdItem;
      _syncLookupCache(hydratedItem);

      // Instantly add it to the state at the beginning
      state = state.copyWith(
        items: [hydratedItem, ...state.items],
        totalItemsCount: (state.totalItemsCount ?? 0) + 1,
        isSaving: false,
        error: null,
      );

      // Sync in background without blocking
      loadItems();

      return true;
    } on ValidationException catch (e) {
      AppLogger.error(
        'Validation error creating item',
        error: e,
        module: 'items',
      );
      state = state.copyWith(error: e.userMessage, isSaving: false);
      return false;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        AppLogger.warning(
          'API conflict creating item',
          error: e,
          module: 'items',
        );
        final message = e.message.toLowerCase();
        if (message.contains('sku')) {
          state = state.copyWith(
            error: e.userMessage,
            validationErrors: {'sku': 'SKU already exists'},
            isSaving: false,
          );
        } else {
          state = state.copyWith(
            error: e.userMessage,
            validationErrors: {'itemCode': 'Code already exists'},
            isSaving: false,
          );
        }
      } else {
        state = state.copyWith(error: e.userMessage, isSaving: false);
      }
      return false;
    } on AppException catch (e) {
      AppLogger.error('Failed to create item', error: e, module: 'items');
      state = state.copyWith(error: e.userMessage, isSaving: false);
      return false;
    } catch (e) {
      AppLogger.error(
        'Unexpected error creating item',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to save item. Please try again.",
        isSaving: false,
      );
      return false;
    }
  }

  Future<bool> updateItem(Item item) async {
    try {
      // Validate first
      final errors = validateItem(item);
      if (errors.isNotEmpty) {
        AppLogger.warning(
          'Item validation failed on update',
          module: 'items',
          data: {'itemId': item.id, 'errors': errors},
        );
        state = state.copyWith(validationErrors: errors);
        return false;
      }

      // Check for duplicate item code locally (excluding current item)
      final codeExists = state.items.any(
        (i) =>
            i.id != item.id &&
            i.itemCode.toLowerCase() == item.itemCode.toLowerCase(),
      );
      if (codeExists) {
        state = state.copyWith(
          validationErrors: {
            'itemCode': 'This item code is already in use by another item.',
          },
        );
        return false;
      }

      // Check for duplicate SKU locally
      if (item.sku != null && item.sku!.isNotEmpty) {
        final skuExists = state.items.any(
          (i) =>
              i.id != item.id &&
              i.sku?.toLowerCase() == item.sku?.toLowerCase(),
        );
        if (skuExists) {
          state = state.copyWith(
            validationErrors: {
              'sku': 'This SKU is already in use by another item.',
            },
          );
          return false;
        }
      }

      AppLogger.info(
        'Updating item',
        module: 'items',
        data: {'itemId': item.id, 'name': item.productName},
      );

      state = state.copyWith(isSaving: true, validationErrors: {});
      await repo.updateItem(item);

      AppLogger.info(
        'Item updated successfully',
        module: 'items',
        data: {'itemId': item.id},
      );

      // Instantly update the item locally
      final updatedItem = await repo.getItemById(item.id!);
      if (updatedItem != null) {
        _syncLookupCache(updatedItem);
        final updatedList = state.items
            .map((i) => i.id == item.id ? updatedItem : i)
            .toList();
        state = state.copyWith(
          items: updatedList,
          isSaving: false,
          error: null,
        );
      } else {
        // Fallback to updating with the submitted payload if fetch fails
        final updatedList = state.items
            .map((i) => i.id == item.id ? item : i)
            .toList();
        state = state.copyWith(
          items: updatedList,
          isSaving: false,
          error: null,
        );
      }

      // Do a background sync without blocking
      loadItems();

      return true;
    } on ValidationException catch (e) {
      AppLogger.error(
        'Validation error updating item',
        error: e,
        module: 'items',
      );
      state = state.copyWith(error: e.userMessage, isSaving: false);
      return false;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        AppLogger.warning(
          'API conflict updating item',
          error: e,
          module: 'items',
        );
        final message = e.message.toLowerCase();
        if (message.contains('sku')) {
          state = state.copyWith(
            error: e.userMessage,
            validationErrors: {'sku': 'SKU already exists'},
            isSaving: false,
          );
        } else {
          state = state.copyWith(
            error: e.userMessage,
            validationErrors: {'itemCode': 'Code already exists'},
            isSaving: false,
          );
        }
      } else {
        state = state.copyWith(error: e.userMessage, isSaving: false);
      }
      return false;
    } on AppException catch (e) {
      AppLogger.error('Failed to update item', error: e, module: 'items');
      state = state.copyWith(error: e.userMessage, isSaving: false);
      return false;
    } catch (e) {
      AppLogger.error(
        'Unexpected error updating item',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to update item. Please try again.",
        isSaving: false,
      );
      return false;
    }
  }

  Future<int> updateItemsBulk(
    Set<String> ids,
    Map<String, dynamic> changes,
  ) async {
    if (ids.isEmpty) return 0;

    try {
      AppLogger.info(
        'Bulk updating items',
        module: 'items',
        data: {'count': ids.length},
      );

      state = state.copyWith(isSaving: true, validationErrors: {});
      final updated = await repo.updateItemsBulk(ids, changes);

      AppLogger.info(
        'Bulk items updated successfully',
        module: 'items',
        data: {'updated': updated},
      );

      await loadItems();
      state = state.copyWith(isSaving: false, error: null);
      return updated;
    } on AppException catch (e) {
      AppLogger.error('Failed to bulk update items', error: e, module: 'items');
      state = state.copyWith(error: e.userMessage, isSaving: false);
      return 0;
    } catch (e) {
      AppLogger.error(
        'Unexpected error bulk updating items',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to update items. Please try again.",
        isSaving: false,
      );
      return 0;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      AppLogger.info('Deleting item', module: 'items', data: {'itemId': id});

      await repo.deleteItem(id);

      AppLogger.info(
        'Item deleted successfully',
        module: 'items',
        data: {'itemId': id},
      );

      await loadItems();
    } on AppException catch (e) {
      AppLogger.error(
        'Failed to delete item',
        error: e,
        module: 'items',
        data: {'itemId': id},
      );
      state = state.copyWith(error: e.userMessage);
    } catch (e) {
      AppLogger.error(
        'Unexpected error deleting item',
        error: e,
        module: 'items',
        data: {'itemId': id},
      );
      state = state.copyWith(error: "Failed to delete item. Please try again.");
    }
  }

  Future<List<Unit>> syncUnits(List<Unit> units) async {
    try {
      debugPrint('🎯 Controller: Starting syncUnits...');
      final results = await _lookupsService.syncUnits(units);
      debugPrint(
        '🎯 Controller: Sync completed, clearing cache and reloading lookup data...',
      );

      // Clear cache to force fresh data fetch
      _lookupsService.clearLookupsCache();

      await loadLookupData(force: true); // Force refresh all lookups
      return results;
    } catch (e) {
      debugPrint('❌ Controller: Failed to sync units: $e');
      state = state.copyWith(error: "Failed to sync units: $e");
      return [];
    }
  }

  Future<List<String>> checkUnitUsage(List<String> unitIds) async {
    try {
      final response = await _lookupsService.checkUnitUsage(unitIds);
      return response;
    } catch (e) {
      debugPrint('❌ Controller: Failed to check unit usage: $e');
      return [];
    }
  }

  Future<String?> checkLookupUsage(
    String lookupKey,
    Map<String, dynamic> item,
  ) async {
    final id = item['id'];
    if (id == null || id.toString().isEmpty) return null;

    try {
      final result = await _lookupsService.checkLookupUsage(
        lookupKey,
        id.toString(),
      );
      if (result['inUse'] == true) {
        final usedIn = result['usedIn'] ?? 'existing records';
        final displayName = item['name'] ?? result['name'] ?? 'this item';

        if (lookupKey == 'reorder-terms') {
          return 'The reorder term "$displayName" cannot be deleted as it is in use.';
        }

        final label = lookupKey.replaceAll('-', ' ');
        // Get singular form for the error message
        String singularLabel = label.endsWith('s')
            ? label.substring(0, label.length - 1)
            : label;
        if (singularLabel == 'storage-location')
          singularLabel = 'storage location';

        final prettyLabel = singularLabel.isNotEmpty
            ? '${singularLabel[0].toUpperCase()}${singularLabel.substring(1)}'
            : singularLabel;

        return 'You cannot delete the $prettyLabel $displayName as it is associated with $usedIn. Dissociate the $prettyLabel from all $usedIn and try again.';
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: "Failed to check usage for $lookupKey: $e");
      return 'Unable to delete because usage could not be verified.';
    }
  }

  Future<List<Map<String, dynamic>>> syncCategories(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric('Categories', () => _lookupsService.syncCategories(items));

  Future<List<Map<String, dynamic>>> syncManufacturers(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric(
    'Manufacturers',
    () => _lookupsService.syncManufacturers(items),
  );

  Future<List<Map<String, dynamic>>> syncBrands(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric('Brands', () => _lookupsService.syncBrands(items));

  Future<List<Map<String, dynamic>>> syncVendors(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric('Vendors', () => _lookupsService.syncVendors(items));

  Future<List<Map<String, dynamic>>> syncStorageLocations(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric(
    'Storage Locations',
    () => _lookupsService.syncStorageLocations(items),
  );

  Future<List<Map<String, dynamic>>> syncAccounts(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric('Accountant', () => _lookupsService.syncAccounts(items));

  Future<List<Map<String, dynamic>>> syncRacks(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric('Racks', () => _lookupsService.syncRacks(items));

  Future<List<Map<String, dynamic>>> syncReorderTerms(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric(
    'Reorder Terms',
    () => _lookupsService.syncReorderTerms(items),
  );

  Future<List<Map<String, dynamic>>> syncContents(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric('Contents', () => _lookupsService.syncContents(items));

  Future<List<Map<String, dynamic>>> syncStrengths(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric('Strengths', () => _lookupsService.syncStrengths(items));

  Future<List<Map<String, dynamic>>> syncBuyingRules(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric(
    'Buying Rules',
    () => _lookupsService.syncBuyingRules(items),
  );

  Future<List<Map<String, dynamic>>> syncDrugSchedules(
    List<Map<String, dynamic>> items,
  ) => _syncGeneric(
    'Drug Schedules',
    () => _lookupsService.syncDrugSchedules(items),
  );

  Future<List<Unit>> searchUnits(String query) async {
    final results = await _lookupsService.searchLookups('units', query);
    final mapped = results.map((u) => Unit.fromJson(u)).toList();

    // Merge new items into state if they don't exist
    final Map<String, Unit> currentMap = {for (var u in state.units) u.id: u};
    bool added = false;
    for (var u in mapped) {
      if (!currentMap.containsKey(u.id)) {
        currentMap[u.id] = u;
        added = true;
      }
    }
    if (added) {
      state = state.copyWith(units: currentMap.values.toList());
    }

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    final results = await _lookupsService.searchLookups('categories', query);
    final mapped = results
        .map((c) => {...c, 'name': c['name'] ?? 'Unknown'})
        .toList();

    // Merge new items into state if they don't exist
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var c in state.categories) c['id']: c,
    };
    bool added = false;
    for (var c in mapped) {
      if (!currentMap.containsKey(c['id'])) {
        currentMap[c['id']] = c;
        added = true;
      }
    }
    if (added) {
      state = state.copyWith(categories: currentMap.values.toList());
    }

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchManufacturers(String query) async {
    final results = await _lookupsService.searchManufacturers(query);
    final mapped = results
        .map(
          (m) => {
            ...m,
            'name': m['name'] ?? m['manufacturer_name'] ?? 'Unknown',
          },
        )
        .toList();

    // Merge new items into state if they don't exist
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var m in state.manufacturers) m['id']: m,
    };
    bool added = false;
    for (var m in mapped) {
      if (!currentMap.containsKey(m['id'])) {
        currentMap[m['id']] = m;
        added = true;
      }
    }
    if (added) {
      state = state.copyWith(manufacturers: currentMap.values.toList());
    }

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchBrands(String query) async {
    final results = await _lookupsService.searchBrands(query);
    final mapped = results
        .map((b) => {...b, 'name': b['name'] ?? b['brand_name'] ?? 'Unknown'})
        .toList();

    // Merge new items into state if they don't exist
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var b in state.brands) b['id']: b,
    };
    bool added = false;
    for (var b in mapped) {
      if (!currentMap.containsKey(b['id'])) {
        currentMap[b['id']] = b;
        added = true;
      }
    }
    if (added) {
      state = state.copyWith(brands: currentMap.values.toList());
    }

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchVendors(String query) async {
    final results = await _lookupsService.searchLookups('vendors', query);
    final mapped = results
        .map(
          (v) => {
            ...v,
            'name': v['display_name'] ?? v['vendor_name'] ?? 'Unknown',
          },
        )
        .toList();

    // Merge new items into state if they don't exist
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var v in state.vendors) v['id']: v,
    };
    bool added = false;
    for (var v in mapped) {
      if (!currentMap.containsKey(v['id'])) {
        currentMap[v['id']] = v;
        added = true;
      }
    }
    if (added) {
      state = state.copyWith(vendors: currentMap.values.toList());
    }

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchAccounts(String query) async {
    final results = await _lookupsService.searchLookups('Accountant', query);
    final mapped = results
        .map((a) => {...a, 'name': a['account_name'] ?? a['name'] ?? 'Unknown'})
        .toList();

    // Merge new items into state if they don't exist
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var a in state.accounts) a['id']: a,
    };
    bool added = false;
    for (var a in mapped) {
      if (!currentMap.containsKey(a['id'])) {
        currentMap[a['id']] = a;
        added = true;
      }
    }
    if (added) {
      state = state.copyWith(accounts: currentMap.values.toList());
    }

    return mapped;
  }

  Future<List<Item>> searchItems(String query) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final results = await _lookupsService.searchLookups('products', query);
      final mapped = results.map((i) => Item.fromJson(i)).toList();

      // Merge new items into state if they don't exist
      final Map<String, Item> currentMap = {
        for (var i in state.items)
          if (i.id != null) i.id!: i,
      };
      bool added = false;
      for (var i in mapped) {
        if (i.id != null && !currentMap.containsKey(i.id)) {
          currentMap[i.id!] = i;
          added = true;
        }
      }
      if (added) {
        state = state.copyWith(
          items: currentMap.values.toList(),
          isSearching: false,
        );
      } else {
        state = state.copyWith(isSearching: false);
      }
      return mapped;
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
      return [];
    }
  }

  Future<List<TaxRate>> searchTaxRates(String query) async {
    final results = await _lookupsService.searchLookups('tax-rates', query);
    final mapped = results.map((t) => TaxRate.fromJson(t)).toList();

    // Merge new items into state (always update with fresh search data)
    final Map<String, TaxRate> currentMap = {
      for (var t in state.taxRates) t.id: t,
    };
    for (var t in mapped) {
      currentMap[t.id] = t;
    }
    state = state.copyWith(taxRates: currentMap.values.toList());

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchPaymentTerms(String query) async {
    final results = await _lookupsService.searchLookups('payment-terms', query);
    return results; // Note: We don't have a model for payment terms yet in state as objects, they are Maps
  }

  Future<List<Map<String, dynamic>>> searchTdsRates(String query) async {
    final results = await _lookupsService.searchLookups('tds-rates', query);
    return results;
  }

  Future<List<Map<String, dynamic>>> searchPriceLists(String query) async {
    final results = await _lookupsService.searchLookups('price-lists', query);
    return results;
  }

  Future<List<Map<String, dynamic>>> searchStorageLocations(
    String query,
  ) async {
    final results = await _lookupsService.searchLookups(
      'storage-locations',
      query,
    );
    final mapped = results.map((s) {
      final name = [s['name'], s['location_name']].firstWhere(
        (val) => val != null && val.toString().trim().isNotEmpty,
        orElse: () => 'Unknown',
      );
      return {...s, 'name': name};
    }).toList();

    // Merge new items into state
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var s in state.storageLocations) s['id']: s,
    };
    for (var s in mapped) {
      currentMap[s['id']] = s;
    }
    state = state.copyWith(storageLocations: currentMap.values.toList());

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchReorderTerms(String query) async {
    final results = await _lookupsService.searchLookups('reorder-terms', query);
    final mapped = results.map((r) {
      final name = [r['name'], r['term_name']].firstWhere(
        (val) => val != null && val.toString().trim().isNotEmpty,
        orElse: () => 'Unknown',
      );
      return {...r, 'name': name};
    }).toList();

    // Merge new items into state
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var r in state.reorderTerms) r['id']: r,
    };
    for (var r in mapped) {
      currentMap[r['id']] = r;
    }
    state = state.copyWith(reorderTerms: currentMap.values.toList());

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchContents(String query) async {
    final results = await _lookupsService.searchLookups('contents', query);
    final mapped = results.map((c) {
      final name = [c['name'], c['item_content'], c['content_name']].firstWhere(
        (val) => val != null && val.toString().trim().isNotEmpty,
        orElse: () => 'Unknown',
      );
      return {...c, 'name': name};
    }).toList();

    // Merge new items into state (always update with fresh search data)
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var c in state.contents) c['id']: c,
    };
    for (var c in mapped) {
      currentMap[c['id']] = c;
    }
    state = state.copyWith(contents: currentMap.values.toList());

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchStrengths(String query) async {
    final results = await _lookupsService.searchLookups('strengths', query);
    final mapped = results.map((s) {
      final name = [s['name'], s['item_strength'], s['strength_name']]
          .firstWhere(
            (val) => val != null && val.toString().trim().isNotEmpty,
            orElse: () => 'Unknown',
          );
      return {...s, 'name': name};
    }).toList();

    // Merge new items into state (always update with fresh search data)
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var s in state.strengths) s['id']: s,
    };
    for (var s in mapped) {
      currentMap[s['id']] = s;
    }
    state = state.copyWith(strengths: currentMap.values.toList());

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchBuyingRules(String query) async {
    final results = await _lookupsService.searchLookups('buying-rules', query);
    final mapped = results.map((b) {
      final name = [b['name'], b['rule_name'], b['buying_rule']].firstWhere(
        (val) => val != null && val.toString().trim().isNotEmpty,
        orElse: () => 'Unknown',
      );
      return {...b, 'name': name};
    }).toList();

    // Merge new items into state (always update with fresh search data)
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var b in state.buyingRules) b['id']: b,
    };
    for (var b in mapped) {
      currentMap[b['id']] = b;
    }
    state = state.copyWith(buyingRules: currentMap.values.toList());

    return mapped;
  }

  Future<List<Map<String, dynamic>>> searchDrugSchedules(String query) async {
    final results = await _lookupsService.searchLookups(
      'drug-schedules',
      query,
    );
    final mapped = results.map((d) {
      final name = [d['name'], d['schedule_name'], d['shedule_name']]
          .firstWhere(
            (val) => val != null && val.toString().trim().isNotEmpty,
            orElse: () => 'Unknown',
          );
      return {...d, 'name': name};
    }).toList();

    // Merge new items into state (always update with fresh search data)
    final Map<String, Map<String, dynamic>> currentMap = {
      for (var d in state.drugSchedules) d['id']: d,
    };
    for (var d in mapped) {
      currentMap[d['id']] = d;
    }
    state = state.copyWith(drugSchedules: currentMap.values.toList());

    return mapped;
  }

  Future<List<Map<String, dynamic>>> _syncGeneric(
    String label,
    Future<List<Map<String, dynamic>>> Function() syncJob,
  ) async {
    try {
      final results = await syncJob();
      // Clear cache to force fresh data fetch
      _lookupsService.clearLookupsCache();
      // Force reload to reflect changes
      await loadLookupData(force: true);
      return results;
    } catch (e) {
      state = state.copyWith(error: "Failed to sync $label: $e");
      rethrow; // Rethrow to allow caller (like dialogs) to handle the error
    }
  }

  void clearValidationErrors() {
    state = state.copyWith(validationErrors: {});
  }

  Future<bool> updateReorderPoint(String itemId, int reorderPoint) async {
    try {
      // Find the item
      final item = state.items.firstWhere((i) => i.id == itemId);

      // Create updated item with new reorder point using copyWith
      final updatedItem = item.copyWith(reorderPoint: reorderPoint);

      // Update in repository
      await repo.updateItem(updatedItem);

      // Reload items to reflect changes
      await loadItems();

      return true;
    } catch (e) {
      AppLogger.error('Failed to update reorder point', error: e);
      state = state.copyWith(error: "Failed to update reorder point: $e");
      return false;
    }
  }

  Future<bool> updateReorderTerm(String itemId, String? reorderTermId) async {
    try {
      // Find the item
      final item = state.items.firstWhere((i) => i.id == itemId);

      // Create updated item with new reorder term using copyWith
      final updatedItem = item.copyWith(reorderTermId: reorderTermId);

      // Update in repository
      await repo.updateItem(updatedItem);

      // Reload items to reflect changes
      await loadItems();

      return true;
    } catch (e) {
      AppLogger.error('Failed to update reorder term', error: e);
      state = state.copyWith(error: "Failed to update reorder term: $e");
      return false;
    }
  }

  Future<void> updateOpeningStock(
    String itemId,
    double totalStock,
    double totalValue,
  ) async {
    try {
      state = state.copyWith(isSaving: true);
      AppLogger.info(
        'Updating opening stock',
        module: 'items',
        data: {
          'itemId': itemId,
          'totalStock': totalStock,
          'totalValue': totalValue,
        },
      );

      await repo.updateOpeningStock(itemId, totalStock, totalValue);

      AppLogger.info(
        'Opening stock updated successfully',
        module: 'items',
        data: {'itemId': itemId},
      );

      await loadItems();
      state = state.copyWith(isSaving: false, error: null);
    } catch (e) {
      AppLogger.error(
        'Failed to update opening stock',
        error: e,
        module: 'items',
        data: {'itemId': itemId},
      );
      state = state.copyWith(
        error: "Failed to update opening stock. Please try again.",
        isSaving: false,
      );
    }
  }

  Future<int> updateCompositeItemsBulk(
    Set<String> ids,
    Map<String, dynamic> changes,
  ) async {
    if (ids.isEmpty) return 0;

    try {
      debugPrint(
        'CONTROLLER: Bulk updating ${ids.length} items with changes: $changes',
      );
      AppLogger.info(
        'Bulk updating composite items',
        module: 'items',
        data: {'count': ids.length},
      );

      state = state.copyWith(isSaving: true, validationErrors: {});

      // Optimistic Update: Update local state immediately
      final currentItems = List<CompositeItem>.from(state.compositeItems);
      final updatedLocalItems = currentItems.map((item) {
        if (item.id != null && ids.contains(item.id)) {
          // Apply changes to the local item
          return item.copyWith(
            isActive: changes['is_active'] ?? item.isActive,
            isReturnable: changes['is_returnable'] ?? item.isReturnable,
            trackBinLocation:
                changes['track_bin_location'] ?? item.trackBinLocation,
            isLock: changes['is_lock'] ?? item.isLock,
            pushToEcommerce:
                changes['push_to_ecommerce'] ?? item.pushToEcommerce,
          );
        }
        return item;
      }).toList();

      state = state.copyWith(compositeItems: updatedLocalItems);

      final updated = await repo.updateCompositeItemsBulk(ids, changes);

      AppLogger.info(
        'Bulk composite items updated successfully',
        module: 'items',
        data: {'updated': updated},
      );

      // Still reload to ensure synchronization with server state
      await loadCompositeItems();
      state = state.copyWith(isSaving: false, error: null);
      return updated;
    } on AppException catch (e) {
      AppLogger.error(
        'Failed to bulk update composite items',
        error: e,
        module: 'items',
      );
      state = state.copyWith(error: e.userMessage, isSaving: false);
      return 0;
    } catch (e) {
      AppLogger.error(
        'Unexpected error bulk updating composite items',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to update composite items. Please try again.",
        isSaving: false,
      );
      return 0;
    }
  }

  Future<int> deleteCompositeItemsBulk(Set<String> ids) async {
    if (ids.isEmpty) return 0;

    try {
      AppLogger.info(
        'Bulk deleting composite items',
        module: 'items',
        data: {'count': ids.length},
      );

      state = state.copyWith(isSaving: true, validationErrors: {});
      final deleted = await repo.deleteCompositeItemsBulk(ids);

      AppLogger.info(
        'Bulk composite items deleted successfully',
        module: 'items',
        data: {'deleted': deleted},
      );

      await loadCompositeItems();
      state = state.copyWith(isSaving: false, error: null);
      return deleted;
    } on AppException catch (e) {
      AppLogger.error(
        'Failed to bulk delete composite items',
        error: e,
        module: 'items',
      );
      state = state.copyWith(error: e.userMessage, isSaving: false);
      return 0;
    } catch (e) {
      AppLogger.error(
        'Unexpected error bulk deleting composite items',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to delete items. Please try again.",
        isSaving: false,
      );
      return 0;
    }
  }

  Future<void> loadCompositeItems() async {
    try {
      AppLogger.info('Loading composite items', module: 'items');
      state = state.copyWith(isLoading: true);

      final compositeItems = await repo.getCompositeItems();

      AppLogger.info(
        'Composite items loaded successfully',
        module: 'items',
        data: {'count': compositeItems.length},
      );

      state = state.copyWith(
        compositeItems: compositeItems,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading composite items',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to load composite items. Please try again.",
        isLoading: false,
      );
    }
  }

  Future<bool> createCompositeItem(Map<String, dynamic> payload) async {
    try {
      state = state.copyWith(isSaving: true);
      AppLogger.info('Creating composite item', module: 'items');

      final success = await repo.createCompositeItem(payload);

      if (success) {
        AppLogger.info('Composite item created successfully', module: 'items');
        await loadCompositeItems();
      }

      state = state.copyWith(isSaving: false, error: null);
      return success;
    } catch (e) {
      AppLogger.error(
        'Failed to create composite item',
        error: e,
        module: 'items',
      );
      state = state.copyWith(
        error: "Failed to create composite item. Please try again.",
        isSaving: false,
      );
      return false;
    }
  }

  Future<Map<String, int>> syncOfflineItems() async {
    state = state.copyWith(isSaving: true);
    final drafts = await _syncService.getDrafts();
    final keysToRemove = <String>[];
    int successCount = 0;
    int failCount = 0;

    for (var key in drafts.keys) {
      final keyStr = key.toString();
      try {
        final draftData = drafts[key] as Map;
        final payload = Map<String, dynamic>.from(draftData['data']);

        if (keyStr.startsWith('item_')) {
          final item = Item.fromJson(payload);
          await repo.createItem(
            item,
          ); // Direct repo call to avoid double-drafting
          keysToRemove.add(keyStr);
          successCount++;
        } else if (keyStr.startsWith('composite_')) {
          final success = await repo.createCompositeItem(payload);
          if (success) {
            keysToRemove.add(keyStr);
            successCount++;
          } else {
            failCount++;
          }
        }
      } catch (e) {
        failCount++;
        AppLogger.error('Failed to sync draft $key', error: e, module: 'items');
      }
    }

    // Cleanup successful drafts
    for (var key in keysToRemove) {
      await _syncService.deleteDraft(key);
    }

    await loadItems();
    state = state.copyWith(isSaving: false);

    return {'synced': successCount, 'failed': failCount};
  }

  Map<String, String> _getUpdatedCache(Item item) {
    final Map<String, String> newCache = Map.from(state.lookupCache);

    void add(String? id, String? label) {
      if (id != null && label != null && label.isNotEmpty) {
        if (newCache[id] != label) {
          newCache[id] = label;
        }
      }
    }

    add(item.unitId, item.unitName);
    add(item.categoryId, item.categoryName);
    add(item.manufacturerId, item.manufacturerName);
    add(item.brandId, item.brandName);
    add(item.storageId, item.storageName);
    add(item.rackId, item.rackName);
    add(item.inventoryAccountId, item.inventoryAccountName);
    add(item.salesAccountId, item.salesAccountName);
    add(item.purchaseAccountId, item.purchaseAccountName);
    add(item.preferredVendorId, item.preferredVendorName);
    add(item.intraStateTaxId, item.intraStateTaxName);
    add(item.interStateTaxId, item.interStateTaxName);
    add(item.buyingRuleId, item.buyingRuleName);
    add(item.scheduleOfDrugId, item.drugScheduleName);

    if (item.compositions != null) {
      for (final comp in item.compositions!) {
        add(comp.contentId, comp.contentName);
        add(comp.strengthId, comp.strengthName);
      }
    }
    return newCache;
  }

  void _syncLookupCache(Item item) {
    final newCache = _getUpdatedCache(item);
    if (!mapEquals(newCache, state.lookupCache)) {
      state = state.copyWith(lookupCache: newCache);
    }
  }

  // =====================================
  // PRICE LISTS
  // =====================================

  Future<void> loadAllPriceLists() async {
    try {
      final priceLists = await repo.getAllPriceLists();
      state = state.copyWith(priceLists: priceLists);
    } catch (e) {
      AppLogger.error('Failed to load all price lists', error: e);
    }
  }

  Future<void> fetchAssociatedPriceLists(String productId) async {
    try {
      state = state.copyWith(isLoading: true);
      final associated = await repo.getAssociatedPriceLists(productId);
      state = state.copyWith(
        associatedPriceLists: associated,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to fetch associated price lists', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> associatePriceList({
    required String productId,
    required String priceListId,
    double? customRate,
    double? discountPercentage,
  }) async {
    try {
      state = state.copyWith(isSaving: true);
      final result = await repo.associatePriceList(
        productId: productId,
        priceListId: priceListId,
        customRate: customRate,
        discountPercentage: discountPercentage,
      );

      if (result != null) {
        // Refresh associated list
        await fetchAssociatedPriceLists(productId);
        state = state.copyWith(isSaving: false);
        return true;
      }
      state = state.copyWith(isSaving: false);
      return false;
    } catch (e) {
      AppLogger.error('Failed to associate price list', error: e);
      state = state.copyWith(
        isSaving: false,
        error: "Failed to associate price list",
      );
      return false;
    }
  }
}

final itemsControllerProvider =
    StateNotifierProvider<ItemsController, ItemsState>((ref) {
      final repository = ref.watch(itemRepositoryProvider);
      final syncService = ref.watch(syncServiceProvider.notifier);
      return ItemsController(repository, syncService);
    });
