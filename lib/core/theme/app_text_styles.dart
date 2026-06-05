import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class AppTextStyles {
  // Prevent instantiation
  const AppTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: AppTheme.textBody,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppTheme.textBody,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    color: AppTheme.textSecondary,
  );

  static const TextStyle labelRequired = TextStyle(
    fontSize: 13,
    color: AppTheme.errorRed,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle input = TextStyle(
    fontSize: 13,
    color: AppTheme.textPrimary,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 13,
    color: AppTheme.textMuted,
  );

  /// Used for top bar titles like "Welcome To Zerpai"
  static const TextStyle topBarTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  /// Small helper / caption text
  static const TextStyle helper = TextStyle(
    fontSize: 11,
    color: AppTheme.textSecondary,
  );
}
