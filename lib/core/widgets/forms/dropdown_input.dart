import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:zerpai_erp/core/widgets/common/skeleton.dart';

class FormDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String? hint;
  final ValueChanged<T?> onChanged;

  final bool showSettings;
  final String settingsLabel;
  final VoidCallback? onSettingsTap;

  final bool allowClear;

  // ✅ ADD BACK itemBuilder (this fixes your error)
  final Widget Function(T item, bool isSelected, bool isHovered)? itemBuilder;

  // ✅ Optional enable/disable per item
  final bool Function(T item)? isItemEnabled;

  final String Function(T value)? displayStringForValue;

  final bool enabled;
  final String? errorText;
  final double? height;
  final bool allowCustomValue;
  final String Function(T item)? searchStringForValue;
  final IconData? settingsIcon;
  final EdgeInsets? padding;
  final double? iconSize;
  final BorderRadius? borderRadius;
  final Future<List<T>> Function(String query)? onSearch;
  final bool isLoading;
  final bool showSearchIcon;
  final bool showSearch;
  final bool forceUppercase;

  // Added missing properties from items_composite_item_create.dart usage
  final VoidCallback? onEdit;
  final bool showArrowOnSelection;
  final Color? fillColor;
  final bool showLeftBorder;
  final bool showRightBorder;
  final double? itemHeight;

  const FormDropdown({
    super.key,
    required this.value,
    required this.items,
    this.hint,
    required this.onChanged,
    this.showSettings = false,
    this.settingsLabel = 'Configure...',
    this.onSettingsTap,
    this.allowClear = false,
    this.itemBuilder,
    this.isItemEnabled,
    this.displayStringForValue,
    this.enabled = true,
    this.errorText,
    this.height,
    this.allowCustomValue = false,
    this.searchStringForValue,
    this.settingsIcon,
    this.padding,
    this.iconSize,
    this.borderRadius,
    this.onSearch,
    this.isLoading = false,
    this.showSearchIcon = true,
    this.showSearch = true,
    this.forceUppercase = false,
    this.onEdit,
    this.showArrowOnSelection = true,
    this.fillColor,
    this.showLeftBorder = true,
    this.showRightBorder = true,
    this.hideBorderDefault = false,
    this.itemHeight,
  });

  final bool hideBorderDefault;

  @override
  State<FormDropdown<T>> createState() => _FormDropdownState<T>();
}

