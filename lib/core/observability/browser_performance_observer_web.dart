import 'dart:js_interop';

import 'package:web/web.dart' as web;

typedef PerformanceEventRecorder =
    void Function(
      String name, {
      String category,
      Duration? duration,
      Map<String, Object?> metrics,
      String? correlationId,
    });

web.PerformanceObserver? _observer;

void startBrowserPerformanceObserver(PerformanceEventRecorder record) {
  final supported = web.PerformanceObserver.supportedEntryTypes.toDart
      .map((entry) => entry.toDart)
      .toSet();
  final entryTypes = <String>[
    'resource',
    'longtask',
    'event',
    'layout-shift',
    'largest-contentful-paint',
    'paint',
  ].where(supported.contains).toList();
  if (entryTypes.isEmpty) return;

  final callback =
      ((
            web.PerformanceObserverEntryList entries,
            web.PerformanceObserver observer,
          ) {
            for (final entry in entries.getEntries().toDart) {
              record(
                'browser_${entry.entryType}',
                category: 'browser',
                duration: Duration(
                  microseconds: (entry.duration * 1000).round(),
                ),
                metrics: <String, Object?>{
                  'entry_name': entry.name,
                  'start_ms': entry.startTime,
                },
              );
            }
          })
          .toJS;

  _observer = web.PerformanceObserver(callback);
  _observer!.observe(
    web.PerformanceObserverInit(
      entryTypes: entryTypes.map((entry) => entry.toJS).toList().toJS,
      buffered: true,
    ),
  );
}
