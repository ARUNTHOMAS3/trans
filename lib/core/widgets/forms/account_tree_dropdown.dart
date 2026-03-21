import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccountTreeDropdown extends StatefulWidget {
  final String? value;
  final List<AccountNode> nodes;
  final String? hint;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  final String? errorText;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const AccountTreeDropdown({
    super.key,
    required this.value,
    required this.nodes,
    this.hint,
    this.enabled = true,
    required this.onChanged,
    this.errorText,
    this.height,
    this.borderRadius,
    this.border,
  });

  @override
  State<AccountTreeDropdown> createState() => _AccountTreeDropdownState();
}

class _AccountTreeDropdownState extends State<AccountTreeDropdown> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _fieldFocus = FocusNode();

  OverlayEntry? _overlay;
  bool _isOpen = false;
  int? _hoveredIndex;
  int? _keyboardIndex;
  bool _didScrollToSelected = false;

  static const double _rowHeight = 36;
  static const double _fieldHeight = 44;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  List<_RenderNode> _flatten() {
    final list = <_RenderNode>[];
    final String query = _searchCtrl.text.toLowerCase().trim();

    for (final p in widget.nodes) {
      final bool parentMatches = p.name.toLowerCase().contains(query);
      final matchingChildren = p.children
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();

      if (query.isEmpty || parentMatches || matchingChildren.isNotEmpty) {
        list.add(_RenderNode(p, 0));
        if (query.isEmpty) {
          for (final c in p.children) {
            list.add(_RenderNode(c, 1));
          }
        } else {
          for (final c in matchingChildren) {
            list.add(_RenderNode(c, 1));
          }
        }
      }
    }
    return list;
  }

  void _scrollToSelected(List<_RenderNode> list) {
    if (widget.value == null) return;
    final index = list.indexWhere((e) => e.node.id == widget.value);
    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(index * _rowHeight);
      }
    });
  }

  List<int> _selectableIndices(List<_RenderNode> list) {
    final indices = <int>[];
    for (int i = 0; i < list.length; i++) {
      if (list[i].node.selectable) {
        indices.add(i);
      }
    }
    return indices;
  }

  void _setInitialKeyboardIndex(List<_RenderNode> list) {
    final selectable = _selectableIndices(list);
    if (selectable.isEmpty) {
      _keyboardIndex = null;
      return;
    }

    if (widget.value != null) {
      final selected = list.indexWhere((e) => e.node.id == widget.value);
      if (selected >= 0 && selectable.contains(selected)) {
        _keyboardIndex = selected;
        return;
      }
    }

    _keyboardIndex = selectable.first;
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(index * _rowHeight);
      }
    });
  }

  void _moveKeyboardSelection(List<_RenderNode> list, int delta) {
    final selectable = _selectableIndices(list);
    if (selectable.isEmpty) return;

    final current = _keyboardIndex;
    int pointer;
    if (current == null || !selectable.contains(current)) {
      pointer = delta > 0 ? 0 : selectable.length - 1;
    } else {
      final currentPos = selectable.indexOf(current);
      pointer = (currentPos + delta).clamp(0, selectable.length - 1);
    }

    setState(() {
      _keyboardIndex = selectable[pointer];
      _hoveredIndex = _keyboardIndex;
    });
    _scrollToIndex(_keyboardIndex!);
    _markOverlayNeedsBuild();
  }

  void _selectKeyboardItem(List<_RenderNode> list) {
    final idx = _keyboardIndex;
    if (idx == null || idx < 0 || idx >= list.length) return;
    final node = list[idx].node;
    if (!node.selectable) return;
    widget.onChanged(node.id);
    _close();
  }

  KeyEventResult _onDropdownKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (!_isOpen) {
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space) {
        _open();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final list = _flatten();
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveKeyboardSelection(list, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveKeyboardSelection(list, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _selectKeyboardItem(list);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _open() {
    if (!widget.enabled || _overlay != null) return;
    _didScrollToSelected = false;
    _setInitialKeyboardIndex(_flatten());
    _overlay = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);

    Future.delayed(const Duration(milliseconds: 10), () {
      _searchFocus.requestFocus();
    });
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    _searchCtrl.clear();
    setState(() {
      _isOpen = false;
      _hoveredIndex = null;
      _keyboardIndex = null;
      _didScrollToSelected = false;
    });
  }

  void _markOverlayNeedsBuild() {
    _overlay?.markNeedsBuild();
  }

  Offset _calculateOverlayOffset(Size fieldSize, double overlayHeight) {
    if (!mounted) return Offset(0, fieldSize.height + 4);

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;

    if (overlayBox == null ||
        targetBox == null ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return Offset(0, fieldSize.height + 4);
    }

    final targetGlobal = targetBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

    final double spaceBelow =
        overlayBox.size.height - (targetGlobal.dy + fieldSize.height);
    final double spaceAbove = targetGlobal.dy;
    final bool showAbove =
        spaceBelow < overlayHeight && spaceAbove > spaceBelow;

    return Offset(0, showAbove ? -(overlayHeight + 4) : fieldSize.height + 4);
  }

  Widget _buildOverlay() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();

    final items = _flatten();
    if (!_didScrollToSelected) {
      _didScrollToSelected = true;
      _scrollToSelected(items);
      if (_keyboardIndex == null) {
        _setInitialKeyboardIndex(items);
      }
      if (_keyboardIndex != null) {
        _scrollToIndex(_keyboardIndex!);
      }
    }
    final double listHeight = (items.length * _rowHeight)
        .clamp(72, 240)
        .toDouble();

    final double overlayHeight = listHeight + 50; // Plus search field

    return Stack(
      children: [
        Positioned.fill(child: GestureDetector(onTap: _close)),
        CompositedTransformFollower(
          link: _layerLink,
          offset: _calculateOverlayOffset(box.size, overlayHeight),
          showWhenUnlinked: false,
          child: Material(
            elevation: 6,
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: _onDropdownKeyEvent,
              child: Container(
                width: box.size.width,
                height: overlayHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 34,
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search accounts...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _setInitialKeyboardIndex(_flatten());
                            });
                            _markOverlayNeedsBuild();
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        itemCount: items.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          final node = entry.node;
                          final selected = widget.value == node.id;
                          final hovered =
                              _hoveredIndex == index || _keyboardIndex == index;

                          if (!node.selectable) {
                            return Container(
                              height: _rowHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                node.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            );
                          }

                          Color bg = Colors.transparent;
                          Color text = const Color(0xFF374151);
                          Color check = const Color(0xFF1B75E5);

                          if (selected) {
                            bg = const Color(0xFFF3F4F6);
                            text = const Color(0xFF111827);
                          }
                          if (hovered) {
                            bg = const Color(0xFF1B75E5);
                            text = Colors.white;
                            check = Colors.white;
                          }

                          return MouseRegion(
                            onEnter: (_) {
                              _hoveredIndex = index;
                              _keyboardIndex = index;
                              _markOverlayNeedsBuild();
                            },
                            onExit: (_) {
                              _hoveredIndex = null;
                              _markOverlayNeedsBuild();
                            },
                            child: InkWell(
                              onTap: () {
                                widget.onChanged(node.id);
                                _close();
                              },
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              child: Container(
                                height: _rowHeight,
                                padding: EdgeInsets.only(
                                  left: 12 + entry.depth * 16,
                                  right: 12,
                                ),
                                color: bg,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        node.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: text,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        LucideIcons.check,
                                        size: 16,
                                        color: check,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String label = widget.hint ?? '';
    for (final p in widget.nodes) {
      if (p.id == widget.value) label = p.name;
      for (final c in p.children) {
        if (c.id == widget.value) label = c.name;
      }
    }

    final bool hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Focus(
            focusNode: _fieldFocus,
            onKeyEvent: _onDropdownKeyEvent,
            child: SizedBox(
              height: widget.height ?? _fieldHeight,
              child: InkWell(
                onTap: () {
                  _fieldFocus.requestFocus();
                  _open();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? Colors.white
                        : const Color(0xFFF3F4F6),
                    border:
                        widget.border ??
                        Border.all(
                          color: hasError
                              ? const Color(0xFFEF4444) // Red on error
                              : _isOpen
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD1D5DB),
                        ),
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.value == null
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF111827),
                          ),
                        ),
                      ),
                      Icon(
                        _isOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _RenderNode {
  final AccountNode node;
  final int depth;
  _RenderNode(this.node, this.depth);
}
