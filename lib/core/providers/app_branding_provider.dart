import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const String _kAccentKey = 'branding_accent';
const String _kThemeModeKey = 'branding_theme';

/// Reads cached branding synchronously from the already-open 'config' Hive box.
/// Returns defaults if no cached value exists.
BrandingSettings loadCachedBranding() {
  try {
    final box = Hive.box('config');
    final accentHex =
        (box.get(_kAccentKey) as String?) ?? '#22A95E';
    final themeMode =
        (box.get(_kThemeModeKey) as String?) ?? 'dark';
    final clean = accentHex.replaceAll('#', '');
    final colorVal = int.tryParse('FF$clean', radix: 16);
    return BrandingSettings(
      accentColor: colorVal != null ? Color(colorVal) : const Color(0xFF22A95E),
      isDarkPane: themeMode != 'light',
    );
  } catch (_) {
    return const BrandingSettings();
  }
}

/// Holds the current live branding preferences — theme mode and accent color.
/// Updated immediately on selection; persisted to DB on Save.
class BrandingSettings {
  final Color accentColor;
  final bool isDarkPane;

  const BrandingSettings({
    this.accentColor = const Color(0xFF22A95E),
    this.isDarkPane = true,
  });

  BrandingSettings copyWith({Color? accentColor, bool? isDarkPane}) =>
      BrandingSettings(
        accentColor: accentColor ?? this.accentColor,
        isDarkPane: isDarkPane ?? this.isDarkPane,
      );

  // Sidebar background
  Color get sidebarBg =>
      isDarkPane ? const Color(0xFF1F2637) : Colors.white;

  // Collapse-toggle button background
  Color get collapseToggleBg =>
      isDarkPane ? const Color(0xFF2B3040) : const Color(0xFFE5E7EB);

  // Item hover background
  Color get itemHoverBg =>
      isDarkPane ? const Color(0xFF3A3F4F) : const Color(0xFFE5E7EB);

  // Active parent background (not a leaf destination)
  Color get activeParentBg =>
      isDarkPane ? const Color(0xFF2A3A55) : const Color(0xFFEFF6FF);

  // Item foreground (text + icons)
  Color get itemFg =>
      isDarkPane ? Colors.white : const Color(0xFF1F2937);

  // Muted foreground (inactive labels, arrows)
  Color get itemFgMuted =>
      isDarkPane ? Colors.white70 : const Color(0xFF6B7280);
}

class AppBrandingNotifier extends StateNotifier<BrandingSettings> {
  AppBrandingNotifier(BrandingSettings initial) : super(initial);

  void setAccentColor(Color color) =>
      state = state.copyWith(accentColor: color);

  void setDarkPane(bool isDark) => state = state.copyWith(isDarkPane: isDark);

  void apply({required Color accentColor, required bool isDarkPane}) {
    state = BrandingSettings(accentColor: accentColor, isDarkPane: isDarkPane);
    _persist(accentColor, isDarkPane);
  }

  void _persist(Color color, bool isDark) {
    try {
      final box = Hive.box('config');
      final hex =
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      box.put(_kAccentKey, hex);
      box.put(_kThemeModeKey, isDark ? 'dark' : 'light');
    } catch (_) {}
  }
}

final appBrandingProvider =
    StateNotifierProvider<AppBrandingNotifier, BrandingSettings>(
  (ref) => AppBrandingNotifier(loadCachedBranding()),
);
