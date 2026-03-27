import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Standard ERP search input bar.
///
/// Usage:
/// ```dart
/// ZSearchField(
///   hintText: 'Search by name, SKU...',
///   onChanged: (query) => _onSearch(query),
///   onSubmitted: (query) => _onSearch(query),
/// )
/// ```
class ZSearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double width;
  final VoidCallback? onClear;
  final List<Widget>? trailingActions;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;

  const ZSearchField({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.width = 320,
    this.onClear,
    this.trailingActions,
    this.controller,
    this.focusNode,
    this.initialValue,
  });

  @override
  State<ZSearchField> createState() => _ZSearchFieldState();
}

class _ZSearchFieldState extends State<ZSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  bool _isFocused = false;
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ZSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownsController &&
        widget.initialValue != null &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue!;
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: 38,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isFocused ? AppTheme.primaryBlue : AppTheme.borderColor,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(
            LucideIcons.search,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              onPressed: _clear,
              icon: const Icon(LucideIcons.x, size: 14),
              color: AppTheme.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
            ),
          if (widget.trailingActions != null) ...[
            const VerticalDivider(width: 1, indent: 8, endIndent: 8),
            ...widget.trailingActions!,
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
