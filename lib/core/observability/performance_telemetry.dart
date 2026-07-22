import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'browser_performance_observer.dart';

/// Compile-time kill switch. Disabled builds do not attach observers or keep
/// telemetry records in memory.
class PerformanceMonitoringConfig {
  const PerformanceMonitoringConfig._();

  static const bool enabled = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: false,
  );
  static const String mode = String.fromEnvironment(
    'PERFORMANCE_MONITORING_MODE',
    defaultValue: 'production',
  );
  static const String sampleRateText = String.fromEnvironment(
    'PERFORMANCE_MONITORING_SAMPLE_RATE',
    defaultValue: '1.0',
  );

  static double get sampleRate =>
      double.tryParse(sampleRateText)?.clamp(0, 1) ?? 1.0;
}

class PerformanceTelemetryEvent {
  const PerformanceTelemetryEvent({
    required this.name,
    required this.category,
    required this.timestamp,
    this.durationMs,
    this.metrics = const <String, Object?>{},
    this.correlationId,
  });

  final String name;
  final String category;
  final DateTime timestamp;
  final double? durationMs;
  final Map<String, Object?> metrics;
  final String? correlationId;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    if (durationMs != null) 'duration_ms': durationMs,
    if (correlationId != null) 'correlation_id': correlationId,
    ...metrics,
  };
}

class PerformanceTelemetrySpan {
  PerformanceTelemetrySpan(
    this._telemetry,
    this.name,
    this.category,
    this.correlationId,
  ) : _watch = Stopwatch()..start() {
    if (PerformanceMonitoringConfig.enabled) {
      developer.Timeline.startSync(
        name,
        arguments: <String, Object?>{
          'category': category,
          if (correlationId != null) 'correlation_id': correlationId,
        },
      );
    }
  }

  final PerformanceTelemetry _telemetry;
  final String name;
  final String category;
  final String? correlationId;
  final Stopwatch _watch;
  bool _stopped = false;

  void stop([Map<String, Object?> metrics = const <String, Object?>{}]) {
    if (_stopped) return;
    _stopped = true;
    _watch.stop();
    if (PerformanceMonitoringConfig.enabled) developer.Timeline.finishSync();
    _telemetry.record(
      name,
      category: category,
      duration: _watch.elapsed,
      metrics: metrics,
      correlationId: correlationId,
    );
  }
}

class PerformanceTelemetry {
  PerformanceTelemetry._();

  static final PerformanceTelemetry instance = PerformanceTelemetry._();

  static const int _maxEvents = 2000;
  final List<PerformanceTelemetryEvent> _events = <PerformanceTelemetryEvent>[];
  final Random _random = Random();
  String? _sessionCorrelationId;
  bool _started = false;

  bool get enabled => PerformanceMonitoringConfig.enabled;
  String get sessionCorrelationId =>
      _sessionCorrelationId ??= _newCorrelationId();
  List<PerformanceTelemetryEvent> get events => List.unmodifiable(_events);

  void start() {
    if (!enabled || _started) return;
    _started = true;
    WidgetsBinding.instance.addTimingsCallback(_recordFrameTimings);
    startBrowserPerformanceObserver(record);
  }

  String newCorrelationId() => _newCorrelationId();

  PerformanceTelemetrySpan span(
    String name, {
    String category = 'custom',
    String? correlationId,
  }) => PerformanceTelemetrySpan(
    this,
    name,
    category,
    correlationId ?? sessionCorrelationId,
  );

  T measureSync<T>(
    String name,
    T Function() action, {
    String category = 'custom',
    String? correlationId,
    Map<String, Object?> Function(T value)? metrics,
  }) {
    if (!enabled) return action();
    final spanValue = span(
      name,
      category: category,
      correlationId: correlationId,
    );
    try {
      final value = action();
      spanValue.stop(metrics?.call(value) ?? const <String, Object?>{});
      return value;
    } catch (_) {
      spanValue.stop(const <String, Object?>{'error': true});
      rethrow;
    }
  }

