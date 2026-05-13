// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../theme/text_styles.dart';

class FormRadio extends StatelessWidget {
  final String label;
  final bool value;

  const FormRadio({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<bool>(value: value),
        Text(label, style: AppTextStyles.input),
      ],
    );
  }
}
