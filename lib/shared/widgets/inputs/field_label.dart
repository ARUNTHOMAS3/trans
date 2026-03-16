import 'package:flutter/material.dart';
import '../../theme/text_styles.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel({super.key, required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      required ? "$text *" : text,
      style: required ? AppTextStyles.labelRequired : AppTextStyles.label,
    );
  }
}
