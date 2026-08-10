import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

enum ReportTooltipPlacement { bottom, top, right, left }

class ReportTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final double maxWidth;
  final ReportTooltipPlacement preferredPlacement;
  final bool autoPosition;

  const ReportTooltip({
    super.key,
    required this.message,
    required this.child,
    this.maxWidth = 220,
    this.preferredPlacement = ReportTooltipPlacement.bottom,
    this.autoPosition = true,
  });

  @override
  State<ReportTooltip> createState() => _ReportTooltipState();
}

class _ReportTooltipState extends State<ReportTooltip> {
  static const Duration _hoverHideDelay = Duration(milliseconds: 100);
  static const Duration _fadeDuration = Duration(milliseconds: 160);
  static const double _viewportPadding = AppTheme.space8;
  static const double _gap = AppTheme.space8;
  static const double _arrowMain = AppTheme.space6;
  static const double _arrowCross = AppTheme.space10;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _isDisposing = false;
  bool _isHoveringTarget = false;
  bool _isHoveringTooltip = false;
  bool _isShowScheduled = false;

  static TextStyle get _tooltipTextStyle => AppTheme.metaHelper.copyWith(
    color: AppTheme.backgroundColor,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    decoration: TextDecoration.none,
    decorationColor: AppTheme.transparent,
  );

