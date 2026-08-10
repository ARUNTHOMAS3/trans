import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ReportAgingIntervalSection extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String>? onChanged;
  final List<String> options;

  const ReportAgingIntervalSection({
    super.key,
    required this.selectedValue,
    this.onChanged,
    this.options = const <String>['6 X 3 Days', '5 X 7 Days', '4 X 15 Days'],
  });

  @override
  State<ReportAgingIntervalSection> createState() => _ReportAgingIntervalSectionState();
}

class _ReportAgingIntervalSectionState extends State<ReportAgingIntervalSection> {
  static const double _screenPadding = AppTheme.space8;
  static const double _popupGap = 0;
  static const double _preferredPopupWidth = 272;
  static const double _popupMaxHeight = 306;
  static const double _pointerWidth = 14;
  static const double _pointerHeight = 8;

  final LayerLink _dropdownLayerLink = LayerLink();
  final GlobalKey _dropdownAnchorKey = GlobalKey();
  
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isDisposing = false;
  bool _overlayRebuildScheduled = false;

  late String _selectedCount;
  late String _intervalValue;
  late String _selectedUnit;
  late TextEditingController _intervalValueController;
  final FocusNode _intervalFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _parseCurrentValue();
    _intervalValueController = TextEditingController(text: _intervalValue);
    _intervalFocusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (_isDisposing || !mounted) return;
    _scheduleOverlayNeedsBuild();
  }


  @override
  void didUpdateWidget(covariant ReportAgingIntervalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _parseCurrentValue();
      _intervalValueController.text = _intervalValue;
    }
  }

  void _parseCurrentValue() {
    final match = RegExp(
      r'(\d+)\s*x\s*(\d+)\s*(\w+)?',
      caseSensitive: false,
    ).firstMatch(widget.selectedValue);
    if (match != null) {
      _selectedCount = match.group(1) ?? '6';
      _intervalValue = match.group(2) ?? '3';
      final rawUnit = match.group(3)?.toLowerCase() ?? 'days';
      if (rawUnit.startsWith('week')) {
        _selectedUnit = 'Weeks';
      } else if (rawUnit.startsWith('month')) {
        _selectedUnit = 'Months';
      } else if (rawUnit.startsWith('year')) {
        _selectedUnit = 'Years';
      } else {
        _selectedUnit = 'Days';
      }
    } else {
      _selectedCount = '6';
      _intervalValue = '3';
      _selectedUnit = 'Days';
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _removeOverlay(updateState: false);
    _intervalValueController.dispose();
    _intervalFocusNode.removeListener(_handleFocusChanged);
    _intervalFocusNode.dispose();
    super.dispose();
  }

  void _togglePopup() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted || _isDisposing || _overlayEntry != null) return;

    _parseCurrentValue();
    _intervalValueController.text = _intervalValue;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_overlayEntry!);

    if (!mounted || _isDisposing) return;
    setState(() => _isOpen = true);
  }

  void _removeOverlay({bool updateState = true}) {
    _overlayRebuildScheduled = false;
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      if (entry.mounted) {
        entry.remove();
      }
      entry.dispose();
    }
    if (updateState && mounted && !_isDisposing && _isOpen) {
      setState(() => _isOpen = false);
    }
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

  void _applyValue() {
    final cleanValue = _intervalValueController.text.trim();
    final parsedVal = int.tryParse(cleanValue) ?? 3;
    final newValue = '$_selectedCount X $parsedVal $_selectedUnit';
    widget.onChanged?.call(newValue);
    _removeOverlay();
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

    const popupWidth = _preferredPopupWidth;
    const popupHeight = _popupMaxHeight + _pointerHeight;
    final placement = _calculateOverlayPlacement(
      anchorBox: anchorRenderObject,
      overlayWidth: popupWidth,
      overlayHeight: popupHeight,
    );

    final countOptions = List<String>.generate(12, (i) => '${i + 1}');
    final unitOptions = const <String>['Days', 'Weeks', 'Months', 'Years'];

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _removeOverlay(),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(_pointerWidth, _pointerHeight),
                  painter: _AgingIntervalPopupPointerPainter(
                    color: AppTheme.backgroundColor,
                    borderColor: AppTheme.borderLight,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: popupWidth,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.space8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: AppTheme.bgHover,
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.space16,
                            AppTheme.space12,
                            AppTheme.space16,
                            AppTheme.space12,
                          ),
                          child: Text(
                            'Aging Intervals',
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.space16,
                            AppTheme.space16,
                            AppTheme.space16,
                            AppTheme.space14,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: AppTheme.buttonHeight,
                                child: FormDropdown<String>(
                                  value: _selectedCount,
                                  items: countOptions,
                                  hint: 'Select count',
                                  onChanged: (val) {
                                    if (val != null) {
                                      _selectedCount = val;
                                      _markOverlayNeedsBuild();
                                    }
                                  },
                                  showSearch: true,
                                  showSearchIcon: true,
                                  showCustomValueAction: false,
                                  menuWidth: popupWidth - (AppTheme.space16 * 2),
                                  menuMaxHeight: 180,
                                  itemHeight: 40,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space16),
                              Text(
                                'Intervals of',
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Container(
                                height: AppTheme.buttonHeight,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(AppTheme.space8),
                                  border: Border.all(
                                    color: _intervalFocusNode.hasFocus
                                        ? AppTheme.primaryBlue
                                        : AppTheme.borderLight,
                                    width: _intervalFocusNode.hasFocus ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _intervalValueController,
                                        focusNode: _intervalFocusNode,
                                        keyboardType: TextInputType.number,
                                        style: AppTheme.bodyText,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.space12,
                                            vertical: AppTheme.space10,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, color: AppTheme.borderLight),
                                    SizedBox(
                                      width: 78,
                                      height: double.infinity,
                                      child: FormDropdown<String>(
                                        value: _selectedUnit,
                                        items: unitOptions,
                                        hint: 'Unit',
                                        onChanged: (val) {
                                          if (val != null) {
                                            _selectedUnit = val;
                                            _markOverlayNeedsBuild();
                                          }
                                        },
                                        showSearch: false,
                                        hideBorderDefault: true,
                                        fillColor: const Color(0xFFF3F4F6),
                                        showLeftBorder: false,
                                        showRightBorder: false,
                                        border: Border.all(color: Colors.transparent),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.space16,
                            AppTheme.space14,
                            AppTheme.space16,
                            AppTheme.space14,
                          ),
                          child: Row(
                            children: [
                              _CompactAgingButton(
                                child: ZButton.primary(
                                  label: 'Apply',
                                  onPressed: _applyValue,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              _CompactAgingButton(
                                child: ZButton.secondary(
                                  label: 'Cancel',
                                  onPressed: () => _removeOverlay(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

    return CompositedTransformTarget(
      link: _dropdownLayerLink,
      child: Focus(
        key: _dropdownAnchorKey,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _togglePopup,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space4,
                vertical: AppTheme.space6,
              ),
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.calendarDays,
                    size: AppTheme.space16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space6),
                  Text('Aging Intervals : ', style: labelStyle),
                  Text(widget.selectedValue, style: valueStyle),
                  const SizedBox(width: AppTheme.space4),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: AppTheme.space16,
                    color: AppTheme.textSecondary,
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

class _CompactAgingButton extends StatelessWidget {
  final Widget child;

  const _CompactAgingButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.84,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _AgingIntervalPopupPointerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;

  const _AgingIntervalPopupPointerPainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawShadow(path, shadowColor, 2, false);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(
      borderPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _AgingIntervalPopupPointerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
