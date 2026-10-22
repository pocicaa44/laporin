import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration.
/// Safely loads from .env without hardcoding credentials in source code.
class AppConfig {
  AppConfig._();

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // If .env is missing or fails to load, gracefully continue with empty values.
    }
  }

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String get googleWebClient =>
      (dotenv.maybeGet('web_client') ?? dotenv.maybeGet('WEB_CLIENT') ?? '')
          .trim();
  static String get googleAndroidClient =>
      (dotenv.maybeGet('android_client') ??
              dotenv.maybeGet('ANDROID_CLIENT') ??
              '')
          .trim();
  static String get googleIosClient =>
      (dotenv.maybeGet('ios_client') ?? dotenv.maybeGet('IOS_CLIENT') ?? '')
          .trim();

  static bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
