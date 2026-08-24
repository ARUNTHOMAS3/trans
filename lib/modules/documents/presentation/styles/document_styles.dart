import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class DocumentStyles {
  const DocumentStyles._();

  static const Color surface = AppTheme.backgroundColor;
  static const Color transparent = AppTheme.transparent;
  static const Color surface70 = Color(0xB3FFFFFF);
  static const Color surface60 = Color(0x99FFFFFF);
  static const Color surface38 = Color(0x61FFFFFF);
  static const Color surface30 = Color(0x4DFFFFFF);
  static const Color surface24 = Color(0x3DFFFFFF);
  static const Color shadowMedium = Color(0x42000000);
  static const Color primary = AppTheme.primaryBlue;
  static const Color primaryDark = AppTheme.primaryBlueDark;
  static const Color focusBlue = Color(0xFF1E88E5);
  static const Color success = AppTheme.successGreen;
  static const Color successDark = AppTheme.successTextDark;
  static const Color error = AppTheme.errorRed;
  static const Color requiredText = Color(0xFFC5221F);

  static const Color headerBg = AppTheme.bgLight;
  static const Color chipBg = AppTheme.bgHover;
  static const Color subtleSurface = AppTheme.bgLight;
  static const Color processedBg = Color(0xFFE6F4EA);
  static const Color processedText = Color(0xFF137333);
  static const Color unreadableBg = Color(0xFFFCE8E6);
  static const Color warningBg = Color(0xFFFEF7E0);
  static const Color warningText = Color(0xFFB06000);
  static const Color folderInfoBg = Color(0xFFE8F0FE);

  static const Color previewBackdrop = Color(0xFF0F1115);
  static const Color previewHeader = Color(0xFF1E222B);
  static const Color previewToolbar = Color(0xFF2A2E39);
  static const Color previewControl = Color(0xFF2C313C);
  static const Color previewPdfHeader = Color(0xFF1A1D24);

  static const Color envelopeBack = Color(0xFF60A5FA);
  static const Color envelopePaper = Color(0xFFFCD34D);
  static const Color documentGreen = Color(0xFF1D6F42);

  static TextStyle get dialogTitle =>
      AppTheme.textPrimaryStyle(15, FontWeight.bold);

  static TextStyle get fieldLabel =>
      AppTheme.tableCell.copyWith(fontWeight: FontWeight.w500);

  static TextStyle get requiredLabel => fieldLabel.copyWith(
        color: requiredText,
      );

  static TextStyle get requiredAsterisk => AppTheme.tableCell.copyWith(
        fontWeight: FontWeight.bold,
        color: requiredText,
      );

  static TextStyle get body13 =>
      AppTheme.tableCell.copyWith(fontSize: 13);

  static TextStyle get body13Secondary =>
      body13.copyWith(color: AppTheme.textSecondary);

  static TextStyle get body13Medium =>
      body13.copyWith(fontWeight: FontWeight.w500);

  static TextStyle get smallButton =>
      AppTheme.captionText.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get smallButtonOnPrimary =>
      smallButton.copyWith(color: surface);

  static TextStyle get smallBadge =>
      AppTheme.captionText.copyWith(fontSize: 10, fontWeight: FontWeight.w600);

  static TextStyle get sectionCaption =>
      AppTheme.captionText.copyWith(fontWeight: FontWeight.bold);

  static TextStyle get tooltipText => AppTheme.metaHelper.copyWith(
        color: surface,
        height: 1.4,
      );
}