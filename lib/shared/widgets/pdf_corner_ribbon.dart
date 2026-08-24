// FILE: lib/shared/widgets/pdf_corner_ribbon.dart
//
// Diagonal status ribbon folded into the top-left corner of a document/PDF
// preview (e.g. "CONFIRMED", "RECEIVED", "DRAFT"). Place it at the top-left of a
// Stack inside a `ClipRect` so the fold clips to the paper corner.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class PdfCornerRibbon extends StatelessWidget {
  const PdfCornerRibbon({
    super.key,
    required this.label,
    required this.color,
    this.size = 110,
    this.showFold = true,
  });

  final String label;
  final Color color;
  final double size;

  /// When false, only the diagonal band is drawn — the darker triangular fold
  /// behind it (the "page corner" effect) is omitted. Defaults to true so the
  /// existing callers are unchanged.
  final bool showFold;

  // Every dimension below is expressed as a ratio of [size], derived from the
  // original fixed values at the 110 default (170/110, 30/110, …). At size 110
  // this reproduces the previous geometry exactly, so the ten existing callers
  // render unchanged; smaller sizes now scale the whole ribbon instead of
  // leaving an over-large band on a narrower page.
  static const double _bandWidthRatio = 170 / 110;
  static const double _bandHeightRatio = 30 / 110;
  static const double _shadowTopRatio = 24 / 110;
  static const double _shadowLeftRatio = -32 / 110;
  static const double _bandTopRatio = 22 / 110;
  static const double _bandLeftRatio = -34 / 110;
  static const double _fontRatio = 9 / 110;
  static const double _letterSpacingRatio = 1.8 / 110;

  @override
  Widget build(BuildContext context) {
    final bandWidth = size * _bandWidthRatio;
    final bandHeight = size * _bandHeightRatio;
    final scale = size / 110;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          if (showFold)
            CustomPaint(
              size: Size(size, size),
              painter: _CornerFoldPainter(color: color),
            ),
          Positioned(
            top: size * _shadowTopRatio,
            left: size * _shadowLeftRatio,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: bandWidth,
                height: bandHeight,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10 * scale,
                      offset: Offset(0, 4 * scale),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: size * _bandTopRatio,
            left: size * _bandLeftRatio,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: bandWidth,
                height: bandHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness(
                            (HSLColor.fromColor(color).lightness * 0.85)
                                .clamp(0.0, 1.0),
                          )
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.only(bottom: scale),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * _fontRatio,
                    fontWeight: FontWeight.w900,
                    letterSpacing: size * _letterSpacingRatio,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, scale),
                        blurRadius: 2 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFoldPainter extends CustomPainter {
  const _CornerFoldPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0),
        )
        .toColor();
    final paint = Paint()..color = darkColor;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerFoldPainter oldDelegate) =>
      oldDelegate.color != color;
}
