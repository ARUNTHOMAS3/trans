// FILE: lib/shared/responsive/breakpoints.dart

import 'package:flutter/widgets.dart';

/// Logical breakpoints for the whole app.
/// These do NOT change any UI by themselves.
/// You will use them from ResponsiveLayout or context extensions.
class ZpBreakpoints {
  // < 600
  static const double mobileMax = 599;

  // 600 - 1023
  static const double tabletMin = 600;
  static const double tabletMax = 1023;

  // 1024 - 1439 (normal desktop / laptop)
  static const double desktopMin = 1024;
  static const double desktopMax = 1439;

  // 1440+ (very wide desktop)
  static const double largeDesktopMin = 1440;
}

enum DeviceSize { mobile, tablet, desktop, largeDesktop }

DeviceSize deviceSizeForWidth(double width) {
  if (width <= ZpBreakpoints.mobileMax) {
    return DeviceSize.mobile;
  }
  if (width <= ZpBreakpoints.tabletMax) {
    return DeviceSize.tablet;
  }
  if (width <= ZpBreakpoints.desktopMax) {
    return DeviceSize.desktop;
  }
  return DeviceSize.largeDesktop;
}

bool isMobileWidth(double width) =>
    deviceSizeForWidth(width) == DeviceSize.mobile;

bool isTabletWidth(double width) =>
    deviceSizeForWidth(width) == DeviceSize.tablet;

bool isDesktopWidth(double width) {
  final size = deviceSizeForWidth(width);
  return size == DeviceSize.desktop || size == DeviceSize.largeDesktop;
}

/// Convenience helpers using BuildContext directly.
DeviceSize deviceSizeOf(BuildContext context) {
  final width = MediaQuery.maybeOf(context)?.size.width ?? 1200;
  return deviceSizeForWidth(width);
}

bool isMobile(BuildContext context) =>
    isMobileWidth(MediaQuery.maybeOf(context)?.size.width ?? 1200);

bool isTablet(BuildContext context) =>
    isTabletWidth(MediaQuery.maybeOf(context)?.size.width ?? 1200);

bool isDesktop(BuildContext context) =>
    isDesktopWidth(MediaQuery.maybeOf(context)?.size.width ?? 1200);