  Future<T> measureAsync<T>(
    String name,
    Future<T> Function() action, {
    String category = 'custom',
    String? correlationId,
    Map<String, Object?> Function(T value)? metrics,
  }) async {
    if (!enabled) return action();
    final spanValue = span(
      name,
      category: category,
      correlationId: correlationId,
    );
    try {
      final value = await action();
      spanValue.stop(metrics?.call(value) ?? const <String, Object?>{});
      return value;
    } catch (_) {
      spanValue.stop(const <String, Object?>{'error': true});
      rethrow;
    }
  }

  void record(
    String name, {
    String category = 'custom',
    Duration? duration,
    Map<String, Object?> metrics = const <String, Object?>{},
    String? correlationId,
  }) {
    if (!enabled ||
        _random.nextDouble() > PerformanceMonitoringConfig.sampleRate) {
      return;
    }
    final event = PerformanceTelemetryEvent(
      name: name,
      category: category,
      timestamp: DateTime.now().toUtc(),
      durationMs: duration?.inMicroseconds.toDouble() == null
          ? null
          : duration!.inMicroseconds / 1000,
      metrics: metrics,
      correlationId: correlationId ?? sessionCorrelationId,
    );
    if (_events.length >= _maxEvents) _events.removeAt(0);
    _events.add(event);
    if (PerformanceMonitoringConfig.mode == 'console' || kDebugMode) {
      debugPrint('[telemetry] ${jsonEncode(event.toJson())}');
    }
  }

  void recordCache(String operation, String key, {bool? hit}) => record(
    'cache_$operation',
    category: 'cache',
    metrics: <String, Object?>{'key': key, if (hit != null) 'hit': hit},
  );

  void _recordFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final build = timing.buildDuration;
      final raster = timing.rasterDuration;
      final total = timing.totalSpan;
      record(
        'frame',
        category: 'frame',
        duration: total,
        metrics: <String, Object?>{
          'build_ms': build.inMicroseconds / 1000,
          'raster_ms': raster.inMicroseconds / 1000,
          'dropped': total > const Duration(milliseconds: 16),
          'long_frame': total > const Duration(milliseconds: 50),
        },
      );
    }
  }

  String exportJson() => jsonEncode(<String, Object?>{
    'session_correlation_id': sessionCorrelationId,
    'events': _events.map((event) => event.toJson()).toList(),
  });

  String exportCsv() {
    final rows = <List<String>>[
      <String>[
        'timestamp',
        'category',
        'name',
        'duration_ms',
        'correlation_id',
        'metrics',
      ],
      ..._events.map(
        (event) => <String>[
          event.timestamp.toIso8601String(),
          event.category,
          event.name,
          event.durationMs?.toString() ?? '',
          event.correlationId ?? '',
          jsonEncode(event.metrics),
        ],
      ),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  String _newCorrelationId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_random.nextInt(0x7fffffff).toRadixString(36)}';
}

class ZerpaiProviderObserver extends ProviderObserver {
  const ZerpaiProviderObserver();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    PerformanceTelemetry.instance.record(
      'provider_add',
      category: 'riverpod',
      metrics: <String, Object?>{'provider': provider.name},
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    PerformanceTelemetry.instance.record(
      'provider_update',
      category: 'riverpod',
      metrics: <String, Object?>{
        'provider': provider.name,
        'value_type': newValue.runtimeType.toString(),
      },
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    PerformanceTelemetry.instance.record(
      'provider_dispose',
      category: 'riverpod',
      metrics: <String, Object?>{'provider': provider.name},
    );
  }
}

class ZerpaiNavigatorObserver extends NavigatorObserver {
  ZerpaiNavigatorObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    PerformanceTelemetry.instance.record(
      'route_push',
      category: 'navigation',
      metrics: <String, Object?>{
        'route': route.settings.name,
        'previous_route': previousRoute?.settings.name,
      },
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    PerformanceTelemetry.instance.record(
      'route_pop',
      category: 'navigation',
      metrics: <String, Object?>{
        'route': route.settings.name,
        'previous_route': previousRoute?.settings.name,
      },
    );
  }
}
