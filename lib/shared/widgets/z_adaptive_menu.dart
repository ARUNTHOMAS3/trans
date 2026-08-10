import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A utility that shows an overlay menu anchored to a [LayerLink] target,
/// automatically positioning the dropdown above or below the anchor based
/// on available viewport space.
///
/// Usage:
/// ```dart
/// ZAdaptiveMenu.show(
///   context: context,
///   link: myLayerLink,
///   width: 200,
///   onClose: () { /* cleanup */ },
///   builder: (context) => Column(...),
/// );
/// ```
class ZAdaptiveMenu {
  ZAdaptiveMenu._();

  /// Shows an adaptive overlay menu anchored to [link].
  ///
  /// Returns the [OverlayEntry] so the caller can manage its lifecycle.
  ///
  /// - [link]: The [LayerLink] attached to a [CompositedTransformTarget].
  /// - [width]: Width of the menu container (default 180).
  /// - [gap]: Vertical gap between anchor and menu (default 4).
  /// - [onClose]: Called when the backdrop is tapped.
  /// - [builder]: Builds the menu content inside the positioned container.
  /// - [borderRadius]: Border radius of the menu (default 6).
  /// - [borderColor]: Border color (default `Color(0xFFE5E7EB)`).
  static OverlayEntry show({
    required BuildContext context,
    required LayerLink link,
    required VoidCallback onClose,
    required WidgetBuilder builder,
    double width = 180,
    double? maxHeight,
    double gap = 4,
    double borderRadius = 6,
    Color borderColor = const Color(0xFFE5E7EB),
    bool alignLeft = false,
    EdgeInsetsGeometry? padding = const EdgeInsets.all(8),
  }) {
    final overlay = OverlayEntry(
      builder: (ctx) {
        return _AdaptiveMenuOverlay(
          link: link,
          width: width,
          maxHeight: maxHeight,
          gap: gap,
          borderRadius: borderRadius,
          borderColor: borderColor,
          onClose: onClose,
          builder: builder,
          alignLeft: alignLeft,
          padding: padding,
        );
      },
    );

    Overlay.of(context).insert(overlay);
    return overlay;
  }
}

class _AdaptiveMenuOverlay extends StatefulWidget {
  final LayerLink link;
  final double width;
  final double? maxHeight;
  final double gap;
  final double borderRadius;
  final Color borderColor;
  final VoidCallback onClose;
  final WidgetBuilder builder;
  final bool alignLeft;
  final EdgeInsetsGeometry? padding;

  const _AdaptiveMenuOverlay({
    required this.link,
    required this.width,
    this.maxHeight,
    required this.gap,
    required this.borderRadius,
    required this.borderColor,
    required this.onClose,
    required this.builder,
    required this.alignLeft,
    this.padding,
  });

  @override
  State<_AdaptiveMenuOverlay> createState() => _AdaptiveMenuOverlayState();
}

class _AdaptiveMenuOverlayState extends State<_AdaptiveMenuOverlay> {
  final GlobalKey _menuKey = GlobalKey();
  bool _showAbove = false;
  bool _measured = false;
  double? _computedMaxHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureAndPosition();
    });
  }

  void _measureAndPosition() {
    final menuRenderBox =
        _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (menuRenderBox == null || !menuRenderBox.hasSize) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndPosition());
      }
      return;
    }

    final menuHeight = menuRenderBox.size.height;
    final followerOffset = menuRenderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    final spaceBelow = screenHeight - followerOffset.dy - 12;
    final spaceAbove = followerOffset.dy - widget.gap - 12;

    final menuBottom = followerOffset.dy + menuHeight;
    final overflowsBelow = menuBottom > screenHeight - 12;

    bool showAbove = false;
    if (overflowsBelow && spaceAbove > spaceBelow) {
      showAbove = true;
    }

    final availSpace = (showAbove ? spaceAbove : spaceBelow).clamp(100.0, screenHeight);
    final finalMaxHeight = widget.maxHeight != null
        ? widget.maxHeight!.clamp(50.0, availSpace)
        : availSpace;

    if (mounted) {
      setState(() {
        _showAbove = showAbove;
        _computedMaxHeight = finalMaxHeight;
        _measured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                widget.onClose();
              }
            },
            child: GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        ),
        // Menu
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          targetAnchor: widget.alignLeft
              ? (_showAbove ? Alignment.topLeft : Alignment.bottomLeft)
              : (_showAbove ? Alignment.topRight : Alignment.bottomRight),
          followerAnchor: widget.alignLeft
              ? (_showAbove ? Alignment.bottomLeft : Alignment.topLeft)
              : (_showAbove ? Alignment.bottomRight : Alignment.topRight),
          offset: Offset(0, _showAbove ? -widget.gap : widget.gap),
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: _measured ? 1.0 : 0.0,
              child: Material(
                key: _menuKey,
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: _computedMaxHeight ?? widget.maxHeight ?? 320,
                  ),
                  child: Container(
                    width: widget.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: widget.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: widget.padding != null
                        ? Padding(
                            padding: widget.padding!,
                            child: widget.builder(context),
                          )
                        : widget.builder(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
