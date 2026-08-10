import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';

class ReportEntitiesFilter extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> initialSelection;
  final ValueChanged<List<String>>? onChanged;

  const ReportEntitiesFilter({
    super.key,
    this.label = 'Entities',
    required this.options,
    this.initialSelection = const <String>[],
    this.onChanged,
  });

  @override
  State<ReportEntitiesFilter> createState() => _ReportEntitiesFilterState();
}

class _ReportEntitiesFilterState extends State<ReportEntitiesFilter> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  OverlayEntry? _overlayEntry;
  late List<String> _selectedOptions;
  late List<String> _filteredOptions;
  bool _isOpen = false;
  bool _isDisposing = false;
  bool _overlayRebuildScheduled = false;

  static const double _screenPadding = AppTheme.space8;
  static const double _popupGap = AppTheme.space4;
  static const double _popupWidth = 192;
  static const double _popupMaxHeight = 228;
  static const double _rowHeight = 40;
  static const double _searchHeight = 34;

  @override
  void initState() {
    super.initState();
    _selectedOptions = List<String>.from(widget.initialSelection);
    _filteredOptions = List<String>.from(widget.options);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant ReportEntitiesFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.join('|') != widget.options.join('|')) {
      _filteredOptions = _applyFilter(_searchController.text);
      _scheduleOverlayNeedsBuild();
    }
    if (oldWidget.initialSelection.join('|') !=
        widget.initialSelection.join('|')) {
      _selectedOptions = List<String>.from(widget.initialSelection);
      _scheduleOverlayNeedsBuild();
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _removeOverlay(updateState: false, resetSearch: false);
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (_isDisposing) return;
    _filteredOptions = _applyFilter(_searchController.text);
    _markOverlayNeedsBuild();
  }

  List<String> _applyFilter(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<String>.from(widget.options);
    }
    return widget.options
        .where((option) => option.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  void _markOverlayNeedsBuild() {
    if (!mounted || _isDisposing) return;
    final entry = _overlayEntry;
    if (entry?.mounted ?? false) {
      entry!.markNeedsBuild();
    }
  }

  void _scheduleOverlayNeedsBuild() {
    if (_overlayRebuildScheduled || _isDisposing) return;
    _overlayRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildScheduled = false;
      if (!mounted || _isDisposing) return;
      _markOverlayNeedsBuild();
    });
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted || _isDisposing || _overlayEntry != null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_overlayEntry!);

    if (!mounted || _isDisposing) return;
    setState(() => _isOpen = true);
  }

  void _removeOverlay({bool updateState = true, bool resetSearch = true}) {
    _overlayRebuildScheduled = false;
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      if (entry.mounted) {
        entry.remove();
      }
      entry.dispose();
    }
    if (resetSearch && !_isDisposing) {
      _searchController.clear();
      _filteredOptions = List<String>.from(widget.options);
      _searchFocusNode.unfocus();
    } else {
      _filteredOptions = List<String>.from(widget.options);
    }
    if (updateState && mounted && !_isDisposing) {
      setState(() => _isOpen = false);
    }
  }

  void _toggleSelection(String option) {
    final nextSelection = List<String>.from(_selectedOptions);
    if (nextSelection.contains(option)) {
      nextSelection.remove(option);
    } else {
      nextSelection.add(option);
    }

    setState(() {
      _selectedOptions = nextSelection;
    });
    widget.onChanged?.call(List<String>.unmodifiable(nextSelection));
    _markOverlayNeedsBuild();
  }

  String _displayValue() {
    if (_selectedOptions.isEmpty) return 'None';
    if (_selectedOptions.length == widget.options.length) return 'All';
    if (_selectedOptions.length == 1) return _selectedOptions.first;
    return '${_selectedOptions.length} selected';
  }

  Widget _buildOverlay() {
    if (!mounted || _isDisposing) return const SizedBox.shrink();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return const SizedBox.shrink();
    }

    final triggerSize = renderBox.size;
    final popupWidth = math
        .max(_popupWidth, triggerSize.width - AppTheme.space12)
        .toDouble();
    final visibleRows = _filteredOptions.length.clamp(1, 4);
    final popupHeight = math
        .min(
          _popupMaxHeight,
          AppTheme.space12 +
              _searchHeight +
              AppTheme.space10 +
              (visibleRows * _rowHeight) +
              AppTheme.space8,
        )
        .toDouble();
    final placement = resolveReportPopupPlacement(
      context: context,
      anchorBox: renderBox,
      popupWidth: popupWidth,
      popupHeight: popupHeight,
      screenPadding: _screenPadding,
      popupGap: _popupGap,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: placement.targetAnchor,
          followerAnchor: placement.followerAnchor,
          offset: placement.offset,
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: Focus(
              autofocus: true,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _removeOverlay();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                width: popupWidth,
                constraints: const BoxConstraints(maxHeight: _popupMaxHeight),
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.space8),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.08),
                      blurRadius: AppTheme.space20,
                      offset: const Offset(0, AppTheme.space6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _searchHeight,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: AppTheme.bodyText,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: AppTheme.bodyText.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            LucideIcons.search,
                            size: AppTheme.space16,
                            color: AppTheme.textSecondary,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: AppTheme.space32,
                            minHeight: AppTheme.space16,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space10,
                            vertical: AppTheme.space8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.space8,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.space8,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.space8,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space10),
                    Flexible(
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: _filteredOptions.length > 4,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredOptions.length,
                          itemBuilder: (context, index) {
                            final option = _filteredOptions[index];
                            final selected = _selectedOptions.contains(option);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _toggleSelection(option),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.space8,
                                ),
                                hoverColor: AppTheme.bgHover,
                                splashColor: AppTheme.transparent,
                                highlightColor: AppTheme.transparent,
                                child: Container(
                                  height: _rowHeight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space8,
                                  ),
                                  child: Row(
                                    children: [
                                      IgnorePointer(
                                        child: CheckboxTheme(
                                          data: CheckboxTheme.of(context).copyWith(
                                            fillColor:
                                                WidgetStateProperty.resolveWith(
                                                  (states) {
                                                    if (states.contains(
                                                      WidgetState.selected,
                                                    )) {
                                                      return AppTheme
                                                          .primaryBlue;
                                                    }
                                                    return AppTheme
                                                        .backgroundColor;
                                                  },
                                                ),
                                            checkColor: WidgetStateProperty.all(
                                              AppTheme.backgroundColor,
                                            ),
                                            overlayColor:
                                                WidgetStateProperty.all(
                                                  AppTheme.transparent,
                                                ),
                                            side: const BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                          ),
                                          child: Checkbox(
                                            value: selected,
                                            onChanged: (_) {},
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity: const VisualDensity(
                                              horizontal: -4,
                                              vertical: -4,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.space4,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.space8),
                                      Expanded(
                                        child: Text(
                                          option,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.bodyText.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: selected
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        child: InkWell(
          onTap: _toggleOverlay,
          borderRadius: BorderRadius.circular(AppTheme.space8),
          hoverColor: AppTheme.bgHover,
          child: Container(
            height: AppTheme.buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(AppTheme.space8),
              border: Border.all(
                color: _isOpen ? AppTheme.primaryBlue : AppTheme.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.label} : ',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 118),
                  child: Text(
                    _displayValue(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    LucideIcons.chevronDown,
                    size: AppTheme.space16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
