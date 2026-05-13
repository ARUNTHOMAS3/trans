import 'package:flutter/material.dart';
import 'zerpai_layout.dart';
import '../../core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: title,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space32),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.construction,
                size: 64,
                color: AppTheme.primaryBlue.withAlpha(128),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              '$title Module',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            const Text(
              'This module is currently under development.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
