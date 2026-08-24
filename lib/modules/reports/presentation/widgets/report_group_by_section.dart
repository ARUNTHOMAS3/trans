import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';

class ReportGroupBySection extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String>? onChanged;
  final List<String> options;
  final String label;
  final IconData leadingIcon;
  final bool showClearAction;

  const ReportGroupBySection({
    super.key,
    this.selectedValue = 'None',
    this.onChanged,
    this.options = const <String>['None', 'Item Group', 'Category'],
    this.label = 'Group By',
    this.leadingIcon = Icons.inventory_2_outlined,
    this.showClearAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownOptions = [
      'None',
      ...options.where((option) => option.trim().toLowerCase() != 'none'),
    ];

    final valueStyle = selectedValue == 'None'
        ? AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          )
        : AppTheme.bodyText.copyWith(color: AppTheme.textPrimary);

    final dropdown = ReportSearchableFilterDropdown(
      label: label,
      value: selectedValue,
      options: dropdownOptions,
      onChanged: (nextValue) => onChanged?.call(nextValue),
      width: 234, // Width constraint required by FormDropdown
      menuWidth: 302,
      menuMaxHeight: 228,
      leadingIcon: leadingIcon,
      labelColor: AppTheme.textSecondary,
      showLabel: true,
      fillColor: AppTheme.transparent,
      hideBorderDefault: true,
      showLeftBorder: false,
      showRightBorder: false,
      clipActiveBorder: true,
      activeBorderCoverColor: AppTheme.backgroundColor,
      activeBorderCoverThickness: AppTheme.space6,
      allowClear: showClearAction && selectedValue != 'None',
      isHovered: showClearAction && selectedValue != 'None',
      valueTextStyle: valueStyle,
    );

    final labelStyle = AppTheme.bodyText.copyWith(
      color: AppTheme.textSecondary,
      fontWeight: FontWeight.w500,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visible custom trigger exactly matching Compare With
          Container(
            height: AppTheme.buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
            decoration: const BoxDecoration(
              color: AppTheme.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  leadingIcon,
                  size: AppTheme.space16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.space6),
                Text('$label : ', style: labelStyle),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(selectedValue, style: valueStyle),
                      const SizedBox(width: AppTheme.space4),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: AppTheme.space16,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Invisible actual dropdown to handle popup and state
          Positioned.fill(
            child: Opacity(
              opacity: 0.01,
              child: dropdown,
            ),
          ),
        ],
      ),
    );
  }
}