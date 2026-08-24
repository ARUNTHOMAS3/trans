import 'package:flutter/material.dart';

import 'package:zerpai_erp/core/theme/app_theme.dart';

class CnGridHeader extends StatelessWidget {
  final String label;
  final bool center;

  const CnGridHeader({super.key, required this.label, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
