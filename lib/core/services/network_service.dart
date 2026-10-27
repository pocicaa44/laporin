import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// NetworkService monitors network connectivity and displays offline/online SnackBars
/// across the application, with the exception of the initial overview/splash screen.
class NetworkService extends ChangeNotifier {
  NetworkService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Global singleton instance
  static final NetworkService instance = NetworkService();

  /// Global ScaffoldMessenger key to show SnackBars from anywhere without Scaffold context
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global RouteObserver to track screen transitions
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _isOverviewActive = false;
  bool _hasInitialized = false;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Whether user is currently on the initial overview/splash screen
  bool get isOverviewActive => _isOverviewActive;

  /// Check whether the results indicate active network connection
  static bool isConnectedResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other,
    );
  }

  /// Initialize connectivity listening
  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = isConnectedResults(results);
    } catch (e) {
      debugPrint('NetworkService initialize error: $e');
      _isOnline = true;
    }
    _hasInitialized = true;

    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(
      handleConnectivityResults,
    );
  }

  /// Handle connectivity state change
  void handleConnectivityResults(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    final nowOnline = isConnectedResults(results);
    _isOnline = nowOnline;

    if (_hasInitialized && wasOnline == nowOnline) {
      return;
    }
    _hasInitialized = true;

    if (!nowOnline) {
      // Device is now offline
      if (!_isOverviewActive) {
        showOfflineSnackBar();
      }
    } else {
      // Device is now back online (only notify if was previously offline)
      if (!wasOnline && !_isOverviewActive) {
        showOnlineSnackBar();
      }
    }

    notifyListeners();
  }

  /// Set whether the initial overview/splash screen is active
  void setOverviewActive(bool active, {bool notifyIfOffline = true}) {
    if (_isOverviewActive == active) return;
    _isOverviewActive = active;

    if (active) {
      // Entering overview screen: hide any network snackbars
      hideSnackBar();
    } else if (notifyIfOffline) {
      // Leaving overview screen: if currently offline, show offline warning
      if (!_isOnline) {
        showOfflineSnackBar();
      }
    }
    notifyListeners();
  }

  /// Show "Anda sedang offline" SnackBar
  void showOfflineSnackBar() {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null || !messenger.mounted) return;

    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Anda sedang offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF23272F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint('showOfflineSnackBar skipped: $e');
    }
  }

  /// Show "Kembali online" SnackBar
  void showOnlineSnackBar() {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null || !messenger.mounted) return;

    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kembali online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint('showOnlineSnackBar skipped: $e');
    }
  }

  /// Hide current SnackBar
  void hideSnackBar() {
    try {
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    } catch (_) {}
  }

  /// Testing helper to simulate status changes
  void updateStatusForTesting({
    required bool isOnline,
    bool? isOverviewActive,
  }) {
    if (isOverviewActive != null) {
      _isOverviewActive = isOverviewActive;
    }
    final wasOnline = _isOnline;
    _isOnline = isOnline;
    _hasInitialized = true;

    if (!isOnline) {
      if (!_isOverviewActive) {
        showOfflineSnackBar();
      }
    } else {
      if (!wasOnline && !_isOverviewActive) {
        showOnlineSnackBar();
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
