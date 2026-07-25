import 'package:flutter/material.dart';

import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Reveals the full value of a grid cell in a floating box while the pointer is
/// over it.
///
/// Grid columns are narrow, so long values (category names, pack sizes, item
/// descriptions) render ellipsised. Wrap the cell in this to let the user read
/// the whole value on hover without widening the column.
///
/// This is NOT a help tooltip — use [ZTooltip] for those. This shows the cell's
/// own value, so it renders as a plain white surface rather than a dark bubble.
///
/// Supply either a static [text] or a [controller] to follow a live field:
///
/// ```dart
/// HoverRevealText(
///   text: item.category,
///   child: Text(item.category ?? '—', overflow: TextOverflow.ellipsis),
/// )
/// ```
class HoverRevealText extends StatefulWidget {
  const HoverRevealText({
    super.key,
    required this.child,
    this.text,
    this.controller,
    this.maxWidth = 260,
  }) : assert(text == null || controller == null,
            'Provide either text or controller, not both.');

  final Widget child;

  /// Static value to reveal. Nothing is shown when null or empty.
  final String? text;

  /// Live value to reveal — the box tracks edits to the field.
  final TextEditingController? controller;

  /// Max width of the box before the value wraps onto another line.
  final double maxWidth;

  @override
  State<HoverRevealText> createState() => _HoverRevealTextState();
}

class _HoverRevealTextState extends State<HoverRevealText> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  void _show() {
    if (_entry != null || !mounted) return;

    _entry = OverlayEntry(
      // The Stack is load-bearing: an OverlayEntry's root child is laid out by
      // the overlay with tight, full-screen constraints, which would stretch the
      // box. Inside a Stack it gets loose constraints and hugs its text.
      builder: (_) => Stack(
        children: [
          Positioned(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: widget.controller != null
                    ? ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller!,
                        builder: (_, value, __) => _box(value.text),
                      )
                    : _box(widget.text),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  Widget _box(String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppTheme.textBody,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        child: widget.child,
      ),
    );
  }
}
