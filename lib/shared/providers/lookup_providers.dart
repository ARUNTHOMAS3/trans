import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Fix: Use correct shared constants if they exist, otherwise use inline for now
// import '../../core/constants/app_constants.dart'; 

final allWarehousesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('warehouses')
      .select('id, name')
      .eq('org_id', _kDevOrgSystemId) 
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

const String _kDevOrgSystemId = '00000000-0000-0000-0000-000000000000';

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

  final priceMapByBatchNo = <String, Map<String, dynamic>>{};
  final priceMapByBatchId = <String, Map<String, dynamic>>{};

  // Preferred source: legacy batches table (if present in current DB)
  try {
    final pricingResponse = await supabase
        .from('batches')
        .select('batch, mrp, ptr')
        .eq('product_id', productId)
        .eq('is_active', true);

    if (pricingResponse.isNotEmpty) {
      for (final p in pricingResponse as List) {
        final batchNo = p['batch']?.toString().trim();
        if (batchNo != null && batchNo.isNotEmpty) {
          priceMapByBatchNo[batchNo] = Map<String, dynamic>.from(p);
        }
      }
    }
  } catch (_) {
    // Fallback source: batch_stock_layers in newer schema
    try {
      final pricingResponse = await supabase
          .from('batch_stock_layers')
          .select('batch_id, mrp, purchase_rate')
          .eq('product_id', productId);

      if (pricingResponse.isNotEmpty) {
        for (final p in pricingResponse as List) {
          final batchId = p['batch_id']?.toString();
          if (batchId != null && batchId.isNotEmpty) {
            priceMapByBatchId[batchId] = {
              'mrp': p['mrp'],
              'ptr': p['purchase_rate'],
            };
          }
        }
      }
    } catch (_) {
      // Leave price maps empty; batch selection can still proceed.
    }
  }

  final result = (response as List).map((batch) {
    final batchMap = Map<String, dynamic>.from(batch as Map);
    final bno = batchMap['batch_no']?.toString().trim();
    final batchId = batchMap['id']?.toString();

    final price = (bno != null && bno.isNotEmpty)
        ? priceMapByBatchNo[bno]
        : null;
    final fallbackPrice = (batchId != null && batchId.isNotEmpty)
        ? priceMapByBatchId[batchId]
        : null;

    return {
      ...batchMap,
      'prices': price != null
          ? [price]
          : (fallbackPrice != null ? [fallbackPrice] : []),
    };
  }).toList();

  return List<Map<String, dynamic>>.from(result);
});
