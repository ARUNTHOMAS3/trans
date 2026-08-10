import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final Widget? illustration;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final double illustrationGap;
  final double titleMessageGap;

  const ReportEmptyState({
    super.key,
    this.title = 'No report data',
    this.message = 'No rows were returned for the current filters.',
    this.illustration,
    this.padding = const EdgeInsets.symmetric(vertical: AppTheme.space64),
    this.titleStyle,
    this.messageStyle,
    this.illustrationGap = AppTheme.space16,
    this.titleMessageGap = AppTheme.space8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                const Icon(
                  LucideIcons.fileSearch,
                  size: AppTheme.space32,
                  color: AppTheme.textSecondary,
                ),
            SizedBox(height: illustrationGap),
            Text(title, textAlign: TextAlign.center, style: titleStyle ?? AppTheme.sectionHeader),
            SizedBox(height: titleMessageGap),
            Text(
              message,
              textAlign: TextAlign.center,
              style: messageStyle ?? AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportTableEmptyBody extends StatelessWidget {
  final double minHeight;
  final String message;

  const ReportTableEmptyBody({
    super.key,
    this.minHeight = 300,
    this.message = 'No data to display',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space24,
        vertical: AppTheme.space32,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
