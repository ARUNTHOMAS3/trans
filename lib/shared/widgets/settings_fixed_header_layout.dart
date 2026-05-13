import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SettingsFixedHeaderLayout extends StatelessWidget {
  const SettingsFixedHeaderLayout({
    super.key,
    required this.header,
    required this.body,
    required this.maxWidth,
    this.headerPadding = const EdgeInsets.fromLTRB(
      AppTheme.space32,
      AppTheme.space32,
      AppTheme.space32,
      AppTheme.space24,
    ),
    this.bodyPadding = const EdgeInsets.fromLTRB(
      AppTheme.space32,
      0,
      AppTheme.space32,
      AppTheme.space32,
    ),
    this.scrollController,
    this.contentAlignment = Alignment.topLeft,
    this.footer,
  });

  final Widget header;
  final Widget body;
  final double maxWidth;
  final EdgeInsets headerPadding;
  final EdgeInsets bodyPadding;
  final ScrollController? scrollController;
  final Alignment contentAlignment;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    Widget wrap(Widget child) {
      return Align(
        alignment: contentAlignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          padding: headerPadding,
          child: wrap(header),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: bodyPadding,
            child: wrap(body),
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }
}
