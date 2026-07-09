import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class RecurringExpenseLoadingIndicator extends StatefulWidget {
  const RecurringExpenseLoadingIndicator({
    super.key,
    this.fillAvailableSpace = false,
    this.backgroundColor,
    this.topOffsetFactor = 0.22,
    this.minTopPadding = 56,
    this.dotSize = 9,
    this.dotSpacing = 8,
  });

  final bool fillAvailableSpace;
  final Color? backgroundColor;
  final double topOffsetFactor;
  final double minTopPadding;
  final double dotSize;
  final double dotSpacing;

  @override
  State<RecurringExpenseLoadingIndicator> createState() =>
      _RecurringExpenseLoadingIndicatorState();
}

class _RecurringExpenseLoadingIndicatorState
    extends State<RecurringExpenseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 5;
  static const Color _inactiveDotColor = AppTheme.borderMid;
  static const Color _activeDotColor = AppTheme.textSecondary;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotIntensity(double phase, int index) {
    final directDistance = (phase - index).abs();
    final wrappedDistance = _dotCount - directDistance;
    final distance = math.min(directDistance, wrappedDistance);
    final normalized = (1 - distance).clamp(0.0, 1.0);
    return Curves.easeInOut.transform(normalized);
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value * _dotCount;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(_dotCount, (index) {
            final intensity = _dotIntensity(phase, index);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.dotSpacing / 2),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    _inactiveDotColor,
                    _activeDotColor,
                    intensity,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fillAvailableSpace) {
      return Center(child: _buildDots());
    }

    final viewportHeight = MediaQuery.maybeSizeOf(context)?.height;
    return ColoredBox(
      color: widget.backgroundColor ?? AppTheme.tableHeaderBg,
      child: CustomSingleChildLayout(
        delegate: _RecurringExpenseLoadingLayoutDelegate(
          viewportHeight: viewportHeight,
          topOffsetFactor: widget.topOffsetFactor,
          minTopPadding: widget.minTopPadding,
          minHeight: widget.minTopPadding + widget.dotSize,
        ),
        child: _buildDots(),
      ),
    );
  }
}

class _RecurringExpenseLoadingLayoutDelegate extends SingleChildLayoutDelegate {
  const _RecurringExpenseLoadingLayoutDelegate({
    required this.viewportHeight,
    required this.topOffsetFactor,
    required this.minTopPadding,
    required this.minHeight,
  });

  final double? viewportHeight;
  final double topOffsetFactor;
  final double minTopPadding;
  final double minHeight;

  @override
  Size getSize(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : 0.0;
    final fallbackHeight = viewportHeight != null && viewportHeight!.isFinite
        ? viewportHeight!
        : minHeight;
    final height =
        constraints.hasBoundedHeight && constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : fallbackHeight;
    return Size(width, height);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = math.max(minTopPadding, size.height * topOffsetFactor);
    return Offset((size.width - childSize.width) / 2, top);
  }

  @override
  bool shouldRelayout(_RecurringExpenseLoadingLayoutDelegate oldDelegate) {
    return oldDelegate.viewportHeight != viewportHeight ||
        oldDelegate.topOffsetFactor != topOffsetFactor ||
        oldDelegate.minTopPadding != minTopPadding ||
        oldDelegate.minHeight != minHeight;
  }
}
