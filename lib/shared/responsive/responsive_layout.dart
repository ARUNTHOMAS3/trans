import 'package:flutter/material.dart';

/// A simple and clean responsive wrapper:
/// - desktop: >= 1024px
/// - tablet: 600–1023px
/// - mobile: < 600px
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints) desktop;
  final Widget Function(BuildContext, BoxConstraints)? tablet;
  final Widget Function(BuildContext, BoxConstraints)? mobile;

  const ResponsiveLayout({
    super.key,
    required this.desktop,
    this.tablet,
    this.mobile,
    required int maxWidth,
  });

  static bool isMobile(BuildContext context) =>
      (MediaQuery.maybeOf(context)?.size.width ?? 1200) < 600;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? 1200;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      (MediaQuery.maybeOf(context)?.size.width ?? 1200) >= 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 1024) {
          return desktop(context, constraints);
        } else if (width >= 600) {
          return (tablet ?? desktop)(context, constraints);
        } else {
          return (mobile ?? tablet ?? desktop)(context, constraints);
        }
      },
    );
  }
}
