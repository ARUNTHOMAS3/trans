import 'package:flutter/material.dart';

class ZTooltip extends StatefulWidget {
  final String message;
  final Widget? child;

  const ZTooltip({super.key, required this.message, this.child});

  @override
  State<ZTooltip> createState() => _ZTooltipState();
}

class _ZTooltipState extends State<ZTooltip> {
  OverlayEntry? _entry;
  bool _isHovering = false;
  bool _isTooltipHovering = false;
  final LayerLink _layerLink = LayerLink();

  void _showTooltip() {
    if (_entry != null) return;

    _entry = _createOverlayEntry();
    if (_entry != null) {
      Overlay.of(context).insert(_entry!);
    }
  }

  void _hideTooltip() async {
    await Future.delayed(const Duration(milliseconds: 180));

    if (!_isHovering && !_isTooltipHovering) {
      _entry?.remove();
      _entry = null;
    }
  }

  OverlayEntry? _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    return OverlayEntry(
      maintainState: true,
      builder: (context) {
        return Positioned(
          width: 260, // Slightly more than max constraints to avoid clipping
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.centerRight,
            followerAnchor: Alignment.centerLeft,
            offset: const Offset(8, 0),
            child: MouseRegion(
              onEnter: (_) {
                _isTooltipHovering = true;
              },
              onExit: (_) {
                _isTooltipHovering = false;
                _hideTooltip();
              },
              child: IgnorePointer(
                ignoring: false,
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(6, 12),
                        painter: _TooltipArrowPainter(),
                      ),
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 240),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovering = true;
          _showTooltip();
        },
        onExit: (_) {
          _isHovering = false;
          _hideTooltip();
        },
        child:
            widget.child ??
            const Icon(Icons.info_outline, size: 16, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
