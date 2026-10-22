import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _authSubscription = authRepository.onAuthStateChange?.listen((data) async {
      if (_isDisposed) return;
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        authRepository.clearSession();
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.signedIn) {
        await authRepository.initSessionFromSupabase();
        if (_isDisposed) return;
        notifyListeners();
      }
    });
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
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

  Future<bool> updateUsername(String newUsername) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updateUsername(newUsername);
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

  /// Membuka galeri perangkat via image_picker dan mengunggah foto profil ke Supabase
  Future<bool> pickAndUploadAvatar() async {
    try {
      final file = await MediaService.instance.pickImage(ImageSource.gallery);
      if (file == null) {
        return false;
      }
      return await updateAvatar(file);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui ulang profil aktif dari Supabase
  Future<void> refreshProfile() async {
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

  Future<void> signOut() async {
    await authRepository.signOut();
    notifyListeners();
  }
}
