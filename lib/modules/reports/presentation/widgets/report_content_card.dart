import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportContentCard extends StatelessWidget {
  final Widget child;

  const ReportContentCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).shadowColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.06),
            blurRadius: AppTheme.space16,
            offset: const Offset(0, AppTheme.space4),
          ),
        ],
      ),
      child: child,
    );
  }
}
