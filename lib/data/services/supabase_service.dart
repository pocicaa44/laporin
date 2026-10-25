import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

/// Service wrapper for Supabase client initialization and access.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? initError;

  Future<void> initialize() async {
    if (!AppConfig.hasValidSupabaseConfig) {
      initError =
          'URL Supabase atau Anon Key belum terkonfigurasi di AppConfig.';
      debugPrint('SupabaseService: $initError');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      initError = null;
    } catch (e) {
      initError = 'Inisialisasi Supabase gagal: $e';
      debugPrint('SupabaseService initialize error: $e');
      _isInitialized = false;
    }
  }

  SupabaseClient? get client {
    if (!_isInitialized) {
      // Lazy attempt: cek apakah Supabase instance sebenarnya sudah terinisialisasi
      try {
        if (Supabase.instance.isInitialized) {
          _isInitialized = true;
          return Supabase.instance.client;
        }
      } catch (_) {}
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      initError = 'Gagal mengakses SupabaseClient: $e';
      return null;
    }
  }

  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
}
