import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/responsive/breakpoints.dart';
import 'package:zerpai_erp/shared/responsive/responsive_context.dart';

class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double? minItemWidth;
  final double? maxItemWidth;

  const ResponsiveForm({
    super.key,
    required this.children,
    this.spacing = 24,
    this.runSpacing = 24,
    this.minItemWidth,
    this.maxItemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveFormGrid(
      spacing: spacing,
      runSpacing: runSpacing,
      minItemWidth: minItemWidth ?? context.formFieldMinWidth,
      maxItemWidth: maxItemWidth ?? context.formFieldMaxWidth,
      children: children,
    );
  }
}

class ResponsiveFormGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minItemWidth;
  final double maxItemWidth;

  const ResponsiveFormGrid({
    super.key,
    required this.children,
    this.spacing = 24,
    this.runSpacing = 24,
    required this.minItemWidth,
    required this.maxItemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = formColumnsForWidth(availableWidth);
        final totalSpacing = spacing * (columns - 1);
        final computedWidth = (availableWidth - totalSpacing) / columns;
        final clampedWidth = computedWidth.clamp(minItemWidth, maxItemWidth);

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minItemWidth,
                maxWidth: clampedWidth.toDouble(),
              ),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class ResponsiveFormRow extends StatelessWidget {
  final Widget label;
  final Widget field;
  final double labelWidth;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveFormRow({
    super.key,
    required this.label,
    required this.field,
    this.labelWidth = 160,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked =
            constraints.maxWidth < ZpBreakpoints.compactContentWidth;

        if (isStacked) {
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              label,
              SizedBox(height: spacing * 0.5),
              field,
            ],
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            SizedBox(width: labelWidth, child: label),
            SizedBox(width: spacing),
            Expanded(child: field),
          ],
        );
      },
    );
  }
}
