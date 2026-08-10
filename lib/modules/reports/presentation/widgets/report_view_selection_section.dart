import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';

class ReportViewSelectionSection extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String>? onChanged;
  final List<String> options;

  const ReportViewSelectionSection({
    super.key,
    this.selectedValue = 'Simplified View',
    this.onChanged,
    this.options = const <String>['Simplified View', 'Detailed View'],
  });

  @override
  Widget build(BuildContext context) {
    return ReportSearchableFilterDropdown(
      label: 'Select Report View',
      value: selectedValue,
      options: options,
      onChanged: (nextValue) => onChanged?.call(nextValue),
      width: _fieldWidthFor(context, 'Select Report View', selectedValue),
      menuWidth: 302,
      menuMaxHeight: 228,
      leadingIcon: LucideIcons.fileSearch,
      labelColor: AppTheme.textSecondary,
      showLabel: true,
      fillColor: AppTheme.transparent,
      hideBorderDefault: true,
      showLeftBorder: false,
      showRightBorder: false,
      clipActiveBorder: true,
      activeBorderCoverColor: AppTheme.backgroundColor,
      activeBorderCoverThickness: AppTheme.space6,
      allowClear: false,
      isHovered: true,
    );
  }

  double _fieldWidthFor(BuildContext context, String label, String value) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double getTextWidth(String text, TextStyle style) {
      textPainter.text = TextSpan(text: text, style: style);
      textPainter.layout();
      return textPainter.size.width;
    }

    final labelStyle = AppTheme.bodyText.copyWith(
      color: AppTheme.textSecondary,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = AppTheme.bodyText.copyWith(color: AppTheme.textPrimary);

    final labelWidth = getTextWidth('$label :', labelStyle);
    final valueWidth = getTextWidth(value, valueStyle);

    return 70.0 + 12.0 + labelWidth + valueWidth;
  }
}
