import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/documents/presentation/styles/document_styles.dart';

enum DocumentTooltipDirection { top, right, bottom }

class DocumentTooltip extends StatefulWidget {
  final String message;
  final Widget? child;
  final double maxWidth;
  final DocumentTooltipDirection direction;

  const DocumentTooltip({
    super.key,
    required this.message,
    this.child,
    this.maxWidth = 220,
    this.direction = DocumentTooltipDirection.top,
  });

  @override
  State<DocumentTooltip> createState() => _DocumentTooltipState();
}

class _DocumentTooltipState extends State<DocumentTooltip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _isHovering = false;
  bool _isTooltipHovering = false;

  Alignment get _targetAnchor {
    return switch (widget.direction) {
      DocumentTooltipDirection.right => Alignment.topRight,
      DocumentTooltipDirection.bottom => Alignment.bottomCenter,
      DocumentTooltipDirection.top => Alignment.topCenter,
    };
  }

  Alignment get _followerAnchor {
    return switch (widget.direction) {
      DocumentTooltipDirection.right => Alignment.topLeft,
      DocumentTooltipDirection.bottom => Alignment.topCenter,
      DocumentTooltipDirection.top => Alignment.bottomCenter,
    };
  }

  Offset get _offset {
    return switch (widget.direction) {
      DocumentTooltipDirection.right => const Offset(12, -4),
      DocumentTooltipDirection.bottom => const Offset(0, 8),
      DocumentTooltipDirection.top => const Offset(0, -8),
    };
  }

  void _showTooltip() {
    if (_entry != null) return;

    _entry = _createOverlayEntry();
    final entry = _entry;
    if (entry != null) {
      Overlay.of(context).insert(entry);
    }
  }

  Future<void> _hideTooltip() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!mounted || _isHovering || _isTooltipHovering) return;
    _entry?.remove();
    _entry = null;
  }

  OverlayEntry? _createOverlayEntry() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: _targetAnchor,
            followerAnchor: _followerAnchor,
            offset: _offset,
            child: MouseRegion(
              onEnter: (_) => _isTooltipHovering = true,
              onExit: (_) {
                _isTooltipHovering = false;
                _hideTooltip();
              },
              child: Material(
                color: DocumentStyles.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: widget.maxWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.textPrimary,
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
                        style: DocumentStyles.tooltipText,
                      ),
                    ),
                    _DocumentTooltipArrow(direction: widget.direction),
                  ],
                ),
              ),
            ),
          ),
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
        child: widget.child ??
            const Icon(
              LucideIcons.helpCircle,
              size: 14,
              color: AppTheme.textMuted,
            ),
      ),
    );
  }
}

class _DocumentTooltipArrow extends StatelessWidget {
  final DocumentTooltipDirection direction;

  const _DocumentTooltipArrow({required this.direction});

  @override
  Widget build(BuildContext context) {
    return switch (direction) {
      DocumentTooltipDirection.right => Positioned(
          left: -6,
          top: 10,
          child: CustomPaint(
            size: const Size(6, 10),
            painter: _DocumentTooltipArrowPainter(direction),
          ),
        ),
      DocumentTooltipDirection.bottom => Positioned(
          top: -6,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(10, 6),
              painter: _DocumentTooltipArrowPainter(direction),
            ),
          ),
        ),
      DocumentTooltipDirection.top => Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(10, 6),
              painter: _DocumentTooltipArrowPainter(direction),
            ),
          ),
        ),
    };
  }
}

class _DocumentTooltipArrowPainter extends CustomPainter {
  final DocumentTooltipDirection direction;

  const _DocumentTooltipArrowPainter(this.direction);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;
    final path = Path();

    switch (direction) {
      case DocumentTooltipDirection.right:
        path
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height)
          ..close();
      case DocumentTooltipDirection.bottom:
        path
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..close();
      case DocumentTooltipDirection.top:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0)
          ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
