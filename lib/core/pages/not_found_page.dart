// PATH: lib/core/pages/not_found_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class NotFoundPage extends StatelessWidget {
  final String? requestedRoute;

  const NotFoundPage({super.key, this.requestedRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.errorRed,
                  ),
                ),

                SizedBox(height: 32),

                // Error Code
                Text(
                  '404',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                    fontSize: 64,
                  ),
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  'Page Not Found',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 12),

                // Description
                Text(
                  requestedRoute != null
                      ? 'The page "$requestedRoute" could not be found.'
                      : 'The page you are looking for could not be found.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                Text(
                  'It may have been moved, deleted, or the URL might be incorrect.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                // Action Buttons
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/dashboard'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Go to Dashboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Go Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Help Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Need Help?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'If you believe this is an error, please contact your system administrator.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Footer
                Text(
                  'ZerpAI ERP System',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
