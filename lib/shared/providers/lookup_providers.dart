import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/entity_provider.dart';

final allWarehousesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final entityId = ref.watch(entityProvider).entityId;
  if (entityId == null) return [];

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('warehouses')
      .select('id, name')
      .eq('entity_id', entityId) 
      .order('name');
  
  return List<Map<String, dynamic>>.from(response);
});

final warehouseNameProvider = Provider.family<String, String>((ref, id) {
  final warehouses = ref.watch(allWarehousesProvider).asData?.value ?? [];
  final match = warehouses.firstWhere(
    (w) => w['id'] == id,
    orElse: () => {'name': '-'},
  );
  return match['name'];
});


final batchLookupProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  productId,
) async {
  if (productId.isEmpty) return [];
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('batch_master')
      .select('*')
      .eq('product_id', productId)
      .eq('is_active', true)
      .order('expiry_date', ascending: false);

  final priceMapByBatchId = <String, Map<String, dynamic>>{};
  final balanceMapByBatchId = <String, double>{};

  try {
    final pricingResponse = await supabase
        .from('batch_stock_layers')
        .select('id, batch_id, mrp, purchase_rate, qty, reserved_qty, updated_at')
        .eq('product_id', productId)
        .order('updated_at', ascending: false);

    if (pricingResponse.isNotEmpty) {
      for (final p in pricingResponse as List) {
        final batchId = p['batch_id']?.toString().trim();
        if (batchId != null && batchId.isNotEmpty) {
          // Store first price found (latest updated_at)
          if (!priceMapByBatchId.containsKey(batchId)) {
            priceMapByBatchId[batchId] = {
              'layer_id': p['id'],
              'mrp': p['mrp'],
              'ptr': p['purchase_rate'],
            };
          }
          // Aggregate balance
          final qty = (p['qty'] as num?)?.toDouble() ?? 0.0;
          final reserved = (p['reserved_qty'] as num?)?.toDouble() ?? 0.0;
          balanceMapByBatchId[batchId] = (balanceMapByBatchId[batchId] ?? 0.0) + (qty - reserved);
        }
      }
    }
  } catch (_) {
    // Leave maps empty; batch selection can still proceed.
  }

  final result = (response as List).map((batch) {
    final batchMap = Map<String, dynamic>.from(batch as Map);
    final batchId = batchMap['id']?.toString();
    final batchNo = (batchMap['batch_no'] ?? batchMap['batchNo'] ?? batchMap['batch'])
        ?.toString()
        .trim();
    
    final fallbackPrice = (batchId != null && batchId.isNotEmpty)
        ? priceMapByBatchId[batchId]
        : null;
    
    final balance = (batchId != null && batchId.isNotEmpty)
        ? (balanceMapByBatchId[batchId] ?? 0.0)
        : 0.0;

    return {
      ...batchMap,
      'batch_no': batchNo,
      'batchNo': batchNo,
      'layer_id': fallbackPrice?['layer_id'],
      'mrp': fallbackPrice?['mrp'] ?? batchMap['mrp'],
      'ptr': fallbackPrice?['ptr'] ?? batchMap['ptr'],
      'balance': balance,
      'prices': fallbackPrice != null ? [fallbackPrice] : [],
    };
  }).toList();

  return List<Map<String, dynamic>>.from(result);
});

final binsLookupProvider =
    FutureProvider.family<List<Map<String, String>>, String?>((
  ref,
  warehouseId,
) async {
  final entityId = ref.watch(entityProvider).entityId;
  if (entityId == null && (warehouseId == null || warehouseId.isEmpty)) {
    return [];
  }

  final supabase = Supabase.instance.client;
  var query = supabase.from('bin_master').select('id, bin_code');

  if (warehouseId != null && warehouseId.isNotEmpty) {
    query = query.eq('warehouse_id', warehouseId);
  } else if (entityId != null) {
    query = query.eq('entity_id', entityId);
  }

  query = query.eq('is_active', true);

  final response = await query.order('bin_code');

  return (response as List).map((b) => <String, String>{
        'id': b['id'].toString(),
        'bin_code': b['bin_code'].toString(),
      }).toList();
});
