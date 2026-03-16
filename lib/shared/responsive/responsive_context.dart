// lib/shared/responsive/responsive_context.dart

import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  double get w => MediaQuery.maybeOf(this)?.size.width ?? 1200;
  double get h => MediaQuery.maybeOf(this)?.size.height ?? 800;

  bool get isMobile => w < 600;
  bool get isTablet => w >= 600 && w < 1024;
  bool get isDesktop => w >= 1024;

  /// Useful for field maxWidth constraints
  double get colWidth {
    if (isMobile) return w - 40;
    if (isTablet) return (w / 2) - 48;
    return 520; // desktop fixed column width
  }
}
