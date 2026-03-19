import 'package:flutter/material.dart';
import '../../theme/text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class FormTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboard;
  final int maxLines;
  final bool enabled;

  const FormTextInput({
    super.key,
    required this.controller,
    this.hint,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      enabled: enabled,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppTheme.primaryBlueDark, width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
    );
  }
}
