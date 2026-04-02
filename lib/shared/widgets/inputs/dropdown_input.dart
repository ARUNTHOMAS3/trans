import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:collection';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

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
  final double? menuWidth;
  final bool showCustomValueAction;

  // Added missing properties from items_composite_item_create.dart usage
  final VoidCallback? onEdit;
  final bool showArrowOnSelection;
  final Widget Function(List<T> items, Widget Function(T item) itemBuilder)?
  listBuilder;
  final BoxBorder? border;
  final Color? fillColor;
  final bool showLeftBorder;
  final bool showRightBorder;
  final bool hideBorderDefault;
  final double? itemHeight;
  final double? itemEstimatedHeight; // Alias for itemHeight
  final double? menuMaxHeight; // Custom constrained overlay height
  final int? maxVisibleItems;
  final String? placeholder; // Alias for hint
  final bool multiSelect;
  final List<T> selectedValues;
  final ValueChanged<List<T>>? onSelectedValuesChanged;
  final bool Function(T value)? isSelectedValueRemovable;
  final bool hideSelectedItemsInMultiSelect;

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
    this.showCustomValueAction = true,
    this.onEdit,
    this.showArrowOnSelection = true,
    this.listBuilder,
    this.menuWidth,
    this.border,
    this.fillColor,
    this.showLeftBorder = true,
    this.showRightBorder = true,
    this.hideBorderDefault = false,
    this.itemHeight,
    this.itemEstimatedHeight,
    this.menuMaxHeight,
    this.maxVisibleItems,
    this.placeholder,
    this.multiSelect = false,
    this.selectedValues = const [],
    this.onSelectedValuesChanged,
    this.isSelectedValueRemovable,
    this.hideSelectedItemsInMultiSelect = true,
  });

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
  double get _rowHeight => widget.itemEstimatedHeight ?? widget.itemHeight ?? 40.0;
  double get _maxOverlayHeight => widget.menuMaxHeight ?? 320.0;
  static const double _searchBlockHeight = 56.0;
  static const double _settingsRowHeight = 40.0;

  final ScrollController _listScrollCtrl = ScrollController();
  bool _isSearching = false;
  Timer? _debounce;
  final Set<T> _hoveredSelectedChips = <T>{};

  @override
  void initState() {
    super.initState();
    _filteredItems = _localFilter('');
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant FormDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items != widget.items ||
        oldWidget.value != widget.value ||
        !listEquals(oldWidget.selectedValues, widget.selectedValues)) {
      final q = _searchCtrl.text;
      setState(() {
        _filteredItems = _localFilter(q);
      });

      // Refresh overlay if open
      if (_isOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _markOverlayNeedsBuild();
            _scrollToSelected();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _listScrollCtrl.dispose();
    // _removeOverlay() calls setState, which fails in dispose
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _filterItems(_searchCtrl.text);

  bool _matchesQuery(T item, String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return true;

    return _searchableText(item).contains(normalized);
  }

  String _searchableText(T item) {
    if (widget.searchStringForValue != null) {
      return widget.searchStringForValue!(item).toLowerCase().trim();
    }

    final String display = widget.displayStringForValue != null
        ? widget.displayStringForValue!(item)
        : item.toString();
    return display.toLowerCase().trim();
  }

  int _matchRank(T item, String normalizedQuery) {
    final text = _searchableText(item);
    if (normalizedQuery.isEmpty) return 4;
    if (text == normalizedQuery) return 0;
    if (text.startsWith(normalizedQuery)) return 1;

    final wordBoundaryMatch = text
        .split(RegExp(r'[\s/(),.-]+'))
        .any((part) => part.startsWith(normalizedQuery));
    if (wordBoundaryMatch) return 2;

    if (text.contains(normalizedQuery)) return 3;
    return 4;
  }

  List<T> _localFilter(String query) {
    final normalized = query.toLowerCase().trim();
    Iterable<T> baseItems = widget.items;

    // Remove already selected items in multiSelect mode
    if (widget.multiSelect && widget.hideSelectedItemsInMultiSelect) {
      baseItems = baseItems.where((item) => !widget.selectedValues.contains(item));
    }

    if (normalized.isEmpty) {
      return baseItems.toList();
    }

    final indexedMatches =
        baseItems.toList()
            .asMap()
            .entries
            .where((entry) => _matchesQuery(entry.value, normalized))
            .toList()
          ..sort((a, b) {
            final rankCompare = _matchRank(
              a.value,
              normalized,
            ).compareTo(_matchRank(b.value, normalized));
            if (rankCompare != 0) return rankCompare;

            final aText = _searchableText(a.value);
            final bText = _searchableText(b.value);
            final textCompare = aText.compareTo(bText);
            if (textCompare != 0) return textCompare;

            return a.key.compareTo(b.key);
          });

    return indexedMatches.map((entry) => entry.value).toList();
  }

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _filterItems(String query) async {
    final q = query.toLowerCase().trim();
    final localMatches = _localFilter(q);

    setState(() {
      _filteredItems = localMatches;
      _isSearching = widget.onSearch != null && q.isNotEmpty;
    });

    if (widget.onSearch != null && q.isNotEmpty) {
      if (_debounce?.isActive ?? false) {
        _debounce!.cancel();
      }

      _debounce = Timer(const Duration(milliseconds: 180), () async {
        try {
          final results = await widget.onSearch!(q);
          if (!mounted || _searchCtrl.text.toLowerCase().trim() != q) {
            return;
          }

          final merged = LinkedHashSet<T>.from(localMatches)..addAll(results);

          setState(() {
            _filteredItems = merged.toList();
            _isSearching = false;
          });
        } catch (e) {
          if (!mounted || _searchCtrl.text.toLowerCase().trim() != q) {
            return;
          }

          setState(() => _isSearching = false);
        }
        _markOverlayNeedsBuild();
      });
    } else {
      _debounce?.cancel();
    }

    _markOverlayNeedsBuild();

    // ✅ after filtering, try to keep selected in view
    _scrollToSelected();
  }

  void _scrollToSelected() {
    final T? selectedItem = widget.multiSelect
        ? (widget.selectedValues.isNotEmpty
              ? widget.selectedValues.first
              : null)
        : widget.value;
    if (selectedItem == null) return;

    final int index = _filteredItems.indexWhere((e) => e == selectedItem);
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
    if (widget.multiSelect) {
      final List<T> nextValues = List<T>.from(widget.selectedValues);
      if (nextValues.contains(value)) {
        if (widget.isSelectedValueRemovable?.call(value) == false) {
          return;
        }
        nextValues.remove(value);
      } else {
        nextValues.add(value);
      }
      widget.onSelectedValuesChanged?.call(nextValues);
      _markOverlayNeedsBuild();
      return;
    }
    widget.onChanged(value);
    _removeOverlay();
  }

  void _handleClear() {
    if (!widget.allowClear || !widget.enabled) return;

    _blockToggleOnce = true;
    if (widget.multiSelect) {
      widget.onSelectedValuesChanged?.call(<T>[]);
      return;
    }
    widget.onChanged(null);

    _searchCtrl.clear();
    _filterItems('');
  }

  void _commitTypedValue() {
    final typedValue = _searchCtrl.text.trim();
    if (typedValue.isEmpty) return;

    if (!widget.allowCustomValue) return;

    _removeOverlay();
    if (T == String) {
      widget.onChanged(typedValue as T);
    }
  }

  double _calculateOverlayHeight(double listHeight) {
    double height = listHeight;
    if (widget.showSearch) {
      height += _searchBlockHeight + 1;
    }
    if (widget.showSettings) {
      height += 1 + _settingsRowHeight;
    }
    return height.clamp(0, _maxOverlayHeight).toDouble();
  }

  Offset _calculateOverlayOffset(Size fieldSize, double overlayHeight) {
    if (!mounted) return Offset(0, fieldSize.height + 4);

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;

    if (overlayBox == null ||
        !overlayBox.hasSize ||
        targetBox == null ||
        !targetBox.hasSize) {
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

    final int visibleItems = widget.maxVisibleItems != null &&
        widget.maxVisibleItems! > 0
      ? _filteredItems.length.clamp(0, widget.maxVisibleItems!)
      : _filteredItems.length;
    final double listHeight = widget.maxVisibleItems != null
      ? (visibleItems == 0 ? _rowHeight : visibleItems * _rowHeight)
      : (_filteredItems.length * _rowHeight).clamp(80, 220).toDouble();
    final bool shouldShowListScrollbar =
      (_filteredItems.length * _rowHeight) > listHeight;
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
              width: widget.menuWidth ?? size.width,
              constraints: BoxConstraints(maxHeight: _maxOverlayHeight),
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
                border: Border.all(color: AppTheme.borderColor),
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
                            hintText: widget.placeholder ?? widget.hint ?? 'Search',
                            hintStyle: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            prefixIcon: widget.showSearchIcon
                                ? const Icon(
                                    Icons.search,
                                    size: 16,
                                    color: AppTheme.textMuted,
                                  )
                                : null,
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryBlueDark,
                                      ),
                                    ),
                                  )
                                : null,
                            contentPadding: EdgeInsets.zero,
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
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _commitTypedValue(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                  ],

                  if (_isSearching && _filteredItems.isEmpty)
                    const SizedBox(
                      height: 80,
                      child: Center(
                        child: SizedBox(
                          width: 100,
                          height: 20,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
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
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else if (widget.listBuilder != null)
                    SizedBox(
                      height: listHeight,
                      child: widget.listBuilder!(_filteredItems, (item) {
                        final int index = _filteredItems.indexOf(item);
                        final bool isSelected = widget.multiSelect
                            ? widget.selectedValues.contains(item)
                            : item == widget.value;
                        final bool isHovered = _hoveredIndex == index;
                        final bool enabled =
                            widget.isItemEnabled?.call(item) ?? true;

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
                              child: widget.itemBuilder!(
                                item,
                                isSelected,
                                isHovered,
                              ),
                            ),
                          ),
                        );
                      }),
                    )
                  else
                    SizedBox(
                      height: listHeight,
                      child: Scrollbar(
                        controller: _listScrollCtrl,
                        thumbVisibility: shouldShowListScrollbar,
                        child: Listener(
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              if (!_listScrollCtrl.hasClients) return;

                              final delta = event.scrollDelta.dy;
                              final max =
                                  _listScrollCtrl.position.maxScrollExtent;
                              final min =
                                  _listScrollCtrl.position.minScrollExtent;

                              final next = (_listScrollCtrl.offset + delta)
                                  .clamp(min, max);
                              _listScrollCtrl.jumpTo(next);
                            }
                          },
                          child: ListView.builder(
                            controller: _listScrollCtrl,
                            padding: EdgeInsets.zero,
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final bool isSelected = widget.multiSelect
                                  ? widget.selectedValues.contains(item)
                                  : item == widget.value;
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
                    ),

                  if (widget.showSettings) ...[
                    const Divider(height: 1, color: AppTheme.borderColor),
                    InkWell(
                      onTap: () {
                        _removeOverlay();
                        widget.onSettingsTap?.call();
                      },
                      hoverColor: AppTheme.bgDisabled,
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
                              color: AppTheme.primaryBlueDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.settingsLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlueDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                    if (widget.showCustomValueAction &&
                      widget.allowCustomValue &&
                      _searchCtrl.text.trim().isNotEmpty &&
                      !_filteredItems.any((e) {
                        final String display =
                            widget.displayStringForValue != null
                            ? widget.displayStringForValue!(e)
                            : e.toString();
                        return display.toLowerCase() ==
                            _searchCtrl.text.trim().toLowerCase();
                      })) ...[
                    const Divider(height: 1, color: AppTheme.borderColor),
                    InkWell(
                      onTap: _commitTypedValue,
                      hoverColor: AppTheme.infoBg,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              size: 14,
                              color: AppTheme.primaryBlueDark,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Add "${_searchCtrl.text.trim()}"',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlueDark,
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
    Color text = AppTheme.textPrimary; // Gray-900 default

    if (!enabled) {
      text = AppTheme.textMuted; // Gray-400
    } else {
      if (isHovered) {
        bg = AppTheme.infoBlue;
        text = Colors.white;
      } else if (isSelected) {
        bg = Colors.transparent;
        text = AppTheme.textPrimary;
      }
    }

    final String label = widget.displayStringForValue != null
        ? widget.displayStringForValue!(item)
        : item.toString();

    return Container(
      height: _rowHeight,
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
            Icon(
              Icons.check,
              size: 16,
              color: isHovered ? Colors.white : AppTheme.primaryBlueDark,
            ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectValue() {
    if (widget.selectedValues.isEmpty) {
      return Text(
        widget.hint ?? '',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.selectedValues.map((item) {
        final String label = widget.displayStringForValue != null
              ? widget.displayStringForValue!(item)
              : item.toString();
          final bool canRemove =
              widget.isSelectedValueRemovable?.call(item) ?? true;
          final bool isHovered = _hoveredSelectedChips.contains(item);

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredSelectedChips.add(item)),
            onExit: (_) => setState(() => _hoveredSelectedChips.remove(item)),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHovered ? Colors.white : AppTheme.bgDisabled,
                borderRadius: BorderRadius.circular(4),
                border: isHovered
                    ? Border.all(color: AppTheme.borderColor)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (canRemove) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.enabled
                          ? () {
                              final List<T> nextValues = List<T>.from(
                                widget.selectedValues,
                              )..remove(item);
                              widget.onSelectedValuesChanged?.call(nextValues);
                            }
                          : null,
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isHovered
                            ? AppTheme.errorRed
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
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
    final hasValue = widget.multiSelect
        ? widget.selectedValues.isNotEmpty
        : widget.value != null;
    final bool hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            constraints: BoxConstraints(minHeight: widget.height ?? _fieldHeight),
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
                    color: widget.fillColor ?? Colors.white,
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(4),
                    border:
                        widget.border ??
                        Border(
                          top: _getBorderSide(hasError),
                          bottom: _getBorderSide(hasError),
                          left: widget.showLeftBorder
                              ? _getBorderSide(hasError)
                              : BorderSide.none,
                          right: widget.showRightBorder
                              ? _getBorderSide(hasError)
                              : BorderSide.none,
                        ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: widget.multiSelect
                            ? _buildMultiSelectValue()
                            : Text(
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
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
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
                            color: AppTheme.primaryBlueDark,
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
                            color: AppTheme.errorRed,
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
                              ? AppTheme.primaryBlueDark
                              : AppTheme.textSecondary,
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

  BorderSide _getBorderSide(bool hasError) {
    final bool shouldShowBorder =
        !widget.hideBorderDefault || _isOpen || _isHoveredField || hasError;
    return BorderSide(
      color: !shouldShowBorder
          ? Colors.transparent
          : hasError
          ? AppTheme.errorRed
          : _isOpen
          ? AppTheme.primaryBlueDark
          : AppTheme.borderColor,
    );
  }
}
