import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/responsive/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
  mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  desktop;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  wideDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wideDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final size = deviceSizeForWidth(width);

        switch (size) {
          case DeviceSize.compactMobile:
          case DeviceSize.mobile:
            return mobile(context, constraints);
          case DeviceSize.tablet:
            return (tablet ?? desktop ?? mobile)(context, constraints);
          case DeviceSize.desktop:
            return (desktop ?? tablet ?? mobile)(context, constraints);
          case DeviceSize.wideDesktop:
            return (wideDesktop ?? desktop ?? tablet ?? mobile)(
              context,
              constraints,
            );
        }
      },
    );
  }
}
