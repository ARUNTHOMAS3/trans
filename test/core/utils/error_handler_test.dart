import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler.getFriendlyMessage', () {
    test('maps account_transactions schema mismatch into a friendly message', () {
      final message = ErrorHandler.getFriendlyMessage(
        Exception(
          'Failed query: insert into "account_transactions" ... contact_id ... does not exist',
        ),
      );

      expect(
        message,
        'We could not save the journal because the accounting transaction table is missing required fields. Contact support or update the database schema.',
      );
    });

    test('maps Dio 404 to not found', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/items'),
        response: Response(
          requestOptions: RequestOptions(path: '/items'),
          statusCode: 404,
          data: {'error': 'Not found'},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(ErrorHandler.getFriendlyMessage(error), 'Not found');
    });

    test('maps timeout to connection timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/items'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        ErrorHandler.getFriendlyMessage(error),
        'Connection timed out. Please check your internet.',
      );
    });
  });
}
