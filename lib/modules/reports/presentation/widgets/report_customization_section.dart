import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportCustomizationSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String? helperText;
  final bool showTopDivider;

  const ReportCustomizationSection({
    super.key,
    required this.title,
    required this.child,
    this.helperText,
    this.showTopDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTopDivider) const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space24,
            AppTheme.space20,
            AppTheme.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.sectionHeader,
              ),
              if (helperText != null) ...[
                const SizedBox(height: AppTheme.space8),
                Text(
                  helperText!,
                  style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: AppTheme.space12),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
