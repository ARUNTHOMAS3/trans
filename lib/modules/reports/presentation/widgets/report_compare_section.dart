import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_popup.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';

class ReportCompareSelection {
  final String? compareType;
  final int count;
  final bool arrangeLatestFirst;

  const ReportCompareSelection({
    required this.compareType,
    required this.count,
    required this.arrangeLatestFirst,
  });

  const ReportCompareSelection.none()
      : compareType = null,
        count = 1,
        arrangeLatestFirst = false;

  bool get isActive => compareType != null;

  String get displayValue => isActive ? 'Applied' : 'None';
}

class ReportCompareSection extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<ReportCompareSelection>? onSelectionApplied;

  const ReportCompareSection({
    super.key,
    this.selectedValue = 'None',
    this.onChanged,
    this.onSelectionApplied,
  });

  @override
  State<ReportCompareSection> createState() => _ReportCompareSectionState();
}

class _ReportCompareSectionState extends State<ReportCompareSection> {
  static const double _screenPadding = AppTheme.space8;
  static const double _popupGap = AppTheme.space4;
  static const double _preferredPopupWidth = AppTheme.space64 * 4.6;

  final LayerLink _dropdownLayerLink = LayerLink();
  final GlobalKey _dropdownAnchorKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isDisposing = false;
  late String _selectedValue;
  String? _selectedCompareType;
  String? _draftCompareType;
  String _selectedCount = '1';
  String _draftCount = '1';
  bool _selectedArrangeLatestFirst = false;
  bool _draftArrangeLatestFirst = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(covariant ReportCompareSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue &&
        widget.selectedValue != _selectedValue) {
      _selectedValue = widget.selectedValue;
      if (!_isOpen && widget.selectedValue == 'None') {
        _selectedCompareType = null;
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _removeOverlay(updateState: false);
    super.dispose();
  }

  void _togglePopup() {
    if (_isOpen) {
      _cancelSelection();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted || _isDisposing || _overlayEntry != null) return;

    _draftCompareType = _selectedCompareType;
    _draftCount = _selectedCount;
    _draftArrangeLatestFirst = _selectedArrangeLatestFirst;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_overlayEntry!);

    if (!mounted || _isDisposing) return;
    setState(() => _isOpen = true);
  }

  void _removeOverlay({bool updateState = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      if (entry.mounted) {
        entry.remove();
      }
      entry.dispose();
    }
    if (!updateState || !mounted || _isDisposing || !_isOpen) return;
    setState(() => _isOpen = false);
  }

  void _markOverlayNeedsBuild() {
    if (_overlayEntry?.mounted ?? false) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _handleCompareTypeChanged(String? value) {
    setState(() {
      _draftCompareType = value;
      if (value == 'Previous Period(s)' && _draftCount == '2') {
        _draftCount = '1';
      }
      if (value == null) {
        _draftCount = _selectedCount;
        _draftArrangeLatestFirst = _selectedArrangeLatestFirst;
      }
    });
    _markOverlayNeedsBuild();
  }

  void _handleCountChanged(String? value) {
    if (value == null) return;
    setState(() => _draftCount = value);
    _markOverlayNeedsBuild();
  }

  void _handleArrangeChanged(bool? value) {
    setState(() => _draftArrangeLatestFirst = value ?? false);
    _markOverlayNeedsBuild();
  }

  void _applySelection() {
    if (!mounted) return;
    final selection = ReportCompareSelection(
      compareType: _draftCompareType,
      count: int.tryParse(_draftCount) ?? 1,
      arrangeLatestFirst: _draftArrangeLatestFirst,
    );
    final nextValue = selection.displayValue;
    final changed =
        nextValue != _selectedValue ||
        _draftCompareType != _selectedCompareType ||
        _draftCount != _selectedCount ||
        _draftArrangeLatestFirst != _selectedArrangeLatestFirst;
    setState(() {
      _selectedCompareType = _draftCompareType;
      _selectedCount = _draftCount;
      _selectedArrangeLatestFirst = _draftArrangeLatestFirst;
      _selectedValue = nextValue;
    });
    if (changed) {
      widget.onChanged?.call(_selectedValue);
      widget.onSelectionApplied?.call(selection);
    }
    _removeOverlay();
  }

  void _cancelSelection() {
    _draftCompareType = _selectedCompareType;
    _draftCount = _selectedCount;
    _draftArrangeLatestFirst = _selectedArrangeLatestFirst;
    _removeOverlay();
  }

  double _calculatePopupWidth(double anchorWidth) {
    return math.max(anchorWidth + AppTheme.space24, _preferredPopupWidth);
  }

  ReportPopupPlacement _calculateOverlayPlacement({
    required RenderBox anchorBox,
    required double overlayWidth,
    required double overlayHeight,
  }) {
    return resolveReportPopupPlacement(
      context: context,
      anchorBox: anchorBox,
      popupWidth: overlayWidth,
      popupHeight: overlayHeight,
      screenPadding: _screenPadding,
      popupGap: _popupGap,
    );
  }

  Widget _buildOverlay() {
    final anchorContext = _dropdownAnchorKey.currentContext;
    final anchorRenderObject = anchorContext?.findRenderObject();
    if (anchorRenderObject is! RenderBox || !anchorRenderObject.hasSize) {
      return const SizedBox.shrink();
    }

    final popupWidth = _calculatePopupWidth(anchorRenderObject.size.width);
    final popupHeight = ReportComparePopup.estimatedHeightFor(
      _draftCompareType,
    );
    final placement = _calculateOverlayPlacement(
      anchorBox: anchorRenderObject,
      overlayWidth: popupWidth,
      overlayHeight: popupHeight,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _cancelSelection,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _dropdownLayerLink,
          targetAnchor: placement.targetAnchor,
          followerAnchor: placement.followerAnchor,
          offset: placement.offset,
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: ReportComparePopup(
              width: popupWidth,
              compareType: _draftCompareType,
              countValue: _draftCount,
              arrangeLatestFirst: _draftArrangeLatestFirst,
              onCompareTypeChanged: _handleCompareTypeChanged,
              onCountChanged: _handleCountChanged,
              onArrangeChanged: _handleArrangeChanged,
              onApply: _applySelection,
              onCancel: _cancelSelection,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTheme.bodyText.copyWith(
      color: AppTheme.textSecondary,
      fontWeight: FontWeight.w400,
    );
    final valueStyle = AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: AppTheme.transparent,
        child: InkWell(
          onTap: _togglePopup,
          borderRadius: BorderRadius.circular(AppTheme.space4),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: CompositedTransformTarget(
            link: _dropdownLayerLink,
            child: Padding(
              key: _dropdownAnchorKey,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space4,
                vertical: AppTheme.space6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.gitCompare,
                    size: AppTheme.space16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space6),
                  Text('Compare With : ', style: labelStyle),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedValue, style: valueStyle),
                        const SizedBox(width: AppTheme.space4),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
