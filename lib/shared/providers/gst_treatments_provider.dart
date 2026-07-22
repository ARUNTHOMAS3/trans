import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final gstTreatmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  
  // gst_treatments is a global lookup table, so no entity_id filter is required.
  final response = await supabase
      .from('gst_treatments')
      .select('id, code, label')
      .order('sort_order');
      
  return List<Map<String, dynamic>>.from(response);
});
