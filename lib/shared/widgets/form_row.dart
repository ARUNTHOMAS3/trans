import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class FormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final String? helper;

  const FormRow({
    super.key,
    required this.label,
    this.required = false,
    required this.child,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(
                required ? "$label *" : label,
                style: required
                    ? AppTextStyles.labelRequired
                    : AppTextStyles.label,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child,

                  if (helper != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(helper!, style: AppTextStyles.helper),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
