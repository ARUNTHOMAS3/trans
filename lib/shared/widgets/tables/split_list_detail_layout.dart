import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SplitListDetailLayout extends StatelessWidget {
  const SplitListDetailLayout({
    super.key,
    required this.leftHeader,
    required this.leftBody,
    required this.rightBody,
    this.leftWidth = 380,
    this.rightHeader,
  });

  final Widget leftHeader;
  final Widget leftBody;
  final Widget? rightHeader;
  final Widget rightBody;
  final double leftWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: leftWidth,
          child: Column(
            children: [
              leftHeader,
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(child: leftBody),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppTheme.borderColor),
        Expanded(
          child: Column(
            children: [
              if (rightHeader != null) rightHeader!,
              if (rightHeader != null)
                const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(child: rightBody),
            ],
          ),
        ),
      ],
    );
  }
}
