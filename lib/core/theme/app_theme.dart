import 'package:flutter/material.dart';

/// Global UI System & Design Governance (Section 14 of PRD)
///
/// This theme layer implements strict Section 14 governance as defined in PRD.
/// ALL UI colors, typography, and spacing MUST originate from this centralized layer.
/// No screen, widget, or component is allowed to define raw colors, fonts, or spacing inline.
class AppTheme {
  // --------------------------------------------------------------------------
  // 1. GLOBAL COLOR PALETTE (Section 14.2) - STRICT COMPLIANCE
  // --------------------------------------------------------------------------

  // PRD Section 14.2 REQUIRED COLORS
  static const Color sidebarColor = Color(0xFF1F2633); // Sidebar Background
  static const Color backgroundColor = Color(0xFFFFFFFF); // App Background
  static const Color primaryBlue = Color(
    0xFF3B7CFF,
  ); // Primary Action (EXACT PRD VALUE)
  static const Color accentGreen = Color(
    0xFF27C59A,
  ); // Secondary Action (EXACT PRD VALUE)
  static const Color textPrimary = Color(
    0xFF1F2933,
  ); // Primary Text (EXACT PRD VALUE)
  static const Color textSecondary = Color(
    0xFF6B7280,
  ); // Secondary Text (EXACT PRD VALUE)
  static const Color borderColor = Color(
    0xFFD3D9E3,
  ); // Borders / Dividers (EXACT PRD VALUE)

  // Extended color palette for complete UI coverage
  static const Color primaryBlueDark = Color(
    0xFF2563EB,
  ); // Darker variant for hover states
  static const Color successGreen = Color(
    0xFF28A745,
  ); // Success actions (Zerpai spec)
  static const Color warningOrange = Color(0xFFF59E0B); // Warning states
  static const Color errorRed = Color(
    0xFFD32F2F,
  ); // Error states (EXACT PRD VALUE for required fields)
  static const Color errorRedDark = Color(0xFFC62828); // Darker error variant
  static const Color textMuted = Color(0xFF9CA3AF); // Muted text
  static const Color textHint = Color(0xFF9CA3AF); // Hint text
  static const Color borderColorDark = Color(0xFFBEC5D1); // Darker borders
  static const Color bgLight = Color(0xFFF9FAFB); // Light background
  static const Color bgDisabled = Color(0xFFF3F4F6); // Disabled states
  static const Color bgHover = Color(0xFFF3F4F6); // Hover states

  // Specific UI Component Colors
  static const Color successBg = Color(0xFFDCFCE7); // Success background
  static const Color infoBg = Color(0xFFEFF6FF); // Info background
  static const Color inputFill = Color(
    0xFFFFFFFF,
  ); // Input field fill (pure white)
  static const Color tableHeaderBg = Color(
    0xFFF5F5F5,
  ); // Table header background
  static const Color selectionActiveBg = Color(
    0xFFF0F7FF,
  ); // Selected card background
  static const Color selectionInactiveBg = Color(
    0xFFF9F9F9,
  ); // Inactive card background

  // --------------------------------------------------------------------------
  // 2. LAYOUT & SPACING SYSTEM (Section 14.4)
  // --------------------------------------------------------------------------

  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space18 = 18.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space36 = 36.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space52 = 52.0;
  static const double space64 = 64.0;

  // Common widget dimensions
  static const double buttonHeight = 36.0;
  static const double inputHeight = 40.0;
  static const double iconSize = 20.0;
  static const double iconSizeLarge = 24.0;

  // Form constraints
  static const double formFieldMaxWidth = 400.0;
  static const double formFieldMaxWidthLarge = 700.0;
  static const double formFieldMaxWidthSmall = 200.0;
  static const double formFieldMaxWidthMedium = 350.0;

  // --------------------------------------------------------------------------
  // 3. TYPOGRAPHY RULES (Section 14.3) - NON-NEGOTIABLE
  // --------------------------------------------------------------------------

  // Custom font registration name in pubspec.yaml
  static const String _fontFamily = 'Inter';
  static const List<String> _fontFamilyFallback = <String>[
    'NotoSansFallback',
    'NotoSansSymbols',
    'NotoSansDevanagari',
    'NotoSansBengali',
    'NotoSansGujarati',
    'NotoSansGurmukhi',
    'NotoSansKannada',
    'NotoSansMalayalam',
    'NotoSansOriya',
    'NotoSansTamil',
    'NotoSansTelugu',
  ];

