// lib/shared/responsive/responsive_form.dart

import 'package:flutter/material.dart';
import 'responsive_context.dart';

class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveForm({
    super.key,
    required this.children,
    this.spacing = 24,
    this.runSpacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ctx.colWidth),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
