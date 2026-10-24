import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/services/media_service.dart';
import '../models/user_profile_model.dart';
import '../services/supabase_service.dart';

/// Repository for handling Authentication & Profile state.
class AuthRepository {
  AuthRepository({SupabaseService? supabaseService})
    : _service = supabaseService ?? SupabaseService.instance;

  final SupabaseService _service;

  // Active user profile state (null if not authenticated)
  UserProfileModel? _currentUserProfile;

  UserProfileModel? get currentUserProfile => _currentUserProfile;

  bool get isAuthenticated => _currentUserProfile != null;

  /// Expose the Supabase auth state change stream for listeners.
  Stream<AuthState>? get onAuthStateChange =>
      _service.client?.auth.onAuthStateChange;

  /// Clear the cached session and profile.
  void clearSession() {
    _currentUserProfile = null;
  }

  /// Helper for unit/widget testing to simulate authenticated states without network.
  void setCurrentUserProfileForTesting(UserProfileModel? profile) {
    _currentUserProfile = profile;
  }

  /// Helper untuk membangun [UserProfileModel] dari user Supabase dan tabel profiles secara konsisten.
  Future<UserProfileModel> _buildUserProfile(
    User user, {
    String? fallbackFullName,
    String? fallbackEmail,
  }) async {
    final client = _service.client;
    String? dbUsername;
    String? dbFullName;
    String? dbAvatarUrl;
    UserRole userRole = UserRole.fromString(
      user.userMetadata?['role'] as String?,
    );

    if (client != null) {
      try {
        final profile = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          dbUsername = profile['username'] as String?;
          dbFullName = profile['full_name'] as String?;
          dbAvatarUrl = profile['avatar_url'] as String?;
          userRole = UserRole.fromString(profile['role'] as String?);
        }
      } catch (e) {
        debugPrint('Catatan fetch profile: $e');
      }
    }

    final resolvedUsername =
        dbUsername ?? user.userMetadata?['username'] as String? ?? '';
    final resolvedFullName =
        dbFullName ??
        user.userMetadata?['full_name'] as String? ??
        fallbackFullName ??
        'Warga Laporin';
    final resolvedAvatarUrl =
        dbAvatarUrl ?? user.userMetadata?['avatar_url'] as String?;

