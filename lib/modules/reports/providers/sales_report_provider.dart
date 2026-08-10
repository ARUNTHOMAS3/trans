import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

enum SalesReportKind {
  customer,
  item,
  salesperson,
  summary,
  profitByItem,
  channelSyncSummary,
}

class SalesReportRequest {
  final SalesReportKind kind;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> entities;
  final String? groupBy;
  final String? reportBy;
  final int refreshKey;

  const SalesReportRequest({
    required this.kind,
    required this.startDate,
    required this.endDate,
    this.entities = const <String>[],
    this.groupBy,
    this.reportBy,
    this.refreshKey = 0,
  });

  String get startDateValue => ReportFormatterCache.date('yyyy-MM-dd').format(startDate);
  String get endDateValue => ReportFormatterCache.date('yyyy-MM-dd').format(endDate);

  @override
  bool operator ==(Object other) {
    return other is SalesReportRequest &&
        other.kind == kind &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        _sameList(other.entities, entities) &&
        other.groupBy == groupBy &&
        other.reportBy == reportBy &&
        other.refreshKey == refreshKey;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        startDate,
        endDate,
        Object.hashAll(entities),
        groupBy,
        reportBy,
        refreshKey,
      );

  static bool _sameList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

final salesReportRowsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, SalesReportRequest>((ref, request) {
  final repository = ref.watch(reportsRepositoryProvider);
  switch (request.kind) {
    case SalesReportKind.customer:
      return repository.getSalesByCustomerRows(
        request.startDateValue,
        request.endDateValue,
        entities: request.entities,
      );
    case SalesReportKind.item:
      return repository.getSalesByItemRows(
        request.startDateValue,
        request.endDateValue,
        entities: request.entities,
        groupBy: request.groupBy,
      );
    case SalesReportKind.salesperson:
      return repository.getSalesBySalespersonRows(
        request.startDateValue,
        request.endDateValue,
      );
    case SalesReportKind.summary:
      return repository.getSalesSummaryRows(
        request.startDateValue,
        request.endDateValue,
        groupBy: request.groupBy,
      );
    case SalesReportKind.profitByItem:
      return repository.getProfitByItemRows(
        request.startDateValue,
        request.endDateValue,
        reportBy: request.reportBy,
      );
    case SalesReportKind.channelSyncSummary:
      return repository.getSalesChannelIntegrationsSyncSummaryRows(
        request.startDateValue,
        request.endDateValue,
      );
  }
});
