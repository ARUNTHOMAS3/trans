import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class VolumePricingHelpButton extends StatefulWidget {
  const VolumePricingHelpButton({super.key});

  @override
  State<VolumePricingHelpButton> createState() =>
      _VolumePricingHelpButtonState();
}

class _VolumePricingHelpButtonState extends State<VolumePricingHelpButton> {
  static const double _popoverMaxWidth = 440;
  static const double _popoverMinWidth = 300;
  static const double _popoverInset = 16;
  static const double _popoverGap = 10;
  static const double _estimatedHeight = 320;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool get _isOpen => _overlayEntry != null;

  @override
  void dispose() {
    _hidePopover();
    super.dispose();
  }

  void _togglePopover() {
    if (_isOpen) {
      _hidePopover();
    } else {
      _showPopover();
    }
  }

  void _showPopover() {
    final targetBox = context.findRenderObject();
    if (targetBox is! RenderBox) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final targetSize = targetBox.size;
    final targetPosition = targetBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.sizeOf(context);
    final spaceToRight =
        screenSize.width -
        targetPosition.dx -
        targetSize.width -
        _popoverGap -
        _popoverInset;
    final width = math.min(
      _popoverMaxWidth,
      math.max(_popoverMinWidth, spaceToRight),
    );
    final opensRight = screenSize.width >= 760;
    final dx = opensRight
        ? targetSize.width + _popoverGap
        : _popoverInset - targetPosition.dx;

    var dy = opensRight ? -184.0 : targetSize.height + _popoverGap;
    final top = targetPosition.dy + dy;
    final bottom = top + _estimatedHeight;
    if (top < _popoverInset) {
      dy += _popoverInset - top;
    } else if (bottom > screenSize.height - _popoverInset) {
      dy -= bottom - (screenSize.height - _popoverInset);
    }
    final arrowTop = (-dy + targetSize.height / 2 - 12).clamp(
      18.0,
      _estimatedHeight - 36,
    );

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _hidePopover(),
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(dx, dy),
              child: Material(
                color: Colors.transparent,
                child: _VolumePricingPopoverAnchor(
                  width: width,
                  opensRight: opensRight,
                  arrowTop: arrowTop,
                  onClose: _hidePopover,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _hidePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: ZTooltip(
        message: 'Volume pricing details.',
        child: InkWell(
          onTap: _togglePopover,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              LucideIcons.helpCircle,
              size: 15,
              color: _isOpen ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumePricingPopoverAnchor extends StatelessWidget {
  const _VolumePricingPopoverAnchor({
    required this.width,
    required this.opensRight,
    required this.arrowTop,
    required this.onClose,
  });

  final double width;
  final bool opensRight;
  final double arrowTop;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final arrow = Padding(
      padding: EdgeInsets.only(top: arrowTop),
      child: CustomPaint(
        size: const Size(12, 24),
        painter: _PopoverArrowPainter(pointsLeft: opensRight),
      ),
    );
    final popover = _VolumePricingPopover(width: width, onClose: onClose);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: opensRight ? [arrow, popover] : [popover, arrow],
    );
  }
}

class _VolumePricingPopover extends StatelessWidget {
  const _VolumePricingPopover({required this.width, required this.onClose});

  final double width;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Volume Pricing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Use Volume Pricing to configure the unit price of the item to be based on the quantity of items sold or purchased.',
                    ),
                    SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'For Example, ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                "when less than 10 items are sold or purchased, you can set each item's price at \u20B910 and when more than 10 items are sold or purchased, you can set each item's price at \u20B95. So, for 5 items, the total price will be \u20B950, while for 15 items, the total price will be \u20B975.",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    Text('Note:'),
                    SizedBox(height: 8),
                    _HelpBullet(
                      text:
                          "If you don't enter the End Quantity for the last range and the item quantity is greater than the start quantity of the last range, then the custom rate of the last range will be applied.",
                    ),
                    SizedBox(height: 8),
                    _HelpBullet(
                      text:
                          "If you don't enter a custom range, then the default item rate will be applied for that quantity range.",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpBullet extends StatelessWidget {
  const _HelpBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Text(
            '\u2022',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  const _PopoverArrowPainter({required this.pointsLeft});

  final bool pointsLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsLeft) {
      path
        ..moveTo(0, size.height / 2)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(size.width, size.height / 2)
        ..lineTo(0, 0)
        ..lineTo(0, size.height);
    }
    path.close();

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _PopoverArrowPainter oldDelegate) {
    return oldDelegate.pointsLeft != pointsLeft;
  }
}






