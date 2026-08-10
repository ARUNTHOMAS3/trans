import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';

typedef ReportsSearchSelect = void Function(Map<String, String> report);

class ReportsSearchExplorer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Map<String, List<Map<String, String>>> groupedReports;
  final ReportsSearchSelect onSelected;
  final double maxWidth;

  const ReportsSearchExplorer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.groupedReports,
    required this.onSelected,
    required this.maxWidth,
  });

  @override
  State<ReportsSearchExplorer> createState() => _ReportsSearchExplorerState();
}

class _ReportsSearchExplorerState extends State<ReportsSearchExplorer> {
  static const Duration _fieldAnimationDuration = Duration(milliseconds: 180);
  static const Duration _dropdownAnimationDuration = Duration(milliseconds: 160);

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  final Object _tapRegionGroupId = Object();
  OverlayEntry? _overlayEntry;
  final ScrollController _resultsScrollController = ScrollController();
  bool _isDisposing = false;
  String? _highlightedReportKey;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleStateChanged);
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant ReportsSearchExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleStateChanged);
      widget.controller.addListener(_handleStateChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
    _syncHighlight();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposing) {
        _syncOverlay();
      }
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    widget.controller.removeListener(_handleStateChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    _removeOverlay();
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _handleStateChanged() {
    if (!mounted || _isDisposing) return;
    setState(() {});
    _syncHighlight();
    _syncOverlay();
  }

  void _handleFocusChanged() {
    if (!mounted || _isDisposing) return;
    setState(() {});
    if (widget.focusNode.hasFocus) {
      _syncHighlight();
      _syncOverlay();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposing) return;
      if (!widget.focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  void _syncOverlay() {
    if (_isDisposing) return;
    final shouldShow = widget.focusNode.hasFocus && _hasResults;
    if (shouldShow) {
      _showOrRefreshOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOrRefreshOverlay() {
    if (_isDisposing || !mounted) return;
    if (_overlayEntry == null) {
      final entry = OverlayEntry(builder: _buildOverlayEntry);
      _overlayEntry = entry;
      Overlay.of(context).insert(entry);
    } else {
      _markOverlayNeedsBuild();
    }
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      if (entry.mounted) {
        entry.remove();
      }
      entry.dispose();
    }
  }

  void _markOverlayNeedsBuild() {
    if (_overlayEntry?.mounted ?? false) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  bool get _hasResults => widget.groupedReports.values.any((reports) => reports.isNotEmpty);

  List<String> get _visibleReportKeys {
    final keys = <String>[];
    for (final entry in widget.groupedReports.entries) {
      for (final report in entry.value) {
        keys.add(_reportKey(entry.key, report));
      }
    }
    return keys;
  }

  void _syncHighlight() {
    final visibleKeys = _visibleReportKeys;
    if (visibleKeys.isEmpty) {
      _highlightedReportKey = null;
      return;
    }
    if (_highlightedReportKey == null || !visibleKeys.contains(_highlightedReportKey)) {
      _highlightedReportKey = visibleKeys.first;
    }
  }

  String _reportKey(String category, Map<String, String> report) {
    return '$category::${report['name'] ?? ''}';
  }

  void _selectReport(Map<String, String> report) {
    widget.onSelected(report);
    widget.focusNode.unfocus();
    _removeOverlay();
  }

  double _resolvedCollapsedWidth(double availableWidth) {
    final targetWidth = widget.maxWidth;
    return availableWidth < targetWidth ? availableWidth : targetWidth;
  }

  double _resolvedExpandedWidth(double availableWidth) {
    final targetWidth = widget.maxWidth + AppTheme.space40;
    return availableWidth < targetWidth ? availableWidth : targetWidth;
  }

 
  Widget _buildOverlayEntry(BuildContext context) {
  final theme = Theme.of(context);

  const double dropdownWidth = 275;
  const double dropdownMaxHeight = 252;

  return Positioned.fill(
    child: TapRegion(
      groupId: _tapRegionGroupId,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, AppTheme.space4),
        child: UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: dropdownWidth,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: dropdownMaxHeight,
              ),
              child: TweenAnimationBuilder<double>(
                duration: _dropdownAnimationDuration,
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * AppTheme.space4),
                      child: child,
                    ),
                  );
                },
                child: Material(
                  color: AppTheme.backgroundColor,
                  elevation: AppTheme.space4,
                  shadowColor: theme.shadowColor,
                  surfaceTintColor: AppTheme.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.space4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(AppTheme.space4),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.space4),
                      child: Scrollbar(
                        controller: _resultsScrollController,
                        thumbVisibility: true,
                        thickness: AppTheme.space4,
                        radius: const Radius.circular(AppTheme.space2),
                        child: ListView(
                          controller: _resultsScrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.space4,
                          ),
                          shrinkWrap: true,
                          children: [
                            for (final entry in widget.groupedReports.entries) ...[
                              if (entry.value.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppTheme.space8,
                                    AppTheme.space4,
                                    AppTheme.space8,
                                    AppTheme.space2,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space8,
                                      vertical: AppTheme.space6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.reportDropdownHeaderBg,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.space4,
                                      ),
                                    ),
                                    child: Text(
                                      entry.key.toUpperCase(),
                                      style: AppTheme.captionText.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                              for (final report in entry.value)
                                Builder(
                                  builder: (context) {
                                    final reportKey = _reportKey(entry.key, report);
                                    final isHighlighted =
                                        _highlightedReportKey == reportKey;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.space8,
                                      ),
                                      child: Material(
                                        color: isHighlighted
                                            ? AppTheme.primaryBlue
                                            : AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.space4,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.space4,
                                          ),
                                          hoverColor: isHighlighted
                                              ? AppTheme.primaryBlue
                                              : AppTheme.selectionActiveBg,
                                          onHover: (isHovering) {
                                            if (isHovering &&
                                                _highlightedReportKey != reportKey) {
                                              if (!mounted || _isDisposing) return;
                                              setState(() {
                                                _highlightedReportKey = reportKey;
                                              });
                                              _markOverlayNeedsBuild();
                                            }
                                          },
                                          onTap: () => _selectReport(report),
                                          child: SizedBox(
                                            height: AppTheme.inputHeight,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppTheme.space8,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  report['name'] ?? '-',
                                                  style: AppTheme.tableCell.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: isHighlighted
                                                        ? AppTheme.backgroundColor
                                                        : AppTheme.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              const SizedBox(height: AppTheme.space2),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    return TapRegion(
      groupId: _tapRegionGroupId,
      onTapOutside: (_) {
        widget.focusNode.unfocus();
        _removeOverlay();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : widget.maxWidth;
          final collapsedWidth = _resolvedCollapsedWidth(availableWidth);
          final expandedWidth = _resolvedExpandedWidth(availableWidth);
          final targetWidth = isFocused ? expandedWidth : collapsedWidth;

          return Align(
            alignment: Alignment.center,
            child: CompositedTransformTarget(
              link: _layerLink,
              child: AnimatedContainer(
                key: _fieldKey,
                duration: _fieldAnimationDuration,
                curve: Curves.easeOutCubic,
                width: targetWidth,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onTap: _syncOverlay,
                  style: AppTheme.bodyText,
                  decoration: InputDecoration(
                    hintText: 'Search reports',
                    hintStyle: AppTextStyles.hint,
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: AppTheme.iconSize,
                      color: AppTheme.primaryBlue,
                    ),
                    filled: true,
                    fillColor: isFocused
                        ? AppTheme.inputFill
                        : AppTheme.reportDropdownHeaderBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.space8),
                      borderSide: const BorderSide(color: AppTheme.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.space8),
                      borderSide: const BorderSide(color: AppTheme.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.space8),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


