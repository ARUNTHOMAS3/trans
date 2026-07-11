import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

class AccountTreeDropdownWithAddButton extends StatefulWidget {
  final String? value;
  final List<AccountNode> nodes;
  final String? hint;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final Future<List<AccountNode>> Function(String)? onSearch;
  final String addButtonText;
  final VoidCallback? onAddAccount;
  final String? errorText;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final FocusNode? focusNode;
  final bool highlightSearchMatches;

  const AccountTreeDropdownWithAddButton({
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
    this.addButtonText = 'New Account',
    this.onAddAccount,
    this.highlightSearchMatches = true,
  });

  @override
  State<AccountTreeDropdownWithAddButton> createState() =>
      _AccountTreeDropdownWithAddButtonState();
}

class _AccountTreeDropdownWithAddButtonState
    extends State<AccountTreeDropdownWithAddButton> {
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
  bool _isAddAccountHovered = false;
  static const double _rowHeight = 36;
  static const double _fieldHeight = 32;

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
    _removeOverlay();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _internalFieldFocus?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AccountTreeDropdownWithAddButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.nodes, widget.nodes)) {
      _remoteResults = null;
      _didScrollToSelected = false;
      if (_isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_isOpen) return;
          _setInitialKeyboardIndex(_flatten());
          _markOverlayNeedsBuild();
        });
      }
    }
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

    _debounce = Timer(const Duration(milliseconds: 180), () async {
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
    if (!widget.enabled || _overlay != null || !mounted) return;
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;
    if (kDebugMode) {
      AppLogger.debug(
        'AccountTreeDropdown open: nodes=${widget.nodes.length}, value=${widget.value}',
        module: 'purchases_recurring_expenses',
      );
      if (widget.nodes.isNotEmpty) {
        AppLogger.debug(
          'AccountTreeDropdown root sample: ${widget.nodes.take(5).map((e) => e.name).join(' | ')}',
          module: 'purchases_recurring_expenses',
        );
      }
    }
    _didScrollToSelected = false;
    _setInitialKeyboardIndex(_flatten());
    _overlay = OverlayEntry(builder: (_) => _buildOverlay());
    overlayState.insert(_overlay!);
    setState(() => _isOpen = true);

    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted && _isOpen) {
        _searchFocus.requestFocus();
      }
    });
  }

  void _removeOverlay() {
    final entry = _overlay;
    if (entry != null) {
      entry.remove();
      _overlay = null;
    }
  }

  void _close() {
    _removeOverlay();
    _searchCtrl.clear();
    if (!mounted) return;
    setState(() {
      _isOpen = false;
      _hoveredIndex = null;
      _keyboardIndex = null;
      _didScrollToSelected = false;
      _isAddAccountHovered = false;
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
        !targetBox.attached ||
        !overlayBox.attached ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return Offset(0, fieldSize.height + 4);
    }

    late final Offset targetGlobal;
    try {
      targetGlobal = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    } catch (_) {
      return Offset(0, fieldSize.height + 4);
    }

    final double spaceBelow =
        overlayBox.size.height - (targetGlobal.dy + fieldSize.height);
    final double spaceAbove = targetGlobal.dy;
    final bool showAbove =
        spaceBelow < overlayHeight && spaceAbove > spaceBelow;

    return Offset(0, showAbove ? -(overlayHeight + 4) : fieldSize.height + 4);
  }

  Widget _buildOverlay() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _close();
      });
      return const SizedBox.shrink();
    }

    final items = _flatten();
    if (kDebugMode) {
      AppLogger.debug(
        'AccountTreeDropdown overlay: flattened=${items.length}, search=\"${_searchCtrl.text}\"',
        module: 'purchases_recurring_expenses',
      );
    }
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

    final double overlayHeight = listHeight + 95; //plus add button
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
                  color: AppTheme.backgroundColor,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    if (_isSearching)
                      const SizedBox(
                        height: 2,
                        child: ZBone(
                          borderRadius: 0,
                          color: AppTheme.infoBlue,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 32,
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search accounts...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryBlueDark,
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
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                _searchCtrl.text.trim().isEmpty
                                    ? 'No accounts available'
                                    : 'No accounts found',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollCtrl,
                              itemCount: items.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                final entry = items[index];
                                final node = entry.node;
                                final selected = widget.value == node.id;
                                final hovered =
                                    _hoveredIndex == index ||
                                    _keyboardIndex == index;

                                final isGroup = node.id.startsWith(
                                  '__account_group__',
                                );
                                final isType = node.id.startsWith(
                                  '__account_type__',
                                );

                                if (!node.selectable) {
                                  final double paddingLeft =
                                      (12 + (entry.depth * 12)).toDouble();

                                  return Container(
                                    height: _rowHeight,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      border: isType
                                          ? const Border(
                                              top: BorderSide(
                                                color: AppTheme.bgDisabled,
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
                                            ? AppTheme.textBody
                                            : AppTheme.textSubtle,
                                      ),
                                    ),
                                  );
                                }

                                Color bg = Colors.transparent;
                                Color text = AppTheme.textPrimary;
                                Color check = Colors.transparent;

                                if (hovered) {
                                  bg = const Color(0xFF3B82F6);
                                  text = AppTheme.backgroundColor;
                                  check = selected
                                      ? AppTheme.backgroundColor
                                      : Colors.transparent;
                                } else if (selected) {
                                  bg = const Color(0xFFF3F4F6);
                                  text = AppTheme.textPrimary;
                                  check = AppTheme.textPrimary;
                                }

                                final bool showBullet = entry.depth > 0;
                                final double paddingLeft =
                                    (12 + (entry.depth * 12)).toDouble();

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
                                          if (showBullet)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Text(
                                                '•',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: text,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
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
                    if (widget.onAddAccount != null) ...[
                      Container(height: 1, color: AppTheme.borderColor),
                      MouseRegion(
                        onEnter: (_) {
                          _hoveredIndex = null;
                          _keyboardIndex = null;
                          setState(() {
                            _isAddAccountHovered = true;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            _isAddAccountHovered = false;
                          });
                        },
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isAddAccountHovered = false;
                            });
                            _close();
                            widget.onAddAccount?.call();
                          },
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Container(
                            height: _rowHeight,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            color: _isAddAccountHovered
                                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryBlueDark,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 12,
                                      color: AppTheme.backgroundColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.addButtonText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryBlueDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
    if (query.isEmpty || isSelected || !widget.highlightSearchMatches) {
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
            style: const TextStyle(backgroundColor: AppTheme.warningBg),
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
                    color: AppTheme.backgroundColor,
                    border:
                        widget.border ??
                        Border.all(
                          color: hasError
                              ? AppTheme
                                    .errorRed // Red on error
                              : _isOpen
                              ? AppTheme.primaryBlueDark
                              : AppTheme.borderColor,
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
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
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
              color: AppTheme.errorRed,
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
