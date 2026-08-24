import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

class ProfitAndLossRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String basis;
  final int refreshKey;

  const ProfitAndLossRequest({
    required this.startDate,
    required this.endDate,
    required this.basis,
    this.refreshKey = 0,
  });

  String get startDateValue => ReportFormatterCache.date('yyyy-MM-dd').format(startDate);
  String get endDateValue => ReportFormatterCache.date('yyyy-MM-dd').format(endDate);

  @override
  bool operator ==(Object other) {
    return other is ProfitAndLossRequest &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.basis == basis &&
        other.refreshKey == refreshKey;
  }

  @override
  int get hashCode => Object.hash(
        startDate,
        endDate,
        basis,
        refreshKey,
      );
}

final profitAndLossProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ProfitAndLossRequest>((ref, request) async {
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.getProfitAndLoss(
    request.startDateValue,
    request.endDateValue,
  );
});