  static TextStyle _baseTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  static TextTheme _applyFontFallbackToTextTheme(TextTheme theme) {
    TextStyle? withFallback(TextStyle? style) {
      if (style == null) return null;
      return style.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
      );
    }

    return theme.copyWith(
      displayLarge: withFallback(theme.displayLarge),
      displayMedium: withFallback(theme.displayMedium),
      displaySmall: withFallback(theme.displaySmall),
      headlineLarge: withFallback(theme.headlineLarge),
      headlineMedium: withFallback(theme.headlineMedium),
      headlineSmall: withFallback(theme.headlineSmall),
      titleLarge: withFallback(theme.titleLarge),
      titleMedium: withFallback(theme.titleMedium),
      titleSmall: withFallback(theme.titleSmall),
      bodyLarge: withFallback(theme.bodyLarge),
      bodyMedium: withFallback(theme.bodyMedium),
      bodySmall: withFallback(theme.bodySmall),
      labelLarge: withFallback(theme.labelLarge),
      labelMedium: withFallback(theme.labelMedium),
      labelSmall: withFallback(theme.labelSmall),
    );
  }

  // PRD Section 14.3 REQUIRED TYPOGRAPHY
  static TextStyle get pageTitle => TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get sectionHeader => _baseTextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get tableHeader => _baseTextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static TextStyle get tableCell => _baseTextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get metaHelper => _baseTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // Additional typography for complete coverage
  static TextStyle get bodyText => _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get captionText => _baseTextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get buttonText => _baseTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get linkText => _baseTextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: primaryBlue,
    decoration: TextDecoration.underline,
  );

  // --------------------------------------------------------------------------
  // 4. THEME DATA
  // --------------------------------------------------------------------------

  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true);
    final themedText = _applyFontFallbackToTextTheme(
      baseTheme.textTheme
          .apply(
            fontFamily: _fontFamily,
            bodyColor: textPrimary,
            displayColor: textPrimary,
          )
          .copyWith(
            displayLarge: textPrimaryStyle(24, FontWeight.bold),
            titleLarge: pageTitle,
            titleMedium: sectionHeader,
            bodyLarge: bodyText,
            bodyMedium: bodyText,
            labelSmall: metaHelper,
          ),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentGreen,
        surface: backgroundColor,
      ),

      textTheme: themedText,
      primaryTextTheme: _applyFontFallbackToTextTheme(
        baseTheme.primaryTextTheme.apply(
          fontFamily: _fontFamily,
          bodyColor: textPrimary,
          displayColor: textPrimary,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: false,
        titleTextStyle: pageTitle,
        shape: const Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: backgroundColor,
        surfaceTintColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(space4), // PRD SPEC: 4px radius
          side: const BorderSide(color: borderColor),
        ),
      ),

      // ZOHO UI/UX SPEC COMPLIANCE (Section 8.3)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill, // PRD SPEC: Pure white #FFFFFF
        border: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
          ), // PRD SPEC: #E0E0E0
          borderRadius: BorderRadius.circular(4), // PRD SPEC: 4px radius
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
          ), // PRD SPEC: #E0E0E0
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFF0088FF),
            width: 1.5,
          ), // PRD SPEC: #0088FF at 1.5px
          borderRadius: BorderRadius.circular(4),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
            width: 1,
          ), // PRD SPEC: Error red
          borderRadius: BorderRadius.circular(4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ), // PRD SPEC: 12px horizontal, 10px vertical
        hintStyle: metaHelper.copyWith(color: textHint),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              primaryBlue, // Will be overridden for success buttons
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(space4), // PRD SPEC: 4px radius
          ),
          textStyle: buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: linkText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(space4),
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Table theme for Zerpai-like appearance
      dataTableTheme: DataTableThemeData(
        headingTextStyle: tableHeader,
        dataTextStyle: tableCell,
        headingRowColor: WidgetStateColor.resolveWith(
          (states) => tableHeaderBg,
        ),
        horizontalMargin: 12, // PRD SPEC: 12px horizontal padding
        columnSpacing: 24, // Adequate spacing between columns
        dataRowMinHeight: 40, // Consistent row height
        headingRowHeight: 40, // Consistent header height
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: backgroundColor,
        surfaceTintColor: backgroundColor,
        elevation: 4,
      ),
    );
  }

  // Helper for text styles
  static TextStyle textPrimaryStyle(double size, FontWeight weight) {
    return _baseTextStyle(
      fontSize: size,
      fontWeight: weight,
      color: textPrimary,
    );
  }

  static InputDecoration get inputDecoration => const InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}
