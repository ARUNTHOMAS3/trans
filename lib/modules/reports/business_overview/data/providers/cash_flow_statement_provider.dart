import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

class CashFlowStatementRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String basis;
  final int refreshKey;

  const CashFlowStatementRequest({
    required this.startDate,
    required this.endDate,
    required this.basis,
    this.refreshKey = 0,
  });

  String get startDateValue => ReportFormatterCache.date('yyyy-MM-dd').format(startDate);
  String get endDateValue => ReportFormatterCache.date('yyyy-MM-dd').format(endDate);

  @override
  bool operator ==(Object other) {
    return other is CashFlowStatementRequest &&
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

final cashFlowStatementProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, CashFlowStatementRequest>((ref, request) async {
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.getCashFlowStatement(
    request.startDateValue,
    request.endDateValue,
  );
});
