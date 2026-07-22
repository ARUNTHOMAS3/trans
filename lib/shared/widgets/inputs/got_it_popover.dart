import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class GotItPopover extends StatefulWidget {
  final Widget child;
  final String title;
  final Widget content;
  final double width;
  final String buttonText;
  final VoidCallback? onButtonTap;
  final double arrowOffset;

  const GotItPopover({
    super.key,
    required this.child,
    required this.title,
    required this.content,
    this.width = 460.0,
    this.buttonText = 'Got it!',
    this.onButtonTap,
    this.arrowOffset = 20.0,
  });

  @override
  State<GotItPopover> createState() => _GotItPopoverState();
}

class _GotItPopoverState extends State<GotItPopover> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _togglePopover() {
    if (_overlayEntry != null) {
      _close();
    } else {
      _show();
    }
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _show() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);

    final double screenHeight = MediaQuery.of(context).size.height;
    final double spaceBelow = screenHeight - position.dy - renderBox.size.height;
    final double spaceAbove = position.dy;

    // Estimate popover height is around 480px based on content
    final bool showBelow = spaceBelow >= 480 || spaceBelow > spaceAbove;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: showBelow ? Alignment.bottomLeft : Alignment.topLeft,
          followerAnchor: showBelow ? Alignment.topLeft : Alignment.bottomLeft,
          offset: Offset(-widget.arrowOffset, showBelow ? 8 : -8),
          child: TapRegion(
            groupId: this,
            onTapOutside: (_) => _close(),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBelow)
                    Padding(
                      padding: EdgeInsets.only(
                        left: widget.arrowOffset + (renderBox.size.width / 2) - 7,
                      ),
                      child: CustomPaint(
                        size: const Size(14, 7),
                        painter: _PopoverArrowPainter(
                          color: Colors.white,
                          borderColor: const Color(0xFFE5E7EB),
                          isUp: true,
                        ),
                      ),
                    ),
                  Container(
                    width: widget.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        widget.content,
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _close();
                            widget.onButtonTap?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            widget.buttonText,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!showBelow)
                    Padding(
                      padding: EdgeInsets.only(
                        left: widget.arrowOffset + (renderBox.size.width / 2) - 7,
                      ),
                      child: CustomPaint(
                        size: const Size(14, 7),
                        painter: _PopoverArrowPainter(
                          color: Colors.white,
                          borderColor: const Color(0xFFE5E7EB),
                          isUp: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TapRegion(
        groupId: this,
        child: GestureDetector(
          onTap: _togglePopover,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isUp;

  _PopoverArrowPainter({
    required this.color,
    required this.borderColor,
    required this.isUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    if (isUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width / 2, 0);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final mergePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (isUp) {
      canvas.drawLine(
        Offset(1, size.height),
        Offset(size.width - 1, size.height),
        mergePaint,
      );
    } else {
      canvas.drawLine(
        const Offset(1, 0),
        Offset(size.width - 1, 0),
        mergePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PopoverArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isUp != isUp;
  }
}
