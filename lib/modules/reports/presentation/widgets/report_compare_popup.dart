import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ReportComparePopup extends StatelessWidget {
  final double width;
  final String? compareType;
  final String countValue;
  final bool arrangeLatestFirst;
  final ValueChanged<String?> onCompareTypeChanged;
  final ValueChanged<String?> onCountChanged;
  final ValueChanged<bool?> onArrangeChanged;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  static const double _pointerWidth = 14;
  static const double _pointerHeight = 8;
  static const double _collapsedHeight = 154;
  static const double _expandedHeight = 272;

  const ReportComparePopup({
    super.key,
    required this.width,
    required this.compareType,
    required this.countValue,
    required this.arrangeLatestFirst,
    required this.onCompareTypeChanged,
    required this.onCountChanged,
    required this.onArrangeChanged,
    required this.onApply,
    required this.onCancel,
  });

  static const List<String> _compareOptions = <String>[
    'Previous Year(s)',
    'Previous Period(s)',
  ];

  static double estimatedHeightFor(String? compareType) {
    return compareType == null ? _collapsedHeight : _expandedHeight;
  }

  List<String> get _countOptions {
    return const <String>['1', '2', '3', '4', '5'];
  }

  @override
  Widget build(BuildContext context) {
    final popupRadius = BorderRadius.circular(6);
    final titleStyle = AppTheme.bodyText.copyWith(
      fontWeight: FontWeight.w500,
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(_pointerWidth, _pointerHeight),
            painter: _ComparePopupPointerPainter(
              color: AppTheme.backgroundColor,
              borderColor: AppTheme.borderColor,
              shadowColor: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: width,
            constraints: const BoxConstraints(maxWidth: AppTheme.space64 * 4.6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: popupRadius,
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: popupRadius,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
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
                      child: Text('Compare With', style: titleStyle),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
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
                          FormDropdown<String>(
                            height: 36,
                            value: compareType,
                            items: _compareOptions,
                            hint: 'None',
                            onChanged: onCompareTypeChanged,
                            showSearch: false,
                            allowClear: true,
                            menuWidth: width - (AppTheme.space16 * 2),
                            menuMaxHeight: 124,
                            itemHeight: 40,
                            borderRadius: BorderRadius.circular(AppTheme.space8),
                          ),
                          if (compareType != null) ...[
                            const SizedBox(height: AppTheme.space16),
                            _DynamicCompareFields(
                              compareType: compareType!,
                              countValue: countValue,
                              countOptions: _countOptions,
                              arrangeLatestFirst: arrangeLatestFirst,
                              onCountChanged: onCountChanged,
                              onArrangeChanged: onArrangeChanged,
                              menuWidth: width - (AppTheme.space16 * 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space16,
                        AppTheme.space14,
                        AppTheme.space16,
                        AppTheme.space14,
                      ),
                      child: Row(
                        children: [
                          _CompactSharedButton(
                            child: ZButton.primary(
                              label: 'Apply',
                              onPressed: onApply,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          _CompactSharedButton(
                            child: ZButton.secondary(
                              label: 'Cancel',
                              onPressed: onCancel,
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
        ],
      ),
    );
  }
}

class _DynamicCompareFields extends StatelessWidget {
  final String compareType;
  final String countValue;
  final List<String> countOptions;
  final bool arrangeLatestFirst;
  final ValueChanged<String?> onCountChanged;
  final ValueChanged<bool?> onArrangeChanged;
  final double menuWidth;

  const _DynamicCompareFields({
    required this.compareType,
    required this.countValue,
    required this.countOptions,
    required this.arrangeLatestFirst,
    required this.onCountChanged,
    required this.onArrangeChanged,
    required this.menuWidth,
  });

  @override
  Widget build(BuildContext context) {
    final label = compareType == 'Previous Year(s)' ? 'Number of Year(s)' : 'Number of Period(s)';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        FormDropdown<String>(
          height: 36,
          value: countValue,
          items: countOptions,
          hint: countOptions.first,
          onChanged: onCountChanged,
          showSearch: false,
          menuWidth: menuWidth,
          menuMaxHeight: 164,
          itemHeight: 40,
          borderRadius: BorderRadius.circular(AppTheme.space8),
        ),
        const SizedBox(height: AppTheme.space10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: AppTheme.borderColor),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryBlue;
                    }
                    return AppTheme.backgroundColor;
                  }),
                ),
              ),
              child: Checkbox(
                value: arrangeLatestFirst,
                onChanged: onArrangeChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppTheme.space4),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onArrangeChanged(!arrangeLatestFirst),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space2),
                  child: Text(
                    'Arrange period/year from latest to\noldest',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactSharedButton extends StatelessWidget {
  final Widget child;

  const _CompactSharedButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.84,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _ComparePopupPointerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;

  const _ComparePopupPointerPainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawShadow(shadowPath, shadowColor, 2, false);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(shadowPath, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ComparePopupPointerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
