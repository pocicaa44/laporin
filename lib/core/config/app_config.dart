import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration.
/// Safely loads from:
/// 1. Compile-time environment (--dart-define / --dart-define-from-file)
/// 2. Runtime assets (assets/env or .env)
/// 3. Project default configuration
class AppConfig {
  AppConfig._();

  // 1. Compile-time constants via const String.fromEnvironment (resolved at compile time by Dart compiler)
  static const String _constSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _constSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _constWebClient = String.fromEnvironment(
    'web_client',
    defaultValue: String.fromEnvironment('WEB_CLIENT'),
  );
  static const String _constAndroidClient = String.fromEnvironment(
    'android_client',
    defaultValue: String.fromEnvironment('ANDROID_CLIENT'),
  );
  static const String _constIosClient = String.fromEnvironment(
    'ios_client',
    defaultValue: String.fromEnvironment('IOS_CLIENT'),
  );

  // 2. Project Default Configuration Fallback
  static const String _defaultSupabaseUrl =
      'https://ecgnhfkzvivddgbbfajx.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjZ25oZmt6dml2ZGRnYmJmYWp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0OTUwNzgsImV4cCI6MjEwODA3MTA3OH0.cVWMhVBH8iRtcW5x-SkWKUZXIqpizMS5NOXUDKtpTFQ';
  static const String _defaultWebClient =
      '291599246813-0a7veehv5emr30i5u0qhpioam1o323ff.apps.googleusercontent.com';
  static const String _defaultAndroidClient =
      '291599246813-s4qbci9fidph7o32u9tkt39kj6mh6vpj.apps.googleusercontent.com';
  static const String _defaultIosClient =
      '291599246813-a9rtbd1cu95sbv91kehn0vjnrfg0iggf.apps.googleusercontent.com';

  static Future<void> initialize() async {
    // 1. Try loading non-dotfile asset 'assets/env' first
    try {
      await dotenv.load(fileName: 'assets/env');
      if (hasValidSupabaseConfig) return;
    } catch (_) {}

    // 2. Fallback to '.env' asset
    try {
      await dotenv.load(fileName: '.env');
      if (hasValidSupabaseConfig) return;
    } catch (e) {
      debugPrint('AppConfig: Note: .env asset could not be loaded ($e).');
    }
  }

  static String get supabaseUrl {
    if (_constSupabaseUrl.isNotEmpty) return _constSupabaseUrl.trim();
    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.maybeGet('SUPABASE_URL');
      if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
        return fromDotenv.trim();
      }
    }
    return _defaultSupabaseUrl.trim();
  }

  static String get supabaseAnonKey {
    if (_constSupabaseAnonKey.isNotEmpty) return _constSupabaseAnonKey.trim();
    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.maybeGet('SUPABASE_ANON_KEY');
      if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
        return fromDotenv.trim();
      }
    }
    return _defaultSupabaseAnonKey.trim();
  }

  static String get googleWebClient {
    if (_constWebClient.isNotEmpty) return _constWebClient.trim();
    if (dotenv.isInitialized) {
      final fromDotenv =
          dotenv.maybeGet('web_client') ?? dotenv.maybeGet('WEB_CLIENT');
      if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
        return fromDotenv.trim();
      }
    }
    return _defaultWebClient.trim();
  }

  static String get googleAndroidClient {
    if (_constAndroidClient.isNotEmpty) return _constAndroidClient.trim();
    if (dotenv.isInitialized) {
      final fromDotenv =
          dotenv.maybeGet('android_client') ??
          dotenv.maybeGet('ANDROID_CLIENT');
      if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
        return fromDotenv.trim();
      }
    }
    return _defaultAndroidClient.trim();
  }

  static String get googleIosClient {
    if (_constIosClient.isNotEmpty) return _constIosClient.trim();
    if (dotenv.isInitialized) {
      final fromDotenv =
          dotenv.maybeGet('ios_client') ?? dotenv.maybeGet('IOS_CLIENT');
      if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
        return fromDotenv.trim();
      }
    }
    return _defaultIosClient.trim();
  }

  static bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
