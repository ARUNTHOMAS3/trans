import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class ReportSearchableFilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final double width;
  final double? menuWidth;
  final double menuMaxHeight;
  final Widget? labelSuffix;
  final IconData? leadingIcon;
  final bool showLabel;
  final Color? fillColor;
  final BoxBorder? border;
  final bool hideBorderDefault;
  final bool showLeftBorder;
  final bool showRightBorder;
  final bool clipActiveBorder;
  final Color? activeBorderCoverColor;
  final double activeBorderCoverThickness;
  final bool allowClear;
  final Color? labelColor;
  final bool isHovered;
  final TextStyle? valueTextStyle;

  const ReportSearchableFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 234,
    this.menuWidth,
    this.menuMaxHeight = 172,
    this.labelSuffix,
    this.leadingIcon,
    this.showLabel = true,
    this.fillColor,
    this.border,
    this.hideBorderDefault = false,
    this.showLeftBorder = true,
    this.showRightBorder = true,
    this.clipActiveBorder = false,
    this.activeBorderCoverColor,
    this.activeBorderCoverThickness = 2,
    this.allowClear = false,
    this.labelColor,
    this.isHovered = false,
    this.valueTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedFillColor = fillColor ?? AppTheme.bgLight;
    final dropdown = FormDropdown<String>(
      height: AppTheme.buttonHeight,
      value: value,
      items: options,
      hint: 'Search',
      placeholder: 'Search',
      onChanged: (nextValue) {
        final resolvedValue = nextValue ?? 'None';
        if (resolvedValue == value) return;
        onChanged(resolvedValue);
      },
      showSearch: true,
      showSearchIcon: true,
      allowClear: allowClear,
      showCustomValueAction: false,
      forceDownward: true,
      suppressActiveBorder: hideBorderDefault,
      menuWidth: menuWidth ?? width,
      menuMaxHeight: menuMaxHeight,
      itemHeight: 48,
      borderRadius: BorderRadius.circular(AppTheme.space8),
      fillColor: resolvedFillColor,
      border: border,
      hideBorderDefault: hideBorderDefault,
      showLeftBorder: showLeftBorder,
      showRightBorder: showRightBorder,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
      iconSize: AppTheme.space18,
      prefixWidget: _buildPrefixWidget(),
      textStyle: valueTextStyle ?? AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
      displayStringForValue: (option) =>
          (allowClear && option != 'None') ? '$option  |' : option,
      searchStringForValue: (option) => option,
      isHovered: isHovered,
      itemBuilder: (option, isSelected, isHovered) {
        final textColor = isHovered
            ? AppTheme.backgroundColor
            : AppTheme.textPrimary;
        final iconColor = isHovered
            ? AppTheme.backgroundColor
            : AppTheme.primaryBlue;

        return SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppTheme.space8),
                  Icon(Icons.check, size: AppTheme.space16, color: iconColor),
                ],
              ],
            ),
          ),
        );
      },
    );

    final shouldClipActiveBorder = clipActiveBorder || hideBorderDefault;
    if (!shouldClipActiveBorder) {
      return SizedBox(width: width, child: dropdown);
    }

    final coverColor = activeBorderCoverColor ??
        (resolvedFillColor == AppTheme.transparent ||
                resolvedFillColor == Colors.transparent
            ? AppTheme.backgroundColor
            : resolvedFillColor);
    final coverThickness =
        activeBorderCoverThickness < AppTheme.inputActiveBorderWidth + 2
            ? AppTheme.inputActiveBorderWidth + 2
            : activeBorderCoverThickness;

    return SizedBox(
      width: width,
      height: AppTheme.buttonHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: dropdown),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                height: coverThickness,
                color: coverColor,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: coverThickness,
                color: coverColor,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: coverThickness,
                color: coverColor,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: coverThickness,
                color: coverColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildPrefixWidget() {
    final icon = leadingIcon == null
        ? null
        : Icon(
            leadingIcon,
            size: AppTheme.space16,
            color: AppTheme.textSecondary,
          );

    if (!showLabel) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon,
          const SizedBox(width: AppTheme.space6),
        ],
        if (labelSuffix == null)
          Text(
            '$label :',
            style: AppTheme.bodyText.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          )
        else ...[
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          labelSuffix!,
          Text(
            ' :',
            style: AppTheme.bodyText.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
