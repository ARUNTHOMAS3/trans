import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsRepository(apiClient);
});

class HorizontalBalanceSheetArgs {
  final String asOfDate;
  final String basis;

  const HorizontalBalanceSheetArgs({
    required this.asOfDate,
    this.basis = 'Accrual',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HorizontalBalanceSheetArgs &&
          runtimeType == other.runtimeType &&
          asOfDate == other.asOfDate &&
          basis == other.basis;

  @override
  int get hashCode => asOfDate.hashCode ^ basis.hashCode;
}

final horizontalBalanceSheetProvider = FutureProvider.family<Map<String, dynamic>, HorizontalBalanceSheetArgs>(
  (ref, args) async {
    final repository = ref.watch(reportsRepositoryProvider);
    return await repository.getHorizontalBalanceSheet(
      args.asOfDate,
      basis: args.basis,
    );
  },
);
