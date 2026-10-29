import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
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

  SupabaseClient _requireClient() {
    final client = _service.client;
    if (client == null) {
      final detail = _service.initError;
      throw Exception(
        detail != null
            ? 'Koneksi Supabase belum terhubung ($detail)'
            : 'Koneksi Supabase belum terhubung. Periksa konfigurasi .env',
      );
    }
    return client;
  }

  /// Helper untuk membangun [UserProfileModel] dari user Supabase dan tabel profiles secara konsisten.
  Future<UserProfileModel> _buildUserProfile(
    User user, {
    String? fallbackFullName,
    String? fallbackEmail,
    String? fallbackAvatarUrl,
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

    // Ambil avatar bawaan dari Google OAuth / OIDC metadata (avatar_url, picture, photo_url)
    // atau fallback dari native GoogleSignIn (photoUrl)
    final googleMetaAvatar =
        user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String? ??
        user.userMetadata?['photo_url'] as String? ??
        fallbackAvatarUrl;

    // Prioritas:
    // 1. dbAvatarUrl jika ada di profiles (bisa custom avatar yang diunggah pengguna)
    // 2. googleMetaAvatar jika dbAvatarUrl belum diisi / null (avatar bawaan akun Google)
    final resolvedAvatarUrl =
        (dbAvatarUrl != null && dbAvatarUrl.trim().isNotEmpty)
        ? dbAvatarUrl.trim()
        : (googleMetaAvatar != null && googleMetaAvatar.trim().isNotEmpty
              ? googleMetaAvatar.trim()
              : null);

    // Jika di database profiles belum ada avatar_url (atau masih kosong),
    // tapi pengguna memiliki foto profil bawaan Google, sinkronkan ke
    // tabel profiles di Supabase secara otomatis agar laporan & interaksi pengguna
    // mendapatkan foto profil Google mereka secara konsisten.
    if ((dbAvatarUrl == null || dbAvatarUrl.trim().isEmpty) &&
        resolvedAvatarUrl != null &&
        resolvedAvatarUrl.isNotEmpty &&
        client != null) {
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': resolvedFullName,
          if (resolvedUsername.isNotEmpty) 'username': resolvedUsername,
          'avatar_url': resolvedAvatarUrl,
          'role': userRole.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (syncError) {
        debugPrint('Catatan sync google avatar ke profiles: $syncError');
      }
    }

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
      try {
        _currentUserProfile = await _buildUserProfile(sessionUser);
      } catch (e) {
        debugPrint('Catatan initSessionFromSupabase offline fallback: $e');
        _currentUserProfile = UserProfileModel(
          id: sessionUser.id,
          email: sessionUser.email ?? '',
          fullName:
              sessionUser.userMetadata?['full_name'] as String? ??
              'Warga Laporin',
          username: sessionUser.userMetadata?['username'] as String? ?? '',
          avatarUrl: sessionUser.userMetadata?['avatar_url'] as String?,
          role: UserRole.fromString(
            sessionUser.userMetadata?['role'] as String?,
          ),
        );
      }
    } else {
      _currentUserProfile = null;
    }
  }

  /// Cek apakah username tersedia dan belum digunakan oleh user lain.
  Future<bool> checkUsernameAvailability(String username) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.length < 3 || trimmed.length > 30) {
      return false;
    }

    final client = _service.client;
    if (client == null) {
      if (_currentUserProfile != null) {
        // Offline / mock testing fallback when profile is initialized
        return true;
      }
      final detail = _service.initError;
      throw Exception(
        detail != null
            ? 'Koneksi Supabase belum terhubung ($detail)'
            : 'Koneksi Supabase belum terhubung.',
      );
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
    final client = _requireClient();

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

  /// Simpan atau perbarui informasi profil pengguna (Nama Pengguna / full_name dan Nama Akun / username)
  Future<UserProfileModel> updateProfileInfo({
    String? fullName,
    String? username,
  }) async {
    final client = _service.client;
    final user = client?.auth.currentUser;
    final userId = _currentUserProfile?.id ?? user?.id;

    if (userId == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    String? cleanUsername;
    if (username != null) {
      final trimmed = username.trim().replaceFirst('@', '').toLowerCase();
      if (trimmed.isNotEmpty) {
        // Cek ketersediaan jika username berubah
        final currentUsername =
            _currentUserProfile?.username
                .trim()
                .replaceFirst('@', '')
                .toLowerCase() ??
            '';
        if (trimmed != currentUsername) {
          final isAvailable = await checkUsernameAvailability(trimmed);
          if (!isAvailable) {
            throw Exception('Nama akun "@$trimmed" sudah digunakan.');
          }
        }
        cleanUsername = trimmed;
      }
    }

    String? cleanFullName;
    if (fullName != null) {
      final trimmed = fullName.trim();
      if (trimmed.isNotEmpty) {
        cleanFullName = trimmed;
      }
    }

    final finalFullName =
        cleanFullName ??
        _currentUserProfile?.fullName ??
        user?.userMetadata?['full_name'] as String? ??
        'Warga Laporin';

    final finalUsername =
        cleanUsername ??
        _currentUserProfile?.username ??
        user?.userMetadata?['username'] as String? ??
        '';

    if (client != null) {
      try {
        final profileUpdates = <String, dynamic>{
          'id': userId,
          'full_name': finalFullName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (finalUsername.isNotEmpty) {
          profileUpdates['username'] = finalUsername;
        }

        final resolvedAvatar =
            _currentUserProfile?.avatarUrl ??
            user?.userMetadata?['avatar_url'] as String? ??
            user?.userMetadata?['picture'] as String? ??
            user?.userMetadata?['photo_url'] as String?;
        if (resolvedAvatar != null && resolvedAvatar.trim().isNotEmpty) {
          profileUpdates['avatar_url'] = resolvedAvatar.trim();
        }

        await client.from('profiles').upsert(profileUpdates);

        final authMetadataUpdates = <String, dynamic>{
          'full_name': finalFullName,
        };
        if (finalUsername.isNotEmpty) {
          authMetadataUpdates['username'] = finalUsername;
        }

        await client.auth.updateUser(UserAttributes(data: authMetadataUpdates));
      } catch (e) {
        throw Exception(
          e
              .toString()
              .replaceFirst('AuthException: ', '')
              .replaceFirst('Exception: ', ''),
        );
      }
    }

    _currentUserProfile =
        _currentUserProfile?.copyWith(
          fullName: finalFullName,
          username: finalUsername,
        ) ??
        UserProfileModel(
          id: userId,
          email: user?.email ?? '',
          fullName: finalFullName,
          username: finalUsername,
          role: UserRole.fromString(user?.userMetadata?['role'] as String?),
        );

    return _currentUserProfile!;
  }

  /// Simpan atau perbarui username akun pengguna
  Future<UserProfileModel> updateUsername(String newUsername) async {
    return updateProfileInfo(username: newUsername);
  }

  /// Simpan atau perbarui nama pengguna / nama lengkap
  Future<UserProfileModel> updateFullName(String newFullName) async {
    return updateProfileInfo(fullName: newFullName);
  }

  /// Unggah foto profil baru ke Supabase Storage, perbarui database, dan hapus foto lama secara aman.
  ///
  /// Urutan aman:
  /// 1. Catat avatar lama sebelum mutasi.
  /// 2. Upload avatar baru (terkompresi <= 30 KB).
  /// 3. Update database tabel profiles dan auth metadata.
  ///    Jika database gagal, bersihkan avatar baru yatim (best-effort) dan pertahankan avatar lama.
  /// 4. Perbarui state lokal aplikasi.
  /// 5. Hapus file avatar lama dari Supabase Storage jika valid milik pengguna.
  ///    Jika penghapusan avatar lama gagal, avatar baru tetap aktif (jangan batalkan mutasi).
  /// 6. Evict cache gambar agar foto baru langsung terlihat.
  Future<UserProfileModel> updateAvatar(XFile file) async {
    final client = _service.client;
    final user = client?.auth.currentUser;
    final userId = _currentUserProfile?.id ?? user?.id;

    if (userId == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    // 1. Ambil path avatar lama dari data profil aktif
    final oldAvatarUrl =
        _currentUserProfile?.avatarUrl ??
        (user?.userMetadata?['avatar_url'] as String?);

    // 2. Upload foto baru ke Supabase Storage (otomatis terkompresi <= 30.000 byte)
    final String newAvatarUrl;
    try {
      newAvatarUrl = await MediaService.instance.uploadAvatar(
        userId: userId,
        file: file,
      );
    } catch (e) {
      // Upload avatar baru gagal: pertahankan avatar lama dan tampilkan pesan kegagalan
      rethrow;
    }

    // 3. Perbarui referensi avatar pada tabel profiles di database
    if (client != null) {
      try {
        try {
          await client
              .from('profiles')
              .update({
                'avatar_url': newAvatarUrl,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', userId);
        } catch (profileError) {
          debugPrint('Catatan update avatar di profiles: $profileError');
          // Fallback upsert jika baris belum terbentuk
          await client.from('profiles').upsert({
            'id': userId,
            'avatar_url': newAvatarUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        }

        // Perbarui user metadata di auth session
        try {
          await client.auth.updateUser(
            UserAttributes(data: {'avatar_url': newAvatarUrl}),
          );
        } catch (authMetaError) {
          debugPrint('Catatan update user metadata: $authMetaError');
        }
      } catch (dbError) {
        // Update database gagal: bersihkan file baru yang yatim, pertahankan avatar lama
        debugPrint(
          'Catatan update database gagal, membersihkan avatar baru yatim: $dbError',
        );
        try {
          await MediaService.instance.deleteAvatarFile(
            avatarUrl: newAvatarUrl,
            userId: userId,
          );
        } catch (cleanupError) {
          debugPrint(
            'Catatan gagal membersihkan avatar baru yatim: $cleanupError',
          );
        }
        throw Exception(
          'Gagal memperbarui referensi foto profil di database: $dbError',
        );
      }
    }

    // 4. Perbarui state lokal currentUserProfile secara reaktif
    _currentUserProfile =
        _currentUserProfile?.copyWith(avatarUrl: newAvatarUrl) ??
        UserProfileModel(
          id: userId,
          email: user?.email ?? '',
          fullName:
              user?.userMetadata?['full_name'] as String? ?? 'Warga Laporin',
          username: user?.userMetadata?['username'] as String? ?? '',
          avatarUrl: newAvatarUrl,
          role: UserRole.fromString(user?.userMetadata?['role'] as String?),
        );

    // 5. Setelah avatar baru aktif dan profil berhasil disimpan, hapus file avatar lama dari Storage
    if (oldAvatarUrl != null &&
        oldAvatarUrl.trim().isNotEmpty &&
        oldAvatarUrl.trim() != newAvatarUrl.trim()) {
      try {
        await MediaService.instance.deleteAvatarFile(
          avatarUrl: oldAvatarUrl,
          userId: userId,
        );
      } catch (deleteError) {
        // Kegagalan penghapusan avatar lama tidak membatalkan avatar baru yang sudah aktif
        debugPrint(
          'Catatan penghapusan avatar lama gagal (diabaikan agar pengguna tidak terganggu): $deleteError',
        );
      }

      // 6. Bersihkan cache gambar lama
      _evictImageCache(oldAvatarUrl);
    }

    return _currentUserProfile!;
  }

  /// Reset / hapus foto profil kustom dan kembali ke avatar default generic.
  /// Menghapus file avatar lama dari storage setelah database berhasil diperbarui.
  Future<UserProfileModel> removeAvatar() async {
    final client = _service.client;
    final user = client?.auth.currentUser;
    final userId = _currentUserProfile?.id ?? user?.id;

    if (userId == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    final oldAvatarUrl =
        _currentUserProfile?.avatarUrl ??
        (user?.userMetadata?['avatar_url'] as String?);

    if (client != null) {
      try {
        await client
            .from('profiles')
            .update({
              'avatar_url': null,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', userId);
      } catch (profileError) {
        debugPrint('Catatan reset avatar di profiles: $profileError');
        throw Exception('Gagal mereset foto profil di database: $profileError');
      }

      try {
        await client.auth.updateUser(
          UserAttributes(data: {'avatar_url': null}),
        );
      } catch (authMetaError) {
        debugPrint('Catatan reset avatar di user metadata: $authMetaError');
      }
    }

    _currentUserProfile = _currentUserProfile?.copyWith(resetAvatar: true);

    // Hapus file avatar lama dari Supabase Storage jika ada
    if (oldAvatarUrl != null && oldAvatarUrl.trim().isNotEmpty) {
      try {
        await MediaService.instance.deleteAvatarFile(
          avatarUrl: oldAvatarUrl,
          userId: userId,
        );
      } catch (deleteError) {
        debugPrint(
          'Catatan gagal menghapus avatar lama saat reset: $deleteError',
        );
      }
      _evictImageCache(oldAvatarUrl);
    }

    return _currentUserProfile!;
  }

  /// Membersihkan memori imageCache Flutter agar avatar yang diperbarui tidak tertutup cache
  void _evictImageCache(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return;
    try {
      PaintingBinding.instance.imageCache.evict(NetworkImage(imageUrl.trim()));
    } catch (_) {
      // Abaikan jika binding belum diinisialisasi pada pure unit tests
    }
  }

  Future<UserProfileModel> signInWithEmail(
    String email,
    String password,
  ) async {
    final client = _requireClient();

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
        throw Exception('Email atau password salah');
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credential') ||
          e.code == 'invalid_credentials' ||
          (e.statusCode == '400' && msg.contains('credential'))) {
        throw Exception('Email atau password salah');
      }
      throw Exception(
        e.message
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credential')) {
        throw Exception('Email atau password salah');
      }
      throw Exception(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<UserProfileModel?> signInWithGoogle() async {
    final client = _requireClient();

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
        fallbackAvatarUrl: googleAccount.photoUrl,
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

  /// Mengirim kode OTP pemulihan kata sandi ke email pengguna via Supabase Auth
  Future<void> sendResetPasswordOtp(String email) async {
    final client = _requireClient();

    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Verifikasi kode 6-digit OTP pemulihan kata sandi pengguna
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    final client = _requireClient();

    try {
      final response = await client.auth.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: OtpType.recovery,
      );
      if (response.user == null) {
        throw Exception('Kode OTP tidak valid atau sudah kedaluwarsa.');
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('token has expired') ||
          msg.contains('token is invalid') ||
          msg.contains('otp has expired') ||
          msg.contains('invalid token')) {
        throw Exception('Kode OTP tidak valid atau sudah kedaluwarsa.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Memperbarui kata sandi baru untuk sesi pemulihan yang telah terotentikasi
  Future<void> updatePassword(String newPassword) async {
    final client = _requireClient();

    try {
      final response = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user == null) {
        throw Exception('Gagal memperbarui kata sandi.');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
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
