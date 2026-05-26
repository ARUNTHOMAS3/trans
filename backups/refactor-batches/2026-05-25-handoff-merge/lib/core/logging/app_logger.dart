// FILE: lib/core/logging/app_logger.dart
// Structured logging service (PRD Section 18.2)

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized logging service with structured output
///
/// Usage:
/// ```dart
/// AppLogger.info('User logged in', data: {'userId': '123'});
/// AppLogger.error('API failed', error: e, stackTrace: st);
/// ```
class AppLogger {
  static const bool _enableVerboseDebugLogs = bool.fromEnvironment(
    'ZERPAI_VERBOSE_LOGS',
    defaultValue: false,
  );

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.info,
  );

  /// Log debug information (development only)
  static void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? module,
    String? orgId,
    String? userId,
  }) {
    if (!kDebugMode || !_enableVerboseDebugLogs) return;
    final context = _buildContext(module, orgId, userId, data);
    _logger.d(
      '$message${context.isNotEmpty ? ' | $context' : ''}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log informational messages
  static void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? module,
    String? orgId,
    String? userId,
  }) {
    final context = _buildContext(module, orgId, userId, data);
    _logger.i(
      '$message${context.isNotEmpty ? ' | $context' : ''}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warnings
  static void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? module,
    String? orgId,
    String? userId,
  }) {
    final context = _buildContext(module, orgId, userId, data);
    _logger.w(
      '$message${context.isNotEmpty ? ' | $context' : ''}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log errors
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? module,
    String? orgId,
    String? userId,
  }) {
    final context = _buildContext(module, orgId, userId, data);
    _logger.e(
      '$message${context.isNotEmpty ? ' | $context' : ''}',
      error: error,
      stackTrace: stackTrace,
    );
    Sentry.captureException(
      error ?? message,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('level', 'error');
        if (module != null) scope.setTag('module', module);
        if (orgId != null) scope.setTag('org_id', orgId);
        if (userId != null) scope.setTag('user_id', userId);
        if (data != null) {
          scope.setContexts('data', data);
        }
      },
    );
  }

  /// Log fatal errors (application-breaking)
  static void fatal(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? module,
    String? orgId,
    String? userId,
  }) {
    final context = _buildContext(module, orgId, userId, data);
    _logger.f(
      '$message${context.isNotEmpty ? ' | $context' : ''}',
      error: error,
      stackTrace: stackTrace,
    );
    Sentry.captureException(
      error ?? message,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('level', 'fatal');
        if (module != null) scope.setTag('module', module);
        if (orgId != null) scope.setTag('org_id', orgId);
        if (userId != null) scope.setTag('user_id', userId);
        if (data != null) {
          scope.setContexts('data', data);
        }
      },
    );
  }

  /// Build contextual information for logs
  static String _buildContext(
    String? module,
    String? orgId,
    String? userId,
    Map<String, dynamic>? data,
  ) {
    final parts = <String>[];

    if (module != null) parts.add('module=$module');
    if (orgId != null) parts.add('org=$orgId');
    if (userId != null) parts.add('user=$userId');
    if (data != null && data.isNotEmpty) {
      parts.add('data=${data.toString()}');
    }

    return parts.join(', ');
  }

  /// Log API request
  static void apiRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? body,
  }) {
    if (!kDebugMode || !_enableVerboseDebugLogs) return;
    final details = <String>[];
    if (params != null && params.isNotEmpty) {
      details.add('params=$params');
    }
    if (body != null && body.isNotEmpty) {
      details.add('body=$body');
    }

    _logger.d(
      '[API] Request: $method $endpoint${details.isNotEmpty ? ' | ${details.join(', ')}' : ''}',
    );
  }

  /// Log API response
  static void apiResponse(
    String method,
    String endpoint,
    int statusCode, {
    dynamic data,
    Duration? duration,
  }) {
    if (!kDebugMode || !_enableVerboseDebugLogs) return;
    final status = statusCode >= 200 && statusCode < 300 ? 'SUCCESS' : 'ERROR';
    final durationText = duration != null
        ? ' (${duration.inMilliseconds}ms)'
        : '';

    _logger.d(
      '[API] Response ($status): $method $endpoint → $statusCode$durationText',
    );
  }

  /// Log cache operations
  static void cache(
    String operation,
    String resource, {
    int? count,
    bool? hit,
  }) {
    if (!kDebugMode || !_enableVerboseDebugLogs) return;
    final hitText = hit != null ? (hit ? ' HIT' : ' MISS') : '';
    final details = count != null ? ' ($count items)' : '';

    _logger.d('[CACHE] $operation: $resource$hitText$details');
  }

  /// Log sync operations
  static void sync(
    String resource,
    String status, {
    int? count,
    String? direction,
  }) {
    final directionText = direction != null ? ' ($direction)' : '';
    final countText = count != null ? ' - $count items' : '';

    _logger.i('[SYNC] $status: $resource$directionText$countText');
  }

  /// Log performance metrics
  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metrics,
  }) {
    if (!kDebugMode || !_enableVerboseDebugLogs) return;
    final ms = duration.inMilliseconds;
    final metricsText = metrics != null ? ' | $metrics' : '';

    _logger.d('[PERF] $operation took ${ms}ms$metricsText');
  }
}
