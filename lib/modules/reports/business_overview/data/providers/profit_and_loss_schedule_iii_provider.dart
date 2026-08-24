import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

final profitAndLossScheduleIIIProvider = FutureProvider.family<Map<String, dynamic>, ({String startDate, String endDate})>((ref, params) async {
  try {
    final repository = ref.watch(reportsRepositoryProvider);
    return await repository.getProfitAndLossScheduleIII(
      params.startDate,
      params.endDate,
    );
  } catch (e) {
    rethrow;
  }
});
