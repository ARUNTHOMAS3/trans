// PATH: lib/core/services/env_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment variable service for type-safe access to .env values
class EnvService {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  // Supabase Configuration
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    return key;
  }

  // Application Environment
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
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
