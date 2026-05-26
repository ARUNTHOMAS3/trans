import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SettingsPlaceholderPage extends StatelessWidget {
  const SettingsPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This settings module is under safe phased migration.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
