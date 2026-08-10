import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Reports-only table typography aligned with the Purchase Orders table header.
class ReportTableTypography {
  const ReportTableTypography._();

  static TextStyle get header => AppTheme.metaHelper.copyWith(
        fontWeight: FontWeight.bold,
      );
}
