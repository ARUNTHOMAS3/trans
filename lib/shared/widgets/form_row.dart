import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

// ─── ZerpaiFormRow ────────────────────────────────────────────────────────────
/// Standard Zerpai ERP horizontal label-left form row.
///
/// This is the **Horizontal Form Layout** (also called "label-left form" or
/// "property-sheet" layout in enterprise UX): a fixed-width label column on the
/// left (~200 px) and a flexible field column on the right, separated from
/// adjacent rows by hairline [kZerpaiFormDivider] dividers, all inside a
/// [ZerpaiFormCard] white card.
///
/// ```dart
/// ZerpaiFormCard(children: [
///   ZerpaiFormRow(label: 'Branch name', required: true,
///       child: TextFormField(...)),
///   kZerpaiFormDivider,
///   ZerpaiFormRow(label: 'Email', child: TextFormField(...)),
/// ])
/// ```
class ZerpaiFormRow extends StatelessWidget {
  final String label;
  final bool required;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget child;
  final String? tooltipMessage;

  /// Label column width. Defaults to [kZerpaiFormLabelWidth] (200 px).
  final double labelWidth;

  const ZerpaiFormRow({
    super.key,
    required this.label,
    this.required = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    required this.child,
    this.labelWidth = kZerpaiFormLabelWidth,
    this.tooltipMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: labelWidth,
            child: label.isEmpty
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            text: label,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Inter',
                              color: required
                                  ? AppTheme.errorRed
                                  : AppTheme.textBody,
                            ),
                            children: required
                                ? const [
                                    TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      if (tooltipMessage != null &&
                          tooltipMessage!.trim().isNotEmpty) ...[
                        const SizedBox(width: AppTheme.space6),
                        ZTooltip(message: tooltipMessage!.trim()),
                      ],
                    ],
                  ),
          ),
          const SizedBox(width: AppTheme.space20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── ZerpaiFormCard ───────────────────────────────────────────────────────────
/// White bordered card that wraps [ZerpaiFormRow] children.
///
/// Add [kZerpaiFormDivider] between rows manually so conditional rows still
/// work correctly:
///
/// ```dart
/// ZerpaiFormCard(children: [
///   ZerpaiFormRow(label: 'Name', required: true, child: ...),
///   kZerpaiFormDivider,
///   if (showExtra) ...[
///     ZerpaiFormRow(label: 'Extra', child: ...),
///     kZerpaiFormDivider,
///   ],
///   ZerpaiFormRow(label: 'Email', child: ...),
/// ])
/// ```
class ZerpaiFormCard extends StatelessWidget {
  final List<Widget> children;

  const ZerpaiFormCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─── Constants ────────────────────────────────────────────────────────────────

/// Standard label column width used by [ZerpaiFormRow]. 200 px.
const double kZerpaiFormLabelWidth = 200.0;

/// Hairline divider between rows in a [ZerpaiFormCard].
const Widget kZerpaiFormDivider = Divider(
  height: 1,
  indent: 0,
  endIndent: 0,
  color: AppTheme.borderLight,
);

// ─── Legacy alias ─────────────────────────────────────────────────────────────
/// Legacy name — prefer [ZerpaiFormRow] for new code.
@Deprecated('Use ZerpaiFormRow instead')
class FormRow extends ZerpaiFormRow {
  const FormRow({
    super.key,
    required super.label,
    super.required,
    required super.child,
  });
}
