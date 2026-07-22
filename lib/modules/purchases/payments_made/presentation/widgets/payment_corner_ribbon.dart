import 'dart:math' as math;
import 'package:flutter/material.dart';

class PaymentCornerRibbon extends StatelessWidget {
  final String label;
  final Color color;

  const PaymentCornerRibbon({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    const double size = 140; // Increased size from 110 to 140
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerFoldPainter(color: color),
          ),
          Positioned(
            top: 36, // Increased top
            left: -53, // Adjusted left
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 220, // Increased width
                height: 38, // Increased height
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 34, // Increased top
            left: -55, // Adjusted left
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 220, // Increased width
                height: 38, // Increased height
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness(
                            (HSLColor.fromColor(color).lightness * 0.85).clamp(
                              0.0,
                              1.0,
                            ),
                          )
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11, // Increased font size from 9 to 11
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0, // Increased letter spacing
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
                        blurRadius: 2,
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
  final Color color;
  _CornerFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0),
        )
        .toColor();

    final paint = Paint()..color = darkColor;

    // Increased the size of the corner fold as well, scaled by roughly 140/110
    final path = Path()
      ..moveTo(92, 0)
      ..lineTo(107, 0)
      ..lineTo(92, 15)
      ..close()
      ..moveTo(0, 92)
      ..lineTo(0, 107)
      ..lineTo(15, 92)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
