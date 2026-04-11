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
      .select('id, batch_no, expiry_date, unit_pack')
      .eq('product_id', productId)
      .eq('is_active', true)
      .order('expiry_date', ascending: false);

  return List<Map<String, dynamic>>.from(response as List);
});