  void _showTooltip() {
    if (_entry != null ||
        widget.message.trim().isEmpty ||
        !mounted ||
        _isShowScheduled) {
      return;
    }

    if (_tryInsertTooltip()) return;

    _isShowScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isShowScheduled = false;
      if (!mounted || _isDisposing || _entry != null || !_isHoveringTarget) {
        return;
      }
      _tryInsertTooltip();
    });
  }

  bool _tryInsertTooltip() {
    final entry = _createOverlayEntry();
    if (entry == null) return false;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || !mounted || _isDisposing) {
      entry.dispose();
      return false;
    }

    _entry = entry;
    overlay.insert(entry);
    return true;
  }

  Future<void> _hideTooltip() async {
    await Future.delayed(_hoverHideDelay);
    if (!mounted || _isDisposing || _isHoveringTarget || _isHoveringTooltip) {
      return;
    }
    _removeTooltip();
  }

  void _removeTooltip() {
    _isShowScheduled = false;
    final entry = _entry;
    _entry = null;
    if (entry != null) {
      if (entry.mounted) {
        entry.remove();
      }
      entry.dispose();
    }
  }

  OverlayEntry? _createOverlayEntry() {
    if (!mounted || _isDisposing) return null;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;

    if (overlayBox == null ||
        !overlayBox.hasSize ||
        targetBox == null ||
        !targetBox.hasSize) {
      return null;
    }

    final overlaySize = overlayBox.size;
    final targetTopLeft = targetBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final targetRect = targetTopLeft & targetBox.size;

    final bubbleSize = _measureTooltipBubble(
      context,
      widget.message,
      widget.maxWidth,
    );
    final placement = _resolvePlacement(targetRect, overlaySize, bubbleSize);
    final position = _resolvePosition(
      placement,
      targetRect,
      overlaySize,
      bubbleSize,
    );

    return OverlayEntry(
      builder: (context) => Positioned(
        left: position.offset.dx,
        top: position.offset.dy,
        child: MouseRegion(
          onEnter: (_) => _isHoveringTooltip = true,
          onExit: (_) {
            _isHoveringTooltip = false;
            _hideTooltip();
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: _fadeDuration,
            curve: Curves.easeOutCubic,
            builder: (context, opacity, child) {
              final slideOffset = switch (placement) {
                ReportTooltipPlacement.bottom => Offset(0, (1 - opacity) * -4),
                ReportTooltipPlacement.top => Offset(0, (1 - opacity) * 4),
                ReportTooltipPlacement.right => Offset((1 - opacity) * -4, 0),
                ReportTooltipPlacement.left => Offset((1 - opacity) * 4, 0),
              };

              return Opacity(
                opacity: opacity,
                child: Transform.translate(offset: slideOffset, child: child),
              );
            },
            child: _TooltipBubble(
              message: widget.message,
              bubbleSize: bubbleSize,
              placement: placement,
              arrowOffset: position.arrowOffset,
            ),
          ),
        ),
      ),
    );
  }

  Size _measureTooltipBubble(
    BuildContext context,
    String message,
    double maxWidth,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: message, style: _tooltipTextStyle),
      textDirection: Directionality.of(context),
      maxLines: null,
    )..layout(maxWidth: maxWidth - (AppTheme.space12 * 2));

    final horizontalPadding = AppTheme.space12 * 2;
    final verticalPadding = AppTheme.space8 * 2;
    final bubbleWidth = (textPainter.width + horizontalPadding)
        .clamp(0, maxWidth)
        .toDouble();
    final bubbleHeight = textPainter.height + verticalPadding;

    return Size(bubbleWidth, bubbleHeight);
  }

  ReportTooltipPlacement _resolvePlacement(
    Rect targetRect,
    Size overlaySize,
    Size bubbleSize,
  ) {
    if (!widget.autoPosition) {
      return widget.preferredPlacement;
    }

    final placements = <ReportTooltipPlacement>[
      widget.preferredPlacement,
      ...ReportTooltipPlacement.values.where(
        (placement) => placement != widget.preferredPlacement,
      ),
    ];

    for (final placement in placements) {
      if (_fitsPlacement(placement, targetRect, overlaySize, bubbleSize)) {
        return placement;
      }
    }

    return placements.first;
  }

  bool _fitsPlacement(
    ReportTooltipPlacement placement,
    Rect targetRect,
    Size overlaySize,
    Size bubbleSize,
  ) {
    final arrowAllowance =
        placement == ReportTooltipPlacement.top ||
            placement == ReportTooltipPlacement.bottom
        ? _arrowMain
        : _arrowCross / 2;
    final requiredHeight = bubbleSize.height + _gap + arrowAllowance;
    final requiredWidth = bubbleSize.width + _gap + arrowAllowance;

    return switch (placement) {
      ReportTooltipPlacement.bottom =>
        overlaySize.height - targetRect.bottom - _viewportPadding >=
            requiredHeight,
      ReportTooltipPlacement.top =>
        targetRect.top - _viewportPadding >= requiredHeight,
      ReportTooltipPlacement.right =>
        overlaySize.width - targetRect.right - _viewportPadding >=
            requiredWidth,
      ReportTooltipPlacement.left =>
        targetRect.left - _viewportPadding >= requiredWidth,
    };
  }

  _TooltipPosition _resolvePosition(
    ReportTooltipPlacement placement,
    Rect targetRect,
    Size overlaySize,
    Size bubbleSize,
  ) {
    double left;
    double top;
    final arrowAllowance =
        placement == ReportTooltipPlacement.top ||
            placement == ReportTooltipPlacement.bottom
        ? _arrowMain
        : _arrowCross / 2;

    switch (placement) {
      case ReportTooltipPlacement.bottom:
        left = targetRect.center.dx - (bubbleSize.width / 2);
        top = targetRect.bottom + _gap + arrowAllowance;
        break;
      case ReportTooltipPlacement.top:
        left = targetRect.center.dx - (bubbleSize.width / 2);
        top = targetRect.top - bubbleSize.height - _gap - arrowAllowance;
        break;
      case ReportTooltipPlacement.right:
        left = targetRect.right + _gap + arrowAllowance;
        top = targetRect.center.dy - (bubbleSize.height / 2);
        break;
      case ReportTooltipPlacement.left:
        left = targetRect.left - bubbleSize.width - _gap - arrowAllowance;
        top = targetRect.center.dy - (bubbleSize.height / 2);
        break;
    }

    final clampedLeft = left
        .clamp(
          _viewportPadding,
          overlaySize.width - bubbleSize.width - _viewportPadding,
        )
        .toDouble();
    final clampedTop = top
        .clamp(
          _viewportPadding,
          overlaySize.height - bubbleSize.height - _viewportPadding,
        )
        .toDouble();

    final isVertical =
        placement == ReportTooltipPlacement.top ||
        placement == ReportTooltipPlacement.bottom;
    final arrowOffset = isVertical
        ? (targetRect.center.dx - clampedLeft)
              .clamp(_arrowCross / 2, bubbleSize.width - (_arrowCross / 2))
              .toDouble()
        : (targetRect.center.dy - clampedTop)
              .clamp(_arrowCross / 2, bubbleSize.height - (_arrowCross / 2))
              .toDouble();

    return _TooltipPosition(
      offset: Offset(clampedLeft, clampedTop),
      arrowOffset: arrowOffset,
    );
  }

  @override
  void dispose() {
    _isDisposing = true;
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHoveringTarget = true;
          _showTooltip();
        },
        onExit: (_) {
          _isHoveringTarget = false;
          _hideTooltip();
        },
        child: widget.child,
      ),
    );
  }
}

