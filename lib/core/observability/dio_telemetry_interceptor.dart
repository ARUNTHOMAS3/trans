import 'dart:convert';

import 'package:dio/dio.dart';

import 'performance_telemetry.dart';

class ZerpaiDioTelemetryInterceptor extends Interceptor {
  final PerformanceTelemetry _telemetry = PerformanceTelemetry.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final correlationId = _telemetry.newCorrelationId();
    options.extra['telemetry_started_at'] = DateTime.now();
    options.extra['telemetry_correlation_id'] = correlationId;
    options.headers['X-Request-ID'] = correlationId;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _recordResponse(
      response.requestOptions,
      response.statusCode,
      response.data,
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    _recordResponse(
      error.requestOptions,
      error.response?.statusCode,
      error.response?.data,
      error: true,
    );
    handler.next(error);
  }

  void _recordResponse(
    RequestOptions options,
    int? statusCode,
    Object? data, {
    bool error = false,
  }) {
    final startedAt = options.extra['telemetry_started_at'];
    final duration = startedAt is DateTime
        ? DateTime.now().difference(startedAt)
        : null;
    final bodyBytes = _encodedSize(data);
    _telemetry.record(
      'api_request',
      category: 'network',
      duration: duration,
      correlationId: options.extra['telemetry_correlation_id'] as String?,
      metrics: <String, Object?>{
        'method': options.method,
        'path': options.uri.path,
        'status_code': statusCode,
        'request_bytes': _encodedSize(options.data),
        'response_bytes': bodyBytes,
        'error': error,
      },
    );
  }

  int _encodedSize(Object? value) {
    if (value == null) return 0;
    if (value is List<int>) return value.length;
    try {
      return utf8.encode(jsonEncode(value)).length;
    } catch (_) {
      return value.toString().length;
    }
  }
}
