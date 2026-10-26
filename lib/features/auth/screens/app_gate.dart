import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/fcm_service.dart';
import '../../admin/screens/admin_navigation_screen.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/screens/main_navigation_screen.dart';
import '../controllers/auth_controller.dart';
import 'set_username_screen.dart';
import 'splash_screen.dart';

/// AppGate dynamically resolves the root screen based on the user's authentication state and role.
///
/// Invariants:
/// - Authenticated admin with username: renders [AdminNavigationScreen].
/// - Authenticated citizen with username: renders [MainNavigationScreen].
/// - Authenticated user without a username (e.g., initial Google sign-in): renders [SetUsernameScreen].
/// - Unauthenticated user: renders [SplashScreen] (Overview screen with 'Mulai Sekarang').
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool? _wasAuthenticated;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isAuthenticated = auth.isAuthenticated;

    // Reset ke Beranda/Feed jika ada transisi dari belum login ke sudah login
    if (_wasAuthenticated == false && isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.read<NavigationController>().resetToHome();
          } catch (_) {}
        }
      });
    }
    _wasAuthenticated = isAuthenticated;

    if (isAuthenticated) {
      final user = auth.currentUser;
      final hasUsername = user?.username.trim().isNotEmpty ?? false;
      if (!hasUsername) {
        return const SetUsernameScreen();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmService.instance.consumePendingInitialMessage();
      });

      if (auth.isAdmin) {
        return const AdminNavigationScreen();
      }
      return const MainNavigationScreen();
    }

    return const SplashScreen();
  }
}
