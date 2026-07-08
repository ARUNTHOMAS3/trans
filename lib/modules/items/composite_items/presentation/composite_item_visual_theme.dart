import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class CompositeItemVisualTheme extends StatelessWidget {
  final Widget child;

  const CompositeItemVisualTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: Colors.white,
        dividerColor: AppTheme.borderLight,
        visualDensity: VisualDensity.standard,
        textTheme: base.textTheme.copyWith(
          titleLarge: AppTheme.pageTitle.copyWith(fontSize: 24),
          titleMedium: AppTheme.sectionHeader.copyWith(fontSize: 16),
          bodyLarge: AppTheme.bodyText.copyWith(fontSize: 14),
          bodyMedium: AppTheme.bodyText.copyWith(fontSize: 13),
          bodySmall: AppTheme.metaHelper.copyWith(fontSize: 12),
          labelLarge: AppTheme.buttonText.copyWith(fontSize: 14),
          labelMedium: AppTheme.tableHeader.copyWith(
            fontSize: 12,
            letterSpacing: .3,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: AppTheme.borderColor, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppTheme.primaryBlue
                : Colors.white,
          ),
          checkColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashRadius: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(
              color: AppTheme.primaryBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
