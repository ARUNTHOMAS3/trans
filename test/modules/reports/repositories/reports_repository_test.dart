import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late ReportsRepository repository;

  setUp(() {
    apiClient = _MockApiClient();
    repository = ReportsRepository(apiClient);
  });

  test('getAuditLogs forwards all non-empty filters to the API', () async {
    when(
      () => apiClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: <String, dynamic>{'items': <dynamic>[]},
        statusCode: 200,
        requestOptions: RequestOptions(path: 'reports/audit-logs'),
      ),
    );

    await repository.getAuditLogs(
      page: 2,
      pageSize: 50,
      search: 'manual journals',
      tables: const <String>['accounts_manual_journals', 'account_transactions'],
      actions: const <String>['UPDATE', 'DELETE'],
      requestId: 'req-123',
      source: 'api',
      fromDate: '2026-03-01',
      toDate: '2026-03-17',
      scope: 'recent',
    );

    verify(
      () => apiClient.get(
        'reports/audit-logs',
        queryParameters: <String, dynamic>{
          'page': 2,
          'pageSize': 50,
          'search': 'manual journals',
          'tables': 'accounts_manual_journals,account_transactions',
          'actions': 'UPDATE,DELETE',
          'requestId': 'req-123',
          'source': 'api',
          'fromDate': '2026-03-01',
          'toDate': '2026-03-17',
          'scope': 'recent',
        },
      ),
    ).called(1);
  });

  test('getAuditLogs omits blank optional values', () async {
    when(
      () => apiClient.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: <String, dynamic>{'items': <dynamic>[]},
        statusCode: 200,
        requestOptions: RequestOptions(path: 'reports/audit-logs'),
      ),
    );

    await repository.getAuditLogs(
      search: '   ',
      tables: const <String>[],
      actions: const <String>[],
      requestId: '  ',
      source: '',
      fromDate: '',
      toDate: '',
      scope: '',
    );

    verify(
      () => apiClient.get(
        'reports/audit-logs',
        queryParameters: <String, dynamic>{'page': 1, 'pageSize': 25},
      ),
    ).called(1);
  });
}
