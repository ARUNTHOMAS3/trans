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

  if (response == null) return [];

  // Also fetch pricing from batches table
  final pricingResponse = await supabase
      .from('batches')
      .select('batch, mrp, ptr')
      .eq('product_id', productId)
      .eq('is_active', true);

  final priceMap = <String, Map<String, dynamic>>{};
  if (pricingResponse != null) {
    for (final p in pricingResponse as List) {
      final b = p['batch']?.toString().trim();
      if (b != null) {
        priceMap[b] = p;
      }
    }
  }

  final result = (response as List).map((batch) {
    final bno = batch['batch_no']?.toString().trim();
    final price = priceMap[bno];
    return {
      ...batch as Map<String, dynamic>,
      'prices': price != null ? [price] : [],
    };
  }).toList();

  return List<Map<String, dynamic>>.from(result);
});
