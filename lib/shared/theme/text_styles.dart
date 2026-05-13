import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class AppTextStyles {
  static const label = TextStyle(
    fontSize: 13,
    color: AppTheme.textSecondary,
    fontFamily: 'Inter',
  );

  static const labelRequired = TextStyle(
    fontSize: 13,
    color: AppTheme.errorRed,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  static const input = TextStyle(
    fontSize: 13,
    color: AppTheme.textPrimary,
    fontFamily: 'Inter',
  );

  static const hint = TextStyle(
    fontSize: 13,
    color: AppTheme.textHint,
    fontFamily: 'Inter',
  );

  static TextStyle? helper;
}
