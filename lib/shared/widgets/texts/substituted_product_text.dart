import 'package:flutter/material.dart';

import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Renders a product name, showing its substitution when one has been applied:
/// the superseded name struck through and faded, an arc arrow, then the product
/// that replaced it.
///
/// A product can be substituted more than once, so [substitutionChain] holds the
/// full ordered chain of replacements. Only the last hop is drawn — the previous
/// name and the current one — which keeps a row the same height no matter how
/// many times the item has been swapped.
///
/// With an empty [substitutionChain] this is just a plain [Text], so it is safe
/// to use for every product cell whether or not a substitution exists.
///
/// Used by the demand pool grid and the sales order pages so a substitution
/// reads identically wherever it surfaces.
class SubstitutedProductText extends StatelessWidget {
  const SubstitutedProductText({
    super.key,
    required this.product,
    this.substitutionChain = const [],
    this.fontSize = 13.0,
    this.style,
  });

  /// The original product name.
  final String product;

  /// Replacements in the order they were applied. Empty = never substituted.
  final List<String> substitutionChain;

  final double fontSize;

  /// Style for the un-substituted case, so a call site can keep its own look
  /// (e.g. the blue link text on the sales order detail panel).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (substitutionChain.isEmpty) {
      return Text(
        product,
        style: style ??
            TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBody,
            ),
      );
    }

    const arcWidth = 11.0;
    // Half of a single text line height — used to anchor the arc at text centres.
    final halfLineH = fontSize * 0.72;
    const itemGap = 2.0;

    final allItems = [product, ...substitutionChain];
    final arcFrom = allItems[allItems.length - 2];
    final arcTo = allItems[allItems.length - 1];

    final fadedStyle = TextStyle(
      fontSize: fontSize,
      color: AppTheme.textBody,
      decoration: TextDecoration.lineThrough,
      decorationColor: AppTheme.textBody,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: arcWidth,
            child: CustomPaint(
              painter: _LeftArcArrowPainter(halfLineH: halfLineH),
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(opacity: 0.4, child: Text(arcFrom, style: fadedStyle)),
                const SizedBox(height: itemGap),
                Text(
                  arcTo,
                  style: style?.copyWith(fontWeight: FontWeight.w700) ??
                      TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftArcArrowPainter extends CustomPainter {
  const _LeftArcArrowPainter({required this.halfLineH});
  final double halfLineH;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Anchor at the vertical centre of the first and last text lines
    final startY = halfLineH;
    final endY = size.height - halfLineH;

    // "(" shape: start at right edge (touching text), bulge LEFT, end at right edge
    final path = Path()
      ..moveTo(size.width, startY)
      ..cubicTo(
        -size.width * 0.8,
        startY,
        -size.width * 0.8,
        endY,
        size.width,
        endY,
      );
    canvas.drawPath(path, paint);

    // Arrowhead pointing right toward the new item
    const ah = 3.0;
    canvas.drawLine(
        Offset(size.width, endY), Offset(size.width - ah, endY - ah), paint);
    canvas.drawLine(
        Offset(size.width, endY), Offset(size.width - ah, endY + ah), paint);
  }

  @override
  bool shouldRepaint(_LeftArcArrowPainter old) => old.halfLineH != halfLineH;
}
