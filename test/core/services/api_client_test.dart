import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

void main() {
  // dotenv must be loaded before ApiClient singleton is first accessed.
  setUpAll(() {
    dotenv.testLoad(
      mergeWith: {'API_BASE_URL': 'http://localhost:3001'},
    );
  });

  group('ResponseStandardizer extension', () {
    test('success returns true for 2xx status codes', () {
      for (final code in [200, 201, 204, 299]) {
        final response = Response(
          data: null,
          statusCode: code,
          requestOptions: RequestOptions(path: '/test'),
        );
        expect(response.success, isTrue, reason: 'Expected 2xx ($code) to be success');
      }
    });

    test('success returns false for non-2xx status codes', () {
      for (final code in [400, 401, 403, 404, 500]) {
        final response = Response(
          data: null,
          statusCode: code,
          requestOptions: RequestOptions(path: '/test'),
        );
        expect(response.success, isFalse, reason: 'Expected $code to not be success');
      }
    });

    test('success prefers extra["success"] flag over status code', () {
      final response = Response(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      );
      response.extra['success'] = false;

      expect(response.success, isFalse);
    });

    test('message returns null when neither extra nor data contains message', () {
      final response = Response(
        data: <String, dynamic>{},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(response.message, isNull);
    });

    test('message reads from extra["message"] first', () {
      final response = Response(
        data: <String, dynamic>{'message': 'DataMessage'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      );
      response.extra['message'] = 'ExtraMessage';

      expect(response.message, 'ExtraMessage');
    });

    test('message falls back to data["message"] when extra has none', () {
      final response = Response(
        data: <String, dynamic>{'message': 'DataMessage'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(response.message, 'DataMessage');
    });

    test('message joins List<String> with comma when value is a list', () {
      final response = Response(
        data: <String, dynamic>{'message': ['err1', 'err2']},
        statusCode: 400,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(response.message, 'err1, err2');
    });
  });

  group('ApiClient cache', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient();
      client.clearCache();
    });

    test('clearCache() removes all entries without throwing', () {
      expect(() => client.clearCache(), returnsNormally);
    });

    test('clearCache(path) scoped removal does not throw', () {
      expect(() => client.clearCache('items'), returnsNormally);
    });
  });

  group('CachedResponse', () {
    test('isExpired returns false for a freshly created entry', () {
      final cached = CachedResponse(
        data: <String, dynamic>{},
        timestamp: DateTime.now(),
        statusCode: 200,
      );

      expect(cached.isExpired, isFalse);
    });

    test('isExpired returns true for an entry older than 30 seconds', () {
      final cached = CachedResponse(
        data: <String, dynamic>{},
        timestamp: DateTime.now().subtract(const Duration(seconds: 31)),
        statusCode: 200,
      );

      expect(cached.isExpired, isTrue);
    });

    test('isExpired returns false exactly at the 30-second boundary', () {
      final cached = CachedResponse(
        data: <String, dynamic>{},
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        statusCode: 200,
      );

      // Difference is exactly 30s which is NOT > 30, so not expired
      expect(cached.isExpired, isFalse);
    });
  });
}
