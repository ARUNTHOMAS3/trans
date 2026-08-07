import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class FormDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String? hint;
  final String? hintText;
  final ValueChanged<T?> onChanged;

  final bool showSettings;
  final String settingsLabel;
  final VoidCallback? onSettingsTap;
  final Widget? settingsLeading;

  final bool allowClear;
  final String? clearTooltipMessage;
  final dynamic clearTooltipDirection;
  final bool showClearDivider;

  // ✅ ADD BACK itemBuilder (this fixes your error)
  final Widget Function(T item, bool isSelected, bool isHovered)? itemBuilder;
  final Widget Function(
    T item,
    bool isSelected,
    bool isHovered,
    bool isMenuHovered,
  )?
  itemBuilderWithMenuHover;

  // ✅ Optional enable/disable per item
  final bool Function(T item)? isItemEnabled;

  final String Function(T value)? displayStringForValue;

  final bool enabled;
  final String? errorText;
  final double? height;
  final double? fieldHeight;
  final bool allowCustomValue;
  final String Function(T item)? searchStringForValue;
  final IconData? settingsIcon;
  final EdgeInsets? padding;
  final double? iconSize;
  final BorderRadius? borderRadius;
  final BorderRadius? rowBorderRadius;
  final Future<List<T>> Function(String query)? onSearch;
  final bool isLoading;
  final bool showSearchIcon;
  final bool showSearch;
  final bool forceUppercase;
  final double? menuWidth;
  final bool showCustomValueAction;
  final bool forceDownward;
  final bool openAbove;
  final double? dropdownWidth;
  final bool boldSelected;
  final bool paintSelectionBackground;
  final bool showHierarchyBullets;
  final int? hierarchyBulletMinDepth;
  final Color? activeBorderColor;
  final bool disableBorder;
  final String? emptyText;
  final Widget? searchIcon;
  final Widget? suffixWidget;
  final bool isInline;
  final bool alignMenuRightToField;
  final double? scrollbarThickness;
  final Color? scrollbarThumbColor;
  final Color? scrollHintColor;
  final double? scrollHintWidth;
  final double? scrollbarGutterWidth;
  final double? scrollHintIconSize;

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
  final bool compactMultiSelectSummary;
  final String? compactMultiSelectLabel;
  final double? compactMultiSelectLabelYOffset;
  final T? multiSelectAllValue;
  final bool alwaysShowClear;
  final Color? selectedBackgroundColor;
  final Color? hoverBackgroundColor;
  final Widget? prefixWidget;
  final bool isHovered;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  final Color? searchIconColor;

  const FormDropdown({
    super.key,
    required this.value,
    required this.items,
    this.hint,
    this.hintText,
    required this.onChanged,
    this.showSettings = false,
    this.settingsLabel = 'Configure...',
    this.onSettingsTap,
    this.settingsLeading,
    this.allowClear = false,
    this.clearTooltipMessage,
    this.clearTooltipDirection,
    this.showClearDivider = false,
    this.itemBuilder,
    this.itemBuilderWithMenuHover,
    this.isItemEnabled,
    this.displayStringForValue,
    this.enabled = true,
    this.errorText,
    this.height,
    this.fieldHeight,
    this.allowCustomValue = false,
    this.searchStringForValue,
    this.settingsIcon,
    this.padding,
    this.iconSize,
    this.borderRadius,
    this.rowBorderRadius,
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
    this.hideSelectedItemsInMultiSelect = false,
    this.compactMultiSelectSummary = false,
    this.compactMultiSelectLabel,
    this.compactMultiSelectLabelYOffset,
    this.multiSelectAllValue,
    this.alwaysShowClear = false,
    this.selectedBackgroundColor,
    this.hoverBackgroundColor,
    this.prefixWidget,
    this.isHovered = false,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.searchIconColor,
    this.forceDownward = false,
    this.openAbove = false,
    this.dropdownWidth,
    this.boldSelected = true,
    this.paintSelectionBackground = true,
    this.showHierarchyBullets = true,
    this.hierarchyBulletMinDepth,
    this.activeBorderColor,
    this.disableBorder = false,
    this.emptyText,
    this.searchIcon,
    this.suffixWidget,
    this.isInline = false,
    this.alignMenuRightToField = false,
    this.scrollbarThickness,
    this.scrollbarThumbColor,
    this.scrollHintColor,
    this.scrollHintWidth,
    this.scrollbarGutterWidth,
    this.scrollHintIconSize,
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
  double get _rowHeight =>
      widget.itemEstimatedHeight ?? widget.itemHeight ?? 40.0;
  double get _maxOverlayHeight => widget.menuMaxHeight ?? 320.0;
  static const double _searchBlockHeight = 56.0;
  static const double _settingsRowHeight = 40.0;

  final ScrollController _listScrollCtrl = ScrollController();
  bool _isSearching = false;
  Timer? _debounce;
  bool _overlayRebuildQueued = false;
  final Set<T> _hoveredSelectedChips = <T>{};

  Widget Function(T item, bool isSelected, bool isHovered)?
  get _effectiveItemBuilder => widget.itemBuilderWithMenuHover != null
      ? (item, isSelected, isHovered) =>
            widget.itemBuilderWithMenuHover!(item, isSelected, isHovered, false)
      : widget.itemBuilder;

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
      final selectedList = widget.selectedValues;
      baseItems = baseItems.where((item) => !selectedList.contains(item));
    }

    if (normalized.isEmpty) {
      return baseItems.toList();
    }

    final indexedMatches =
        baseItems
            .toList()
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
    final entry = _overlayEntry;
    if (entry == null) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final canRebuildNow =
        phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (canRebuildNow) {
      entry.markNeedsBuild();
      return;
    }

    if (_overlayRebuildQueued) return;
    _overlayRebuildQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildQueued = false;
      if (!mounted) return;
      _overlayEntry?.markNeedsBuild();
    });
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

    // Start each open with the full list so stale search text from a previous
    // session does not make options look randomly empty.
    _debounce?.cancel();
    if (_searchCtrl.text.isNotEmpty) {
      _searchCtrl.clear();
    }
    _filteredItems = _localFilter('');
    _isSearching = false;

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
    if (!(widget.allowClear || widget.alwaysShowClear) || !widget.enabled) {
      return;
    }

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

  bool _shouldShowBelow(Size fieldSize, double overlayHeight) {
    if (!mounted) return true;
    final targetBox = context.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) return true;

    final targetGlobal = targetBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double spaceBelow =
        screenHeight - (targetGlobal.dy + fieldSize.height) - 16;
    final double spaceAbove = targetGlobal.dy - 16;

    if (widget.forceDownward) return true;

    if (spaceBelow < overlayHeight && spaceAbove > spaceBelow) {
      return false;
    }
    return true;
  }

  Offset _calculateOverlayOffset(Size fieldSize, bool showBelow) {
    if (!mounted) return const Offset(0, 4);

    final targetBox = context.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) {
      return const Offset(0, 4);
    }

    final targetGlobal = targetBox.localToGlobal(Offset.zero);
    final double screenWidth = MediaQuery.of(context).size.width;

    final rightOverflow = (targetGlobal.dx + fieldSize.width) - screenWidth;
    final double xOffset = rightOverflow > 0 ? -(rightOverflow + 8) : 0;

    return Offset(xOffset, showBelow ? 4 : -4);
  }

  Widget _buildDropdownOverlay() {
    if (!mounted) return const SizedBox.shrink();

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return const SizedBox.shrink();

    final size = renderObject.size;

    final bool isSearchActive =
        widget.showSearch && _searchCtrl.text.trim().isNotEmpty;

    final double searchRowHeight =
        widget.itemEstimatedHeight ??
        widget.itemHeight ??
        (_effectiveItemBuilder != null ? 56.0 : _rowHeight);
    final double effectiveRowHeight = isSearchActive
        ? searchRowHeight
        : _rowHeight;

    final bool showCustomValueAction =
        widget.showCustomValueAction &&
        widget.allowCustomValue &&
        _searchCtrl.text.trim().isNotEmpty &&
        !_filteredItems.any((e) {
          final String display = widget.displayStringForValue != null
              ? widget.displayStringForValue!(e)
              : e.toString();
          return display.toLowerCase() == _searchCtrl.text.trim().toLowerCase();
        });

    double reservedHeight = 0;
    if (widget.showSearch) {
      reservedHeight += _searchBlockHeight + 1;
    }
    if (widget.showSettings) {
      reservedHeight += 1 + _settingsRowHeight;
    }
    if (showCustomValueAction) {
      reservedHeight += 1 + _settingsRowHeight;
    }

    const double _borderWidth = 2.0; // 1px top + 1px bottom from Border.all
    final double idealHeight =
        reservedHeight +
        (_filteredItems.isEmpty
            ? 64.0
            : (_filteredItems.length * effectiveRowHeight)) +
        _borderWidth;

    // Compute available space below/above the field and clamp max overlay height
    double effectiveMaxHeight = _maxOverlayHeight;
    final targetGlobal = renderObject.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double spaceBelow =
        screenHeight - (targetGlobal.dy + size.height) - 16;
    final double spaceAbove = targetGlobal.dy - 16;

    final bool showBelow = _shouldShowBelow(size, idealHeight);

    if (showBelow) {
      if (spaceBelow < effectiveMaxHeight) {
        effectiveMaxHeight = math.max(60.0, spaceBelow);
      }
    } else {
      if (spaceAbove < effectiveMaxHeight) {
        effectiveMaxHeight = math.max(60.0, spaceAbove);
      }
    }

    final double effectiveMaxHeightInner = effectiveMaxHeight - _borderWidth;
    final double maxListHeight = math.max(
      effectiveRowHeight,
      effectiveMaxHeightInner,
    );
    final double availableListHeight =
        (effectiveMaxHeightInner - reservedHeight)
            .clamp(effectiveRowHeight, maxListHeight)
            .toDouble();
    final bool isEmptyState = _filteredItems.isEmpty;
    final bool hasMaxVisibleItems =
        widget.maxVisibleItems != null && widget.maxVisibleItems! > 0;
    final int itemCount = _filteredItems.length;
    final int cappedVisibleCount = hasMaxVisibleItems
        ? itemCount.clamp(1, math.max(1, widget.maxVisibleItems!))
        : math.max(1, itemCount);

    final double dynamicHeight = (_filteredItems.length * effectiveRowHeight)
        .clamp(effectiveRowHeight, availableListHeight)
        .toDouble();
    final double cappedHeight = (cappedVisibleCount * effectiveRowHeight)
        .clamp(effectiveRowHeight, availableListHeight)
        .toDouble();
    final double listHeight = (!isSearchActive && hasMaxVisibleItems)
        ? cappedHeight
        : dynamicHeight;
    final double emptyStateHeight = availableListHeight
        .clamp(64.0, 80.0)
        .toDouble();
    final double contentListHeight = isEmptyState
        ? emptyStateHeight
        : listHeight;
    final bool shouldShowListScrollbar =
        (_filteredItems.length * effectiveRowHeight) > contentListHeight;

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _removeOverlay(),
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _removeOverlay();
              }
            },
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: showBelow ? Alignment.bottomLeft : Alignment.topLeft,
          followerAnchor: showBelow ? Alignment.topLeft : Alignment.bottomLeft,
          offset: _calculateOverlayOffset(size, showBelow),
          showWhenUnlinked: false,
          child: Material(
            elevation: 6,
            color: Colors.transparent,
            child: Container(
              width: widget.dropdownWidth ?? widget.menuWidth ?? size.width,
              constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
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
                            hintText:
                                widget.placeholder ?? widget.hint ?? 'Search',
                            hintStyle: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            prefixIcon: widget.showSearchIcon
                                ? (widget.searchIcon ??
                                      const Icon(
                                        Icons.search,
                                        size: 16,
                                        color: AppTheme.textMuted,
                                      ))
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
                                width: AppTheme.inputBorderWidth,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.borderColor,
                                width: AppTheme.inputBorderWidth,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.infoBlue,
                                width: AppTheme.inputActiveBorderWidth,
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
                    SizedBox(
                      height: emptyStateHeight,
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
                      height: emptyStateHeight,
                      child: Center(
                        child: Text(
                          widget.emptyText ?? 'No results found',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else if (widget.listBuilder != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: listHeight),
                      child: Scrollbar(
                        controller: _listScrollCtrl,
                        thumbVisibility: shouldShowListScrollbar,
                        thickness: 6,
                        radius: const Radius.circular(3),
                        child: SingleChildScrollView(
                          controller: _listScrollCtrl,
                          physics: const ClampingScrollPhysics(),
                          child: widget.listBuilder!(_filteredItems, (item) {
                            final int index = _filteredItems.indexOf(item);
                            final bool isSelected = widget.multiSelect
                                ? widget.selectedValues.contains(item)
                                : item == widget.value;
                            final bool isHovered = _hoveredIndex == index;
                            final bool enabled =
                                widget.isItemEnabled?.call(item) ?? true;

                            final Color itemBg = enabled
                                ? (isHovered
                                      ? (widget.hoverBackgroundColor ??
                                            const Color(0xFF3B82F6))
                                      : (isSelected
                                            ? (widget.selectedBackgroundColor ??
                                                  const Color(0xFFF3F4F6))
                                            : Colors.transparent))
                                : Colors.transparent;

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
                                  child: Container(
                                    color: itemBg,
                                    child: _effectiveItemBuilder!(
                                      item,
                                      isSelected,
                                      isHovered,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: listHeight),
                      child: Scrollbar(
                        controller: _listScrollCtrl,
                        thumbVisibility: shouldShowListScrollbar,
                        thickness: 6,
                        radius: const Radius.circular(3),
                        child: ListView.builder(
                          controller: _listScrollCtrl,
                          physics: const ClampingScrollPhysics(),
                          shrinkWrap: true,
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
                            final Widget rowChild =
                                _effectiveItemBuilder != null
                                ? _effectiveItemBuilder!(
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

                            final Color itemBg = enabled
                                ? (isHovered
                                      ? (widget.hoverBackgroundColor ??
                                            const Color(0xFF3B82F6))
                                      : (isSelected
                                            ? (widget.selectedBackgroundColor ??
                                                  const Color(0xFFF3F4F6))
                                            : Colors.transparent))
                                : Colors.transparent;

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
                                  child: Container(
                                    color: itemBg,
                                    child: rowChild,
                                  ),
                                ),
                              ),
                            );
                          },
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
                      child: SizedBox(
                        height: _settingsRowHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              widget.settingsLeading ??
                                  Icon(
                                    widget.settingsIcon ?? Icons.settings,
                                    size: 14,
                                    color: AppTheme.primaryBlueDark,
                                  ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.settingsLabel,
                                  maxLines: 1,
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
                    ),
                  ],

                  if (showCustomValueAction) ...[
                    const Divider(height: 1, color: AppTheme.borderColor),
                    InkWell(
                      onTap: _commitTypedValue,
                      hoverColor: AppTheme.infoBg,
                      child: SizedBox(
                        height: _settingsRowHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                  maxLines: 1,
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
    Color text = AppTheme.textPrimary; // Gray-900 default

    if (!enabled) {
      text = AppTheme.textMuted; // Gray-400
    } else {
      if (isHovered) {
        text = Colors.white;
      } else if (isSelected) {
        text = const Color(0xFF111827);
      }
    }

    final String label = widget.displayStringForValue != null
        ? widget.displayStringForValue!(item)
        : item.toString();

    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.transparent,
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
        ],
      ),
    );
  }

  Widget _buildMultiSelectValue() {
    if (widget.selectedValues.isEmpty) {
      return Text(
        widget.hintText ?? widget.hint ?? '',
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
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
        height: widget.height ?? widget.fieldHeight ?? _fieldHeight,
        borderRadius: widget.borderRadius?.topLeft.x ?? 4.0,
      );
    }
    final hasValue = widget.multiSelect
        ? widget.selectedValues.isNotEmpty
        : widget.value != null;
    final bool hasError = widget.errorText != null;
    final double effectiveHeight =
        widget.height ?? widget.fieldHeight ?? _fieldHeight;

    final borderRadius =
        widget.borderRadius ??
        widget.rowBorderRadius ??
        BorderRadius.circular(4);
    bool isUniform = widget.showLeftBorder && widget.showRightBorder;
    if (widget.border != null) {
      final b = widget.border;
      if (b is Border) {
        if (!b.isUniform) {
          isUniform = false;
        }
      } else {
        isUniform = false;
      }
    }

    final Widget field = CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHoveredField = true),
        onExit: (_) => setState(() => _isHoveredField = false),
        child: InkWell(
          onTap: widget.enabled ? _toggleDropdown : null,
          hoverColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: widget.multiSelect ? null : effectiveHeight,
              constraints: widget.multiSelect
                  ? BoxConstraints(minHeight: effectiveHeight)
                  : null,
              padding:
                  widget.padding ?? const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: widget.fillColor ?? Colors.white,
                borderRadius: isUniform ? borderRadius : null,
                border: (_isOpen || _isHoveredField || widget.isHovered)
                    ? Border(
                        top: BorderSide(
                          color: hasError
                              ? AppTheme.errorRed
                              : const Color(0xFF3B82F6),
                          width: AppTheme.inputActiveBorderWidth,
                        ),
                        bottom: BorderSide(
                          color: hasError
                              ? AppTheme.errorRed
                              : const Color(0xFF3B82F6),
                          width: AppTheme.inputActiveBorderWidth,
                        ),
                        left: widget.showLeftBorder
                            ? BorderSide(
                                color: hasError
                                    ? AppTheme.errorRed
                                    : const Color(0xFF3B82F6),
                                width: AppTheme.inputActiveBorderWidth,
                              )
                            : BorderSide.none,
                        right: widget.showRightBorder
                            ? BorderSide(
                                color: hasError
                                    ? AppTheme.errorRed
                                    : const Color(0xFF3B82F6),
                                width: AppTheme.inputActiveBorderWidth,
                              )
                            : BorderSide.none,
                      )
                    : (widget.border ??
                          Border(
                            top: _getBorderSide(hasError),
                            bottom: _getBorderSide(hasError),
                            left: widget.showLeftBorder
                                ? _getBorderSide(hasError)
                                : BorderSide.none,
                            right: widget.showRightBorder
                                ? _getBorderSide(hasError)
                                : BorderSide.none,
                          )),
              ),
              child: Row(
                children: [
                  if (widget.prefixWidget != null) ...[
                    widget.prefixWidget!,
                    const SizedBox(width: 8),
                  ],
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
                                : (widget.hintText ?? widget.hint ?? ''),
                            textAlign: widget.textAlign,
                            overflow: TextOverflow.ellipsis,
                            style:
                                widget.textStyle ??
                                TextStyle(
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
                  if ((widget.allowClear || widget.alwaysShowClear) &&
                      hasValue &&
                      (_isHoveredField || widget.isHovered)) ...[
                    const SizedBox(width: 8),
                    if (widget.showClearDivider)
                      Container(
                        width: 1,
                        height: 18,
                        color: AppTheme.borderColor,
                      ),
                    GestureDetector(
                      onTap: _handleClear,
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                  if (widget.suffixWidget != null) ...[
                    const SizedBox(width: 6),
                    widget.suffixWidget!,
                  ] else if (widget.showArrowOnSelection || !hasValue) ...[
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
    );

    return field;
  }

  BorderSide _getBorderSide(bool hasError) {
    final bool isHovered = _isHoveredField || widget.isHovered;
    final bool shouldShowBorder =
        !widget.disableBorder &&
        (!widget.hideBorderDefault || _isOpen || isHovered || hasError);
    final bool isActiveBorder = hasError || _isOpen || isHovered;
    return BorderSide(
      color: !shouldShowBorder
          ? Colors.transparent
          : hasError
          ? AppTheme.errorRed
          : (_isOpen || isHovered)
          ? (widget.activeBorderColor ?? AppTheme.primaryBlue)
          : AppTheme.borderColor,
      width: isActiveBorder
          ? AppTheme.inputActiveBorderWidth
          : AppTheme.inputBorderWidth,
    );
  }
}
