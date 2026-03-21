// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';

class FormRadio extends StatelessWidget {
  final String label;
  final bool value;

  const FormRadio({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<bool>(value: value),
        Text(
          label,
          style:
              (context
                      .findAncestorWidgetOfExactType<Theme>()
                      ?.data
                      .textTheme
                      .bodyMedium)
                  ?.merge(AppTextStyles.input) ??
              AppTextStyles.input,
        ),
      ],
    );
  }
}
