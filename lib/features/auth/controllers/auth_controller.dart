import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/fcm_service.dart';
import '../../../core/services/media_service.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Controller for authentication and active user session state.
class AuthController extends ChangeNotifier {
  AuthController({required this.authRepository}) {
    _initAuthListener();
  }

  final AuthRepository authRepository;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isDisposed = false;

  void _initAuthListener() {
    _authSubscription = authRepository.onAuthStateChange?.listen(
      (data) async {
        if (_isDisposed) return;
        final event = data.event;
        if (event == AuthChangeEvent.signedOut) {
          authRepository.clearSession();
          try {
            FcmService.instance.removeTokenFromSupabase();
          } catch (_) {}
          notifyListeners();
        } else if (event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated ||
            event == AuthChangeEvent.signedIn) {
          try {
            await authRepository.initSessionFromSupabase();
          } catch (e) {
            debugPrint('Auth listener initSession notice: $e');
          }
          if (_isDisposed) return;
          try {
            FcmService.instance.syncTokenWithSupabase();
          } catch (e) {
            debugPrint('Auth listener syncToken notice: $e');
          }
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('Auth state change listener notice: $error');
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProfileModel? get currentUser => authRepository.currentUserProfile;
  bool get isAuthenticated => authRepository.isAuthenticated;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<bool> signInWithEmail(String email, String password) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      final rawMsg = e.toString().replaceFirst('Exception: ', '');
      final lower = rawMsg.toLowerCase();
      if (lower.contains('invalid login credentials') ||
          lower.contains('invalid credential') ||
          lower.contains('email atau password salah') ||
          lower.contains('email atau password tidak sesuai')) {
        _errorMessage = 'Email atau password salah';
      } else {
        _errorMessage = rawMsg;
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRepository.signInWithGoogle();
      _isLoading = false;
      if (user == null) {
        // Pemilihan akun dibatalkan oleh pengguna secara sadar
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.signUpWithEmail(
        username: username,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileInfo({String? fullName, String? username}) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updateProfileInfo(
        fullName: fullName,
        username: username,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUsername(String newUsername) async {
    return updateProfileInfo(username: newUsername);
  }

  Future<bool> updateFullName(String newFullName) async {
    return updateProfileInfo(fullName: newFullName);
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      return await authRepository.checkUsernameAvailability(username);
    } catch (_) {
      return false;
    }
  }

  /// Unggah foto avatar dari objek XFile yang dipilih
  Future<bool> updateAvatar(XFile file) async {
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updateAvatar(file);
      _isUploadingAvatar = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploadingAvatar = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Hapus foto profil dan kembali menggunakan avatar default generic
  Future<bool> removeAvatar() async {
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.removeAvatar();
      _isUploadingAvatar = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploadingAvatar = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Membuka galeri perangkat via image_picker dan mengunggah foto profil teroptimasi ke Supabase
  Future<bool> pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return false;
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await MediaService.instance.pickAvatarImage(
        ImageSource.gallery,
      );
      if (file == null) {
        _isUploadingAvatar = false;
        notifyListeners();
        return false;
      }
      return await updateAvatar(file);
    } catch (e) {
      _isUploadingAvatar = false;
      final msg = e.toString().toLowerCase();
      if (msg.contains('already_active') || msg.contains('already active')) {
        notifyListeners();
        return false;
      }
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui ulang profil aktif dari Supabase
  Future<void> refreshProfile() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      await authRepository.initSessionFromSupabase();
    } catch (e) {
      debugPrint('Catatan refreshProfile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendResetPasswordOtp(String email) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.sendResetPasswordOtp(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.verifyRecoveryOtp(email: email, otp: otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      try {
        await FcmService.instance.removeTokenFromSupabase();
      } catch (_) {}
      await authRepository.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
