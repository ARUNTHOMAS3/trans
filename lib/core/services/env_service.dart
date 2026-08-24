// PATH: lib/core/services/env_service.dart

import 'package:flutter/services.dart';

/// Public client configuration with dart-define priority and a local fallback.
class EnvService {
  static Map<String, String> _localValues = const {};

  /// Loads ignored local development values when the asset is available.
  ///
  /// Release builds should supply values through `--dart-define`; those values
  /// always override this fallback.
  static Future<void> initialize() async {
    try {
      final contents = await rootBundle.loadString('assets/.env');
      _localValues = _parse(contents);
    } catch (_) {
      // The local asset is deliberately absent in CI and production builds.
      _localValues = const {};
    }
  }

  static Map<String, String> _parse(String contents) {
    final values = <String, String>{};
    for (final rawLine in contents.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final separator = line.indexOf('=');
      if (separator <= 0) continue;

      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        values[key] = _withoutWrappingQuotes(value);
      }
    }
    return Map.unmodifiable(values);
  }

  static String _withoutWrappingQuotes(String value) {
    if (value.length < 2) return value;

    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' || first == "'") && first == last) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static String _value(String definedValue, String key) =>
      definedValue.isNotEmpty ? definedValue : (_localValues[key] ?? '');

  // Supabase Configuration
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    final resolvedUrl = _value(url, 'SUPABASE_URL');
    if (resolvedUrl.isEmpty) {
      throw Exception(
        'SUPABASE_URL is missing. Add it to assets/.env for local development '
        'or pass it via --dart-define.',
      );
    }
    return resolvedUrl;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    final resolvedKey = _value(key, 'SUPABASE_ANON_KEY');
    if (resolvedKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is missing. Add it to assets/.env for local '
        'development or pass it via --dart-define.',
      );
    }
    return resolvedKey;
  }

  // Application Environment
  static String get environment => const String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'development',
      );
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  /// Validate that all required environment variables are present
  static void validate() {
    final errors = <String>[];

    // Check required Supabase variables
    try {
      supabaseUrl;
    } catch (e) {
      errors.add('Missing SUPABASE_URL');
    }

    try {
      supabaseAnonKey;
    } catch (e) {
      errors.add('Missing SUPABASE_ANON_KEY');
    }
    if (errors.isNotEmpty) {
      throw Exception('Environment validation failed:\n${errors.join('\n')}');
    }
  }
}
