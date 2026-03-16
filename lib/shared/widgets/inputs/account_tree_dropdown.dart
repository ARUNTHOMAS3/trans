import 'dart:async';
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
  final Future<List<AccountNode>> Function(String)? onSearch;

  final String? errorText;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final FocusNode? focusNode;

  const AccountTreeDropdown({
    super.key,
    required this.value,
    required this.nodes,
    this.hint,
    this.enabled = true,
    required this.onChanged,
    this.onSearch,
    this.errorText,
    this.height,
    this.borderRadius,
    this.border,
    this.focusNode,
  });

  @override
  State<AccountTreeDropdown> createState() => _AccountTreeDropdownState();
}

class _AccountTreeDropdownState extends State<AccountTreeDropdown> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  FocusNode? _internalFieldFocus;
  late FocusNode _effectiveFieldFocus;

  OverlayEntry? _overlay;
  bool _isOpen = false;
  int? _hoveredIndex;
  int? _keyboardIndex;
  bool _didScrollToSelected = false;
  List<AccountNode>? _remoteResults;
  bool _isSearching = false;
  Timer? _debounce;

  static const double _rowHeight = 36;
  static const double _fieldHeight = 44;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFieldFocus = FocusNode();
    }
    _effectiveFieldFocus = widget.focusNode ?? _internalFieldFocus!;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _internalFieldFocus?.dispose();
    super.dispose();
  }

  List<_RenderNode> _flatten() {
    final list = <_RenderNode>[];
    final String query = _searchCtrl.text.toLowerCase().trim();

    final nodesToUse = (query.isNotEmpty && _remoteResults != null)
        ? _remoteResults!
        : widget.nodes;

    bool hasMatch(AccountNode node) {
      if (node.name.toLowerCase().contains(query)) return true;
      for (final child in node.children) {
        if (hasMatch(child)) return true;
      }
      return false;
    }

    void addNode(AccountNode node, int depth, bool forceAdd) {
      final matches = node.name.toLowerCase().contains(query);
      final hasMatchingChild = node.children.any((c) => hasMatch(c));

      if (query.isEmpty ||
          matches ||
          hasMatchingChild ||
          forceAdd ||
          _remoteResults != null) {
        list.add(_RenderNode(node, depth));
        for (final child in node.children) {
          addNode(
            child,
            depth + 1,
            query.isEmpty || matches || forceAdd || _remoteResults != null,
          );
        }
      }
    }

    for (final p in nodesToUse) {
      addNode(p, 0, false);
    }
    return list;
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    if (widget.onSearch == null || v.isEmpty) {
      setState(() {
        _remoteResults = null;
        _isSearching = false;
      });
      _markOverlayNeedsBuild();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      _markOverlayNeedsBuild();
      try {
        final results = await widget.onSearch!(v);
        setState(() {
          _remoteResults = results;
          _isSearching = false;
        });
      } catch (e) {
        setState(() => _isSearching = false);
      }
      _markOverlayNeedsBuild();
    });
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
                    if (_isSearching)
                      const SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                        ),
                      ),
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
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (v) {
                            _onSearchChanged(v);
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

                          final isGroup = node.id.startsWith(
                            '__account_group__',
                          );
                          final isType = node.id.startsWith('__account_type__');

                          if (!node.selectable) {
                            final double paddingLeft =
                                (entry.depth <= 1
                                        ? 12
                                        : (entry.depth == 2 ? 24 : 36))
                                    .toDouble();

                            return Container(
                              height: _rowHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: isType
                                    ? const Border(
                                        top: BorderSide(
                                          color: Color(0xFFF3F4F6),
                                          width: 1,
                                        ),
                                      )
                                    : null,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: paddingLeft,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                node.name,
                                style: TextStyle(
                                  fontSize: isGroup ? 13 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: isGroup
                                      ? const Color(0xFF374151)
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            );
                          }

                          Color bg = Colors.transparent;
                          Color text = const Color(0xFF1F2937);
                          Color check = Colors.transparent;

                          if (selected) {
                            bg = const Color(0xFF2563EB);
                            text = Colors.white;
                            check = Colors.white;
                          } else if (hovered) {
                            bg = const Color(0xFFF9FAFB);
                            text = const Color(0xFF1F2937);
                          }

                          final double paddingLeft =
                              (entry.depth <= 1
                                      ? 12
                                      : (entry.depth == 2 ? 24 : 36))
                                  .toDouble();

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
                                  left: paddingLeft,
                                  right: 12,
                                ),
                                color: bg,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildNameWithHighlight(
                                        node.name,
                                        text,
                                        selected,
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

  Widget _buildNameWithHighlight(
    String name,
    Color textColor,
    bool isSelected,
  ) {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty || isSelected) {
      return Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
      );
    }

    final int index = name.toLowerCase().indexOf(query);
    if (index == -1) {
      return Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textColor,
          fontFamily: 'Inter',
        ),
        children: [
          TextSpan(text: name.substring(0, index)),
          TextSpan(
            text: name.substring(index, index + query.length),
            style: const TextStyle(backgroundColor: Color(0xFFFEF08A)),
          ),
          TextSpan(text: name.substring(index + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? findLabel(List<AccountNode> nodes, String? id) {
      if (id == null) return null;
      for (final node in nodes) {
        if (node.id == id) return node.name;
        final found = findLabel(node.children, id);
        if (found != null) return found;
      }
      return null;
    }

    final String label =
        findLabel(widget.nodes, widget.value) ?? widget.hint ?? '';

    final bool hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Focus(
            focusNode: _effectiveFieldFocus,
            onKeyEvent: _onDropdownKeyEvent,
            child: SizedBox(
              height: widget.height ?? _fieldHeight,
              child: InkWell(
                onTap: () {
                  _effectiveFieldFocus.requestFocus();
                  _open();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
