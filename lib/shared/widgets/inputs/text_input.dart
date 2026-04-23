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

  bool _isNumericKeyboard(TextInputType type) {
    final String value = type.toString();
    return value.contains('TextInputType.number');
  }

  bool _isZeroLikeValue(String text) {
    final String trimmed = text.trim();
    return RegExp(r'^0+(?:\.0+)?$').hasMatch(trimmed);
  }

  void _selectAllIfDefaultZero() {
    if (!_isNumericKeyboard(keyboard)) return;

    final String text = controller.text;
    if (text.isEmpty || !_isZeroLikeValue(text)) return;

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      enabled: enabled,
      onTap: _selectAllIfDefaultZero,
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
          borderSide: const BorderSide(
            color: AppTheme.borderColor,
            width: AppTheme.inputBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: AppTheme.primaryBlueDark,
            width: AppTheme.inputActiveBorderWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: AppTheme.inputBorderWidth,
          ),
        ),
      ),
    );
  }
}
