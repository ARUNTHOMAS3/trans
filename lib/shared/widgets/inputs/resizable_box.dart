import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ResizableBox extends StatefulWidget {
  final Widget child;
  final double initialHeight;
  final double minHeight;
  final double? maxHeight;
  final ValueChanged<double>? onResize;

  const ResizableBox({
    super.key,
    required this.child,
    this.initialHeight = 44,
    this.minHeight = 44,
    this.maxHeight,
    this.onResize,
  });

  @override
  State<ResizableBox> createState() => _ResizableBoxState();
}

class _ResizableBoxState extends State<ResizableBox> {
  late double height;

  @override
  void initState() {
    super.initState();
    height = widget.initialHeight;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            right: 0,
            bottom: -15,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  height += details.delta.dy;
                  if (height < widget.minHeight) {
                    height = widget.minHeight;
                  }
                  if (widget.maxHeight != null && height > widget.maxHeight!) {
                    height = widget.maxHeight!;
                  }
                });
                widget.onResize?.call(height);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: Container(
                  width: 12,
                  height: 12,
                  color: Colors.transparent,
                  child: CustomPaint(painter: _ResizeHandlePainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResizeHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textMuted
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Draw two clean diagonal lines
    canvas.drawLine(
      Offset(size.width * 0.2, size.height),
      Offset(size.width, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height),
      Offset(size.width, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
