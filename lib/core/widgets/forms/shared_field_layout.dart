// // FILE: lib/core/widgets/forms/shared_field_layout.dart

import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/widgets/forms/z_tooltip.dart';

class SharedFieldLayout extends StatelessWidget {
  final String? label;
  final bool required;
  final String? helper;
  final Color? labelColor;

  final Widget? customLabel;
  final String? tooltip;

  /// Prefer horizontal layout on wide screens
  final bool compact;

  /// Desired label width (used only on wide screens)
  final double labelWidth;
  final CrossAxisAlignment crossAxisAlignment;

  final double? maxWidth;
  final Widget child;

  const SharedFieldLayout({
    super.key,
    this.label,
    this.required = false,
    this.helper,
    this.labelColor,
    this.customLabel,
    this.tooltip,
    this.compact = true,
    this.labelWidth = 140,
    this.maxWidth,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor =
        labelColor ??
        (required ? const Color(0xFFE11D48) : const Color(0xFF6B7280));

    Widget buildLabel() {
      if (customLabel != null) return customLabel!;
      if (label == null) return const SizedBox.shrink();

      final baseLabel = Text.rich(
        TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: effectiveLabelColor,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: " *",
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]
              : const [],
        ),
      );

      if (tooltip == null) return baseLabel;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          baseLabel,
          const SizedBox(width: 6),
          ZTooltip(
            message: tooltip!,
            child: const Icon(
              Icons.info_outline,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      );
    }

    /// 🔑 Input column wrapper
    /// This MUST exist in both horizontal and vertical layouts
    Widget buildInput(Widget child) {
      return Padding(padding: const EdgeInsets.only(left: 12), child: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool forceVertical = constraints.maxWidth < (labelWidth + 260);

        final Widget result = (compact && !forceVertical)
            ? Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: crossAxisAlignment,
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: buildLabel(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: buildInput(child)),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLabel(),
                    const SizedBox(height: 6),
                    buildInput(child),
                    if (helper != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        helper!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
              );

        if (maxWidth != null) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: result,
          );
        }
        return result;
      },
    );
  }
}
