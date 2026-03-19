import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZTooltip extends StatefulWidget {
  final String message;
  final Widget? child;

  const ZTooltip({super.key, required this.message, this.child});

  @override
  State<ZTooltip> createState() => _ZTooltipState();
}

class _ZTooltipState extends State<ZTooltip> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovering = false;
  bool _isTooltipHovering = false;

  void _showTooltip() {
    if (_entry != null) return;

    _entry = _createOverlayEntry();
    if (_entry != null) {
      Overlay.of(context).insert(_entry!);
    }
  }

  void _hideTooltip() async {
    // Small delay to allow moving mouse from child to tooltip
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted && !_isHovering && !_isTooltipHovering) {
      _entry?.remove();
      _entry = null;
    }
  }

  OverlayEntry? _createOverlayEntry() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              // Allow it to find its own size within constraints
              width: 240,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                // Anchor to the top-right of the target
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.topLeft,
                // Offset to the right and center vertically relative to the target's top-right
                offset: const Offset(12, -4),
                child: MouseRegion(
                  onEnter: (_) => _isTooltipHovering = true,
                  onExit: (_) {
                    _isTooltipHovering = false;
                    _hideTooltip();
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Tooltip Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimary, // Slate 800
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                        // Arrow pointing left
                        Positioned(
                          left: -6,
                          top: 10,
                          child: CustomPaint(
                            size: const Size(6, 10),
                            painter: _TooltipArrowPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
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
            const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
