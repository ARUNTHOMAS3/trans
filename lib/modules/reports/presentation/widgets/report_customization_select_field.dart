import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportCustomizationSelectField extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final IconData? leadingIcon;

  const ReportCustomizationSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppTheme.space64 * 4,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppTheme.textSecondary,
        ),
        decoration: InputDecoration(
          prefixIcon: leadingIcon == null
              ? null
              : Icon(
                  leadingIcon,
                  size: AppTheme.space18,
                  color: AppTheme.textPrimary,
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space12,
          ),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}
