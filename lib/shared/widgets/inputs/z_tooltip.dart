import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

enum ZTooltipDirection { right, bottom }

class ZTooltip extends StatefulWidget {
  final String message;
  final Widget? child;

  /// Max width of the tooltip bubble. Defaults to 220 for compact wrapping.
  final double maxWidth;
  final ZTooltipDirection direction;

  const ZTooltip({
    super.key,
    required this.message,
    this.child,
    this.maxWidth = 220,
    this.direction = ZTooltipDirection.right,
  });

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
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: widget.direction == ZTooltipDirection.right
                    ? Alignment.topRight
                    : Alignment.bottomCenter,
                followerAnchor: widget.direction == ZTooltipDirection.right
                    ? Alignment.topLeft
                    : Alignment.topCenter,
                offset: widget.direction == ZTooltipDirection.right
                    ? const Offset(12, -4)
                    : const Offset(0, 8),
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
                          constraints: BoxConstraints(maxWidth: widget.maxWidth),
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
                        // Arrow
                        if (widget.direction == ZTooltipDirection.right)
                          Positioned(
                            left: -6,
                            top: 10,
                            child: CustomPaint(
                              size: const Size(6, 10),
                              painter: _TooltipArrowPainter(widget.direction),
                            ),
                          )
                        else
                          Positioned(
                            top: -6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: CustomPaint(
                                size: const Size(10, 6),
                                painter: _TooltipArrowPainter(widget.direction),
                              ),
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
            const Icon(LucideIcons.helpCircle, size: 14, color: AppTheme.textMuted),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final ZTooltipDirection direction;
  _TooltipArrowPainter(this.direction);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;

    final path = Path();
    if (direction == ZTooltipDirection.right) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
