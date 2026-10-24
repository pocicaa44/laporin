import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/screens/admin_navigation_screen.dart';
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
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isAuthenticated) {
      final user = auth.currentUser;
      final hasUsername = user?.username.trim().isNotEmpty ?? false;
      if (!hasUsername) {
        return const SetUsernameScreen();
      }
      if (auth.isAdmin) {
        return const AdminNavigationScreen();
      }
      return const MainNavigationScreen();
    }

    return const SplashScreen();
  }
}
