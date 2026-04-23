import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZerpaiDatePickerStyle {
  static const double popupWidth = 280;
  static const double popupPadding = 16;
  static const double popupRadius = 4;
  static const double popupOffsetY = 4;
  static const double headerBottomPadding = 8;
  static const double sectionSpacing = 16;
  static const double weekdaySpacing = 8;
  static const double dayCellSize = 32;
  static const double monthCellWidth = 60;
  static const double monthCellHeight = 40;
  static const double gridCellMargin = 1;
  static const double dayCellVerticalMargin = 2;
  static const double dayCellHorizontalMargin = 2;
  static const double headerTapRadius = 4;
  static const double monthYearCellRadius = 4;
  static const double shadowBlurRadius = 10;
  static const double shadowOpacity = 0.1;

  static const Color surfaceColor = Colors.white;
  static const Color borderColor = AppTheme.borderColor;
  static const Color titleColor = AppTheme.textBody;
  static const Color iconColor = AppTheme.textSecondary;
  static const Color weekdayColor = AppTheme.textMuted;
  static const Color adjacentMonthTextColor = AppTheme.borderColor;
  static const Color disabledTextColor = AppTheme.borderColor;
  static const Color selectedTextColor = Colors.white;

  static const TextStyle headerTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: titleColor,
  );

  static const TextStyle weekdayTextStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: weekdayColor,
  );

  static const TextStyle gridTextStyle = TextStyle(fontSize: 13);

  static List<BoxShadow> popupShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: shadowOpacity),
      blurRadius: shadowBlurRadius,
      offset: const Offset(0, 4),
    ),
  ];

  static Color get accentColor => AppTheme.primaryBlue;

  static Color get selectedFillColor => accentColor;

  static Color get disabledSelectedFillColor =>
      accentColor.withValues(alpha: 0.3);

  static Color get todayOutlineColor => accentColor;

  static Color get disabledTodayOutlineColor =>
      accentColor.withValues(alpha: 0.3);
}
