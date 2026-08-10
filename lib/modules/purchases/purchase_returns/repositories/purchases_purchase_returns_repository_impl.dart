import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/models/purchases_purchase_returns_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/repositories/purchases_purchase_returns_repository.dart';

class PurchaseReturnsRepositoryImpl implements PurchaseReturnsRepository {
  final SupabaseClient _client;

  PurchaseReturnsRepositoryImpl([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<PurchaseReturn>> getPurchaseReturns({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    try {
      dynamic response;
      try {
        var query = _client
            .from('purchase_returns')
            .select('*, vendors(display_name, company_name), purchase_return_items(*, products(product_name, billing_name, purchase_description), purchase_return_item_batches(*))');

        if (search != null && search.trim().isNotEmpty) {
          query = query.ilike('purchase_return_number', '%${search.trim()}%');
        }

        if (status != null &&
            status.trim().isNotEmpty &&
            status.toLowerCase() != 'all') {
          query = query.eq('status', status.toLowerCase());
        }

        final from = (page - 1) * limit;
        final to = from + limit - 1;
        response = await query.order('created_at', ascending: false).range(from, to);
      } catch (_) {
        var query = _client
            .from('purchase_returns')
            .select('*, purchase_return_items(*, purchase_return_item_batches(*))');

        if (search != null && search.trim().isNotEmpty) {
          query = query.ilike('purchase_return_number', '%${search.trim()}%');
        }

        if (status != null &&
            status.trim().isNotEmpty &&
            status.toLowerCase() != 'all') {
          query = query.eq('status', status.toLowerCase());
        }

        final from = (page - 1) * limit;
        final to = from + limit - 1;
        response = await query.order('created_at', ascending: false).range(from, to);
      }

      final List<dynamic> list = response as List<dynamic>;
      final rawList = list
          .whereType<Map<String, dynamic>>()
          .map(PurchaseReturn.fromJson)
          .toList();

      return await Future.wait(rawList.map(_enrichPurchaseReturn));
    } catch (e, st) {
      AppLogger.error('Supabase fetch purchase returns error: $e',
          module: 'purchases', error: e, stackTrace: st);
      return [];
    }
  }

  @override
  Future<PurchaseReturn?> getPurchaseReturn(String id) async {
    try {
      dynamic response;
      try {
        response = await _client
            .from('purchase_returns')
            .select('*, vendors(display_name, company_name), purchase_return_items(*, products(product_name, billing_name, purchase_description), purchase_return_item_batches(*))')
            .eq('id', id)
            .maybeSingle();
      } catch (_) {
        response = await _client
            .from('purchase_returns')
            .select('*, purchase_return_items(*, purchase_return_item_batches(*))')
            .eq('id', id)
            .maybeSingle();
      }

      if (response == null) return null;
      final ret = PurchaseReturn.fromJson(response);
      return await _enrichPurchaseReturn(ret);
    } catch (e, st) {
      AppLogger.error('Supabase fetch purchase return by id error: $e',
          module: 'purchases', error: e, stackTrace: st);
      return null;
    }
  }

  Future<PurchaseReturn> _enrichPurchaseReturn(PurchaseReturn returnObj) async {
    String? vendorName = returnObj.vendorName;
    if ((vendorName == null || vendorName.trim().isEmpty) && isUuid(returnObj.vendorId)) {
      try {
        final vRes = await _client
            .from('vendors')
            .select('display_name, company_name')
            .eq('id', returnObj.vendorId!)
            .maybeSingle();
        if (vRes != null) {
          vendorName = (vRes['display_name'] ?? vRes['company_name'])?.toString();
        }
      } catch (_) {}
    }

    final enrichedItems = <PurchaseReturnItem>[];
    for (final item in returnObj.items) {
      String itemName = item.itemName;
      String? description = item.description;

      // 1. Try resolving from products table using item.itemId
      if (itemName.trim().isEmpty && isUuid(item.itemId)) {
        try {
          final pRes = await _client
              .from('products')
              .select('product_name, billing_name, purchase_description, sales_description')
              .eq('id', item.itemId!)
              .maybeSingle();
          if (pRes != null) {
            itemName = (pRes['product_name'] ?? pRes['billing_name'])?.toString() ?? '';
            if (description == null || description.trim().isEmpty) {
              description = (pRes['purchase_description'] ?? pRes['sales_description'])?.toString();
            }
          }
        } catch (_) {}
      }

      // 2. Try resolving from bill_items table using item.billItemId
      if (itemName.trim().isEmpty && isUuid(item.billItemId)) {
        try {
          final biRes = await _client
              .from('bill_items')
              .select('product_id, item_name, description, products(product_name, billing_name, purchase_description)')
              .eq('id', item.billItemId!)
              .maybeSingle();
          if (biRes != null) {
            itemName = biRes['item_name']?.toString() ?? '';
            if (itemName.isEmpty && biRes['products'] is Map) {
              final pMap = biRes['products'] as Map;
              itemName = (pMap['product_name'] ?? pMap['billing_name'])?.toString() ?? '';
              if (description == null || description.trim().isEmpty) {
                description = (pMap['purchase_description'] ?? pMap['sales_description'])?.toString();
              }
            }
            if (description == null || description.trim().isEmpty) {
              description = biRes['description']?.toString();
            }
            if (itemName.isEmpty && isUuid(biRes['product_id']?.toString())) {
              final pRes = await _client
                  .from('products')
                  .select('product_name, billing_name, purchase_description, sales_description')
                  .eq('id', biRes['product_id'].toString())
                  .maybeSingle();
              if (pRes != null) {
                itemName = (pRes['product_name'] ?? pRes['billing_name'])?.toString() ?? '';
              }
            }
          }
        } catch (_) {}
      }

      // 3. Try resolving from batch_master/batch_stock_layers using item.batches
      if (itemName.trim().isEmpty && item.batches.isNotEmpty) {
        for (final b in item.batches) {
          if (itemName.trim().isNotEmpty) break;
          if (isUuid(b.batchId)) {
            try {
              final bmRes = await _client
                  .from('batch_master')
                  .select('product_id, products(product_name, billing_name, purchase_description)')
                  .eq('id', b.batchId)
                  .maybeSingle();
              if (bmRes != null) {
                if (bmRes['products'] is Map) {
                  final pMap = bmRes['products'] as Map;
                  itemName = (pMap['product_name'] ?? pMap['billing_name'])?.toString() ?? '';
                  if (description == null || description.trim().isEmpty) {
                    description = (pMap['purchase_description'] ?? pMap['sales_description'])?.toString();
                  }
                }
                if (itemName.isEmpty && isUuid(bmRes['product_id']?.toString())) {
                  final pRes = await _client
                      .from('products')
                      .select('product_name, billing_name, purchase_description, sales_description')
                      .eq('id', bmRes['product_id'].toString())
                      .maybeSingle();
                  if (pRes != null) {
                    itemName = (pRes['product_name'] ?? pRes['billing_name'])?.toString() ?? '';
                  }
                }
              }
            } catch (_) {}
          }
        }
      }

      // 4. Ultimate fallback if itemName is still empty
      if (itemName.trim().isEmpty) {
        if (description != null && description.trim().isNotEmpty) {
          itemName = description;
        } else if (item.remarks != null && item.remarks!.trim().isNotEmpty) {
          itemName = item.remarks!;
        } else if (item.reason != null && item.reason!.trim().isNotEmpty) {
          itemName = 'Returned Item (${item.reason})';
        } else {
          itemName = 'Returned Item';
        }
      }

      enrichedItems.add(item.copyWith(
        itemName: itemName,
        description: description,
      ));
    }

    return returnObj.copyWith(
      vendorName: vendorName,
      items: enrichedItems,
    );
  }

  @override
  Future<PurchaseReturn> createPurchaseReturn(
      PurchaseReturn purchaseReturn) async {
    try {
      final headerJson = purchaseReturn.toJson();
      final headerResult = await _client
          .from('purchase_returns')
          .insert(headerJson)
          .select('*, purchase_return_items(*, purchase_return_item_batches(*))')
          .single();

      final createdHeaderId = headerResult['id'] as String;

      for (final item in purchaseReturn.items) {
        final itemJson = item.toJson();
        itemJson['purchase_return_id'] = createdHeaderId;

        try {
          final itemResult = await _client
              .from('purchase_return_items')
              .insert(itemJson)
              .select()
              .single();

          final createdItemId = itemResult['id'] as String;

          for (final batch in item.batches) {
            try {
              final batchJson = await _prepareBatchJson(
                batch,
                item,
                purchaseReturn,
                createdItemId,
              );
              await _client
                  .from('purchase_return_item_batches')
                  .insert(batchJson);
            } catch (bErr, bSt) {
              AppLogger.error(
                'Supabase insert purchase return item batch error: $bErr',
                module: 'purchases',
                error: bErr,
                stackTrace: bSt,
              );
            }
          }
        } catch (iErr, iSt) {
          AppLogger.error(
            'Supabase insert purchase return item error: $iErr',
            module: 'purchases',
            error: iErr,
            stackTrace: iSt,
          );
        }
      }

      final fullFetch = await getPurchaseReturn(createdHeaderId);
      return fullFetch ?? PurchaseReturn.fromJson(headerResult);
    } catch (e, st) {
      AppLogger.error('Supabase create purchase return error: $e',
          module: 'purchases', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<PurchaseReturn?> updatePurchaseReturn(
    String id,
    PurchaseReturn purchaseReturn,
  ) async {
    try {
      final headerJson = purchaseReturn.toJson();
      headerJson.remove('id');

      await _client
          .from('purchase_returns')
          .update(headerJson)
          .eq('id', id);

      // Delete existing line items (DB CASCADE will delete item batches)
      await _client
          .from('purchase_return_items')
          .delete()
          .eq('purchase_return_id', id);

      // Re-insert items & batches
      for (final item in purchaseReturn.items) {
        final itemJson = item.toJson();
        itemJson['purchase_return_id'] = id;

        try {
          final itemResult = await _client
              .from('purchase_return_items')
              .insert(itemJson)
              .select()
              .single();

          final createdItemId = itemResult['id'] as String;

          for (final batch in item.batches) {
            try {
              final batchJson = await _prepareBatchJson(
                batch,
                item,
                purchaseReturn,
                createdItemId,
              );
              await _client
                  .from('purchase_return_item_batches')
                  .insert(batchJson);
            } catch (bErr, bSt) {
              AppLogger.error(
                'Supabase update purchase return item batch error: $bErr',
                module: 'purchases',
                error: bErr,
                stackTrace: bSt,
              );
            }
          }
        } catch (iErr, iSt) {
          AppLogger.error(
            'Supabase update purchase return item error: $iErr',
            module: 'purchases',
            error: iErr,
            stackTrace: iSt,
          );
        }
      }

      return await getPurchaseReturn(id);
    } catch (e, st) {
      AppLogger.error('Supabase update purchase return error: $e',
          module: 'purchases', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _prepareBatchJson(
    PurchaseReturnItemBatch batch,
    PurchaseReturnItem item,
    PurchaseReturn purchaseReturn,
    String createdItemId,
  ) async {
    final batchJson = batch.toJson();
    batchJson['purchase_return_item_id'] = createdItemId;

    String? resolvedWarehouseId = isUuid(batch.warehouseId) ? batch.warehouseId : null;
    String? resolvedBatchId = isUuid(batch.batchId) ? batch.batchId : null;
    String? resolvedLayerId = isUuid(batch.layerId) ? batch.layerId : null;

    // 1. Resolve warehouse_id
    if (resolvedWarehouseId == null) {
      if (isUuid(purchaseReturn.warehouseId)) {
        resolvedWarehouseId = purchaseReturn.warehouseId;
      } else {
        try {
          final whRes = await _client
              .from('warehouses')
              .select('id')
              .limit(1)
              .maybeSingle();
          if (whRes != null && whRes['id'] != null) {
            resolvedWarehouseId = whRes['id'] as String;
          }
        } catch (_) {}
      }
    }

    // 2. Resolve batch_id
    if (resolvedBatchId == null && isUuid(item.itemId)) {
      final prodId = item.itemId!;
      final bNo = (batch.manufactureBatchNo != null && batch.manufactureBatchNo!.isNotEmpty)
          ? batch.manufactureBatchNo!
          : 'DEFAULT';
      try {
        final bmRes = await _client
            .from('batch_master')
            .select('id')
            .eq('product_id', prodId)
            .limit(1)
            .maybeSingle();
        if (bmRes != null && bmRes['id'] != null) {
          resolvedBatchId = bmRes['id'] as String;
        } else {
          final newBm = await _client
              .from('batch_master')
              .insert({
                'product_id': prodId,
                'batch_no': bNo,
                'mrp': batch.mrp ?? 0,
                'purchase_rate': batch.purchaseRate ?? 0,
                if (batch.expiryDate != null)
                  'expiry_date': batch.expiryDate!.toIso8601String().split('T').first,
                if (batch.manufactureDate != null)
                  'manufacture_date': batch.manufactureDate!.toIso8601String().split('T').first,
              })
              .select('id')
              .single();
          resolvedBatchId = newBm['id'] as String;
        }
      } catch (_) {}
    }

    // 3. Resolve layer_id
    if (resolvedLayerId == null && isUuid(resolvedBatchId) && isUuid(item.itemId)) {
      try {
        final layerRes = await _client
            .from('batch_stock_layers')
            .select('id')
            .eq('batch_id', resolvedBatchId!)
            .limit(1)
            .maybeSingle();
        if (layerRes != null && layerRes['id'] != null) {
          resolvedLayerId = layerRes['id'] as String;
        } else {
          final newLayer = await _client
              .from('batch_stock_layers')
              .insert({
                'batch_id': resolvedBatchId,
                'product_id': item.itemId,
                if (resolvedWarehouseId != null) 'warehouse_id': resolvedWarehouseId,
                'qty': batch.quantityOut,
                'mrp': batch.mrp ?? 0,
                'purchase_rate': batch.purchaseRate ?? 0,
              })
              .select('id')
              .single();
          resolvedLayerId = newLayer['id'] as String;
        }
      } catch (_) {}
    }

    String? resolvedBinId = isUuid(batch.binId) ? batch.binId : null;
    if (resolvedBinId == null && batch.binId != null && batch.binId!.trim().isNotEmpty) {
      try {
        final binRes = await _client
            .from('bin_master')
            .select('id')
            .eq('bin_code', batch.binId!.trim())
            .limit(1)
            .maybeSingle();
        if (binRes != null && binRes['id'] != null) {
          resolvedBinId = binRes['id'] as String;
        }
      } catch (_) {}
    }

    if (resolvedBatchId != null) batchJson['batch_id'] = resolvedBatchId;
    if (resolvedLayerId != null) batchJson['layer_id'] = resolvedLayerId;
    if (resolvedWarehouseId != null) batchJson['warehouse_id'] = resolvedWarehouseId;
    if (resolvedBinId != null) batchJson['bin_id'] = resolvedBinId;

    return batchJson;
  }

  @override
  Future<bool> deletePurchaseReturn(String id) async {
    try {
      await _client.from('purchase_returns').delete().eq('id', id);
      return true;
    } catch (e, st) {
      AppLogger.error('Supabase delete purchase return error: $e',
          module: 'purchases', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<String> getNextReturnNumber() async {
    try {
      final response = await _client
          .from('purchase_returns')
          .select('purchase_return_number')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['purchase_return_number'] != null) {
        final lastNum = response['purchase_return_number'] as String;
        final match = RegExp(r'(\d+)').firstMatch(lastNum);
        if (match != null) {
          final digits = match.group(1)!;
          final nextInt = int.parse(digits) + 1;
          final prefix = lastNum.substring(0, match.start);
          return '$prefix${nextInt.toString().padLeft(digits.length, '0')}';
        }
      }
      return 'PR-00001';
    } catch (e) {
      return 'PR-00001';
    }
  }
}