class _FormDropdownState<T> extends State<FormDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool _isOpen = false;
  bool _blockToggleOnce = false;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late List<T> _filteredItems;
  int? _hoveredIndex;
  bool _isHoveredField = false;

  static const double _fieldHeight = 40.0;
  double get _rowHeight => widget.itemHeight ?? 36.0;
  static const double _overlayMaxHeight = 400.0;
  static const double _searchBlockHeight = 56.0;
  static const double _settingsRowHeight = 40.0;

  final ScrollController _listScrollCtrl = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = List<T>.from(widget.items);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant FormDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items != widget.items || oldWidget.value != widget.value) {
      // Logic to update filtered items without triggering setState immediately
      final q = _searchCtrl.text.toLowerCase().trim();
      _filteredItems = q.isEmpty
          ? List<T>.from(widget.items)
          : widget.items.where((e) {
              final String display = widget.displayStringForValue != null
                  ? widget.displayStringForValue!(e)
                  : e.toString();
              return display.toLowerCase().contains(q);
            }).toList();

      // Defer overlay update to avoid "Build scheduled during frame" error
      if (_isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _markOverlayNeedsBuild();
            // Also try to scroll to selected if value changed
            _scrollToSelected();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _listScrollCtrl.dispose();
    // _removeOverlay() calls setState, which fails in dispose
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _filterItems(_searchCtrl.text);

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _filterItems(String query) async {
    final q = query.toLowerCase().trim();

    if (widget.onSearch != null) {
      setState(() => _isSearching = true);
      _markOverlayNeedsBuild();
      try {
        final results = await widget.onSearch!(q);
        if (mounted) {
          setState(() {
            _filteredItems = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    } else {
      setState(() {
        _filteredItems = q.isEmpty
            ? List<T>.from(widget.items)
            : widget.items.where((e) {
                if (widget.searchStringForValue != null) {
                  return widget.searchStringForValue!(e).toLowerCase().contains(
                    q,
                  );
                }
                final String display = widget.displayStringForValue != null
                    ? widget.displayStringForValue!(e)
                    : e.toString();
                return display.toLowerCase().contains(q);
              }).toList();
      });
    }

    _markOverlayNeedsBuild();

    // ✅ after filtering, try to keep selected in view
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (widget.value == null) return;

    final int index = _filteredItems.indexWhere((e) => e == widget.value);
    if (index < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listScrollCtrl.hasClients) return;

      final target = (index * _rowHeight)
          .clamp(
            _listScrollCtrl.position.minScrollExtent,
            _listScrollCtrl.position.maxScrollExtent,
          )
          .toDouble();

      _listScrollCtrl.jumpTo(target);
    });
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_blockToggleOnce) {
      _blockToggleOnce = false;
      return;
    }

    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (_) => _buildDropdownOverlay());

    overlay.insert(_overlayEntry!);

    setState(() => _isOpen = true);

    // ✅ after open: focus search + scroll to selected
    Future.delayed(const Duration(milliseconds: 30), () {
      if (!mounted) return;
      if (widget.showSearch) {
        _searchFocus.requestFocus();
      }
      _scrollToSelected();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (!mounted) return;
    setState(() {
      _isOpen = false;
      _hoveredIndex = null;
    });
  }

  void _handleItemTap(T value) {
    widget.onChanged(value);
    _removeOverlay();
  }

  void _handleClear() {
    if (!widget.allowClear || !widget.enabled) return;

    _blockToggleOnce = true;
    widget.onChanged(null);

    _searchCtrl.clear();
    _filterItems('');
  }

  double _calculateOverlayHeight(double listHeight) {
    double height = listHeight;
    if (widget.showSearch) {
      height += _searchBlockHeight + 1;
    }
    if (widget.showSettings) {
      height += 1 + _settingsRowHeight;
    }
    return height.clamp(0, _overlayMaxHeight).toDouble();
  }

  Offset _calculateOverlayOffset(Size fieldSize, double overlayHeight) {
    if (!mounted) return Offset(0, fieldSize.height + 4);

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;

    if (overlayBox == null || targetBox == null) {
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
    final rightOverflow =
        (targetGlobal.dx + fieldSize.width) - overlayBox.size.width;

    return Offset(
      rightOverflow > 0 ? -(rightOverflow + 8) : 0,
      showAbove ? -(overlayHeight + 4) : fieldSize.height + 4,
    );
  }

  Widget _buildDropdownOverlay() {
    if (!mounted) return const SizedBox.shrink();

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return const SizedBox.shrink();

    final size = renderObject.size;

    final double listHeight = (_filteredItems.length * _rowHeight)
        .clamp(80, 220)
        .toDouble();
    final double overlayHeight = _calculateOverlayHeight(listHeight);

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _removeOverlay(),
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          offset: _calculateOverlayOffset(size, overlayHeight),
          showWhenUnlinked: false,
          child: Material(
            elevation: 6,
            color: Colors.transparent,
            child: Container(
              width: size.width,
              constraints: const BoxConstraints(maxHeight: _overlayMaxHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  6,
                ), // Standard rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSearch == true) ...[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                            ),
                            prefixIcon: widget.showSearchIcon
                                ? const Icon(
                                    Icons.search,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  )
                                : null,
                            contentPadding: EdgeInsets.zero,
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ],

                  if (_isSearching)
                    const SizedBox(
                      height: 80,
                      child: Center(
                        child: SizedBox(
                          width: 100,
                          height: 20,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                      ),
                    )
                  else if (_filteredItems.isEmpty)
                    SizedBox(
                      height: 80,
                      child: const Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: listHeight,
                      child: Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            if (!_listScrollCtrl.hasClients) return;

                            final delta = event.scrollDelta.dy;
                            final max =
                                _listScrollCtrl.position.maxScrollExtent;
                            final min =
                                _listScrollCtrl.position.minScrollExtent;

                            final next = (_listScrollCtrl.offset + delta).clamp(
                              min,
                              max,
                            );
                            _listScrollCtrl.jumpTo(next);
                          }
                        },
                        child: ListView.builder(
                          controller: _listScrollCtrl,
                          padding: EdgeInsets.zero,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final bool isSelected = item == widget.value;
                            final bool isHovered = _hoveredIndex == index;
                            final bool enabled =
                                widget.isItemEnabled?.call(item) ?? true;

                            // ✅ If custom renderer exists, use it
                            final Widget rowChild = widget.itemBuilder != null
                                ? widget.itemBuilder!(
                                    item,
                                    isSelected,
                                    isHovered,
                                  )
                                : _defaultRow(
                                    item,
                                    isSelected,
                                    isHovered,
                                    enabled,
                                  );

                            // If itemBuilder is provided, it should only render content.
                            // We still need hover tracking + click wrapper.
                            return MouseRegion(
                              onEnter: (_) {
                                if (!enabled) return;
                                setState(() => _hoveredIndex = index);
                                _markOverlayNeedsBuild();
                              },
                              onExit: (_) {
                                if (!enabled) return;
                                setState(() => _hoveredIndex = null);
                                _markOverlayNeedsBuild();
                              },
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: enabled
                                      ? () => _handleItemTap(item)
                                      : null,
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  child: rowChild,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  if (widget.showSettings) ...[
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    InkWell(
                      onTap: () {
                        _removeOverlay();
                        widget.onSettingsTap?.call();
                      },
                      hoverColor: const Color(0xFFF3F4F6),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.settingsIcon ?? Icons.settings,
                              size: 14,
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.settingsLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultRow(T item, bool isSelected, bool isHovered, bool enabled) {
    Color bg = Colors.transparent;
    Color text = const Color(0xFF374151); // Gray-700

    if (!enabled) {
      text = const Color(0xFF9CA3AF); // Gray-400
    } else {
      if (isSelected) {
        bg = const Color(
          0xFFF3F4F6,
        ); // Gray-100 (Light background for selected)
        text = const Color(0xFF111827); // Gray-900 (Darker text)
      }
      if (isHovered) {
        bg = const Color(0xFFF9FAFB); // Gray-50 (Very light hover)
        // If hovered AND selected, maybe darker?
        if (isSelected) {
          bg = const Color(0xFFE5E7EB); // Gray-200
        }
      }
    }

    final String label = widget.displayStringForValue != null
        ? widget.displayStringForValue!(item)
        : item.toString();

    return Container(
      height: widget.itemHeight,
      constraints: BoxConstraints(minHeight: _rowHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: bg,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: text,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (enabled && isSelected)
            const Icon(
              Icons.check,
              size: 16,
              color: Color(0xFF2563EB), // Blue-600 checkmark
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Skeleton(
        height: widget.height ?? _fieldHeight,
        borderRadius: widget.borderRadius?.topLeft.x ?? 4.0,
      );
    }
    final hasValue = widget.value != null;
    final bool hasError = widget.errorText != null;

    /// Border color logic
    Color borderColor;
    if (hasError) {
      borderColor = const Color(0xFFEF4444); // Red on error
    } else if (!widget.enabled) {
      borderColor = const Color(0xFFE5E7EB);
    } else if (_isOpen) {
      borderColor = const Color(0xFF2563EB); // Blue on open/focus
    } else {
      borderColor = const Color(0xFFD1D5DB); // Default grey
    }

    final bool shouldShowBorder =
        !widget.hideBorderDefault || _isOpen || _isHoveredField || hasError;

    final effectiveBorderColor = shouldShowBorder
        ? borderColor
        : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(
            height: widget.height ?? _fieldHeight,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHoveredField = true),
              onExit: (_) => setState(() => _isHoveredField = false),
              child: InkWell(
                onTap: widget.enabled ? _toggleDropdown : null,
                hoverColor: Colors.transparent,
                child: Container(
                  padding:
                      widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color:
                        widget.fillColor ??
                        (widget.enabled
                            ? Colors.white
                            : const Color(0xFFF3F4F6)),
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(4),
                    border: Border(
                      top: BorderSide(color: effectiveBorderColor),
                      bottom: BorderSide(color: effectiveBorderColor),
                      left: widget.showLeftBorder
                          ? BorderSide(color: effectiveBorderColor)
                          : BorderSide.none,
                      right: widget.showRightBorder
                          ? BorderSide(color: effectiveBorderColor)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasValue
                              ? (widget.displayStringForValue != null
                                    ? widget.displayStringForValue!(
                                        widget.value as T,
                                      )
                                    : widget.value.toString())
                              : (widget.hint ?? ''),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasValue
                                ? const Color(0xFF111827)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      if (widget.onEdit != null && hasValue) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _blockToggleOnce = true;
                            widget.onEdit!();
                          },
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                      if (widget.allowClear && hasValue) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _handleClear,
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                      if (widget.showArrowOnSelection || !hasValue) ...[
                        const SizedBox(width: 6),
                        Icon(
                          _isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: widget.iconSize ?? 18,
                          color: _isOpen
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF6B7280),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Error text removed - parent should handle layout with error text if needed
      ],
    );
  }
}
