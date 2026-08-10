import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportPageHeader extends StatelessWidget {
  final String categoryLabel;
  final String title;
  final String dateLabel;
  final Widget toolbar;
  final VoidCallback? onLeadingPressed;

  const ReportPageHeader({
    super.key,
    required this.categoryLabel,
    required this.title,
    required this.dateLabel,
    required this.toolbar,
    this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.space8),
            child: InkWell(
              onTap: onLeadingPressed,
              borderRadius: BorderRadius.circular(AppTheme.space8),
              child: Container(
                width: AppTheme.space40,
                height: AppTheme.space40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.space8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Icon(
                  LucideIcons.panelLeft,
                  size: AppTheme.space18,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoryLabel, style: AppTheme.metaHelper),
                const SizedBox(height: AppTheme.space4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppTheme.space10,
                  runSpacing: AppTheme.space4,
                  children: [
                    Text(title, style: AppTheme.pageTitle.copyWith(fontSize: 18)),
                    Text('•', style: AppTheme.metaHelper),
                    Text(dateLabel, style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Flexible(child: toolbar),
        ],
      ),
    );
  }
}
