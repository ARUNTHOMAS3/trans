typedef PerformanceEventRecorder =
    void Function(
      String name, {
      String category,
      Duration? duration,
      Map<String, Object?> metrics,
      String? correlationId,
    });

void startBrowserPerformanceObserver(PerformanceEventRecorder record) {}
