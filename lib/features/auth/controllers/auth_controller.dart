import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signOut() async {
    await authRepository.signOut();
    notifyListeners();
  }
}
