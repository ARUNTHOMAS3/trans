import 'package:flutter/material.dart';

class AppTextStyles {
  // Prevent instantiation
  const AppTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF111827),
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF6B7280),
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: Color(0xFF374151),
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Color(0xFF374151),
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    color: Color(0xFF6B7280),
  );

  static const TextStyle labelRequired = TextStyle(
    fontSize: 13,
    color: Color(0xFFE11D48),
    fontWeight: FontWeight.w600,
  );

  static const TextStyle input = TextStyle(
    fontSize: 13,
    color: Color(0xFF111827),
  );

  static const TextStyle hint = TextStyle(
    fontSize: 13,
    color: Color(0xFF9CA3AF),
  );

  /// Used for top bar titles like "Welcome To Zerpai"
  static const TextStyle topBarTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF111827),
  );

  /// Small helper / caption text
  static const TextStyle helper = TextStyle(
    fontSize: 11,
    color: Color(0xFF6B7280),
  );
}