class _TooltipPosition {
  final Offset offset;
  final double arrowOffset;

  const _TooltipPosition({required this.offset, required this.arrowOffset});
}

class _TooltipBubble extends StatelessWidget {
  final String message;
  final Size bubbleSize;
  final ReportTooltipPlacement placement;
  final double arrowOffset;

  const _TooltipBubble({
    required this.message,
    required this.bubbleSize,
    required this.placement,
    required this.arrowOffset,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = SizedBox(
      width: bubbleSize.width,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.textPrimary,
          borderRadius: BorderRadius.circular(AppTheme.space6),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.15),
              blurRadius: AppTheme.space10,
              offset: const Offset(0, AppTheme.space4),
            ),
          ],
        ),
        child: Text(
          message,
          style: _ReportTooltipState._tooltipTextStyle,
          textAlign: TextAlign.start,
        ),
      ),
    );

    final arrow = CustomPaint(
      size:
          placement == ReportTooltipPlacement.top ||
              placement == ReportTooltipPlacement.bottom
          ? const Size(
              _ReportTooltipState._arrowCross,
              _ReportTooltipState._arrowMain,
            )
          : const Size(
              _ReportTooltipState._arrowMain,
              _ReportTooltipState._arrowCross,
            ),
      painter: _ReportTooltipArrowPainter(placement),
    );

    final isVertical =
        placement == ReportTooltipPlacement.top ||
        placement == ReportTooltipPlacement.bottom;
    final arrowRail = SizedBox(
      width: isVertical ? bubbleSize.width : _ReportTooltipState._arrowMain,
      height: isVertical ? _ReportTooltipState._arrowMain : bubbleSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: isVertical
                ? arrowOffset - (_ReportTooltipState._arrowCross / 2)
                : 0,
            top: isVertical
                ? 0
                : arrowOffset - (_ReportTooltipState._arrowCross / 2),
            child: arrow,
          ),
        ],
      ),
    );

    return switch (placement) {
      ReportTooltipPlacement.bottom => Column(
        mainAxisSize: MainAxisSize.min,
        children: [arrowRail, bubble],
      ),
      ReportTooltipPlacement.top => Column(
        mainAxisSize: MainAxisSize.min,
        children: [bubble, arrowRail],
      ),
      ReportTooltipPlacement.right => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [arrowRail, bubble],
      ),
      ReportTooltipPlacement.left => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [bubble, arrowRail],
      ),
    };
  }
}

class _ReportTooltipArrowPainter extends CustomPainter {
  final ReportTooltipPlacement placement;

  const _ReportTooltipArrowPainter(this.placement);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;

    final path = Path();
    switch (placement) {
      case ReportTooltipPlacement.bottom:
        path
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..close();
        break;
      case ReportTooltipPlacement.top:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0)
          ..close();
        break;
      case ReportTooltipPlacement.right:
        path
          ..moveTo(0, size.height / 2)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..close();
        break;
      case ReportTooltipPlacement.left:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height)
          ..close();
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReportTooltipArrowPainter oldDelegate) {
    return oldDelegate.placement != placement;
  }
}
