import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ConsoleErrorReporter {
  static void log(
    String context, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    if (!kDebugMode) return;

    debugPrint('========== ERROR: $context ==========');

    if (details != null && details.isNotEmpty) {
      for (final entry in details.entries) {
        debugPrint('${entry.key}: ${entry.value}');
      }
    }

    if (error != null) {
      debugPrint('error: $error');
    }

    if (error is DioException) {
      _logDioException(error);
    }

    if (stackTrace != null) {
      debugPrint('stackTrace: $stackTrace');
    }

    debugPrint('====================================');
  }

  static void _logDioException(DioException error) {
    final request = error.requestOptions;
    debugPrint('dio.type: ${error.type}');
    debugPrint('dio.method: ${request.method}');
    debugPrint('dio.uri: ${request.uri}');
    debugPrint('dio.headers: ${request.headers}');
    if (request.queryParameters.isNotEmpty) {
      debugPrint('dio.query: ${request.queryParameters}');
    }
    if (request.data != null) {
      debugPrint('dio.requestBody: ${request.data}');
    }

    final response = error.response;
    if (response != null) {
      debugPrint('dio.statusCode: ${response.statusCode}');
      debugPrint('dio.responseHeaders: ${response.headers.map}');
      debugPrint('dio.responseBody: ${response.data}');
    }
  }
}
