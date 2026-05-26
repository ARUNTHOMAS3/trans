import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that enables keyboard arrow key scrolling for its child ScrollView
class KeyboardScrollable extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  final double scrollSpeed;

  const KeyboardScrollable({
    super.key,
    required this.child,
    this.scrollController,
    this.scrollSpeed = 50.0,
  });

  @override
  State<KeyboardScrollable> createState() => _KeyboardScrollableState();
}

class _KeyboardScrollableState extends State<KeyboardScrollable> {
  late ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (!_scrollController.hasClients) return;

      final currentOffset = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final minScroll = _scrollController.position.minScrollExtent;

      double? newOffset;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        newOffset = (currentOffset + widget.scrollSpeed).clamp(minScroll, maxScroll);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        newOffset = (currentOffset - widget.scrollSpeed).clamp(minScroll, maxScroll);
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        // Scroll one page down
        final viewportHeight = _scrollController.position.viewportDimension;
        newOffset = (currentOffset + viewportHeight).clamp(minScroll, maxScroll);
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        // Scroll one page up
        final viewportHeight = _scrollController.position.viewportDimension;
        newOffset = (currentOffset - viewportHeight).clamp(minScroll, maxScroll);
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        // Scroll to top
        newOffset = minScroll;
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        // Scroll to bottom
        newOffset = maxScroll;
      }

      if (newOffset != null && newOffset != currentOffset) {
        _scrollController.animateTo(
          newOffset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Request focus when user clicks anywhere in the scrollable area
        _focusNode.requestFocus();
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        skipTraversal: true, // Don't interfere with tab navigation
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          // Only handle if it's a navigation key, otherwise let it pass through
          if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.pageDown ||
              event.logicalKey == LogicalKeyboardKey.pageUp ||
              event.logicalKey == LogicalKeyboardKey.home ||
              event.logicalKey == LogicalKeyboardKey.end) {
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
