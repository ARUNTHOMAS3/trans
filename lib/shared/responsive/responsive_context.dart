import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/responsive/breakpoints.dart';

extension ResponsiveContext on BuildContext {
  double get w => MediaQuery.maybeOf(this)?.size.width ?? 1440;
  double get h => MediaQuery.maybeOf(this)?.size.height ?? 900;

  DeviceSize get deviceSize => deviceSizeForWidth(w);

  bool get isCompactMobile => deviceSize == DeviceSize.compactMobile;
  bool get isMobile => isMobileWidth(w);
  bool get isTablet => deviceSize == DeviceSize.tablet;
  bool get isDesktop => isDesktopWidth(w);
  bool get isWideDesktop => deviceSize == DeviceSize.wideDesktop;

  int get formColumns => formColumnsForWidth(w);
  double get contentHorizontalPadding => horizontalPaddingForWidth(w);
  double get preferredDialogWidth => dialogWidthForWidth(w);

  double get formFieldMinWidth {
    if (isCompactMobile) return w - 32;
    if (isMobile) return w - 40;
    if (isTablet) return 280;
    if (isWideDesktop) return 320;
    return 300;
  }

  double get formFieldMaxWidth {
    if (isWideDesktop) return 520;
    if (isDesktop) return 480;
    return double.infinity;
  }
}