    return UserProfileModel(
      id: user.id,
      email: user.email ?? fallbackEmail ?? '',
      fullName: resolvedFullName,
      username: resolvedUsername,
      avatarUrl: resolvedAvatarUrl,
      role: userRole,
    );
  }

  Future<void> initSessionFromSupabase() async {
    final client = _service.client;
    final sessionUser = client?.auth.currentUser;
    if (sessionUser != null && client != null) {
      _currentUserProfile = await _buildUserProfile(sessionUser);
    } else {
      _currentUserProfile = null;
    }
  }

  /// Cek apakah username tersedia dan belum digunakan oleh user lain.
  Future<bool> checkUsernameAvailability(String username) async {
    final client = _service.client;
    if (client == null) {
      throw Exception('Koneksi Supabase belum terhubung.');
    }

    final trimmed = username.trim().toLowerCase();
    if (trimmed.length < 3 || trimmed.length > 30) {
      return false;
    }

    try {
      final currentUserId = client.auth.currentUser?.id;
      final data = await client
          .from('profiles')
          .select('id, username')
          .ilike('username', trimmed)
          .maybeSingle();

      if (data == null) {
        return true;
      }

      // Jika username sudah milik akun aktif saat ini
      if (currentUserId != null && data['id'] == currentUserId) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      rethrow;
    }
  }

  /// Registrasi akun baru dengan username, email, dan password.
  Future<UserProfileModel> signUpWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    final client = _service.client;
    if (client == null) {
      throw Exception(
        'Koneksi Supabase belum terhubung. Periksa konfigurasi .env',
      );
    }

    final cleanUsername = username.trim().toLowerCase();

    // 1. Validasi keunikan username
    final isAvailable = await checkUsernameAvailability(cleanUsername);
    if (!isAvailable) {
      throw Exception('Username "$cleanUsername" sudah digunakan.');
    }

    try {
      // 2. Registrasi di Supabase Auth
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': cleanUsername,
          'full_name': username.trim(),
          'role': 'user',
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Gagal membuat akun baru.');
      }

      // 3. Simpan entri di tabel public.profiles
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'username': cleanUsername,
          'full_name': username.trim(),
          'role': 'user',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (profileError) {
        debugPrint('Catatan insert profile: $profileError');
      }

      _currentUserProfile = UserProfileModel(
        id: user.id,
        email: user.email ?? email.trim(),
        fullName: username.trim(),
        username: cleanUsername,
        role: UserRole.user,
      );

      return _currentUserProfile!;
    } catch (e) {
      throw Exception(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Simpan atau perbarui username akun pengguna
  Future<UserProfileModel> updateUsername(String newUsername) async {
    final client = _service.client;
    if (client == null) {
      throw Exception('Koneksi Supabase belum terhubung.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    final cleanUsername = newUsername.trim().toLowerCase();

    // Pastikan username belum digunakan
    final isAvailable = await checkUsernameAvailability(cleanUsername);
    if (!isAvailable) {
      throw Exception('Username "$cleanUsername" sudah digunakan.');
    }

    try {
      final displayName =
          _currentUserProfile?.fullName ??
          user.userMetadata?['full_name'] as String? ??
          cleanUsername;

      await client.from('profiles').upsert({
        'id': user.id,
        'username': cleanUsername,
        'full_name': displayName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      await client.auth.updateUser(
        UserAttributes(data: {'username': cleanUsername}),
      );

      _currentUserProfile =
          _currentUserProfile?.copyWith(username: cleanUsername) ??
          UserProfileModel(
            id: user.id,
            email: user.email ?? '',
            fullName: displayName,
            username: cleanUsername,
            role: UserRole.fromString(user.userMetadata?['role'] as String?),
          );

      return _currentUserProfile!;
    } catch (e) {
      throw Exception(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Unggah foto profil baru ke Supabase Storage dan perbarui kolom avatar_url di tabel profiles
  Future<UserProfileModel> updateAvatar(XFile file) async {
    final client = _service.client;
    final user = client?.auth.currentUser;
    final userId = _currentUserProfile?.id ?? user?.id;

    if (userId == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    // 1. Upload ke Supabase Storage (path aman: avatars/{userId}/avatar_{timestamp}.{ext})
    final avatarUrl = await MediaService.instance.uploadAvatar(
      userId: userId,
      file: file,
    );

    // 2. Perbarui kolom avatar_url pada tabel public.profiles di Supabase jika client aktif
    if (client != null) {
      try {
        await client
            .from('profiles')
            .update({
              'avatar_url': avatarUrl,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', userId);
      } catch (profileError) {
        debugPrint('Catatan update avatar di profiles: $profileError');
        try {
          await client.from('profiles').upsert({
            'id': userId,
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (upsertError) {
          debugPrint('Catatan upsert avatar di profiles: $upsertError');
        }
      }

      // 3. Perbarui user metadata di auth session
      try {
        await client.auth.updateUser(
          UserAttributes(data: {'avatar_url': avatarUrl}),
        );
      } catch (authMetaError) {
        debugPrint('Catatan update user metadata: $authMetaError');
      }
    }

    // 4. Perbarui state lokal currentUserProfile secara reaktif
    _currentUserProfile =
        _currentUserProfile?.copyWith(avatarUrl: avatarUrl) ??
        UserProfileModel(
          id: userId,
          email: user?.email ?? '',
          fullName:
              user?.userMetadata?['full_name'] as String? ?? 'Warga Laporin',
          username: user?.userMetadata?['username'] as String? ?? '',
          avatarUrl: avatarUrl,
          role: UserRole.fromString(user?.userMetadata?['role'] as String?),
        );

    return _currentUserProfile!;
  }

  Future<UserProfileModel> signInWithEmail(
    String email,
    String password,
  ) async {
    final client = _service.client;
    if (client == null) {
      throw Exception(
        'Koneksi Supabase belum terhubung. Periksa konfigurasi .env',
      );
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        _currentUserProfile = await _buildUserProfile(
          user,
          fallbackEmail: email,
        );
        return _currentUserProfile!;
      } else {
        throw Exception('Email atau password tidak sesuai.');
      }
    } catch (e) {
      throw Exception(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<UserProfileModel?> signInWithGoogle() async {
    final client = _service.client;
    if (client == null) {
      throw Exception(
        'Koneksi Supabase belum terhubung. Periksa konfigurasi .env',
      );
    }

    // Platform check: Di Web, gunakan Supabase OAuth flow (redirect/popup)
    if (kIsWeb) {
      try {
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : null,
        );
        return null;
      } catch (e) {
        throw Exception(
          e
              .toString()
              .replaceFirst('AuthException: ', '')
              .replaceFirst('Exception: ', ''),
        );
      }
    }

    // Platform check: Di Mobile (Android/iOS), gunakan native Gmail account picker
    try {
      // 1. Inisialisasi GoogleSignIn dengan client ID dari konfigurasi
      await GoogleSignIn.instance.initialize(
        clientId: AppConfig.googleIosClient.isNotEmpty
            ? AppConfig.googleIosClient
            : null,
        serverClientId: AppConfig.googleWebClient.isNotEmpty
            ? AppConfig.googleWebClient
            : null,
      );

      // 2. Tampilkan dialog native Gmail account picker di mobile
      final googleAccount = await GoogleSignIn.instance.authenticate();

      // 3. Ambil token otentikasi OIDC Google (ID Token)
      final googleAuthentication = googleAccount.authentication;
      final idToken = googleAuthentication.idToken;

      if (idToken == null) {
        throw Exception('Tidak berhasil mendapatkan ID Token dari Google.');
      }

      // Ambil accessToken jika tersedia/didukung tanpa memicu requestedScopes empty error
      String? accessToken;
      try {
        final googleAuthorization = await googleAccount.authorizationClient
            .authorizationForScopes(const ['email', 'profile']);
        accessToken = googleAuthorization?.accessToken;
      } catch (e) {
        debugPrint('Catatan scopes authorization: $e');
      }

      // 4. Tukarkan ID Token ke Supabase Auth
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user ?? client.auth.currentUser;
      if (user == null) {
        throw Exception('Gagal membuat sesi otentikasi dengan akun Google.');
      }

      _currentUserProfile = await _buildUserProfile(
        user,
        fallbackFullName: googleAccount.displayName,
        fallbackEmail: googleAccount.email,
      );

      return _currentUserProfile!;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User membatalkan pemilihan akun di Gmail picker
        return null;
      }
      throw Exception('Google Sign-In gagal: ${e.description ?? e.code.name}');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('canceled') || msg.contains('Canceled')) {
        return null;
      }
      throw Exception(
        msg.replaceFirst('AuthException: ', '').replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    try {
      await _service.client?.auth.signOut();
    } catch (_) {}
    _currentUserProfile = null;
  }
}
