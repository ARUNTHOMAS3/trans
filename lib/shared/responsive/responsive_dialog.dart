import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/responsive/breakpoints.dart';

class ResponsiveDialog {
  const ResponsiveDialog._();

  static BoxConstraints constraintsFor(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? 1440;
    final dialogWidth = dialogWidthForWidth(width);
    final maxHeight = (MediaQuery.maybeOf(context)?.size.height ?? 900) * 0.9;

    return BoxConstraints(
      minWidth: dialogWidth.clamp(320, dialogWidth),
      maxWidth: dialogWidth,
      maxHeight: maxHeight,
    );
  }

  static EdgeInsets insetPaddingFor(BuildContext context) {
    final width = MediaQuery.maybeOf(context)?.size.width ?? 1440;
    final horizontal = width < ZpBreakpoints.tabletMin ? 12.0 : 24.0;
    final vertical = width < ZpBreakpoints.tabletMin ? 12.0 : 24.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static Widget wrap(BuildContext context, Widget child) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: insetPaddingFor(context),
      child: ConstrainedBox(constraints: constraintsFor(context), child: child),
    );
  }
}
