// PATH: lib/core/services/env_service.dart

/// Build-time configuration service for public client settings.
/// Runtime dotenv loading is intentionally unsupported for Flutter Web.
class EnvService {
  static Future<void> initialize() async {}

  // Supabase Configuration
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    if (url.isEmpty) {
      throw Exception('SUPABASE_URL was not supplied via --dart-define');
    }
    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY was not supplied via --dart-define');
    }
    return key;
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
