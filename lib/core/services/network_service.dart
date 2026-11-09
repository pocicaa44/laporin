import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';

typedef InternetChecker = Future<bool> Function();

/// NetworkService monitors network connectivity, validates real internet reachability,
/// and broadcasts reactive connectivity status across the application.
class NetworkService extends ChangeNotifier {
  NetworkService({Connectivity? connectivity, InternetChecker? internetChecker})
    : _connectivity = connectivity ?? Connectivity(),
      _internetChecker = internetChecker ?? defaultInternetChecker;

  /// Global singleton instance
  static final NetworkService instance = NetworkService();

  /// Global ScaffoldMessenger key
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global RouteObserver to track screen transitions
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  final Connectivity _connectivity;
  final InternetChecker _internetChecker;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _isOverviewActive = false;
  bool _isTestingMode = false;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Stream of connectivity status changes
  Stream<bool> get onOnlineStatusChanged => _statusController.stream;

  /// Whether user is currently on the initial overview/splash screen (retained for backward compatibility)
  bool get isOverviewActive => _isOverviewActive;

  /// Default internet checker validating real host lookup
  static Future<bool> defaultInternetChecker() async {
    if (kIsWeb) {
      return true;
    }
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check whether the results indicate active network interface
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

  /// Initialize connectivity listening and verify internet
  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _evaluateConnectivity(results, initial: true);
    } catch (e) {
      debugPrint('NetworkService initialize error: $e');
      _isOnline = true;
    }

    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(
      handleConnectivityResults,
    );
  }

  /// Evaluate interface and real internet reachability
  Future<void> _evaluateConnectivity(
    List<ConnectivityResult> results, {
    bool initial = false,
  }) async {
    final hasInterface = isConnectedResults(results);
    bool online = false;
    if (hasInterface) {
      try {
        online = await _internetChecker();
      } catch (_) {
        online = false;
      }
    }

    final wasOnline = _isOnline;
    _isOnline = online;

    if (!initial && wasOnline != online) {
      _statusController.add(online);
      notifyListeners();
    } else if (initial) {
      notifyListeners();
    }
  }

  /// Handle connectivity state change from platform stream
  Future<void> handleConnectivityResults(
    List<ConnectivityResult> results,
  ) async {
    await _evaluateConnectivity(results);
  }

  /// Manually check connection reachability on-demand
  Future<bool> checkConnection() async {
    if (_isTestingMode) {
      return _isOnline;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      await _evaluateConnectivity(results);
    } catch (_) {}
    return _isOnline;
  }

  /// Set overview active (backward-compatible method)
  void setOverviewActive(bool active, {bool notifyIfOffline = true}) {
    if (_isOverviewActive == active) return;
    _isOverviewActive = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Backward-compatible SnackBar helpers
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    } catch (_) {}
  }

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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    } catch (_) {}
  }

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
    _isTestingMode = true;
    if (isOverviewActive != null) {
      _isOverviewActive = isOverviewActive;
    }
    final wasOnline = _isOnline;
    _isOnline = isOnline;
    if (wasOnline != isOnline) {
      _statusController.add(isOnline);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    super.dispose();
  }
}

/// Convenience extension on BuildContext for safe network state access
extension NetworkContextExtension on BuildContext {
  /// Safely watch current online status with fallback for isolated widget tests
  bool get isOnline {
    try {
      return watch<NetworkService>().isOnline;
    } catch (_) {
      return NetworkService.instance.isOnline;
    }
  }

  /// Safely read NetworkService instance with fallback for isolated widget tests
  NetworkService get networkService {
    try {
      return read<NetworkService>();
    } catch (_) {
      return NetworkService.instance;
    }
  }
}
