import 'package:flutter/widgets.dart';
import 'package:zerpai_erp/core/layout/zerpai_sidebar.dart';

class ZerpaiShellMetrics {
  final bool isSidebarCollapsed;
  final double sidebarWidth;
  final double viewportWidth;
  final double contentWidth;

  const ZerpaiShellMetrics({
    required this.isSidebarCollapsed,
    required this.sidebarWidth,
    required this.viewportWidth,
    required this.contentWidth,
  });

  bool get isTightContent => contentWidth < 960;
  bool get isVeryTightContent => contentWidth < 720;
}

class ZerpaiShellMetricsScope extends InheritedWidget {
  final ZerpaiShellMetrics metrics;

  const ZerpaiShellMetricsScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  static ZerpaiShellMetrics of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ZerpaiShellMetricsScope>();
    if (scope == null) {
      final viewportWidth = MediaQuery.maybeOf(context)?.size.width ?? 1440;
      final isCollapsed = ZerpaiSidebar.collapsedNotifier.value;
      final sidebarWidth = isCollapsed
          ? ZerpaiSidebar.collapsedWidth
          : ZerpaiSidebar.expandedWidth;
      return ZerpaiShellMetrics(
        isSidebarCollapsed: isCollapsed,
        sidebarWidth: sidebarWidth,
        viewportWidth: viewportWidth,
        contentWidth: viewportWidth - sidebarWidth,
      );
    }
    return scope.metrics;
  }

  @override
  bool updateShouldNotify(ZerpaiShellMetricsScope oldWidget) =>
      metrics != oldWidget.metrics;
}

extension ZerpaiShellMetricsContext on BuildContext {
  ZerpaiShellMetrics get shellMetrics => ZerpaiShellMetricsScope.of(this);
}
