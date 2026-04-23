// PATH: lib/core/pages/unauthorized_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class UnauthorizedPage extends StatelessWidget {
  final String? requiredPermission;

  const UnauthorizedPage({super.key, this.requiredPermission});

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
                // Warning Icon
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    size: 80,
                    color: AppTheme.warningOrange,
                  ),
                ),

                SizedBox(height: 32),

                // Error Code
                Text(
                  '403',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningOrange,
                    fontSize: 64,
                  ),
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  'Access Denied',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 12),

                // Description
                Text(
                  requiredPermission != null
                      ? 'You don\'t have permission to access this resource.'
                      : 'You don\'t have sufficient privileges to view this page.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                if (requiredPermission != null)
                  Text(
                    'Required permission: $requiredPermission',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w500,
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
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dashboard,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Go to Dashboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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

                // Contact Admin Section
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
                        Icons.contact_support,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Contact Administrator',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'If you believe you should have access to this resource, '
                        'please contact your system administrator to request the necessary permissions.',
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
                  'ZerpAI ERP System • Access Control',
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
