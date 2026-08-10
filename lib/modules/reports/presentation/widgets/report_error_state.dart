import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ReportErrorState({
    super.key,
    this.title = 'Unable to load report',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space64),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: AppTheme.space32, color: AppTheme.errorRed),
            const SizedBox(height: AppTheme.space16),
            Text(title, style: AppTheme.sectionHeader),
            const SizedBox(height: AppTheme.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.space16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
