import 'package:flutter/widgets.dart';

class ZpBreakpoints {
  const ZpBreakpoints._();

  static const double compactMobileMax = 479;
  static const double mobileMax = 599;
  static const double tabletMin = 600;
  static const double tabletMax = 1023;
  static const double desktopMin = 1024;
  static const double desktopMax = 1439;
  static const double wideDesktopMin = 1440;

  static const double compactContentWidth = 720;
  static const double comfortableContentWidth = 1120;
  static const double maxCanvasWidth = 1600;
}

enum DeviceSize { compactMobile, mobile, tablet, desktop, wideDesktop }

DeviceSize deviceSizeForWidth(double width) {
  if (width <= ZpBreakpoints.compactMobileMax) {
    return DeviceSize.compactMobile;
  }
  if (width <= ZpBreakpoints.mobileMax) {
    return DeviceSize.mobile;
  }
  if (width <= ZpBreakpoints.tabletMax) {
    return DeviceSize.tablet;
  }
  if (width <= ZpBreakpoints.desktopMax) {
    return DeviceSize.desktop;
  }
  return DeviceSize.wideDesktop;
}

DeviceSize deviceSizeOf(BuildContext context) {
  final width = MediaQuery.maybeOf(context)?.size.width ?? 1440;
  return deviceSizeForWidth(width);
}

bool isCompactMobileWidth(double width) =>
    deviceSizeForWidth(width) == DeviceSize.compactMobile;

bool isMobileWidth(double width) {
  final size = deviceSizeForWidth(width);
  return size == DeviceSize.compactMobile || size == DeviceSize.mobile;
}

bool isTabletWidth(double width) =>
    deviceSizeForWidth(width) == DeviceSize.tablet;

bool isDesktopWidth(double width) {
  final size = deviceSizeForWidth(width);
  return size == DeviceSize.desktop || size == DeviceSize.wideDesktop;
}

int formColumnsForWidth(double width) {
  if (width < ZpBreakpoints.tabletMin) return 1;
  if (width < ZpBreakpoints.desktopMin) return 2;
  if (width < ZpBreakpoints.wideDesktopMin) return 3;
  return 4;
}

double horizontalPaddingForWidth(double width) {
  if (width < ZpBreakpoints.tabletMin) return 16;
  if (width < ZpBreakpoints.desktopMin) return 20;
  if (width < ZpBreakpoints.wideDesktopMin) return 24;
  return 32;
}

double dialogWidthForWidth(double width) {
  if (width < ZpBreakpoints.tabletMin) return width - 24;
  if (width < ZpBreakpoints.desktopMin) return 640;
  if (width < ZpBreakpoints.wideDesktopMin) return 880;
  return 1040;
}
