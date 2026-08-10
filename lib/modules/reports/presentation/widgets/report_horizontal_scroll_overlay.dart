import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// A mixin that provides horizontal scroll button state management.
/// Apply to any [State] that manages a horizontal [ScrollController].
mixin ReportHorizontalScrollMixin<T extends StatefulWidget> on State<T> {
  static const double _scrollStep = 360;

  ScrollController get horizontalScrollController;

  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _isHorizontalScrollDisposed = false;
  bool _horizontalScrollUpdateScheduled = false;

  bool get canScrollLeft => _canScrollLeft;
  bool get canScrollRight => _canScrollRight;

  void initHorizontalScrollListeners() {
    _isHorizontalScrollDisposed = false;
    horizontalScrollController.addListener(_updateHorizontalButtonState);
    _scheduleHorizontalButtonStateUpdate();
  }

  void disposeHorizontalScrollListeners() {
    _isHorizontalScrollDisposed = true;
    _horizontalScrollUpdateScheduled = false;
    horizontalScrollController.removeListener(_updateHorizontalButtonState);
  }

  void _scheduleHorizontalButtonStateUpdate() {
    if (_horizontalScrollUpdateScheduled || _isHorizontalScrollDisposed) return;
    _horizontalScrollUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _horizontalScrollUpdateScheduled = false;
      if (!mounted || _isHorizontalScrollDisposed) return;
      _updateHorizontalButtonState();
    });
  }

  void _updateHorizontalButtonState() {
    if (!mounted || _isHorizontalScrollDisposed) return;
    if (!horizontalScrollController.hasClients) return;
    final position = horizontalScrollController.position;
    final nextCanScrollLeft = position.pixels > 0.5;
    final nextCanScrollRight =
        position.pixels < position.maxScrollExtent - 0.5;
    if (_canScrollLeft == nextCanScrollLeft &&
        _canScrollRight == nextCanScrollRight) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _canScrollLeft = nextCanScrollLeft;
      _canScrollRight = nextCanScrollRight;
    });
  }

  void scrollLeft() {
    if (!mounted || _isHorizontalScrollDisposed) return;
    if (!horizontalScrollController.hasClients) return;
    final position = horizontalScrollController.position;
    final target = (position.pixels - _scrollStep)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    horizontalScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollRight() {
    if (!mounted || _isHorizontalScrollDisposed) return;
    if (!horizontalScrollController.hasClients) return;
    final position = horizontalScrollController.position;
    final target = (position.pixels + _scrollStep)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    horizontalScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

/// Wraps a horizontally scrollable table in a [Stack] and overlays
/// left/right scroll buttons. Pass [canScrollLeft] / [canScrollRight]
/// state and the corresponding callbacks.
///
/// Usage:
/// ```dart
/// ReportHorizontalScrollOverlay(
///   canScrollLeft: _canScrollLeft,
///   canScrollRight: _canScrollRight,
///   onScrollLeft: scrollLeft,
///   onScrollRight: scrollRight,
///   child: SingleChildScrollView(...),
/// )
/// ```
class ReportHorizontalScrollOverlay extends StatelessWidget {
  static const double _buttonWidth = 42;
  static const double _buttonHeight = 74;

  final bool canScrollLeft;
  final bool canScrollRight;
  final VoidCallback onScrollLeft;
  final VoidCallback onScrollRight;
  final Widget child;

  const ReportHorizontalScrollOverlay({
    super.key,
    required this.canScrollLeft,
    required this.canScrollRight,
    required this.onScrollLeft,
    required this.onScrollRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
        final buttonTop = (height / 2) - (_buttonHeight / 2);

        return Stack(
          children: [
            child,
            if (canScrollLeft || canScrollRight) ...[
              Positioned(
                left: AppTheme.space8,
                top: buttonTop > 0 ? buttonTop : AppTheme.space48,
                child: _HScrollButton(
                  icon: Icons.chevron_left,
                  enabled: canScrollLeft,
                  onPressed: onScrollLeft,
                ),
              ),
              Positioned(
                right: 0,
                top: buttonTop > 0 ? buttonTop : AppTheme.space48,
                child: _HScrollButton(
                  icon: Icons.chevron_right,
                  enabled: canScrollRight,
                  onPressed: onScrollRight,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HScrollButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _HScrollButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const buttonWidth = ReportHorizontalScrollOverlay._buttonWidth;
    const buttonHeight = ReportHorizontalScrollOverlay._buttonHeight;

    final button = Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: enabled ? 0.05 : 0.03),
        borderRadius: BorderRadius.circular(AppTheme.space4),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: AppTheme.space28,
        color: enabled ? AppTheme.textSecondary : AppTheme.textMuted,
      ),
    );

    if (!enabled) {
      return MouseRegion(cursor: SystemMouseCursors.forbidden, child: button);
    }

    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onPressed,
        hoverColor: AppTheme.bgHover,
        borderRadius: BorderRadius.circular(AppTheme.space4),
        child: button,
      ),
    );
  }
}
