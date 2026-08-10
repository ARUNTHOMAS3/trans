import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_export_dropdown.dart';

class ReportExportMenu extends StatefulWidget {
  final VoidCallback? onExport;
  final VoidCallback? onDownload;
  final VoidCallback? onPrint;

  const ReportExportMenu({
    super.key,
    this.onExport,
    this.onDownload,
    this.onPrint,
  });

  @override
  State<ReportExportMenu> createState() => _ReportExportMenuState();
}

class _ReportExportMenuState extends State<ReportExportMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isDisposing = false;

  static const double _screenPadding = AppTheme.space8;
  static const double _popupGap = AppTheme.space4;
  static const double _preferredMenuWidth = AppTheme.space64 * 4.5;

  @override
  void dispose() {
    _isDisposing = true;
    _removeOverlay(updateState: false);
    super.dispose();
  }

  void _setMenuOpen(bool value) {
    if (_isOpen == value) return;
    _isOpen = value;

    if (!mounted || _isDisposing) return;
    setState(() {});
  }

  void _disposeOverlayEntry(OverlayEntry entry) {
    if (entry.mounted) {
      entry.remove();
    }
    entry.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted || _isDisposing || _overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(builder: (_) => _buildOverlay());
    _overlayEntry = entry;
    overlay.insert(entry);

    _setMenuOpen(true);
  }

  void _removeOverlay({bool updateState = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;

    if (entry != null) {
      _disposeOverlayEntry(entry);
    }

    if (updateState) {
      _setMenuOpen(false);
    } else {
      _isOpen = false;
    }
  }

  double _calculateMenuWidth(double triggerWidth) {
    return math.max(triggerWidth, _preferredMenuWidth);
  }

  bool _shouldShowBelow(Size triggerSize, double overlayHeight) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return true;

    final targetGlobal = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow =
        screenHeight - (targetGlobal.dy + triggerSize.height) - _screenPadding;
    final spaceAbove = targetGlobal.dy - _screenPadding;

    if (spaceBelow < overlayHeight && spaceAbove > spaceBelow) {
      return false;
    }
    return true;
  }

  Offset _calculateOverlayOffset({
    required Size triggerSize,
    required double overlayWidth,
    required double overlayHeight,
  }) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return Offset(
        triggerSize.width - overlayWidth,
        triggerSize.height + _popupGap,
      );
    }

    final targetGlobal = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    double xOffset = triggerSize.width - overlayWidth;

    final rightEdge = targetGlobal.dx + xOffset + overlayWidth;
    final rightOverflow = rightEdge - (screenSize.width - _screenPadding);
    if (rightOverflow > 0) {
      xOffset -= rightOverflow;
    }

    final leftEdge = targetGlobal.dx + xOffset;
    if (leftEdge < _screenPadding) {
      xOffset += _screenPadding - leftEdge;
    }

    final showBelow = _shouldShowBelow(triggerSize, overlayHeight);
    final yOffset = showBelow
        ? (triggerSize.height + _popupGap)
        : (-overlayHeight - _popupGap);

    return Offset(xOffset, yOffset);
  }

  Widget _buildOverlay() {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) {
      return const SizedBox.shrink();
    }

    final triggerSize = renderBox.size;
    final menuWidth = _calculateMenuWidth(triggerSize.width);
    final overlayHeight = ReportExportDropdown.estimatedHeight;
    final offset = _calculateOverlayOffset(
      triggerSize: triggerSize,
      overlayWidth: menuWidth,
      overlayHeight: overlayHeight,
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
          offset: offset,
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: ReportExportDropdown(
              width: menuWidth,
              onCloseMenu: _removeOverlay,
              onPdf: widget.onDownload,
              onXlsx: widget.onExport,
              onXls: widget.onExport,
              onCsv: widget.onExport,
              onZohoSheet: widget.onExport,
              onPrint: widget.onPrint,
              onPrintPreference: widget.onPrint,
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
          onTap: _toggleMenu,
          borderRadius: BorderRadius.circular(AppTheme.space8),
          hoverColor: AppTheme.bgHover,
          splashColor: AppTheme.selectionActiveBg,
          highlightColor: AppTheme.selectionActiveBg,
          child: Container(
            height: AppTheme.buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(AppTheme.space8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Export',
                  style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: AppTheme.space6),
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
